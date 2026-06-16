"""
Persistent pharmaceutical lookup index.

Stores RxNorm-enriched metadata for all ingested medicines and exposes
fast lookups for:
  - brand name  → generic name
  - generic name → list of brand names
  - ingredient  → list of medicines containing it
  - synonym     → canonical generic name
  - drug class  → descriptive string

Data persists to rag/data/pharma_index.json between restarts.
Thread-safe: a reentrant lock guards all reads and writes; saves are
atomic (write to .tmp then rename).
"""
from __future__ import annotations

import json
import logging
import threading
from pathlib import Path
from typing import Dict, List, Optional

logger = logging.getLogger(__name__)

_INDEX_PATH = Path(__file__).resolve().parent / "data" / "pharma_index.json"

_EMPTY: Dict = {
    "version": 1,
    "drugs": {},
    "brand_to_generic": {},
    "generic_to_brands": {},
    "ingredient_to_medicines": {},
    "synonym_to_medicine": {},
}


class PharmaIndex:
    """
    Thread-safe singleton wrapper around pharma_index.json.

    Obtain via PharmaIndex.instance() — never construct directly.
    """

    _inst: Optional["PharmaIndex"] = None
    _cls_lock = threading.Lock()

    def __init__(self) -> None:
        self._lock = threading.RLock()
        self._data: Dict = self._load()

    # ── Singleton ──────────────────────────────────────────────────────────────

    @classmethod
    def instance(cls) -> "PharmaIndex":
        if cls._inst is None:
            with cls._cls_lock:
                if cls._inst is None:
                    cls._inst = cls()
        return cls._inst

    # ── Persistence ───────────────────────────────────────────────────────────

    def _load(self) -> Dict:
        _INDEX_PATH.parent.mkdir(parents=True, exist_ok=True)
        if _INDEX_PATH.exists():
            try:
                with open(_INDEX_PATH, "r", encoding="utf-8") as fh:
                    data = json.load(fh)
                logger.info(
                    "[PharmaIndex] Loaded %d drugs from disk", len(data.get("drugs", {}))
                )
                return data
            except Exception as exc:
                logger.warning("[PharmaIndex] Load failed (%s) — starting fresh", exc)
        return json.loads(json.dumps(_EMPTY))  # deep copy

    def _save(self) -> None:
        """Write index atomically. Must be called with self._lock held."""
        try:
            tmp = _INDEX_PATH.with_suffix(".json.tmp")
            with open(tmp, "w", encoding="utf-8") as fh:
                json.dump(self._data, fh, indent=2, ensure_ascii=False)
            tmp.replace(_INDEX_PATH)
        except Exception as exc:
            logger.error("[PharmaIndex] Save failed: %s", exc)

    # ── Write ──────────────────────────────────────────────────────────────────

    def update_drug(self, drug_name: str, rxnorm_data: dict) -> None:
        """
        Upsert a drug's RxNorm data and rebuild all derived lookup tables.

        rxnorm_data must have the shape returned by rag.rxnorm.fetch_rxnorm_data:
            {rxcui, generic_name, brand_names, ingredients, synonyms, drug_class}
        """
        key = drug_name.lower().strip()
        with self._lock:
            self._data["drugs"][key] = {
                "rxcui":        rxnorm_data.get("rxcui"),
                "generic_name": rxnorm_data.get("generic_name", key),
                "brand_names":  rxnorm_data.get("brand_names", []),
                "ingredients":  rxnorm_data.get("ingredients", []),
                "synonyms":     rxnorm_data.get("synonyms", []),
                "drug_class":   rxnorm_data.get("drug_class", ""),
            }
            self._rebuild_lookups_for(key, rxnorm_data)
            self._save()

    def _rebuild_lookups_for(self, drug_key: str, rxnorm_data: dict) -> None:
        """Rebuild derived lookups for one drug. Lock must already be held."""
        generic = rxnorm_data.get("generic_name", drug_key).lower()

        for brand in rxnorm_data.get("brand_names", []):
            self._data["brand_to_generic"][brand.lower()] = generic

        brands = rxnorm_data.get("brand_names", [])
        if brands:
            existing = self._data["generic_to_brands"].get(generic, [])
            self._data["generic_to_brands"][generic] = list(
                dict.fromkeys(existing + brands)
            )

        for ing in rxnorm_data.get("ingredients", []):
            ing_key = ing.lower()
            meds = self._data["ingredient_to_medicines"].get(ing_key, [])
            if drug_key not in meds:
                meds.append(drug_key)
            self._data["ingredient_to_medicines"][ing_key] = meds

        for syn in rxnorm_data.get("synonyms", []):
            self._data["synonym_to_medicine"][syn.lower()] = generic

    # ── Read ──────────────────────────────────────────────────────────────────

    def get_drug(self, name: str) -> Optional[dict]:
        """Return the full drug record, or None if not indexed."""
        with self._lock:
            return self._data["drugs"].get(name.lower().strip())

    def get_generic(self, name: str) -> Optional[str]:
        """
        Resolve a brand name, synonym, or generic name to the canonical generic.
        Returns None if not found in the index.
        """
        key = name.lower().strip()
        with self._lock:
            # Direct drug record (already a generic key)
            drug = self._data["drugs"].get(key)
            if drug:
                return drug.get("generic_name", key)
            # Brand → generic table
            generic = self._data["brand_to_generic"].get(key)
            if generic:
                return generic
            # Synonym → medicine table
            return self._data["synonym_to_medicine"].get(key)

    def get_brands(self, generic_name: str) -> List[str]:
        """Return brand names for a generic drug (empty list if none known)."""
        key = generic_name.lower().strip()
        with self._lock:
            drug = self._data["drugs"].get(key)
            if drug and drug.get("brand_names"):
                return drug["brand_names"]
            return self._data["generic_to_brands"].get(key, [])

    def get_medicines_for_ingredient(self, ingredient: str) -> List[str]:
        """Return all medicines that contain this ingredient."""
        key = ingredient.lower().strip()
        with self._lock:
            return self._data["ingredient_to_medicines"].get(key, [])

    def get_drug_class(self, name: str) -> str:
        """Return the drug class string for a generic or brand name."""
        key = name.lower().strip()
        with self._lock:
            drug = self._data["drugs"].get(key)
            if drug:
                return drug.get("drug_class", "")
            # Try resolving via brand lookup
            generic = self._data["brand_to_generic"].get(key)
            if generic:
                drug = self._data["drugs"].get(generic)
                if drug:
                    return drug.get("drug_class", "")
        return ""

    def all_brands(self) -> Dict[str, str]:
        """Return a copy of the full brand→generic mapping."""
        with self._lock:
            return dict(self._data["brand_to_generic"])

    def indexed_drugs(self) -> List[str]:
        """Return list of all drug keys in the index."""
        with self._lock:
            return list(self._data["drugs"].keys())

    def stats(self) -> dict:
        with self._lock:
            return {
                "drugs_indexed":   len(self._data["drugs"]),
                "brand_entries":   len(self._data["brand_to_generic"]),
                "ingredient_keys": len(self._data["ingredient_to_medicines"]),
                "synonym_entries": len(self._data["synonym_to_medicine"]),
            }
