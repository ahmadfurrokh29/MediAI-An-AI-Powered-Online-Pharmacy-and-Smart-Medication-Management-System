"""
Query routing table.

Declarative mapping from a detected Intent to a RoutePlan that says:
  * which knowledge source(s) the answer should come from (for logging/strategy)
  * which ChromaDB section / source filter to apply during retrieval
  * which execution strategy the router should use

This is the "query router" decision layer the rest of the system reads. Keeping
it as a plain data table (not branching code) is what makes the routing
"modular and easily extendable" — to change behaviour you edit one row; to add
an intent you add one enum member (in intent_classifier) and one row here.

Strategies
----------
  direct_lookup    : answer is built directly from the pharma index / a targeted
                     index search — no LLM call (brand/generic/ingredient/disease)
  section_rag      : semantic RAG restricted to a section / source, then Groq
  general_rag      : unrestricted semantic RAG, then Groq
  symptom_workflow : hand off to the dedicated symptom placeholder (no triage)
  refuse           : not medical — let the LLM guardrail decline (falls back to
                     general_rag so existing refusal behaviour is preserved)

NOTE on `source_filter`: ChromaDB only stores "dailymed" / "openfda" chunks
(RxNorm data lives in pharma_index.json, not the vector store). So `source_filter`
is set ONLY when we want to hard-restrict Chroma retrieval (e.g. FDA safety →
openfda). The human-readable `sources` list is for logging and may name RxNorm
or the disease index even when `source_filter` is None.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, List, Optional

from .intent_classifier import Intent
from .schema import (
    SECTION_DOSAGE,
    SECTION_SIDE_EFFECTS,
    SECTION_WARNINGS,
    SECTION_INTERACTIONS,
    SECTION_INDICATIONS,
)

# Strategy constants
STRATEGY_DIRECT_LOOKUP    = "direct_lookup"
STRATEGY_SECTION_RAG      = "section_rag"
STRATEGY_GENERAL_RAG      = "general_rag"
STRATEGY_SYMPTOM_WORKFLOW = "symptom_workflow"
STRATEGY_REFUSE           = "refuse"


@dataclass
class RoutePlan:
    """How a given intent should be served."""
    intent:         Intent
    strategy:       str
    sources:        List[str] = field(default_factory=list)  # human-readable, for logs
    section_filter: Optional[str] = None   # ChromaDB section restriction
    source_filter:  Optional[str] = None   # ChromaDB source restriction
    description:    str = ""


ROUTING_TABLE: Dict[Intent, RoutePlan] = {
    Intent.DRUG_LOOKUP: RoutePlan(
        intent=Intent.DRUG_LOOKUP,
        strategy=STRATEGY_GENERAL_RAG,
        sources=["DailyMed", "RxNorm"],
        description="General medicine information",
    ),
    Intent.DOSAGE_QUERY: RoutePlan(
        intent=Intent.DOSAGE_QUERY,
        strategy=STRATEGY_SECTION_RAG,
        sources=["DailyMed"],
        section_filter=SECTION_DOSAGE,
        description="Dosage & administration",
    ),
    Intent.SIDE_EFFECT_QUERY: RoutePlan(
        intent=Intent.SIDE_EFFECT_QUERY,
        strategy=STRATEGY_SECTION_RAG,
        sources=["OpenFDA", "DailyMed"],
        section_filter=SECTION_SIDE_EFFECTS,
        description="Adverse reactions / side effects",
    ),
    Intent.DISEASE_TO_MEDICINE_QUERY: RoutePlan(
        intent=Intent.DISEASE_TO_MEDICINE_QUERY,
        strategy=STRATEGY_DIRECT_LOOKUP,
        sources=["DiseaseIndex (DailyMed indications)"],
        section_filter=SECTION_INDICATIONS,
        description="Disease -> indicated medicines",
    ),
    Intent.MEDICINE_TO_DISEASE_QUERY: RoutePlan(
        intent=Intent.MEDICINE_TO_DISEASE_QUERY,
        strategy=STRATEGY_SECTION_RAG,
        sources=["DailyMed"],
        section_filter=SECTION_INDICATIONS,
        description="Medicine -> indications / uses",
    ),
    Intent.INGREDIENT_LOOKUP_QUERY: RoutePlan(
        intent=Intent.INGREDIENT_LOOKUP_QUERY,
        strategy=STRATEGY_DIRECT_LOOKUP,
        sources=["RxNorm"],
        description="Ingredient -> medicines mapping",
    ),
    Intent.BRAND_GENERIC_QUERY: RoutePlan(
        intent=Intent.BRAND_GENERIC_QUERY,
        strategy=STRATEGY_DIRECT_LOOKUP,
        sources=["RxNorm", "DailyMed"],
        description="Brand <-> generic mapping",
    ),
    Intent.INTERACTION_QUERY: RoutePlan(
        intent=Intent.INTERACTION_QUERY,
        strategy=STRATEGY_SECTION_RAG,
        sources=["DailyMed", "OpenFDA"],
        section_filter=SECTION_INTERACTIONS,
        description="Drug-drug interactions",
    ),
    Intent.FDA_SAFETY_QUERY: RoutePlan(
        intent=Intent.FDA_SAFETY_QUERY,
        strategy=STRATEGY_SECTION_RAG,
        sources=["OpenFDA"],
        source_filter="openfda",
        description="Recalls / FDA safety alerts",
    ),
    Intent.WARNINGS_QUERY: RoutePlan(
        intent=Intent.WARNINGS_QUERY,
        strategy=STRATEGY_SECTION_RAG,
        sources=["DailyMed", "OpenFDA"],
        section_filter=SECTION_WARNINGS,
        description="Warnings / contraindications / precautions",
    ),
    Intent.SYMPTOM_QUERY: RoutePlan(
        intent=Intent.SYMPTOM_QUERY,
        strategy=STRATEGY_SYMPTOM_WORKFLOW,
        sources=["SymptomWorkflow (placeholder)"],
        description="First-person symptom -> dedicated symptom workflow",
    ),
    Intent.GENERAL_MEDICAL_QUERY: RoutePlan(
        intent=Intent.GENERAL_MEDICAL_QUERY,
        strategy=STRATEGY_GENERAL_RAG,
        sources=["DailyMed", "OpenFDA"],
        description="General pharma question",
    ),
    Intent.UNKNOWN: RoutePlan(
        intent=Intent.UNKNOWN,
        strategy=STRATEGY_REFUSE,
        sources=[],
        description="Not recognisably medical — defer to LLM guardrail",
    ),
}

# Fallback plan if an intent is somehow missing from the table.
_DEFAULT_PLAN = RoutePlan(
    intent=Intent.GENERAL_MEDICAL_QUERY,
    strategy=STRATEGY_GENERAL_RAG,
    sources=["DailyMed", "OpenFDA"],
    description="Fallback general RAG",
)


def get_route(intent: Intent) -> RoutePlan:
    """Return the RoutePlan for an intent (never raises — falls back to general RAG)."""
    return ROUTING_TABLE.get(intent, _DEFAULT_PLAN)
