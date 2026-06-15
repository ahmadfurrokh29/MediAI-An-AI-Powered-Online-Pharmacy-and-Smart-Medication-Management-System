"""
Vector store — thin wrapper around ChromaDB.

ChromaDB is used in persistent mode: all data survives process restarts.
We manage our own embeddings (via embedder.py) and pass them to ChromaDB
using the EmbeddingFunction=None pattern so ChromaDB stores them as-is.

Collection schema (metadata per document):
  drug_name   : str  — e.g. "ibuprofen"
  section     : str  — canonical section constant
  source      : str  — "dailymed" | "openfda"
  doc_id      : str  — upstream document identifier
  chunk_index : int  — 0-based position within section
"""
from __future__ import annotations

import logging
import threading
from typing import Dict, List, Optional

import chromadb
from chromadb.config import Settings

from .config import CHROMA_PERSIST_DIR, CHROMA_COLLECTION_NAME
from .schema import PharmChunk
from .embedder import embed_passages

logger = logging.getLogger(__name__)

# Thread-safe lazy singleton for the Chroma client
_client: Optional[chromadb.PersistentClient] = None
_collection = None
_store_lock = threading.Lock()


def _get_collection():
    """Return (creating if necessary) the ChromaDB collection singleton."""
    global _client, _collection
    if _collection is None:
        with _store_lock:
            if _collection is None:
                logger.info(
                    "[VectorStore] Opening ChromaDB at '%s'", CHROMA_PERSIST_DIR
                )
                _client = chromadb.PersistentClient(
                    path=CHROMA_PERSIST_DIR,
                    settings=Settings(anonymized_telemetry=False),
                )
                # get_or_create — idempotent; safe to call on every startup
                _collection = _client.get_or_create_collection(
                    name=CHROMA_COLLECTION_NAME,
                    # We supply our own embeddings, so no embedding function needed
                    metadata={"hnsw:space": "cosine"},
                )
                logger.info(
                    "[VectorStore] Collection '%s' ready (%d docs)",
                    CHROMA_COLLECTION_NAME,
                    _collection.count(),
                )
    return _collection


def store_chunks(chunks: List[PharmChunk]) -> int:
    """
    Embed [chunks] and upsert them into ChromaDB.
    Upsert is idempotent — re-ingesting the same drug is safe.

    Returns the number of chunks successfully stored.
    """
    if not chunks:
        return 0

    collection = _get_collection()

    # Embed in one batch for efficiency
    texts = [c.content for c in chunks]
    vectors = embed_passages(texts)

    ids        = [c.chroma_id for c in chunks]
    metadatas  = [c.metadata  for c in chunks]

    # ChromaDB upsert: inserts new docs, updates existing ones with the same id
    collection.upsert(
        ids=ids,
        documents=texts,
        embeddings=vectors,
        metadatas=metadatas,
    )
    logger.info("[VectorStore] Upserted %d chunks", len(chunks))
    return len(chunks)


def query_store(
    query_vector: List[float],
    top_k: int,
    where_filter: Optional[Dict] = None,
) -> Dict:
    """
    Query ChromaDB with a pre-computed embedding vector.

    Args:
        query_vector : 384-dim float list from embedder.embed_query()
        top_k        : Maximum number of results to return
        where_filter : Optional ChromaDB metadata filter
                       e.g. {"drug_name": {"$eq": "ibuprofen"}}

    Returns a raw ChromaDB query result dict with keys:
        ids, documents, metadatas, distances
    """
    collection = _get_collection()
    kwargs: Dict = dict(
        query_embeddings=[query_vector],
        n_results=min(top_k, max(collection.count(), 1)),
        include=["documents", "metadatas", "distances"],
    )
    if where_filter:
        kwargs["where"] = where_filter

    return collection.query(**kwargs)


def delete_drug(drug_name: str) -> None:
    """
    Remove all chunks for [drug_name] from the collection.

    Called before a forced re-ingest so that a fresh run cannot leave behind
    orphaned chunks from a previous run that produced more chunks (the upsert
    in store_chunks only overwrites matching ids, never deletes surplus ones).
    """
    collection = _get_collection()
    try:
        collection.delete(where={"drug_name": {"$eq": drug_name.lower().strip()}})
    except Exception as exc:
        logger.warning("[VectorStore] delete_drug('%s') failed: %s", drug_name, exc)


def collection_count() -> int:
    """Return the total number of documents in the collection."""
    return _get_collection().count()


def drug_exists(drug_name: str) -> bool:
    """Return True if [drug_name] already has chunks in the collection."""
    try:
        result = _get_collection().get(
            where={"drug_name": {"$eq": drug_name.lower().strip()}},
            limit=1,
        )
        return len(result["ids"]) > 0
    except Exception:
        return False
