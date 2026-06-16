"""
RxNorm REST API client (free, no auth required).

Fetches structured drug metadata for enrichment of the pharma index:
  - RxCUI (canonical identifier)
  - Generic name (IN term)
  - Brand names (BN terms)
  - Ingredients (IN + PIN terms)
  - Synonyms (SY terms)
  - Drug class (RxClass / MESH, EPC, or VA source)
"""
from __future__ import annotations

import logging
import re
from typing import Optional

import httpx

logger = logging.getLogger(__name__)

_RXNORM_BASE = "https://rxnav.nlm.nih.gov/REST"
_RXCLASS_BASE = "https://rxnav.nlm.nih.gov/REST/rxclass"
_TIMEOUT = 15.0


def _get(url: str, params: dict | None = None) -> dict | None:
    """Synchronous GET with timeout; returns parsed JSON or None on any error."""
    try:
        with httpx.Client(timeout=_TIMEOUT, follow_redirects=True) as client:
            r = client.get(url, params=params)
            r.raise_for_status()
            return r.json()
    except Exception as exc:
        logger.debug("[RxNorm] GET %s failed: %s", url, exc)
        return None


def fetch_rxcui(drug_name: str) -> Optional[str]:
    """Return the best-matching RxCUI for a drug name, or None."""
    # Try normalised match first (handles plurals, case, minor spelling)
    data = _get(f"{_RXNORM_BASE}/rxcui.json", params={"name": drug_name, "search": 1})
    if data:
        rxcui_list = data.get("idGroup", {}).get("rxnormId", [])
        if rxcui_list:
            return rxcui_list[0]

    # Fall back to approximate match
    data = _get(
        f"{_RXNORM_BASE}/approximateTerm.json",
        params={"term": drug_name, "maxEntries": 1},
    )
    if data:
        candidates = data.get("approximateGroup", {}).get("candidate", [])
        if candidates:
            return candidates[0].get("rxcui") or None

    return None


def fetch_rxnorm_data(drug_name: str) -> dict:
    """
    Fetch full RxNorm metadata for one drug.

    Returns:
        {
            "rxcui":        str | None,
            "generic_name": str,
            "brand_names":  list[str],
            "ingredients":  list[str],
            "synonyms":     list[str],
            "drug_class":   str,
        }
    """
    result: dict = {
        "rxcui":        None,
        "generic_name": drug_name.lower(),
        "brand_names":  [],
        "ingredients":  [],
        "synonyms":     [],
        "drug_class":   "",
    }

    rxcui = fetch_rxcui(drug_name)
    if not rxcui:
        logger.info("[RxNorm] No RxCUI found for '%s'", drug_name)
        return result

    result["rxcui"] = rxcui

    # allrelated.json returns every related concept for any RxCUI level (ingredient,
    # clinical drug, brand drug, etc.) without requiring a tty filter — safe for
    # ingredient-level RxCUIs where the tty-filtered /related.json returns 400.
    data = _get(f"{_RXNORM_BASE}/rxcui/{rxcui}/allrelated.json")
    # Track the IN-level RxCUI separately — brands are indexed under the base
    # ingredient concept, not under salt/ester forms (PIN).  allrelated.json for
    # a PIN like "sertraline hydrochloride" (155137) includes the parent IN
    # "sertraline" (36437), so we capture it here for the brand lookup below.
    in_rxcui: Optional[str] = None

    if data:
        groups = data.get("allRelatedGroup", {}).get("conceptGroup", [])
        for group in groups:
            tty = group.get("tty", "")
            props = group.get("conceptProperties") or []
            names = [p["name"] for p in props if "name" in p]
            if tty == "BN":
                # Direct brand-name concepts (rare for ingredient-level RxCUIs)
                result["brand_names"] = list(dict.fromkeys(
                    result["brand_names"] + names
                ))
            elif tty == "SBD":
                # Semantic Brand Drug: "Zoloft 25 MG Oral Capsule" → "Zoloft"
                for sbd_name in names:
                    brand = re.split(
                        r"\s+\d+[\d.]*\s+(?:MG|MCG|ML|%|IU|MG/ML|UNIT)",
                        sbd_name,
                        maxsplit=1,
                        flags=re.IGNORECASE,
                    )[0].strip()
                    if brand and brand not in result["brand_names"]:
                        result["brand_names"].append(brand)
            elif tty == "IN":
                # Capture the parent ingredient RxCUI for brand fallback
                if props and not in_rxcui:
                    in_rxcui = props[0].get("rxcui")
                result["ingredients"].extend(names)
            elif tty == "PIN":
                result["ingredients"].extend(names)
            elif tty == "SY":
                result["synonyms"] = names

    # Deduplicate while preserving order
    result["ingredients"] = list(dict.fromkeys(result["ingredients"]))

    # Use first IN term as canonical generic name if available
    if result["ingredients"]:
        result["generic_name"] = result["ingredients"][0].lower()

    # Fallback brand lookup via /drugs.json — works for all RxCUI levels.
    # Returns SBD (Semantic Brand Drug) entries like "Zoloft 25 MG Oral Tablet"
    # from which we extract the base brand name using the same regex as above.
    # Skip any extracted name that equals the generic/drug name itself — this
    # happens when drugs.json returns generic SCD products tagged as SBD.
    if not result["brand_names"]:
        drugs_data = _get(
            f"{_RXNORM_BASE}/drugs.json", params={"name": drug_name}
        )
        if drugs_data:
            generic_lower = result["generic_name"].lower()
            drug_lower = drug_name.lower()
            for group in drugs_data.get("drugGroup", {}).get("conceptGroup", []):
                if group.get("tty") != "SBD":
                    continue
                for prop in group.get("conceptProperties") or []:
                    sbd_name = prop.get("name", "")
                    brand = re.split(
                        r"\s+\d+[\d.]*\s+(?:MG|MCG|ML|%|IU|MG/ML|UNIT)",
                        sbd_name,
                        maxsplit=1,
                        flags=re.IGNORECASE,
                    )[0].strip()
                    if (brand
                            and brand.lower() not in (generic_lower, drug_lower)
                            and brand not in result["brand_names"]):
                        result["brand_names"].append(brand)

    # Fetch drug class — try MESH first (most human-readable), then EPC, then VA
    for rela_source in ("MESH", "EPC", "VA"):
        cls_data = _get(
            f"{_RXCLASS_BASE}/class/byRxcui.json",
            params={"rxcui": rxcui, "relaSource": rela_source},
        )
        if cls_data:
            infos = (
                cls_data.get("rxclassDrugInfoList", {}).get("rxclassDrugInfo", [])
            )
            if infos:
                class_name = (
                    infos[0].get("rxclassMinConceptItem", {}).get("className", "")
                )
                if class_name:
                    result["drug_class"] = class_name
                    break

    logger.info(
        "[RxNorm] '%s' → rxcui=%s  brands=%d  ingredients=%d  class=%s",
        drug_name,
        rxcui,
        len(result["brand_names"]),
        len(result["ingredients"]),
        result["drug_class"] or "unknown",
    )
    return result
