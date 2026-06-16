"""
Intent classification layer.

This module is the single source of truth for *understanding what the user is
asking* before any retrieval happens. It is intentionally dependency-light
(only stdlib + config) so it can be unit-tested in isolation and reused outside
the RAG pipeline.

Taxonomy (the 12 required intents):

    DRUG_LOOKUP                 general info about a specific medicine
    DOSAGE_QUERY                how much / how often to take
    SIDE_EFFECT_QUERY           adverse effects / "does X cause Y"
    DISEASE_TO_MEDICINE_QUERY   "what treats hypertension"
    MEDICINE_TO_DISEASE_QUERY   "what is ibuprofen used for"
    INGREDIENT_LOOKUP_QUERY     "medicines containing acetaminophen"
    BRAND_GENERIC_QUERY         brand<->generic mapping
    INTERACTION_QUERY           "can I take X with Y"
    FDA_SAFETY_QUERY            recalls / FDA alerts / boxed warnings
    SYMPTOM_QUERY               "I have a headache" (first-person symptom)
    GENERAL_MEDICAL_QUERY       pharma-related but unstructured
    UNKNOWN                     no recognisable medical content

    WARNINGS_QUERY              (internal extension — see note below)

WARNINGS_QUERY is NOT one of the 12 required intents; it is an extension added
to preserve the project's existing contraindication / precaution routing
(e.g. "contraindications for warfarin"). It demonstrates that the taxonomy is
easily extendable: add an enum member, a pattern, and a routing-table row.

Design notes:
  * Classification is ordered — the first matching rule wins. Order is chosen so
    that more specific intents are tested before more general ones.
  * SYMPTOM_QUERY is gated on *first-person symptom framing* ("I have…",
    "what should I take for a…") so it catches "I have a headache" WITHOUT
    stealing structured drug questions like "does metformin cause nausea"
    (SIDE_EFFECT) or "what dosage should I take for ibuprofen" (DOSAGE).
"""
from __future__ import annotations

import logging
import re
from dataclasses import dataclass
from enum import Enum
from typing import List, Optional, Tuple

logger = logging.getLogger(__name__)


class Intent(str, Enum):
    DRUG_LOOKUP               = "drug_lookup"
    DOSAGE_QUERY              = "dosage_query"
    SIDE_EFFECT_QUERY         = "side_effect_query"
    DISEASE_TO_MEDICINE_QUERY = "disease_to_medicine_query"
    MEDICINE_TO_DISEASE_QUERY = "medicine_to_disease_query"
    INGREDIENT_LOOKUP_QUERY   = "ingredient_lookup_query"
    BRAND_GENERIC_QUERY       = "brand_generic_query"
    INTERACTION_QUERY         = "interaction_query"
    FDA_SAFETY_QUERY          = "fda_safety_query"
    SYMPTOM_QUERY             = "symptom_query"
    GENERAL_MEDICAL_QUERY     = "general_medical_query"
    UNKNOWN                   = "unknown"
    # ── Internal extension (not part of the required 12) ──────────────────────
    WARNINGS_QUERY            = "warnings_query"


@dataclass
class IntentResult:
    """
    The outcome of classifying one user message.

    intent     : the detected Intent
    entity     : the drug / ingredient / disease / symptom captured, if any
    sub_type   : finer-grained variant, e.g. "brand_to_generic" vs
                 "generic_to_brands" within BRAND_GENERIC_QUERY
    confidence : 0–1 heuristic confidence (1.0 = exact pattern match)
    matched    : the rule that fired (for logging / debugging)
    """
    intent:     Intent
    entity:     Optional[str] = None
    sub_type:   Optional[str] = None
    confidence: float = 1.0
    matched:    str = ""


# ── Symptom vocabulary ──────────────────────────────────────────────────────
# Actual *symptoms* a user might self-report — deliberately excludes chronic
# disease names (diabetes, hypertension) which belong to the disease intents.
_SYMPTOM_WORDS: Tuple[str, ...] = (
    "headache", "migraine", "fever", "feverish", "temperature", "cough",
    "cold", "flu", "sore throat", "runny nose", "stuffy nose", "congestion",
    "congested", "nausea", "nauseous", "vomiting", "throwing up", "diarrhea",
    "diarrhoea", "constipation", "stomach ache", "stomachache", "stomach pain",
    "tummy ache", "cramps", "cramping", "dizziness", "dizzy", "lightheaded",
    "fatigue", "exhausted", "rash", "itching", "itchy", "hives", "sneezing",
    "chills", "body ache", "body aches", "back pain", "backache", "toothache",
    "earache", "ear pain", "heartburn", "indigestion", "acid reflux",
    "bloating", "insomnia", "trouble sleeping", "anxiety", "anxious",
    "muscle pain", "joint pain", "swelling", "chest pain",
    "shortness of breath", "sore muscles", "sick", "unwell",
)

# First-person illness framing: "I have…", "I'm experiencing…", "I've been having…"
_RX_FIRST_PERSON = re.compile(
    r"\b(?:i|we)\s*(?:'ve|'m| ve| am| have| has)?\s*"
    r"(?:have|having|had|got|getting|get|"
    r"experienc\w+|feel\w*|suffer\w*|been\s+having|keep\s+getting|"
    r"am\s+(?:having|experiencing|feeling|suffering)|dealing\s+with)\b",
    re.IGNORECASE,
)

# Symptom-driven medicine seeking: "what can I take for…", "how do I get rid of…"
_RX_SEEKING = re.compile(
    r"\b(?:what\s+(?:can|should|could|do)\s+i\s+(?:take|use|do|drink)|"
    r"how\s+(?:do|can)\s+i\s+(?:treat|cure|stop|relieve|ease|get\s+rid\s+of)|"
    r"get\s+rid\s+of|remedy|remedies|relief\s+for)\b",
    re.IGNORECASE,
)

# Possessive symptom framing: "my head hurts", "my throat is sore"
# Group 1 captures the body part so we can map it to a symptom/workflow.
_RX_MY_HURTS = re.compile(
    r"\bmy\s+([a-z][a-z ]{0,20}?)\s+"
    r"(?:hurts?|aches?|is\s+(?:sore|hurting|aching|killing\s+me))\b",
    re.IGNORECASE,
)

# Body part -> symptom mapping for the possessive framing path.
_BODY_PART_SYMPTOM = {
    "head":    "headache",
    "stomach": "stomach pain",
    "belly":   "stomach pain",
    "tummy":   "stomach pain",
    "throat":  "sore throat",
    "tooth":   "toothache",
    "teeth":   "toothache",
    "ear":     "earache",
    "back":    "back pain",
}


# ── Structured intent patterns ──────────────────────────────────────────────

_RX_BRAND_TO_GENERIC = re.compile(
    r"(?:"
    r"generic\s+(?:name\s+)?(?:for|of)|"
    r"what\s+is\s+the\s+generic\s+(?:for|of|name\s+(?:for|of))|"
    r"non.?brand\s+(?:name\s+)?(?:for|of)|"
    r"(?:active\s+)?ingredient\s+in"
    r")\s+([a-z0-9\s\-]+)",
    re.IGNORECASE,
)

_RX_GENERIC_TO_BRANDS = re.compile(
    r"(?:"
    r"brand\s+names?\s+(?:for|of)|"
    r"brands?\s+(?:for|of)|"
    r"trade\s+names?\s+(?:for|of)|"
    r"what\s+brands?\s+(?:exist\s+for|are\s+available\s+for|sell)|"
    r"commercial\s+names?\s+(?:for|of)"
    r")\s+([a-z0-9\s\-]+)",
    re.IGNORECASE,
)

_RX_INGREDIENT = re.compile(
    r"(?:medicines?|drugs?|medications?)\s+(?:that\s+)?(?:contain|containing|with|"
    r"include|including|have|made\s+(?:with|from))\s+(?:the\s+ingredient\s+)?"
    r"([a-z0-9\s\-]+)",
    re.IGNORECASE,
)

_RX_DISEASE1 = re.compile(
    r"(?:medicines?|drugs?|medications?|treatments?|pills?)\s+"
    r"(?:for|to\s+treat|that\s+treat|used\s+(?:for|to\s+treat)|good\s+for|"
    r"prescribed\s+for|indicated\s+for|to\s+cure)\s+([a-z0-9\s\-]+)",
    re.IGNORECASE,
)
_RX_DISEASE2 = re.compile(
    r"what\s+(?:medicines?|drugs?|medications?|treatments?)\s+"
    r"(?:are\s+)?(?:used\s+for|treat(?:s)?|available\s+for|indicated\s+for|"
    r"help\s+(?:with|for)|cure)\s+([a-z0-9\s\-]+)",
    re.IGNORECASE,
)
_RX_DISEASE3 = re.compile(
    r"(?:how\s+(?:is|are)|what\s+treats?)\s+([a-z0-9\s\-]+)\s+treated",
    re.IGNORECASE,
)

# "what is ibuprofen used for", "what does metformin treat", "uses of aspirin"
_RX_MED_TO_DISEASE = re.compile(
    r"(?:"
    r"what\s+(?:is|are)\s+([a-z0-9\s\-]+?)\s+(?:used\s+for|prescribed\s+for|"
    r"indicated\s+for|for)\b|"
    r"what\s+(?:does|do)\s+([a-z0-9\s\-]+?)\s+(?:treat|cure|help\s+with|do)\b|"
    r"(?:uses?|indications?|purpose)\s+(?:of|for)\s+([a-z0-9\s\-]+)|"
    r"why\s+(?:is|would)\s+([a-z0-9\s\-]+?)\s+(?:be\s+)?prescribed"
    r")",
    re.IGNORECASE,
)

_RX_DOSAGE = re.compile(
    r"\b(?:dosage|dose|dosing|how\s+much|how\s+many|how\s+often|"
    r"recommended\s+(?:dose|dosage|amount)|max(?:imum)?\s+(?:dose|dosage|amount)|"
    r"daily\s+(?:dose|dosage|amount)|mg\s+of|milligrams?\s+of|"
    r"how\s+to\s+take|frequency|once\s+daily|twice\s+a\s+day|"
    r"(?:tablets?|pills?|capsules?)\s+(?:per|a)\s+day)\b",
    re.IGNORECASE,
)

_RX_SIDE_EFFECT = re.compile(
    r"\b(?:side[\s\-]?effects?|adverse\s+(?:effects?|reactions?|events?)|"
    r"unwanted\s+effects?|undesirable\s+effects?|"
    r"does\s+.+?\s+cause|do(?:es)?\s+.+?\s+(?:lead\s+to|result\s+in)|"
    r"is\s+.+?\s+(?:safe|dangerous|harmful)|risks?\s+of\s+(?:taking|using)|"
    r"reactions?\s+to\b)",
    re.IGNORECASE,
)

# Internal extension: warnings / contraindications / precautions
_RX_WARNINGS = re.compile(
    r"\b(?:warning|contraindications?|precautions?|"
    r"who\s+should\s+not\s+(?:take|use)|do\s+not\s+take\s+if|"
    r"avoid\s+(?:if|when|taking)|allerg(?:y|ic|ies)\s+(?:to|warning)|"
    r"safe\s+(?:in|during)\s+pregnancy|pregnancy\s+(?:warning|category)|"
    r"breastfeeding|hepatic|renal\s+impairment)\b",
    re.IGNORECASE,
)

_RX_INTERACTION = re.compile(
    r"\b(?:interact(?:ions?|s|ing)?|drug\s+interactions?|"
    r"take\s+.+?\s+(?:with|together\s+with|alongside)|"
    r"(?:combine|combined|combining|mix|mixing)\s+.+?\s+(?:with|and)|"
    r"can\s+i\s+take\s+.+?\s+(?:with|and|while\s+(?:taking|on))|"
    r"safe\s+to\s+(?:take|use|combine)\s+.+?\s+with|together\s+with)\b",
    re.IGNORECASE,
)

_RX_FDA_SAFETY = re.compile(
    r"\b(?:recalls?|recalled|withdrawn|market\s+withdrawal|"
    r"safety\s+(?:alert|notice|warning|communication)|"
    r"fda\s+(?:alert|warning|approval|approved|safety|recall)|"
    r"black\s+box\s+warning|boxed\s+warning|ban(?:ned)?|"
    r"pulled\s+from\s+(?:the\s+)?market|adverse\s+event\s+report)\b",
    re.IGNORECASE,
)

# Strong triggers — the user is clearly asking about a *thing*; in a pharma
# chatbot that thing is almost always a drug, so accept even unknown names.
_RX_DRUG_LOOKUP_STRONG = re.compile(
    r"(?:"
    r"tell\s+me\s+about|information\s+(?:on|about)|details\s+(?:on|about)|"
    r"describe|explain|overview\s+of"
    r")\s+([a-z0-9\s\-]+)",
    re.IGNORECASE,
)
# Weak triggers — "what is X" is ambiguous ("what is the weather"); only treat
# as a drug lookup when X looks like a drug or the query has medical context.
_RX_DRUG_LOOKUP_WEAK = re.compile(
    r"(?:what\s+is|what's|about)\s+([a-z0-9\s\-]+)",
    re.IGNORECASE,
)

# Generic pharma vocabulary — distinguishes GENERAL_MEDICAL from UNKNOWN
_RX_MEDICAL_HINT = re.compile(
    r"\b(?:medicine|medication|drug|tablet|pill|capsule|prescription|pharmacy|"
    r"pharmacist|treatment|therapy|antibiotic|painkiller|dose|mg|ml|"
    r"over.the.counter|otc|generic|brand|injection|syrup|ointment)\b",
    re.IGNORECASE,
)


def _subject(text: str) -> str:
    """Normalise a captured entity: trim, strip trailing punctuation, lowercase."""
    return text.strip().rstrip("?.,;:!").strip().lower()


def _find_symptom(query: str) -> Optional[str]:
    """Return the first recognised symptom phrase in the query, or None.

    Matches an optional trailing plural 's' so "migraines" / "cramps" match
    "migraine" / "cramp".
    """
    q = query.lower()
    for word in _SYMPTOM_WORDS:
        if re.search(rf"\b{re.escape(word)}s?\b", q):
            return word
    return None


from functools import lru_cache


@lru_cache(maxsize=1)
def _known_drugs() -> frozenset:
    """Lazily build a set of known generic drug names (curated baseline)."""
    from .config import TARGET_DRUGS
    return frozenset(d.lower() for d in TARGET_DRUGS)


def _looks_like_drug(entity: Optional[str]) -> bool:
    """Best-effort check that `entity` names a medicine we know about."""
    if not entity:
        return False
    entity = entity.lower().strip()
    known = _known_drugs()
    if entity in known or any(tok in known for tok in entity.split()):
        return True
    try:
        from .pharma_index import PharmaIndex
        idx = PharmaIndex.instance()
        if idx.get_generic(entity) or idx.get_drug(entity):
            return True
    except Exception:
        pass
    return False


def _first_group(m: re.Match) -> Optional[str]:
    """Return the first non-empty capturing group of a match."""
    for g in m.groups():
        if g and g.strip():
            return _subject(g)
    return None


def classify(query: str) -> IntentResult:
    """
    Classify a user message into an Intent.

    Ordered rule cascade — the first matching rule wins. Returns an IntentResult
    carrying the captured entity and (where relevant) a sub_type.
    """
    q = (query or "").strip()
    if not q:
        return IntentResult(Intent.UNKNOWN, confidence=0.0, matched="empty")

    # ── 1. Symptom (first-person framing) ─────────────────────────────────────
    symptom = _find_symptom(q)
    if symptom and (
        _RX_FIRST_PERSON.search(q)
        or _RX_SEEKING.search(q)
        or _RX_MY_HURTS.search(q)
    ):
        return IntentResult(
            Intent.SYMPTOM_QUERY, entity=symptom, matched="symptom_first_person"
        )
    # "my throat is sore" / "my head hurts" — possessive framing is itself a
    # symptom report even when no keyword from the list is present. Map the body
    # part to a symptom so the right workflow is selected.
    mh = _RX_MY_HURTS.search(q)
    if mh:
        body = mh.group(1).strip().lower()
        mapped = symptom
        for part, sym in _BODY_PART_SYMPTOM.items():
            if part in body:
                mapped = sym
                break
        return IntentResult(
            Intent.SYMPTOM_QUERY, entity=mapped, matched="symptom_possessive"
        )

    # ── 2. Brand <-> Generic ──────────────────────────────────────────────────
    m = _RX_BRAND_TO_GENERIC.search(q)
    if m:
        return IntentResult(
            Intent.BRAND_GENERIC_QUERY, entity=_subject(m.group(1)),
            sub_type="brand_to_generic", matched="brand_to_generic",
        )
    m = _RX_GENERIC_TO_BRANDS.search(q)
    if m:
        return IntentResult(
            Intent.BRAND_GENERIC_QUERY, entity=_subject(m.group(1)),
            sub_type="generic_to_brands", matched="generic_to_brands",
        )

    # ── 3. Ingredient lookup ──────────────────────────────────────────────────
    m = _RX_INGREDIENT.search(q)
    if m:
        return IntentResult(
            Intent.INGREDIENT_LOOKUP_QUERY, entity=_subject(m.group(1)),
            matched="ingredient",
        )

    # ── 4. Disease -> Medicine ────────────────────────────────────────────────
    m = _RX_DISEASE1.search(q) or _RX_DISEASE2.search(q) or _RX_DISEASE3.search(q)
    if m:
        return IntentResult(
            Intent.DISEASE_TO_MEDICINE_QUERY, entity=_subject(m.group(1)),
            matched="disease_to_medicine",
        )

    # ── 5. Interaction ────────────────────────────────────────────────────────
    if _RX_INTERACTION.search(q):
        return IntentResult(Intent.INTERACTION_QUERY, matched="interaction")

    # ── 6. FDA safety / recalls ───────────────────────────────────────────────
    if _RX_FDA_SAFETY.search(q):
        return IntentResult(Intent.FDA_SAFETY_QUERY, matched="fda_safety")

    # ── 7. Dosage ─────────────────────────────────────────────────────────────
    if _RX_DOSAGE.search(q):
        return IntentResult(Intent.DOSAGE_QUERY, matched="dosage")

    # ── 8. Side effects ───────────────────────────────────────────────────────
    if _RX_SIDE_EFFECT.search(q):
        return IntentResult(Intent.SIDE_EFFECT_QUERY, matched="side_effect")

    # ── 9. Warnings / contraindications (extension) ───────────────────────────
    if _RX_WARNINGS.search(q):
        return IntentResult(Intent.WARNINGS_QUERY, matched="warnings")

    # ── 10. Medicine -> Disease ("what is X used for") ────────────────────────
    m = _RX_MED_TO_DISEASE.search(q)
    if m:
        return IntentResult(
            Intent.MEDICINE_TO_DISEASE_QUERY, entity=_first_group(m),
            matched="medicine_to_disease",
        )

    # ── 11. Drug lookup ("tell me about X", "what is X") ──────────────────────
    m = _RX_DRUG_LOOKUP_STRONG.search(q)
    if m:
        return IntentResult(
            Intent.DRUG_LOOKUP, entity=_subject(m.group(1)),
            matched="drug_lookup_strong",
        )
    m = _RX_DRUG_LOOKUP_WEAK.search(q)
    if m:
        entity = _subject(m.group(1))
        if _looks_like_drug(entity) or _RX_MEDICAL_HINT.search(q):
            return IntentResult(
                Intent.DRUG_LOOKUP, entity=entity, matched="drug_lookup_weak",
            )

    # ── 12. General medical vs unknown ────────────────────────────────────────
    if _RX_MEDICAL_HINT.search(q) or _find_symptom(q):
        return IntentResult(
            Intent.GENERAL_MEDICAL_QUERY, confidence=0.6, matched="medical_hint",
        )

    return IntentResult(Intent.UNKNOWN, confidence=0.3, matched="no_match")
