"""
Query router — turns a classified intent into an action.

This module sits between the intent classifier and the RAG pipeline:

    user query
        │
        ▼
    intent_classifier.classify()      → Intent + entity (WHAT is being asked)
        │
        ▼
    routing_table.get_route()         → RoutePlan (WHICH source + strategy)
        │
        ▼
    route_query()  (this file)        → either a finished answer (direct lookup
                                        / symptom placeholder) OR retrieval
                                        filter hints for the RAG pipeline

Strategies handled here:
  * direct_lookup    — build the answer from the pharma index / disease search
                       (brand/generic, ingredient, disease). No LLM call.
  * symptom_workflow — hand off to the symptom placeholder. No retrieval.
  * section_rag /
    general_rag /
    refuse           — return section/source filter hints; caller runs RAG.

Backward compatibility: `QueryIntent` is re-exported as an alias of the new
`Intent` enum so existing imports keep working.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass
from typing import Dict, List, Optional

from .intent_classifier import Intent, IntentResult, classify
from .routing_table import (
    RoutePlan,
    get_route,
    STRATEGY_DIRECT_LOOKUP,
    STRATEGY_SYMPTOM_WORKFLOW,
    STRATEGY_REFUSE,
)

logger = logging.getLogger(__name__)

# Backward-compatible alias (old code imported `QueryIntent`)
QueryIntent = Intent


@dataclass
class RouterResult:
    """
    Returned by route_query().

    If routed=True  → `answer` is a final response string; skip the RAG pipeline.
    If routed=False → `answer` is None; use `section_filter` / `source_filter`
                      hints when calling retrieve_context().
    """
    intent:         Intent
    answer:         Optional[str] = None
    metadata:       Optional[dict] = None
    section_filter: Optional[str] = None
    source_filter:  Optional[str] = None
    strategy:       str = ""
    sources:        Optional[List[str]] = None
    entity:         Optional[str] = None
    routed:         bool = False


def route_query(query: str) -> RouterResult:
    """
    Classify the query, look up its route, and either build a direct answer or
    return retrieval hints for the RAG pipeline.

    Logging (requirement #6) emits the detected intent, the selected route /
    strategy, and the knowledge source(s) chosen. The retrieval source actually
    used is additionally logged inside retrieve_context().
    """
    ir: IntentResult = classify(query)
    plan: RoutePlan = get_route(ir.intent)

    logger.info(
        "[Router] intent=%s | entity=%s | strategy=%s | sources=[%s] | "
        "section=%s | source_filter=%s | matched=%s",
        ir.intent.value,
        ir.entity or "-",
        plan.strategy,
        ", ".join(plan.sources) if plan.sources else "-",
        plan.section_filter or "*",
        plan.source_filter or "*",
        ir.matched,
    )

    # ── Symptom workflow ──────────────────────────────────────────────────────
    # Phase 2: symptom queries are handled by the stateful triage engine in
    # chat_service (which has the session_id). The router only classifies them
    # and hands control back — it must NOT retrieve medicines here.
    if plan.strategy == STRATEGY_SYMPTOM_WORKFLOW:
        return RouterResult(
            intent=ir.intent, answer=None, routed=False,
            strategy=plan.strategy, sources=plan.sources, entity=ir.entity,
            metadata={"symptom": ir.entity},
        )

    # ── Direct-index lookups (no LLM) ─────────────────────────────────────────
    if plan.strategy == STRATEGY_DIRECT_LOOKUP:
        direct = _try_direct_lookup(ir)
        if direct is not None:
            return direct
        # Fall through: index had no answer → degrade gracefully to RAG using
        # the plan's section hint (preserves prior behaviour, e.g. "Zoloft"
        # answered from DailyMed when the brand isn't in the index).
        logger.info(
            "[Router] direct lookup empty for intent=%s entity=%s → RAG fallback",
            ir.intent.value, ir.entity,
        )

    # ── Section / general RAG (and refuse → general RAG guardrail) ─────────────
    return RouterResult(
        intent=ir.intent,
        section_filter=plan.section_filter,
        source_filter=plan.source_filter,
        strategy=plan.strategy,
        sources=plan.sources,
        entity=ir.entity,
        routed=False,
    )


# ── Direct-lookup builders ──────────────────────────────────────────────────

def _try_direct_lookup(ir: IntentResult) -> Optional[RouterResult]:
    """
    Attempt to answer an intent directly from the pharma index / disease search.
    Returns a routed RouterResult on success, or None to signal "fall through to
    RAG".
    """
    from .pharma_index import PharmaIndex
    idx = PharmaIndex.instance()

    # ── Brand <-> Generic ─────────────────────────────────────────────────────
    if ir.intent == Intent.BRAND_GENERIC_QUERY and ir.entity:
        if ir.sub_type == "generic_to_brands":
            return _build_generic_to_brands(idx, ir)
        # default / brand_to_generic
        result = _build_brand_to_generic(idx, ir)
        if result is not None:
            return result
        # Maybe the user said "brands of <generic>" but phrased as generic→? try other
        return _build_generic_to_brands(idx, ir)

    # ── Ingredient lookup ─────────────────────────────────────────────────────
    if ir.intent == Intent.INGREDIENT_LOOKUP_QUERY and ir.entity:
        meds = idx.get_medicines_for_ingredient(ir.entity)
        if meds:
            from .response_formatter import format_ingredient
            answer = format_ingredient(ir.entity, meds)
            return _routed(ir, answer, {"ingredient": ir.entity, "medicines": meds})
        return None

    # ── Disease -> Medicines ──────────────────────────────────────────────────
    if ir.intent == Intent.DISEASE_TO_MEDICINE_QUERY and ir.entity:
        hits = _search_indications(ir.entity)
        if hits:
            from .response_formatter import format_disease
            drug_classes = [
                (h["drug_name"], idx.get_drug_class(h["drug_name"]))
                for h in hits[:10]
            ]
            answer = format_disease(ir.entity, drug_classes)
            return _routed(ir, answer, {"disease": ir.entity, "hits": hits})
        return None

    return None


def _build_brand_to_generic(idx, ir: IntentResult) -> Optional[RouterResult]:
    generic = idx.get_generic(ir.entity)
    if not generic:
        return None
    drug = idx.get_drug(generic) or {}
    from .response_formatter import format_brand_to_generic
    answer = format_brand_to_generic(ir.entity, generic, drug)
    return _routed(ir, answer,
                   {"generic": generic, "rxcui": drug.get("rxcui"),
                    "drug_class": drug.get("drug_class", "")})


def _build_generic_to_brands(idx, ir: IntentResult) -> Optional[RouterResult]:
    resolved = idx.get_generic(ir.entity) or ir.entity
    brands = idx.get_brands(resolved)
    drug = idx.get_drug(resolved) or {}
    if not brands:
        return None
    from .response_formatter import format_generic_to_brands
    answer = format_generic_to_brands(resolved, brands, drug)
    return _routed(ir, answer, {"generic": resolved, "brands": brands})


def _routed(ir: IntentResult, answer: str, metadata: dict) -> RouterResult:
    """Helper to build a routed (direct-answer) RouterResult."""
    return RouterResult(
        intent=ir.intent, answer=answer, metadata=metadata,
        strategy=STRATEGY_DIRECT_LOOKUP, entity=ir.entity, routed=True,
    )


# ── Disease search helper ────────────────────────────────────────────────────

_DISEASE_MIN_SCORE = 0.63  # higher than general MIN_SCORE to avoid false positives


def _search_indications(disease: str, top_k: int = 12) -> List[Dict]:
    """
    Semantic search over the INDICATIONS section of ChromaDB.

    Returns up to top_k unique-drug results sorted by descending similarity.
    A stricter score threshold than general RAG avoids cross-disease bleed.
    """
    from .embedder import embed_query
    from .vector_store import query_store
    from .schema import SECTION_INDICATIONS

    vector = embed_query(f"indicated for {disease} treatment indications")
    raw = query_store(
        vector,
        top_k=top_k * 3,
        where_filter={"section": {"$eq": SECTION_INDICATIONS}},
    )

    metas = raw.get("metadatas", [[]])[0]
    dists = raw.get("distances", [[]])[0]

    seen: Dict[str, float] = {}
    for meta, dist in zip(metas, dists):
        score = 1.0 - dist
        if score < _DISEASE_MIN_SCORE:
            continue
        drug = meta.get("drug_name", "")
        if drug and score > seen.get(drug, -1):
            seen[drug] = score

    return [
        {"drug_name": d, "score": round(s, 4)}
        for d, s in sorted(seen.items(), key=lambda x: x[1], reverse=True)
    ][:top_k]
