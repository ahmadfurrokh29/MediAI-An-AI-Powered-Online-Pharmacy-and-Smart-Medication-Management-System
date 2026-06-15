# RAG package — exposes the public surface used by main.py
from .retrieval import retrieve_context
from .chat_service import rag_chat

__all__ = ["retrieve_context", "rag_chat"]
