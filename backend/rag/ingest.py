"""
Pharmaceutical data ingestion pipeline.

Run this script ONCE (or whenever you want to refresh the knowledge base):

    cd backend
    python -m rag.ingest

What it does:
  1. For each target drug, fetches data from DailyMed AND OpenFDA
  2. Normalises responses into PharmChunk objects
  3. Generates embeddings using BAAI/bge-small-en-v1.5
  4. Upserts all chunks into ChromaDB (idempotent — safe to re-run)

Expected runtime: ~3-8 minutes on first run (model download + API calls).
Subsequent runs skip drugs that are already ingested (use --force to re-ingest).

Usage:
    python -m rag.ingest               # skip already-ingested drugs
    python -m rag.ingest --force       # re-ingest everything
    python -m rag.ingest --drug ibuprofen   # ingest a single drug
"""
from __future__ import annotations

import argparse
import logging
import sys
import time
from typing import List

from .config import TARGET_DRUGS
from .ingestion.dailymed import ingest_dailymed
from .ingestion.openfda import ingest_openfda
from .schema import PharmChunk
from .vector_store import store_chunks, drug_exists, collection_count, delete_drug

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger(__name__)


def ingest_drug(drug_name: str, force: bool = False) -> int:
    """
    Ingest all data for a single [drug_name].
    Returns the total number of chunks stored.
    """
    normalised = drug_name.lower().strip()

    if not force and drug_exists(normalised):
        logger.info("⏭  '%s' already in vector store — skipping (use --force to override)", drug_name)
        return 0

    # On a forced re-ingest, clear any prior chunks first so a smaller new run
    # cannot leave orphaned chunks behind (upsert only overwrites, never prunes).
    if force:
        delete_drug(normalised)

    logger.info("🔍 Ingesting '%s'…", drug_name)
    all_chunks: List[PharmChunk] = []

    # ── DailyMed ──────────────────────────────────────────────────────────────
    try:
        dm_chunks = ingest_dailymed(drug_name)
        all_chunks.extend(dm_chunks)
        logger.info("  ✓ DailyMed → %d chunks", len(dm_chunks))
    except Exception as exc:
        logger.error("  ✗ DailyMed failed: %s", exc)

    # Small delay to be polite to public APIs
    time.sleep(0.5)

    # ── OpenFDA ───────────────────────────────────────────────────────────────
    try:
        fda_chunks = ingest_openfda(drug_name)
        all_chunks.extend(fda_chunks)
        logger.info("  ✓ OpenFDA  → %d chunks", len(fda_chunks))
    except Exception as exc:
        logger.error("  ✗ OpenFDA failed: %s", exc)

    time.sleep(0.5)

    if not all_chunks:
        logger.warning("  ⚠  No chunks produced for '%s'", drug_name)
        return 0

    # ── Embed + store ─────────────────────────────────────────────────────────
    stored = store_chunks(all_chunks)
    logger.info("  💾 Stored %d chunks for '%s'", stored, drug_name)
    return stored


def run_pipeline(drugs: List[str], force: bool = False) -> None:
    """Run the full ingestion pipeline for [drugs]."""
    total_stored = 0
    failed: List[str] = []

    logger.info("=" * 60)
    logger.info("MediAI RAG Ingestion Pipeline")
    logger.info("Target drugs: %s", ", ".join(drugs))
    logger.info("=" * 60)

    start = time.time()
    for drug in drugs:
        try:
            stored = ingest_drug(drug, force=force)
            total_stored += stored
        except Exception as exc:
            logger.error("Pipeline failed for '%s': %s", drug, exc)
            failed.append(drug)

    elapsed = time.time() - start
    logger.info("=" * 60)
    logger.info("Ingestion complete in %.1fs", elapsed)
    logger.info("Total chunks stored: %d", total_stored)
    logger.info("Total chunks in DB:  %d", collection_count())
    if failed:
        logger.warning("Failed drugs: %s", ", ".join(failed))
    logger.info("=" * 60)


def main() -> None:
    parser = argparse.ArgumentParser(description="MediAI RAG Ingestion Pipeline")
    parser.add_argument(
        "--force",
        action="store_true",
        help="Re-ingest even if the drug is already in the vector store",
    )
    parser.add_argument(
        "--drug",
        type=str,
        default=None,
        help="Ingest a single drug by name instead of the full target list",
    )
    args = parser.parse_args()

    drugs = [args.drug] if args.drug else TARGET_DRUGS
    run_pipeline(drugs, force=args.force)


if __name__ == "__main__":
    main()
