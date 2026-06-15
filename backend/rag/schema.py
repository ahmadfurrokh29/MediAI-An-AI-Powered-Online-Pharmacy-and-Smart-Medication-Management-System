"""
Shared data schema for pharmaceutical chunks.

Every ingestion source (DailyMed, OpenFDA, future sources) normalises its
output into a list of PharmChunk objects before they are embedded and stored.
This keeps the rest of the pipeline source-agnostic.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Optional


# Canonical section names — kept consistent across ingestion sources
SECTION_INDICATIONS    = "indications"
SECTION_DOSAGE         = "dosage"
SECTION_WARNINGS       = "warnings"
SECTION_SIDE_EFFECTS   = "side_effects"
SECTION_INTERACTIONS   = "interactions"
SECTION_CONTRAINDICATIONS = "contraindications"
SECTION_DESCRIPTION    = "description"
SECTION_PHARMACOLOGY   = "pharmacology"
SECTION_OVERDOSE       = "overdose"
SECTION_STORAGE        = "storage"
SECTION_GENERAL        = "general"


@dataclass
class PharmChunk:
    """
    A single piece of pharmaceutical information ready for embedding.

    Attributes:
        drug_name   : Normalised lowercase drug name (e.g. "ibuprofen")
        section     : One of the SECTION_* constants above
        source      : "dailymed" | "openfda"
        content     : The text that will be embedded and retrieved
        chunk_index : 0-based position within the parent section (for multi-chunk sections)
        doc_id      : Upstream document identifier (DailyMed SPL set-id, etc.)
    """
    drug_name:   str
    section:     str
    source:      str
    content:     str
    chunk_index: int = 0
    doc_id:      str = ""

    # ── Derived helpers ───────────────────────────────────────────────────────

    @property
    def chroma_id(self) -> str:
        """Deterministic, collision-resistant ChromaDB document ID."""
        safe_drug = self.drug_name.replace(" ", "_")
        return f"{self.source}::{safe_drug}::{self.section}::{self.chunk_index}"

    @property
    def metadata(self) -> dict:
        """Flat dict stored alongside the embedding in ChromaDB."""
        return {
            "drug_name":   self.drug_name,
            "section":     self.section,
            "source":      self.source,
            "doc_id":      self.doc_id,
            "chunk_index": self.chunk_index,
        }
