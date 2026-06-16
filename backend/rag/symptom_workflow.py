"""
Symptom workflow definitions (declarative registry).

Each workflow describes how to assess one symptom: the questions to ask (in
order), short *educational* "possible causes" text (NEVER a diagnosis), and an
optional RAG query term used at the recommendation stage.

Adding a new symptom workflow = add one SymptomWorkflow entry to WORKFLOWS and
(optionally) map alias symptom words to it. No engine code changes needed —
that's the "modular and extensible" requirement (#12).

All four data points required by spec (#6) are collected via the four standard
question keys: "duration", "severity", "associated", "context".
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, List, Optional


# Standard question keys (the four data points every workflow collects)
Q_DURATION   = "duration"
Q_SEVERITY   = "severity"
Q_ASSOCIATED = "associated"
Q_CONTEXT    = "context"


@dataclass
class Question:
    """One assessment question."""
    key:    str
    prompt: str


@dataclass
class SymptomWorkflow:
    """A complete assessment script for one symptom."""
    name:        str               # canonical workflow key, e.g. "headache"
    display:     str               # human label, e.g. "Headache"
    questions:   List[Question]
    educational: str               # possible causes / general guidance (no dx)
    rag_term:    str               # search term for the recommendation stage
    # Curated, well-established OTC generic options for this symptom. The
    # recommendation stage presents these as *general information* and uses RAG
    # to ground them (citations) against the knowledge base. Curating the list
    # (instead of relying on noisy symptom->drug semantic search) prevents unsafe
    # false positives like suggesting a blood-pressure drug for a headache.
    otc_candidates: List[str] = field(default_factory=list)
    # Patient-friendly self-care tips and "see a professional if…" guidance,
    # rendered by the response formatter in the assessment summary.
    self_care:    List[str] = field(default_factory=list)
    when_to_seek: List[str] = field(default_factory=list)
    red_flags:   List[str] = field(default_factory=list)  # escalation phrases


def _standard_questions(
    severity_prompt: str,
    associated_prompt: str,
    context_prompt: str,
) -> List[Question]:
    """Build the 4 standard questions with a shared duration prompt."""
    return [
        Question(Q_DURATION,
                 "How long have you been experiencing this? "
                 "(e.g. a few hours, 2 days, over a week)"),
        Question(Q_SEVERITY, severity_prompt),
        Question(Q_ASSOCIATED, associated_prompt),
        Question(Q_CONTEXT, context_prompt),
    ]


# ── Workflow registry ───────────────────────────────────────────────────────

WORKFLOWS: Dict[str, SymptomWorkflow] = {
    "headache": SymptomWorkflow(
        name="headache",
        display="Headache",
        questions=_standard_questions(
            "How would you rate the pain — mild, moderate, or severe?",
            "Are you noticing any of these alongside it: nausea, sensitivity to "
            "light or sound, visual changes, or fever?",
            "Anything that might be related — stress, poor sleep, dehydration, "
            "screen time, caffeine changes, or skipped meals?",
        ),
        educational=(
            "Headaches are very common and most are not serious. Frequent, "
            "non-urgent causes include tension-type headache (stress, muscle "
            "tension), migraine, dehydration, eye strain, lack of sleep, or "
            "caffeine withdrawal."
        ),
        rag_term="headache pain relief",
        otc_candidates=["acetaminophen", "ibuprofen", "aspirin", "naproxen"],
        self_care=[
            "Rest in a quiet, dark room",
            "Drink water — dehydration is a common trigger",
            "Try a cool or warm compress on your head or neck",
            "Take regular breaks from screens",
        ],
        when_to_seek=[
            "A sudden, severe \"worst-ever\" headache",
            "A headache after a head injury",
            "Headache with fever, stiff neck, confusion, weakness, vision loss, "
            "or trouble speaking",
            "Headaches that keep getting worse or won't go away",
        ],
        red_flags=["worst headache", "thunderclap", "head injury", "sudden severe"],
    ),
    "fever": SymptomWorkflow(
        name="fever",
        display="Fever",
        questions=_standard_questions(
            "How high is your temperature, if you've measured it? "
            "(e.g. 38°C / 100.4°F)",
            "Any of these too: chills, rash, stiff neck, difficulty breathing, "
            "or a persistent cough?",
            "Any recent infection, travel, or contact with someone who was ill?",
        ),
        educational=(
            "A fever is the body's normal response to infection and is often "
            "caused by common viral illnesses. It usually resolves on its own, "
            "but persistent, very high, or recurring fevers can need evaluation."
        ),
        rag_term="fever reducer antipyretic",
        otc_candidates=["acetaminophen", "ibuprofen"],
        self_care=[
            "Rest and drink plenty of fluids",
            "Dress lightly and keep the room cool",
            "A lukewarm sponge bath can help you feel more comfortable",
        ],
        when_to_seek=[
            "A temperature above 39.4°C / 103°F, or a fever lasting more than 3 days",
            "Fever with a stiff neck, rash, severe headache, or trouble breathing",
            "Fever in a baby, a very elderly person, or someone with a weak "
            "immune system",
        ],
        red_flags=["stiff neck", "rash that doesn't fade", "difficulty breathing"],
    ),
    "cough": SymptomWorkflow(
        name="cough",
        display="Cough",
        questions=_standard_questions(
            "Is it a dry cough or are you bringing up mucus (productive)? "
            "How disruptive is it — mild, moderate, or severe?",
            "Any of these: fever, shortness of breath, wheezing, chest pain, "
            "or coughing up blood?",
            "Are you a smoker, getting over a cold, around allergens, or do you "
            "have known asthma or COPD?",
        ),
        educational=(
            "Coughs commonly follow viral colds and often clear within a couple "
            "of weeks. Other frequent causes include post-nasal drip, allergies, "
            "asthma, or acid reflux. A cough lasting more than ~3 weeks should be "
            "reviewed."
        ),
        rag_term="cough relief",
        otc_candidates=["dextromethorphan", "guaifenesin"],
        self_care=[
            "Drink warm fluids and stay well hydrated",
            "Honey can soothe a cough (but not for children under 1 year)",
            "Use a humidifier or breathe in steam",
            "Avoid smoke and other irritants",
        ],
        when_to_seek=[
            "Coughing up blood",
            "Shortness of breath or wheezing",
            "A cough lasting more than 3 weeks",
            "A high fever or chest pain",
        ],
        red_flags=["coughing up blood", "shortness of breath", "blue lips"],
    ),
    "sore throat": SymptomWorkflow(
        name="sore throat",
        display="Sore Throat",
        questions=_standard_questions(
            "How severe is the pain — mild, moderate, or severe, especially "
            "when swallowing?",
            "Any of these: fever, swollen glands, white patches on the throat, "
            "rash, or trouble breathing/swallowing?",
            "Recent cold, known exposure to strep throat, or a lot of voice use?",
        ),
        educational=(
            "Most sore throats are caused by viral infections and ease within a "
            "few days. Bacterial causes (such as strep throat) are possible, "
            "especially with high fever, swollen glands, and white patches, and "
            "may need testing."
        ),
        rag_term="sore throat pain relief",
        otc_candidates=["acetaminophen", "ibuprofen", "benzocaine"],
        self_care=[
            "Gargle with warm salt water",
            "Drink warm fluids; suck on lozenges or ice chips",
            "Rest your voice and stay hydrated",
        ],
        when_to_seek=[
            "Trouble breathing or swallowing, or drooling",
            "A high fever, or white patches/pus on the throat",
            "A sore throat lasting more than a week, or with a rash",
        ],
        red_flags=["difficulty breathing", "difficulty swallowing", "drooling"],
    ),
    "stomach pain": SymptomWorkflow(
        name="stomach pain",
        display="Stomach Pain",
        questions=_standard_questions(
            "How would you rate it — mild, moderate, or severe? Is it constant "
            "or cramping, and where is it located?",
            "Any of these: vomiting, blood in stool or vomit, fever, diarrhea, "
            "or being unable to keep fluids down?",
            "Is it related to eating, new foods, or do you have known conditions "
            "like ulcers, acid reflux, or IBS?",
        ),
        educational=(
            "Stomach pain has many common, non-urgent causes including "
            "indigestion, gas, constipation, acid reflux, or a stomach bug. "
            "Severe, persistent, or worsening pain — especially with vomiting "
            "blood or blood in stool — needs prompt medical attention."
        ),
        rag_term="stomach pain indigestion relief",
        otc_candidates=["calcium carbonate", "famotidine", "omeprazole"],
        self_care=[
            "Sip clear fluids and try bland foods (toast, rice, bananas)",
            "Avoid spicy, fatty, or heavy meals for a while",
            "Rest, and a warm compress can ease the discomfort",
        ],
        when_to_seek=[
            "Severe or worsening pain, or a hard/very tender belly",
            "Blood in vomit or stool, or black stools",
            "Persistent vomiting, a high fever, or signs of dehydration",
            "Pain after a recent injury",
        ],
        red_flags=["blood in stool", "vomiting blood", "severe abdominal pain",
                   "rigid abdomen"],
    ),
}


# Map alternative symptom words to a workflow key.
_ALIASES: Dict[str, str] = {
    "migraine": "headache",
    "head pain": "headache",
    "feverish": "fever",
    "high temperature": "fever",
    "temperature": "fever",
    "coughing": "cough",
    "throat pain": "sore throat",
    "sore throat": "sore throat",
    "stomach ache": "stomach pain",
    "stomachache": "stomach pain",
    "stomach pain": "stomach pain",
    "tummy ache": "stomach pain",
    "abdominal pain": "stomach pain",
    "belly pain": "stomach pain",
}


# Generic fallback for symptoms we don't have a dedicated workflow for.
_GENERIC = SymptomWorkflow(
    name="generic",
    display="Symptom",
    questions=_standard_questions(
        "How would you rate it — mild, moderate, or severe?",
        "Are there any other symptoms occurring alongside it?",
        "Anything that seems to bring it on or make it worse (activity, food, "
        "stress, or a recent illness)?",
    ),
    educational=(
        "Many everyday symptoms have common, self-limiting causes, but the right "
        "next step depends on the full picture. The summary below is general "
        "information only, not a diagnosis."
    ),
    rag_term="symptom relief",
    self_care=[
        "Rest and stay hydrated",
        "Keep an eye on how the symptom changes over time",
    ],
    when_to_seek=[
        "The symptom is severe, persistent, or rapidly getting worse",
        "You develop new or worrying symptoms",
    ],
)


def resolve_workflow(symptom: Optional[str]) -> SymptomWorkflow:
    """
    Map a symptom phrase to its workflow, falling back to the generic workflow.
    """
    if not symptom:
        return _GENERIC
    key = symptom.lower().strip()
    if key in WORKFLOWS:
        return WORKFLOWS[key]
    if key in _ALIASES:
        return WORKFLOWS[_ALIASES[key]]
    # Substring match (e.g. "bad headache" -> headache)
    for wf_key in WORKFLOWS:
        if wf_key in key:
            return WORKFLOWS[wf_key]
    for alias, wf_key in _ALIASES.items():
        if alias in key:
            return WORKFLOWS[wf_key]
    return _GENERIC
