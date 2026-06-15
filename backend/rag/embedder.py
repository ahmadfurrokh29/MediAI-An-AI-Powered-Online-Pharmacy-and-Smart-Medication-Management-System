"""
Embedding service — wraps SentenceTransformers with a singleton pattern.

Uses BAAI/bge-small-en-v1.5:
  - 33 MB on disk
  - 384-dimensional embeddings
  - Optimised for retrieval tasks (asymmetric: passage vs. query encoding)
  - BGE models benefit from a query prefix "Represent this sentence: "
    when encoding *queries* (not passages).

The model is downloaded from HuggingFace Hub on first use and cached
automatically in ~/.cache/huggingface/hub/.
"""
from __future__ import annotations

import logging
import threading
from typing import List, Optional

logger = logging.getLogger(__name__)

# Thread-safe lazy singleton — model loads once and stays in RAM
_model = None
_model_lock = threading.Lock()

# BGE query prefix — improves retrieval quality for asymmetric search
_BGE_QUERY_PREFIX = "Represent this sentence for searching relevant passages: "


def _get_model():
    """Load the embedding model once and cache it in the module-level singleton.

    The model is loaded from the local HuggingFace cache (`local_files_only=True`)
    so startup makes **zero network calls** — no HEAD requests to huggingface.co,
    no waiting on the Hub. If the model has never been downloaded, we fall back to
    a one-time online download.
    """
    global _model
    if _model is None:
        with _model_lock:
            if _model is None:  # double-checked locking
                from sentence_transformers import SentenceTransformer
                from .config import EMBEDDING_MODEL_NAME
                try:
                    _model = SentenceTransformer(
                        EMBEDDING_MODEL_NAME, local_files_only=True
                    )
                    logger.info("[Embedder] Model loaded from local cache ✓ (offline)")
                except Exception as exc:
                    logger.warning(
                        "[Embedder] Local cache miss (%s) — downloading once from HuggingFace…",
                        exc,
                    )
                    _model = SentenceTransformer(EMBEDDING_MODEL_NAME)
                    logger.info("[Embedder] Model downloaded and cached ✓")
    return _model


def embed_passages(texts: List[str]) -> List[List[float]]:
    """
    Embed a list of document *passages* (no query prefix).
    Used during ingestion to embed chunks before storing in ChromaDB.

    Returns a list of 384-dimensional float vectors.
    """
    if not texts:
        return []
    model = _get_model()
    vectors = model.encode(
        texts,
        batch_size=32,
        show_progress_bar=False,
        normalize_embeddings=True,   # cosine similarity == dot product after normalisation
    )
    return [v.tolist() for v in vectors]


def embed_query(query: str) -> List[float]:
    """
    Embed a single *query* string using the BGE query prefix.
    Used at retrieval time to convert user questions into query vectors.
    """
    model = _get_model()
    prefixed = f"{_BGE_QUERY_PREFIX}{query.strip()}"
    vector = model.encode(
        prefixed,
        normalize_embeddings=True,
        show_progress_bar=False,
    )
    return vector.tolist()
