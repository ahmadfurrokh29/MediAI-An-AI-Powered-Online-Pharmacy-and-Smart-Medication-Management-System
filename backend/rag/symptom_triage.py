"""
Symptom Triage Engine (Phase 2).

Drives a multi-turn symptom assessment on top of the stateless RAG chatbot:

    SYMPTOM_QUERY ─▶ start_assessment ─▶ (ask Q1)            [ASSESSMENT_STARTED → GATHERING_INFO]
    user answer   ─▶ continue_assessment ─▶ (ask Q2..Qn)    [GATHERING_INFO]
    last answer   ─▶ summary + ask "want medicine info?"     [ASSESSMENT_COMPLETE]
    "yes"/"no"    ─▶ RAG-backed medication info / close       [RECOMMENDATION]

Safety rules baked in:
  * Emergency detection runs on EVERY message (detect_emergency). On a hit the
    workflow is abandoned and urgent guidance is returned — no normal triage.
  * The engine never claims a diagnosis. It explains possible causes, gives
    educational guidance, and recommends professional evaluation.
  * Medication information is only surfaced at the RECOMMENDATION stage, after
    assessment context has been gathered, and always RAG-grounded.

The engine is intent/transport-agnostic: it returns plain dicts that
chat_service merges into the API response.
"""
from __future__ import annotations

import logging
import re
from typing import Dict, List, Optional

from .conversation_state import ConversationStore, TriageSession, TriageState
from .symptom_workflow import resolve_workflow, SymptomWorkflow

logger = logging.getLogger(__name__)


# ── Emergency detection ──────────────────────────────────────────────────────
# Two tiers:
#   ALWAYS  — inherently urgent; fire regardless of phrasing.
#   GATED   — can appear in benign info questions ("does X cause chest pain"),
#             so only fire when first-person / present-tense framing is present
#             and it does NOT look like an information lookup.

_EMERGENCY_ALWAYS: Dict[str, List[str]] = {
    "cardiac": [
        r"crushing chest", r"chest pain.*(?:arm|jaw|spreading)", r"heart attack",
    ],
    "stroke": [
        r"droop", r"slurred", r"slurring", r"stroke",
        r"sudden(?:ly)?\s+(?:numb|weak|confused)", r"worst headache of my life",
        r"thunderclap headache",
    ],
    "unconscious": [
        r"passed out", r"pass(?:ing)? out", r"faint(?:ed|ing)?",
        r"unconscious", r"unresponsive", r"lost consciousness",
        r"loss of consciousness", r"blacked out",
    ],
    "seizure": [
        r"seizure", r"convuls(?:ion|ing)", r"having a fit", r"seizing",
    ],
    "bleeding": [
        r"coughing up blood", r"vomiting blood", r"throwing up blood",
        r"blood in (?:my )?(?:stool|vomit|urine)", r"won'?t stop bleeding",
        r"severe bleeding", r"bleeding heavily",
    ],
    "anaphylaxis": [
        r"anaphylaxis", r"throat (?:is )?(?:closing|swelling)",
        r"can'?t breathe.*(?:swell|allerg)", r"tongue (?:is )?swelling",
        r"severe allergic reaction",
    ],
    "suicidal": [
        r"suicid", r"kill myself", r"end my life", r"want to die",
        r"take my own life", r"don'?t want to (?:live|be alive)",
        r"no reason to live", r"harm myself", r"hurt myself",
    ],
}

_EMERGENCY_GATED: Dict[str, List[str]] = {
    "cardiac": [r"chest pain", r"chest (?:tightness|pressure)", r"tight chest"],
    "breathing": [
        r"difficulty breathing", r"can'?t breathe", r"trouble breathing",
        r"struggling to breathe", r"short(?:ness)? of breath", r"gasping",
    ],
    "stroke": [r"numb on one side", r"weak on one side", r"can'?t move my"],
}

_RX_FIRST_PERSON_EMERG = re.compile(
    r"\b(?:i|we|my|i'?m|i am|i'?ve|having|i\s+have|experiencing|feeling)\b",
    re.IGNORECASE,
)
# Markers that the message is an *information question*, not a live emergency.
_RX_INFO_QUERY = re.compile(
    r"\b(?:does|do|can|could|is it|are there|side effect|cause[ds]?|"
    r"normal|risk|symptom of|list of)\b",
    re.IGNORECASE,
)


def detect_emergency(message: str) -> Optional[str]:
    """
    Return an emergency category string if the message describes a medical
    emergency, else None.
    """
    if not message:
        return None
    text = message.lower()

    for category, patterns in _EMERGENCY_ALWAYS.items():
        for pat in patterns:
            if re.search(pat, text):
                return category

    # Gated terms: require present/first-person framing and not an info query.
    if _RX_FIRST_PERSON_EMERG.search(text) and not _RX_INFO_QUERY.search(text):
        for category, patterns in _EMERGENCY_GATED.items():
            for pat in patterns:
                if re.search(pat, text):
                    return category

    return None


_EMERGENCY_GUIDANCE: Dict[str, str] = {
    "cardiac": (
        "⚠️ **This may be a medical emergency.** Chest pain or pressure — "
        "especially spreading to the arm, jaw, or back, or with sweating, "
        "nausea, or shortness of breath — can be a sign of a heart attack."
    ),
    "breathing": (
        "⚠️ **This may be a medical emergency.** Serious difficulty breathing "
        "needs immediate attention."
    ),
    "stroke": (
        "⚠️ **This may be a medical emergency.** Face drooping, arm weakness, "
        "slurred speech, sudden numbness, or the sudden \"worst headache of your "
        "life\" can be signs of a stroke. **Act fast — every minute matters.**"
    ),
    "unconscious": (
        "⚠️ **This is a medical emergency.** Loss of consciousness or someone "
        "being unresponsive needs immediate help."
    ),
    "seizure": (
        "⚠️ **This may be a medical emergency.** For a seizure, protect the "
        "person from injury, do not restrain them or put anything in their "
        "mouth, and time the seizure."
    ),
    "bleeding": (
        "⚠️ **This may be a medical emergency.** Coughing up or vomiting blood, "
        "blood in stool/urine, or heavy bleeding needs urgent evaluation."
    ),
    "anaphylaxis": (
        "⚠️ **This may be a life-threatening allergic reaction (anaphylaxis).** "
        "Throat swelling or trouble breathing after an exposure is an emergency. "
        "If an epinephrine auto-injector (EpiPen) is available, use it now."
    ),
}

_CALL_EMERGENCY = (
    "\n\n**Call your local emergency number (e.g. 911 / 1122 / 999) or go to the "
    "nearest emergency department now.** If someone is with you, ask them to "
    "help.\n\nI can't assist with emergencies — please get help immediately."
)

_SUICIDAL_GUIDANCE = (
    "I'm really sorry you're feeling this way, and I'm glad you reached out. "
    "Your life matters and you deserve support.\n\n"
    "**Please talk to someone right now:**\n"
    "- Call your local emergency number (e.g. 911 / 1122 / 999).\n"
    "- Reach a suicide-prevention helpline. In the US/Canada call or text "
    "**988**. In the UK call **111** or Samaritans on **116 123**. "
    "Elsewhere, search \"suicide helpline\" plus your country.\n"
    "- If you can, reach out to someone you trust and stay with them.\n\n"
    "If you are in immediate danger, please contact emergency services now. "
    "You don't have to go through this alone."
)


def build_emergency_reply(category: str) -> str:
    """Build the urgent-guidance message for an emergency category."""
    if category == "suicidal":
        return _SUICIDAL_GUIDANCE
    guidance = _EMERGENCY_GUIDANCE.get(
        category,
        "⚠️ **This may be a medical emergency.**",
    )
    return guidance + _CALL_EMERGENCY


# ── Cancel detection (let users leave an assessment) ─────────────────────────
CANCEL_RE = re.compile(
    r"\b(?:cancel|stop|never\s*mind|nevermind|forget it|quit|exit|"
    r"start over|not now)\b",
    re.IGNORECASE,
)


# ── Response helper ──────────────────────────────────────────────────────────

def _response(
    session_id: str,
    reply: str,
    state: Optional[TriageState],
    *,
    triage_active: bool,
    emergency: bool = False,
    sources: Optional[List[dict]] = None,
    rag_used: bool = False,
    intent: str = "symptom_query",
) -> dict:
    return {
        "reply":         reply,
        "sources":       sources or [],
        "rag_used":      rag_used,
        "intent":        intent,
        "session_id":    session_id,
        "triage_active": triage_active,
        "triage_state":  state.value if state else None,
        "emergency":     emergency,
    }


# ── State machine: start ─────────────────────────────────────────────────────

def start_assessment(session_id: str, symptom: Optional[str], query: str) -> dict:
    """
    Begin a symptom assessment. Transitions ASSESSMENT_STARTED → GATHERING_INFO
    and asks the first question.
    """
    store = ConversationStore.instance()
    workflow = resolve_workflow(symptom)
    sym = symptom or workflow.name

    session = store.start(session_id, sym, workflow.name)
    session.state = TriageState.GATHERING_INFORMATION
    session.step_index = 0
    first_q = workflow.questions[0]
    session.awaiting = first_q.key
    store.save(session)

    logger.info(
        "[Triage] ASSESSMENT_STARTED → GATHERING_INFORMATION | session=%s "
        "symptom=%s workflow=%s | asking '%s'",
        session_id, sym, workflow.name, first_q.key,
    )

    reply = (
        f"I'm sorry you're dealing with **{workflow.display.lower()}**. I can't "
        "diagnose, but I can ask a few quick questions and share general "
        "information.\n\n"
        "*(You can type \"cancel\" anytime to stop.)*\n\n"
        f"**1 of {len(workflow.questions)}** — {first_q.prompt}"
    )
    return _response(
        session_id, reply, TriageState.GATHERING_INFORMATION, triage_active=True,
    )


# ── State machine: continue ──────────────────────────────────────────────────

def continue_assessment(session_id: str, message: str) -> dict:
    """
    Process the next user message in an active assessment and advance the state
    machine. Assumes the caller has already verified there is an active session
    and that the message is not an emergency / cancel / intent-switch.
    """
    store = ConversationStore.instance()
    session = store.get(session_id)
    if session is None or not session.is_active():
        # Shouldn't happen — caller guards this. Be safe.
        logger.warning("[Triage] continue with no active session=%s", session_id)
        return start_assessment(session_id, None, message)

    workflow = resolve_workflow(session.symptom)
    logger.info(
        "[Triage] continue | session=%s state=%s symptom=%s follow-up='%s'",
        session_id, session.state.value, session.symptom, message.strip()[:40],
    )

    if session.state == TriageState.GATHERING_INFORMATION:
        return _handle_gathering(store, session, workflow, message)

    if session.state == TriageState.WAITING_FOR_MEDICATION_CONSENT:
        return _handle_consent(store, session, workflow, message)

    # Fallback — restart cleanly.
    logger.warning("[Triage] unexpected state=%s session=%s", session.state, session_id)
    store.clear(session_id)
    return start_assessment(session_id, session.symptom, message)


def _handle_gathering(
    store: ConversationStore,
    session: TriageSession,
    workflow: SymptomWorkflow,
    message: str,
) -> dict:
    """Record the current answer and either ask the next question or finish."""
    # Record the answer to the question we were waiting on.
    if session.awaiting:
        session.collected[session.awaiting] = message.strip()
        logger.info(
            "[Triage] GATHERING_INFORMATION collected | session=%s %s='%s'",
            session.session_id, session.awaiting, message.strip()[:80],
        )

    session.step_index += 1

    # More questions remaining?
    if session.step_index < len(workflow.questions):
        q = workflow.questions[session.step_index]
        session.awaiting = q.key
        store.save(session)
        logger.info(
            "[Triage] GATHERING_INFORMATION progress | session=%s step=%d/%d "
            "asking '%s'",
            session.session_id, session.step_index + 1,
            len(workflow.questions), q.key,
        )
        reply = f"**{session.step_index + 1} of {len(workflow.questions)}** — {q.prompt}"
        return _response(
            session.session_id, reply, TriageState.GATHERING_INFORMATION,
            triage_active=True,
        )

    # All questions answered → ASSESSMENT_COMPLETE → ask for medication consent.
    # The summary and the consent question are delivered together; the session
    # then waits in WAITING_FOR_MEDICATION_CONSENT for a yes/no reply.
    session.state = TriageState.ASSESSMENT_COMPLETE
    summary = _build_summary(workflow, session)
    logger.info(
        "[Triage] GATHERING_INFORMATION → ASSESSMENT_COMPLETE | session=%s data=%s",
        session.session_id, session.collected,
    )

    session.state = TriageState.WAITING_FOR_MEDICATION_CONSENT
    session.awaiting = "medication_consent"
    store.save(session)
    logger.info(
        "[Triage] ASSESSMENT_COMPLETE → WAITING_FOR_MEDICATION_CONSENT | "
        "session=%s", session.session_id,
    )

    return _response(
        session.session_id, summary, TriageState.WAITING_FOR_MEDICATION_CONSENT,
        triage_active=True,
    )


def _handle_consent(
    store: ConversationStore,
    session: TriageSession,
    workflow: SymptomWorkflow,
    message: str,
) -> dict:
    """
    WAITING_FOR_MEDICATION_CONSENT: the user is answering "want medicine info?".
    Handle yes / no / unclear directly — conversation state takes precedence over
    intent classification, so words like "tell me" or "continue" mean YES here.
    """
    wants = _is_affirmative(message)
    logger.info(
        "[Triage] WAITING_FOR_MEDICATION_CONSENT | session=%s reply='%s' → %s",
        session.session_id, message.strip()[:40],
        {True: "yes", False: "no", None: "unclear"}[wants],
    )

    # ── No → close gracefully ─────────────────────────────────────────────────
    if wants is False:
        session.state = TriageState.SESSION_CLOSED
        store.save(session)
        store.clear(session.session_id)
        logger.info(
            "[Triage] WAITING_FOR_MEDICATION_CONSENT → SESSION_CLOSED "
            "(declined) | session=%s", session.session_id,
        )
        reply = (
            "Understood. Take care of yourself, and please see a pharmacist or "
            "doctor if things don't improve or you're worried. Feel free to ask "
            "me about any specific medicine anytime."
        )
        return _response(
            session.session_id, reply, TriageState.SESSION_CLOSED,
            triage_active=False,
        )

    # ── Unclear → re-ask, stay in the same state ──────────────────────────────
    if wants is None:
        reply = (
            "Sorry, I didn't quite catch that. Would you like general "
            "over-the-counter medication information for this? "
            "Please reply **yes** or **no**."
        )
        return _response(
            session.session_id, reply,
            TriageState.WAITING_FOR_MEDICATION_CONSENT, triage_active=True,
        )

    # ── Yes → MEDICATION_RECOMMENDATION_STAGE (RAG-grounded) ──────────────────
    session.state = TriageState.MEDICATION_RECOMMENDATION_STAGE
    store.save(session)
    logger.info(
        "[Triage] WAITING_FOR_MEDICATION_CONSENT → MEDICATION_RECOMMENDATION_STAGE "
        "| session=%s symptom=%s", session.session_id, session.symptom,
    )

    reply, sources, rag_used = _build_recommendation(workflow, session)

    # Assessment finished — close the session.
    session.state = TriageState.SESSION_CLOSED
    store.save(session)
    store.clear(session.session_id)
    logger.info(
        "[Triage] MEDICATION_RECOMMENDATION_STAGE → SESSION_CLOSED | session=%s "
        "rag_used=%s sources=%d", session.session_id, rag_used, len(sources),
    )
    return _response(
        session.session_id, reply, TriageState.MEDICATION_RECOMMENDATION_STAGE,
        triage_active=False, sources=sources, rag_used=rag_used,
    )


# ── Summary & recommendation builders ────────────────────────────────────────

def _severity_is_high(session: TriageSession) -> bool:
    sev = session.collected.get("severity", "").lower()
    return any(w in sev for w in ("severe", "worst", "unbearable", "10/10",
                                  "9/10", "8/10", "extreme"))


def _duration_is_long(session: TriageSession) -> bool:
    dur = session.collected.get("duration", "").lower()
    return any(w in dur for w in ("week", "weeks", "month", "months",
                                  "long time", "years"))


def _build_summary(workflow: SymptomWorkflow, session: TriageSession) -> str:
    """ASSESSMENT_COMPLETE: patient-friendly summary via the response formatter."""
    from .response_formatter import format_assessment_summary
    return format_assessment_summary(
        workflow,
        session.collected,
        severity_high=_severity_is_high(session),
        duration_long=_duration_is_long(session),
    )


def _build_recommendation(
    workflow: SymptomWorkflow, session: TriageSession
) -> tuple[str, List[dict], bool]:
    """
    RECOMMENDATION: present this symptom's curated OTC options as general
    information, grounding each against the knowledge base via RAG (citations).

    A curated candidate list is used rather than raw symptom->drug semantic
    search, which is too noisy to be safe (it can surface, e.g., a blood-pressure
    drug for a headache). RAG is still used — to *ground* the curated options and
    attach real label citations. Returns (reply, sources, rag_used).
    """
    from .retrieval import retrieve_context

    grounded: List[str] = []
    ungrounded: List[str] = []
    sources: List[dict] = []

    for cand in workflow.otc_candidates:
        # drug_filter restricts retrieval to this drug, so any returned chunk is
        # on-topic; min_score=0 just confirms the drug exists in the KB.
        chunks = retrieve_context(
            query=workflow.rag_term, top_k=1, min_score=0.0, drug_filter=cand,
        )
        if chunks:
            grounded.append(cand)
            c = chunks[0]
            sources.append({
                "drug_name": c.drug_name, "section": c.section,
                "source": c.source, "score": c.score,
            })
        else:
            ungrounded.append(cand)

    from .response_formatter import format_recommendation
    rag_used = bool(grounded)
    reply = format_recommendation(workflow, grounded, ungrounded)
    return reply, sources, rag_used


# ── Yes/No parsing ───────────────────────────────────────────────────────────

_RX_YES = re.compile(
    r"\b(?:yes|yeah|yep|yup|ya|sure|ok(?:ay)?|alright|please|pls|"
    r"go ahead|go on|continue|carry on|sounds good|"
    r"tell me|show me|let'?s do it|i do|i would|i'?d like|definitely|"
    r"of course|absolutely|why not)\b",
    re.IGNORECASE,
)
_RX_NO = re.compile(
    r"\b(?:no|nope|nah|not really|no thanks|no thank you|skip|"
    r"i'?m good|i'?m fine|don'?t|do not|not now|maybe later|later|pass)\b",
    re.IGNORECASE,
)


def _is_affirmative(message: str) -> Optional[bool]:
    """Return True/False for yes/no, or None if unclear.

    Negatives are checked first so "no thanks" isn't caught by a stray "yes"-like
    token. Conversation state (not intent classification) governs this decision.
    """
    if _RX_NO.search(message):
        return False
    if _RX_YES.search(message):
        return True
    return None
