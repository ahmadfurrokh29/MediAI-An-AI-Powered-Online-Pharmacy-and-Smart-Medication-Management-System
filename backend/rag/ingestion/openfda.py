"""
OpenFDA ingestion service.

OpenFDA provides structured drug label data through its /drug/label endpoint.
We query it by generic drug name and pull every relevant section.

API docs: https://open.fda.gov/apis/drug/label/
"""
from __future__ import annotations

import logging
from typing import Dict, List, Optional

import httpx

from ..config import OPENFDA_BASE_URL, API_TIMEOUT
from ..schema import (
    PharmChunk,
    SECTION_INDICATIONS,
    SECTION_DOSAGE,
    SECTION_WARNINGS,
    SECTION_SIDE_EFFECTS,
    SECTION_INTERACTIONS,
    SECTION_CONTRAINDICATIONS,
    SECTION_DESCRIPTION,
    SECTION_PHARMACOLOGY,
    SECTION_OVERDOSE,
    SECTION_STORAGE,
    SECTION_GENERAL,
)
from ..chunker import chunk_text

logger = logging.getLogger(__name__)

# Map OpenFDA field names → canonical section constants
# OpenFDA returns sections as flat JSON arrays of strings.
_FIELD_MAP: Dict[str, str] = {
    "indications_and_usage":           SECTION_INDICATIONS,
    "dosage_and_administration":        SECTION_DOSAGE,
    "warnings":                         SECTION_WARNINGS,
    "warnings_and_cautions":            SECTION_WARNINGS,
    "boxed_warning":                    SECTION_WARNINGS,
    "adverse_reactions":                SECTION_SIDE_EFFECTS,
    "drug_interactions":                SECTION_INTERACTIONS,
    "contraindications":                SECTION_CONTRAINDICATIONS,
    "description":                      SECTION_DESCRIPTION,
    "clinical_pharmacology":            SECTION_PHARMACOLOGY,
    "mechanism_of_action":              SECTION_PHARMACOLOGY,
    "overdosage":                       SECTION_OVERDOSE,
    "how_supplied":                     SECTION_STORAGE,
    "storage_and_handling":             SECTION_STORAGE,
    "information_for_patients":         SECTION_GENERAL,
    "patient_counseling_information":   SECTION_GENERAL,
    "use_in_specific_populations":      SECTION_GENERAL,
    "purpose":                          SECTION_GENERAL,
    "active_ingredient":                SECTION_DESCRIPTION,
    "inactive_ingredient":              SECTION_DESCRIPTION,
}


def _fetch_openfda_label(drug_name: str, client: httpx.Client) -> Optional[Dict]:
    """
    Query OpenFDA /drug/label for the first matching result for [drug_name].
    Returns the raw result dict, or None on failure.
    """
    try:
        resp = client.get(
            f"{OPENFDA_BASE_URL}/label.json",
            params={
                "search": f'openfda.generic_name:"{drug_name}"',
                "limit": 1,
            },
            timeout=API_TIMEOUT,
        )
        if resp.status_code == 404:
            # Try broader search if exact generic name fails
            resp = client.get(
                f"{OPENFDA_BASE_URL}/label.json",
                params={
                    "search": f'generic_name:"{drug_name}"',
                    "limit": 1,
                },
                timeout=API_TIMEOUT,
            )
        resp.raise_for_status()
        results = resp.json().get("results", [])
        if not results:
            logger.warning("[OpenFDA] No label found for '%s'", drug_name)
            return None
        return results[0]
    except Exception as exc:
        logger.error("[OpenFDA] label fetch failed for '%s': %s", drug_name, exc)
        return None


def ingest_openfda(drug_name: str) -> List[PharmChunk]:
    """
    Fetch and normalise OpenFDA label data for [drug_name].
    Returns a list of PharmChunk objects ready for embedding.
    """
    chunks: List[PharmChunk] = []
    normalised_name = drug_name.lower().strip()

    with httpx.Client() as client:
        label = _fetch_openfda_label(drug_name, client)
        if not label:
            return chunks

        # OpenFDA returns a doc_id inside the 'set_id' or 'id' field
        doc_id = label.get("set_id") or label.get("id", "")

        processed_sections = 0
        # Global chunk index — shared across ALL fields for this drug/source.
        # This is critical: multiple OpenFDA fields can map to the same canonical
        # section (e.g. 'description' and 'active_ingredient' both → SECTION_DESCRIPTION).
        # Using a global counter ensures chunk IDs are always unique.
        global_idx = 0

        for field_name, canonical_section in _FIELD_MAP.items():
            raw_values = label.get(field_name)
            if not raw_values:
                continue

            # OpenFDA fields are arrays of strings — join with a newline
            if isinstance(raw_values, list):
                combined = "\n".join(str(v) for v in raw_values if v)
            else:
                combined = str(raw_values)

            if len(combined.strip()) < 30:
                continue

            text_chunks = chunk_text(combined)
            for chunk_content in text_chunks:
                chunks.append(
                    PharmChunk(
                        drug_name=normalised_name,
                        section=canonical_section,
                        source="openfda",
                        content=chunk_content,
                        chunk_index=global_idx,
                        doc_id=doc_id,
                    )
                )
                global_idx += 1
            processed_sections += 1

    logger.info(
        "[OpenFDA] '%s' → %d sections, %d chunks",
        drug_name,
        processed_sections,
        len(chunks),
    )
    return chunks
