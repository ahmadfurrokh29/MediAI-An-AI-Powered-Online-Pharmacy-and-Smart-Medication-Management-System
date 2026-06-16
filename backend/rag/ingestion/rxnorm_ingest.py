"""
RxNorm enrichment pipeline.

Iterates over TARGET_DRUGS from config.py (plus any drugs ingested on-demand
into the vector store), fetches RxNorm metadata for each one, and saves the
results to the pharma index (rag/data/pharma_index.json).

Usage:
    python -m rag.ingestion.rxnorm_ingest               # enrich all known drugs
    python -m rag.ingestion.rxnorm_ingest --drug advil  # enrich a single drug
    python -m rag.ingestion.rxnorm_ingest --force       # re-fetch already indexed drugs
"""
from __future__ import annotations

import argparse
import logging
import time
from typing import List

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)

# Polite rate-limit for the free NIH API: pause after every N requests
_BATCH_SIZE = 10
_BATCH_PAUSE = 1.0  # seconds


def _discover_drugs() -> List[str]:
    """Return the union of TARGET_DRUGS and any drugs already in the vector store."""
    from rag.config import TARGET_DRUGS
    known: set[str] = set(TARGET_DRUGS)

    try:
        from rag.vector_store import _get_collection
        col = _get_collection()
        result = col.get(include=["metadatas"])
        for meta in result.get("metadatas", []):
            dn = (meta.get("drug_name") or "").strip()
            if dn:
                known.add(dn)
    except Exception as exc:
        logger.warning("[RxNormIngest] Vector store scan failed: %s", exc)

    return sorted(known)


def enrich_one(drug_name: str, force: bool = False) -> bool:
    """
    Fetch and store RxNorm data for a single drug.

    Returns True on success (including "already indexed, skipped").
    """
    from rag.rxnorm import fetch_rxnorm_data
    from rag.pharma_index import PharmaIndex

    idx = PharmaIndex.instance()

    if not force and idx.get_drug(drug_name):
        logger.debug("[RxNormIngest] '%s' already indexed — skipping", drug_name)
        return True

    logger.info("[RxNormIngest] Enriching '%s'…", drug_name)
    try:
        data = fetch_rxnorm_data(drug_name)
    except Exception as exc:
        logger.error("[RxNormIngest] Failed for '%s': %s", drug_name, exc)
        return False

    idx.update_drug(drug_name, data)
    logger.info(
        "[RxNormIngest] '%s' ✓  rxcui=%-8s  brands=%-3d  class=%s",
        drug_name,
        data.get("rxcui") or "n/a",
        len(data.get("brand_names", [])),
        data.get("drug_class") or "unknown",
    )
    return True


def run(drugs: List[str], force: bool = False) -> None:
    from rag.pharma_index import PharmaIndex
    idx = PharmaIndex.instance()

    ok = fail = skipped = 0
    for i, drug in enumerate(drugs, 1):
        if not force and idx.get_drug(drug):
            skipped += 1
            continue
        if enrich_one(drug, force=force):
            ok += 1
        else:
            fail += 1
        if i % _BATCH_SIZE == 0:
            time.sleep(_BATCH_PAUSE)

    logger.info(
        "[RxNormIngest] Complete — enriched=%d  skipped=%d  failed=%d",
        ok, skipped, fail,
    )
    logger.info("[PharmaIndex] Final stats: %s", idx.stats())


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Enrich the pharma index with RxNorm data"
    )
    parser.add_argument("--drug", help="Enrich a single drug by name")
    parser.add_argument(
        "--force", action="store_true",
        help="Re-fetch even if the drug is already in the index",
    )
    args = parser.parse_args()

    if args.drug:
        drugs = [args.drug.lower().strip()]
    else:
        drugs = _discover_drugs()
        logger.info("[RxNormIngest] %d drugs discovered", len(drugs))

    run(drugs, force=args.force)
