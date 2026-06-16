"""
Response formatting & patient-communication layer (Phase 3).

This is the single presentation layer for the whole chatbot. Retrieval and
reasoning happen elsewhere (router, triage, RAG); everything that turns results
into *words a patient reads* lives here, so tone, structure, empathy, source
attribution, and confidence handling stay consistent across every intent.

Three kinds of output flow through this module:

  1. LLM-backed answers (dosage, side effects, warnings, interactions, drug
     info, safety alerts, general) — we don't write the medical content, we
     shape it via an INTENT-SPECIFIC system prompt (generation_system_prompt)
     and then attach a natural source note + confidence note afterwards
     (append_grounded_meta).

  2. Direct index lookups (brand/generic, ingredient, disease) — fully
     deterministic, formatted here in a warm, plain-language style.

  3. Symptom assessment (triage summary + recommendation) — formatted here with
     the patient-friendly structure: empathy, summary, possible explanations,
     self-care, and when to seek help.

Safety invariants (shared by every formatter):
  * Never claim a diagnosis; never overstate certainty.
  * Encourage professional evaluation where it matters.
  * Plain language, short sections, bullets — no raw label dumps.
"""
from __future__ import annotations

import logging
from typing import Dict, List, Optional, Tuple

from .intent_classifier import Intent

logger = logging.getLogger(__name__)


# ── Confidence ───────────────────────────────────────────────────────────────

CONF_HIGH   = "high"
CONF_MEDIUM = "medium"
CONF_LOW    = "low"

_CONF_HIGH_MIN   = 0.72
_CONF_MEDIUM_MIN = 0.62


def confidence_from_chunks(chunks) -> Tuple[str, float]:
    """
    Derive a confidence level from retrieval scores (top chunk wins).
    Returns (level, top_score). Empty input -> ("low", 0.0).
    """
    if not chunks:
        return CONF_LOW, 0.0
    top = max(getattr(c, "score", 0.0) for c in chunks)
    if top >= _CONF_HIGH_MIN:
        return CONF_HIGH, top
    if top >= _CONF_MEDIUM_MIN:
        return CONF_MEDIUM, top
    return CONF_LOW, top


# ── Source attribution ───────────────────────────────────────────────────────

_SOURCE_NAMES: Dict[str, str] = {
    "dailymed": "the FDA-approved drug label (DailyMed)",
    "openfda":  "FDA data (OpenFDA)",
    "rxnorm":   "RxNorm (U.S. National Library of Medicine)",
}


def friendly_source(source: str) -> str:
    """Map an internal source key to a human-friendly description."""
    return _SOURCE_NAMES.get((source or "").lower(), source or "official sources")


def _source_line_from_chunks(chunks) -> str:
    """Build a natural one-line source note from retrieved chunks."""
    sources, drugs = [], []
    for c in chunks:
        s = friendly_source(getattr(c, "source", ""))
        if s not in sources:
            sources.append(s)
        d = (getattr(c, "drug_name", "") or "").title()
        if d and d not in drugs:
            drugs.append(d)
    if not sources:
        return ""
    src = sources[0] if len(sources) == 1 else f"{sources[0]} and {sources[1]}"
    if drugs:
        drug_str = drugs[0] if len(drugs) == 1 else ", ".join(drugs[:2])
        return f"ℹ️ *Source: {src} for {drug_str}.*"
    return f"ℹ️ *Source: {src}.*"


def source_note(source: str, subject: str = "") -> str:
    """Single-source note for direct lookups (e.g. RxNorm brand/generic)."""
    base = friendly_source(source)
    if subject:
        return f"ℹ️ *Source: {base} for {subject}.*"
    return f"ℹ️ *Source: {base}.*"


_LOW_CONF_NOTE = (
    "\n\n_Note: this looks like only a loose match to your question, so please "
    "double-check with a pharmacist or doctor._"
)


def append_grounded_meta(reply: str, chunks, intent: Intent, confidence: str) -> str:
    """
    Attach a natural source note (and a low-confidence caveat when relevant) to
    an LLM-generated, grounded answer.
    """
    line = _source_line_from_chunks(chunks)
    out = reply.rstrip()
    if confidence == CONF_LOW:
        out += _LOW_CONF_NOTE
    if line:
        out += f"\n\n{line}"
    logger.info(
        "[Formatter] type=%s confidence=%s sources=%s",
        intent.value if isinstance(intent, Intent) else intent,
        confidence,
        ",".join(sorted({friendly_source(getattr(c, 'source', '')) for c in chunks})),
    )
    return out


# ── Intent-specific generation prompts ───────────────────────────────────────

_BASE_RULES = """You are MediAI, a warm, plain-spoken pharmacy assistant talking \
directly to a patient (not to a clinician).

GROUND RULES (never break):
- Use ONLY the information in the [CONTEXT] provided. Never add outside facts, \
drug names, or numbers.
- If the context doesn't contain enough to answer, reply with EXACTLY this \
sentence and nothing else: "I don't have enough information about that in my \
knowledge base."
- If the question is not about medicines or health, reply with EXACTLY: "I can \
only assist with pharmaceutical and medicine-related questions."
- Never give a diagnosis. Never overstate certainty. Encourage seeing a \
pharmacist or doctor when it matters.

STYLE:
- Warm, clear, everyday language a non-expert understands. Briefly explain any \
medical term you must use.
- Use short sections with **bold mini-headings** and bullet points. No long \
paragraphs.
- Do NOT copy label section names (e.g. "INDICATIONS AND USAGE", "ADVERSE \
REACTIONS", "DOSAGE AND ADMINISTRATION").
- Do NOT add citations or source tags and do NOT repeat these instructions — \
the app appends the source note for you.
- Be concise and skimmable."""

_INTENT_STRUCTURE: Dict[Intent, str] = {
    Intent.DOSAGE_QUERY: (
        "This is a DOSAGE question. Structure your reply as:\n"
        "**General dosage** — the typical amount and how often, in plain terms.\n"
        "**What can affect your dose** — e.g. age, weight, kidney/liver, other "
        "conditions (only if mentioned in the context).\n"
        "**Staying safe** — maximum limits and key cautions from the context.\n"
        "End with one short line encouraging them to confirm the exact dose with "
        "a pharmacist or doctor."
    ),
    Intent.SIDE_EFFECT_QUERY: (
        "This is a SIDE EFFECTS question. Structure your reply as:\n"
        "**Common side effects** — the everyday, usually mild ones (bullets).\n"
        "**Serious side effects** — rarer ones that need attention (bullets).\n"
        "**When to get help** — when they should contact a healthcare "
        "professional.\n"
        "Reassure briefly that mild effects are common without dismissing concerns."
    ),
    Intent.WARNINGS_QUERY: (
        "This is a SAFETY / WARNINGS question. Structure your reply as:\n"
        "**Who should be careful** — important contraindications and precautions "
        "in plain terms (bullets).\n"
        "**Serious warnings** — any boxed/serious warnings from the context.\n"
        "End by advising them to check with a pharmacist or doctor about their "
        "own situation."
    ),
    Intent.INTERACTION_QUERY: (
        "This is a DRUG INTERACTION question. Structure your reply as:\n"
        "**Key interactions** — what to avoid combining and why, in plain terms "
        "(bullets).\n"
        "**What to do** — practical, calm guidance.\n"
        "Encourage them to have a pharmacist review everything they take together."
    ),
    Intent.MEDICINE_TO_DISEASE_QUERY: (
        "This question asks WHAT A MEDICINE IS USED FOR. Structure your reply as:\n"
        "**What it's used for** — the conditions it treats, in plain language "
        "(bullets).\n"
        "**How it helps** — a one-line, simple explanation only if the context "
        "supports it.\n"
        "Keep it short and invite a follow-up (dose, side effects)."
    ),
    Intent.DRUG_LOOKUP: (
        "This is a GENERAL DRUG LOOKUP. Give a friendly overview:\n"
        "**What it is** — its drug type/what it does, in plain terms.\n"
        "**What it's used for** — the main uses.\n"
        "Keep it brief and invite a follow-up question (dosage, side effects, "
        "interactions)."
    ),
    Intent.FDA_SAFETY_QUERY: (
        "This is a SAFETY ALERT / RECALL question. Be factual and calm, not "
        "alarmist. Structure your reply as:\n"
        "**Safety information** — recalls, alerts, or key warnings from the "
        "context, in plain terms.\n"
        "**What this means for you** — practical next steps.\n"
        "Encourage them to follow up with their pharmacy or doctor."
    ),
}

_DEFAULT_STRUCTURE = (
    "Answer clearly in plain language. Use short sections with bold mini-headings "
    "and bullets where they help readability. Keep it concise."
)

_LOW_CONF_RIDER = (
    "\n\nIMPORTANT: The available context may only loosely match the question. "
    "If so, say honestly that you're not certain, avoid guessing, and suggest "
    "confirming with a pharmacist."
)


def generation_system_prompt(intent: Intent, confidence: str = CONF_HIGH) -> str:
    """
    Build the intent-tailored system prompt used to GENERATE a grounded answer.
    The patient-friendly structure is defined per response type here.
    """
    structure = _INTENT_STRUCTURE.get(intent, _DEFAULT_STRUCTURE)
    prompt = f"{_BASE_RULES}\n\n{structure}"
    if confidence == CONF_LOW:
        prompt += _LOW_CONF_RIDER
    return prompt


# ── Direct-lookup formatters (deterministic, no LLM) ─────────────────────────

def format_brand_to_generic(brand: str, generic: str, drug: dict) -> str:
    lines = [
        f"**{brand.title()}** is a brand name — its active ingredient (the "
        f"generic medicine) is **{generic.title()}**."
    ]
    extras = []
    if drug.get("drug_class"):
        extras.append(f"- **Type of medicine:** {drug['drug_class'].title()}")
    other = [b for b in drug.get("brand_names", []) if b.lower() != brand.lower()]
    if other:
        extras.append(f"- **Other brands of {generic.title()}:** "
                      f"{', '.join(other[:8])}")
    if extras:
        lines.append("")
        lines.extend(extras)
    lines.append("")
    lines.append(
        f"You can ask me about {generic.title()}'s uses, dosage, or side effects "
        "anytime."
    )
    lines.append("")
    lines.append(source_note("rxnorm", brand.title()))
    logger.info("[Formatter] type=brand_generic confidence=high sources=rxnorm")
    return "\n".join(lines)


def format_generic_to_brands(generic: str, brands: List[str], drug: dict) -> str:
    brand_list = ", ".join(f"**{b}**" for b in brands[:15])
    lines = [
        f"**{generic.title()}** is the generic name. You may see it sold under "
        f"these brand names:",
        "",
        brand_list,
    ]
    if drug.get("drug_class"):
        lines.append("")
        lines.append(f"- **Type of medicine:** {drug['drug_class'].title()}")
    lines.append("")
    lines.append(source_note("rxnorm", generic.title()))
    logger.info("[Formatter] type=brand_generic confidence=high sources=rxnorm")
    return "\n".join(lines)


def format_ingredient(ingredient: str, medicines: List[str]) -> str:
    med_list = ", ".join(f"**{m.title()}**" for m in medicines[:20])
    lines = [
        f"Here are medicines in my records that contain **{ingredient.title()}**:",
        "",
        med_list,
        "",
        source_note("rxnorm", ingredient.title()),
    ]
    logger.info("[Formatter] type=ingredient confidence=high sources=rxnorm")
    return "\n".join(lines)


def format_disease(disease: str, drug_classes: List[Tuple[str, str]]) -> str:
    """drug_classes: list of (drug_name, drug_class) tuples, best first."""
    lines = [
        f"Here are medicines whose labels list **{disease.title()}** among their "
        "uses:",
        "",
    ]
    for dn, dclass in drug_classes[:10]:
        note = f" — *{dclass}*" if dclass else ""
        lines.append(f"- **{dn.title()}**{note}")
    lines.append("")
    lines.append(
        "This isn't a recommendation — which one (if any) is right depends on "
        "your situation. Please talk to a doctor or pharmacist before starting "
        "any medication."
    )
    lines.append("")
    lines.append(source_note("dailymed", "indications"))
    logger.info("[Formatter] type=disease confidence=high sources=dailymed")
    return "\n".join(lines)


# ── Symptom assessment formatters ────────────────────────────────────────────

def format_assessment_summary(
    workflow,
    collected: Dict[str, str],
    severity_high: bool,
    duration_long: bool,
) -> str:
    """
    Patient-friendly assessment summary (req #6 symptom structure):
    Empathy · Assessment summary · Possible explanations · Self-care ·
    When to seek medical attention · (ask about OTC info).
    """
    lines = [
        f"Thanks for sharing those details — that sounds uncomfortable, and I'll "
        f"do my best to help you understand it."
    ]

    # Assessment summary
    lines.append("")
    lines.append("**Here's what you told me**")
    label = {
        "duration": "How long", "severity": "Severity",
        "associated": "Other symptoms", "context": "Background",
    }
    for key in ("duration", "severity", "associated", "context"):
        if collected.get(key):
            lines.append(f"- **{label[key]}:** {collected[key]}")

    # Possible explanations (educational, no diagnosis)
    lines.append("")
    lines.append("**Possible explanations** *(general information, not a diagnosis)*")
    lines.append(workflow.educational)

    # Self-care guidance
    if getattr(workflow, "self_care", None):
        lines.append("")
        lines.append("**Self-care that may help**")
        for tip in workflow.self_care:
            lines.append(f"- {tip}")

    # When to seek medical attention
    if getattr(workflow, "when_to_seek", None):
        lines.append("")
        lines.append("**When to seek medical attention**")
        for w in workflow.when_to_seek:
            lines.append(f"- {w}")

    if severity_high or duration_long:
        lines.append("")
        lines.append(
            "⚠️ Because you described this as **severe or long-lasting**, it would "
            "be a good idea to have it checked by a healthcare professional soon."
        )

    lines.append("")
    lines.append(
        "Would you like some general **over-the-counter medication information** "
        "that people commonly use for this? Just reply **yes** or **no**."
    )
    logger.info(
        "[Formatter] type=symptom_summary workflow=%s severe=%s long=%s",
        getattr(workflow, "name", "?"), severity_high, duration_long,
    )
    return "\n".join(lines)


def format_recommendation(
    workflow, grounded: List[str], ungrounded: List[str]
) -> str:
    """Medication-information stage for a symptom (curated + RAG-grounded)."""
    lines = [f"**General medication information for {workflow.display.lower()}**"]
    candidates = list(grounded) + list(ungrounded)
    if candidates:
        lines.append("")
        lines.append("Commonly used over-the-counter options include:")
        for cand in candidates:
            tick = " ✓ *(label info available — ask me about it)*" \
                if cand in grounded else ""
            lines.append(f"- **{cand.title()}**{tick}")
        lines.append("")
        lines.append(
            "*This is general information, not a recommendation or prescription. "
            "Whether something is right for you depends on your age, health "
            "conditions, and other medicines.*"
        )
    else:
        lines.append("")
        lines.append(
            "The right option really depends on the cause, so I can't suggest a "
            "general medicine for this one."
        )

    lines.append("")
    lines.append(
        "👉 **Please check with a pharmacist before taking anything** — they can "
        "make sure it's right for you and your other medicines. See a **doctor** "
        "if symptoms are severe, persistent, or getting worse."
    )
    if grounded:
        lines.append("")
        lines.append(source_note("dailymed"))
    logger.info(
        "[Formatter] type=symptom_recommendation workflow=%s grounded=%d",
        getattr(workflow, "name", "?"), len(grounded),
    )
    return "\n".join(lines)
