from __future__ import annotations

import logging
import re
import xml.etree.ElementTree as ET
from typing import Dict, List, Optional

import httpx

from ..config import DAILYMED_BASE_URL, API_TIMEOUT
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

# SPL XML namespace — all HL7 v3 elements live under this URI
_SPL_NS = "urn:hl7-org:v3"

# Map DailyMed SPL section title keywords → canonical section constants
_SECTION_MAP: Dict[str, str] = {
    "indications and usage":                   SECTION_INDICATIONS,
    "indications & usage":                     SECTION_INDICATIONS,
    "dosage and administration":               SECTION_DOSAGE,
    "dosage & administration":                 SECTION_DOSAGE,
    "warnings":                                SECTION_WARNINGS,
    "warnings and precautions":                SECTION_WARNINGS,
    "boxed warning":                           SECTION_WARNINGS,
    "adverse reactions":                       SECTION_SIDE_EFFECTS,
    "side effects":                            SECTION_SIDE_EFFECTS,
    "drug interactions":                       SECTION_INTERACTIONS,
    "contraindications":                       SECTION_CONTRAINDICATIONS,
    "description":                             SECTION_DESCRIPTION,
    "clinical pharmacology":                   SECTION_PHARMACOLOGY,
    "mechanism of action":                     SECTION_PHARMACOLOGY,
    "overdosage":                              SECTION_OVERDOSE,
    "how supplied":                            SECTION_STORAGE,
    "how supplied/storage and handling":       SECTION_STORAGE,
    "storage and handling":                    SECTION_STORAGE,
    "information for patients":                SECTION_GENERAL,
    "patient counseling information":          SECTION_GENERAL,
    "use in specific populations":             SECTION_GENERAL,
}


def _map_section(raw_name: str) -> str:
    """Map a DailyMed section title to a canonical section constant."""
    lower = raw_name.lower().strip()
    for keyword, section in _SECTION_MAP.items():
        if keyword in lower:
            return section
    return SECTION_GENERAL


def _fetch_set_id(drug_name: str, client: httpx.Client) -> Optional[str]:
    """
    Search DailyMed for a drug and return the first human-label SPL set-id.
    Returns None when no result is found.
    """
    try:
        resp = client.get(
            f"{DAILYMED_BASE_URL}/spls.json",
            params={"drug_name": drug_name, "pagesize": 10},
            timeout=API_TIMEOUT,
        )
        resp.raise_for_status()
        data = resp.json()
        results = data.get("data", [])
        if not results:
            logger.warning("[DailyMed] No SPL found for '%s'", drug_name)
            return None
        # Prefer Human Prescription Drug or OTC label; fall back to first result
        for item in results:
            marketing_cat = (item.get("marketing_category") or "").lower()
            if "prescription" in marketing_cat or "otc" in marketing_cat:
                return item["setid"]
        return results[0]["setid"]
    except Exception as exc:
        logger.error("[DailyMed] set-id lookup failed for '%s': %s", drug_name, exc)
        return None


def _fetch_label_sections(set_id: str, client: httpx.Client) -> List[Dict]:
    """
    Download the SPL document for [set_id] and parse it into a list of
    {'name': str, 'text': str} dicts.

    DailyMed v2 serves the raw HL7 CDA XML directly from:
      GET /spls/{set_id}.xml        (200, application/xml)

    NOTE: the plain `/spls/{set_id}` endpoint (no extension) returns
    415 Unsupported Media Type, and `/spls/{set_id}.zip` 302-redirects to
    a download portal — so we fetch the `.xml` form and parse it in-memory.

    The XML contains an HL7 CDA document with sections structured as:
      <document xmlns="urn:hl7-org:v3">
        <component><structuredBody>
          <component><section>
            <title>Indications and Usage</title>
            <text>...</text>
          </section></component>
        </structuredBody></component>
      </document>
    """
    try:
        resp = client.get(
            f"{DAILYMED_BASE_URL}/spls/{set_id}.xml",
            timeout=API_TIMEOUT * 2,
            headers={"Accept": "application/xml, text/xml, */*"},
        )
        resp.raise_for_status()
        xml_content = resp.content

        # Parse the HL7 CDA XML
        root = ET.fromstring(xml_content)
        sections: List[Dict] = []

        # All section elements — SPL nests them, so iterate recursively
        for section_el in root.iter(f"{{{_SPL_NS}}}section"):
            title_el = section_el.find(f"{{{_SPL_NS}}}title")
            text_el  = section_el.find(f"{{{_SPL_NS}}}text")

            title = ""
            if title_el is not None:
                title = "".join(title_el.itertext()).strip()

            # IMPORTANT: use `is None`. An ElementTree element with no child
            # elements is falsy, so `if not text_el` wrongly skips valid
            # <text> nodes that hold only inline text.
            if text_el is None:
                continue

            # Extract all text within the section/text element recursively
            raw_text = " ".join(text_el.itertext())
            raw_text = re.sub(r"\s+", " ", raw_text).strip()

            if title and raw_text and len(raw_text) > 30:
                sections.append({"name": title, "text": raw_text})

        return sections

    except ET.ParseError as exc:
        logger.error("[DailyMed] XML parse error for set_id=%s: %s", set_id, exc)
        return []
    except Exception as exc:
        logger.error("[DailyMed] label fetch failed for set_id=%s: %s", set_id, exc)
        return []


def ingest_dailymed(drug_name: str) -> List[PharmChunk]:
    """
    Fetch and normalise DailyMed data for [drug_name].
    Returns a list of PharmChunk objects ready for embedding.
    """
    chunks: List[PharmChunk] = []
    normalised_name = drug_name.lower().strip()

    # Global chunk index — unique across ALL sections for this drug/source
    # Prevents duplicate IDs when multiple sections share the same canonical name.
    global_idx = 0

    with httpx.Client() as client:
        set_id = _fetch_set_id(drug_name, client)
        if not set_id:
            return chunks

        sections = _fetch_label_sections(set_id, client)
        logger.info(
            "[DailyMed] '%s' → set_id=%s, %d sections found",
            drug_name, set_id, len(sections),
        )

        for section in sections:
            raw_name = section.get("name", "")
            raw_text = section.get("text", "")
            if not raw_text:
                continue

            canonical_section = _map_section(raw_name)
            text_chunks = chunk_text(raw_text)

            for chunk_content in text_chunks:
                chunks.append(
                    PharmChunk(
                        drug_name=normalised_name,
                        section=canonical_section,
                        source="dailymed",
                        content=chunk_content,
                        chunk_index=global_idx,
                        doc_id=set_id,
                    )
                )
                global_idx += 1

    logger.info("[DailyMed] '%s' → %d chunks produced", drug_name, len(chunks))
    return chunks
