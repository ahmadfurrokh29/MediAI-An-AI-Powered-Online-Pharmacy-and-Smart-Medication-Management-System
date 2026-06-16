"""
Retrieval service — converts a user query into a ranked list of context chunks.

Flow:
  1. Embed the user query with the BGE query prefix
  2. Query ChromaDB for the top-K nearest neighbours
  3. Filter out chunks below the minimum similarity threshold
  4. Return a list of RetrievedChunk objects (content + metadata + score)
"""
from __future__ import annotations

import logging
from dataclasses import dataclass
from typing import List, Optional

from .config import TOP_K, MIN_SCORE, MAX_CONTEXT_CHARS
from .embedder import embed_query
from .vector_store import query_store

logger = logging.getLogger(__name__)


@dataclass
class RetrievedChunk:
    """A single retrieved context chunk with its provenance metadata."""
    content:    str
    drug_name:  str
    section:    str
    source:     str
    score:      float   # cosine similarity (0–1); higher is better
    doc_id:     str = ""
    chunk_index: int = 0

    @property
    def citation(self) -> str:
        """Human-readable citation string for the LLM prompt."""
        return f"[{self.source.upper()} | {self.drug_name.title()} | {self.section.replace('_', ' ').title()}]"


def retrieve_context(
    query: str,
    top_k: int = TOP_K,
    min_score: float = MIN_SCORE,
    drug_filter: Optional[str] = None,
    section_filter: Optional[str] = None,
    source_filter: Optional[str] = None,
) -> List[RetrievedChunk]:
    """
    Retrieve the most relevant pharmaceutical chunks for [query].

    Args:
        query          : The user's natural-language question
        top_k          : Maximum chunks to consider before score filtering
        min_score      : Discard chunks with similarity below this threshold
        drug_filter    : Restrict retrieval to a specific drug name
        section_filter : Restrict to a canonical section (e.g. "dosage", "side_effects")
        source_filter  : Restrict to a data source ("dailymed" | "openfda")

    Returns:
        A list of RetrievedChunk objects sorted by descending similarity score.
    """
    if not query.strip():
        return []

    # 1. Embed the query
    query_vector = embed_query(query)

    # 2. Build optional metadata filter — supports multiple conditions via $and
    conditions = []
    if drug_filter:
        conditions.append({"drug_name": {"$eq": drug_filter.lower().strip()}})
    if section_filter:
        conditions.append({"section": {"$eq": section_filter}})
    if source_filter:
        conditions.append({"source": {"$eq": source_filter}})

    if len(conditions) == 0:
        where_filter = None
    elif len(conditions) == 1:
        where_filter = conditions[0]
    else:
        where_filter = {"$and": conditions}

    # 3. Query ChromaDB
    raw = query_store(query_vector, top_k=top_k, where_filter=where_filter)

    # 4. Unpack and filter
    results: List[RetrievedChunk] = []

    ids_list        = raw.get("ids",        [[]])[0]
    docs_list       = raw.get("documents",  [[]])[0]
    metas_list      = raw.get("metadatas",  [[]])[0]
    distances_list  = raw.get("distances",  [[]])[0]

    for doc, meta, dist in zip(docs_list, metas_list, distances_list):
        # ChromaDB cosine distance ∈ [0, 2]; convert to similarity ∈ [-1, 1]
        # For normalised embeddings: similarity = 1 - distance
        similarity = 1.0 - dist

        if similarity < min_score:
            continue

        results.append(
            RetrievedChunk(
                content=doc,
                drug_name=meta.get("drug_name", ""),
                section=meta.get("section", ""),
                source=meta.get("source", ""),
                score=round(similarity, 4),
                doc_id=meta.get("doc_id", ""),
                chunk_index=int(meta.get("chunk_index", 0)),
            )
        )

    # Sort descending by similarity
    results.sort(key=lambda r: r.score, reverse=True)

    logger.info(
        "[Retrieval] query='%.60s…' → %d/%d chunks above %.2f  "
        "(section=%s source=%s drug=%s)",
        query,
        len(results),
        len(docs_list),
        min_score,
        section_filter or "*",
        source_filter or "*",
        drug_filter or "*",
    )
    return results


def build_context_block(chunks: List[RetrievedChunk]) -> str:
    """
    Format retrieved chunks into a single context string for LLM injection.
    Respects MAX_CONTEXT_CHARS to stay within token limits.
    """
    if not chunks:
        return ""

    parts: List[str] = []
    total_chars = 0

    for chunk in chunks:
        segment = f"{chunk.citation}\n{chunk.content}"
        if total_chars + len(segment) > MAX_CONTEXT_CHARS:
            break
        parts.append(segment)
        total_chars += len(segment)

    return "\n\n---\n\n".join(parts)
