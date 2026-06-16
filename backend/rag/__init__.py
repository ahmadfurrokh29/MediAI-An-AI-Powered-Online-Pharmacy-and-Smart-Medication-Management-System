# RAG package — exposes the public surface used by main.py
from .retrieval import retrieve_context
from .chat_service import rag_chat
from .pharma_index import PharmaIndex
from .intent_classifier import Intent, IntentResult, classify
from .routing_table import RoutePlan, get_route, ROUTING_TABLE
from .query_router import route_query, RouterResult, QueryIntent
from .conversation_state import ConversationStore, TriageSession, TriageState
from .symptom_workflow import WORKFLOWS, resolve_workflow, SymptomWorkflow
from .symptom_triage import (
    detect_emergency,
    build_emergency_reply,
    start_assessment,
    continue_assessment,
)
from .response_formatter import (
    generation_system_prompt,
    confidence_from_chunks,
    append_grounded_meta,
    friendly_source,
)

__all__ = [
    "retrieve_context",
    "rag_chat",
    "PharmaIndex",
    "Intent",
    "IntentResult",
    "classify",
    "RoutePlan",
    "get_route",
    "ROUTING_TABLE",
    "route_query",
    "RouterResult",
    "QueryIntent",
    # Phase 2 — symptom triage
    "ConversationStore",
    "TriageSession",
    "TriageState",
    "WORKFLOWS",
    "resolve_workflow",
    "SymptomWorkflow",
    "detect_emergency",
    "build_emergency_reply",
    "start_assessment",
    "continue_assessment",
    # Phase 3 — response formatting
    "generation_system_prompt",
    "confidence_from_chunks",
    "append_grounded_meta",
    "friendly_source",
]
