"""
Phase 3 — response formatting quality tests.

Pure unit tests for the presentation layer (no server / no network / no LLM).
They verify, across every supported response type, that output is patient-
friendly: structured, plain-language, source-attributed, confidence-aware, and
free of raw label section dumps.

Run:
    cd backend
    .venv\\Scripts\\python.exe -m tests.test_response_formatting
"""
from __future__ import annotations

from dataclasses import dataclass

from rag.intent_classifier import Intent
from rag import response_formatter as rf
from rag.symptom_workflow import WORKFLOWS, resolve_workflow


# Lightweight stand-in for RetrievedChunk (only the fields the formatter reads).
@dataclass
class FakeChunk:
    drug_name: str
    section:   str
    source:    str
    score:     float


_failures = []


def check(name: str, cond: bool, detail: str = ""):
    status = "PASS" if cond else "FAIL"
    if not cond:
        _failures.append(f"{name}: {detail}")
    print(f"  [{status}] {name}" + (f" — {detail}" if not cond else ""))


# Raw label section headings that must NEVER appear verbatim in patient output.
_RAW_HEADINGS = [
    "INDICATIONS AND USAGE", "ADVERSE REACTIONS", "DOSAGE AND ADMINISTRATION",
    "CONTRAINDICATIONS", "WARNINGS AND PRECAUTIONS",
]


def no_raw_headings(text: str) -> bool:
    up = text.upper()
    return not any(h in up for h in _RAW_HEADINGS)


def test_confidence():
    print("\n== confidence_from_chunks ==")
    hi, _ = rf.confidence_from_chunks([FakeChunk("ibuprofen", "dosage", "dailymed", 0.81)])
    md, _ = rf.confidence_from_chunks([FakeChunk("ibuprofen", "dosage", "dailymed", 0.66)])
    lo, _ = rf.confidence_from_chunks([FakeChunk("ibuprofen", "dosage", "dailymed", 0.55)])
    em, _ = rf.confidence_from_chunks([])
    check("high score -> high", hi == rf.CONF_HIGH, hi)
    check("medium score -> medium", md == rf.CONF_MEDIUM, md)
    check("low score -> low", lo == rf.CONF_LOW, lo)
    check("empty -> low", em == rf.CONF_LOW, em)


def test_generation_prompts():
    print("\n== generation_system_prompt (per intent) ==")
    llm_intents = [
        Intent.DOSAGE_QUERY, Intent.SIDE_EFFECT_QUERY, Intent.WARNINGS_QUERY,
        Intent.INTERACTION_QUERY, Intent.MEDICINE_TO_DISEASE_QUERY,
        Intent.DRUG_LOOKUP, Intent.FDA_SAFETY_QUERY, Intent.GENERAL_MEDICAL_QUERY,
    ]
    sentinel1 = "I don't have enough information about that in my knowledge base."
    sentinel2 = "I can only assist with pharmaceutical and medicine-related questions."
    for intent in llm_intents:
        p = rf.generation_system_prompt(intent, rf.CONF_HIGH)
        check(f"{intent.value}: keeps no-context sentinel", sentinel1 in p)
        check(f"{intent.value}: keeps off-topic sentinel", sentinel2 in p)
        check(f"{intent.value}: forbids raw label headings", "Do NOT copy label section names" in p)
        check(f"{intent.value}: bans citation tags", "Do NOT add citations" in p)
    # Type-specific structure cues
    check("dosage prompt has dosage structure",
          "General dosage" in rf.generation_system_prompt(Intent.DOSAGE_QUERY))
    check("side-effects prompt splits common/serious",
          "Common side effects" in rf.generation_system_prompt(Intent.SIDE_EFFECT_QUERY)
          and "Serious side effects" in rf.generation_system_prompt(Intent.SIDE_EFFECT_QUERY))
    # Confidence rider only when low
    lowp = rf.generation_system_prompt(Intent.DOSAGE_QUERY, rf.CONF_LOW)
    check("low-confidence rider added", "only loosely match" in lowp)
    check("high-confidence has no rider",
          "only loosely match" not in rf.generation_system_prompt(Intent.DOSAGE_QUERY, rf.CONF_HIGH))


def test_grounded_meta():
    print("\n== append_grounded_meta (source + confidence) ==")
    chunks = [FakeChunk("ibuprofen", "dosage", "dailymed", 0.81)]
    out = rf.append_grounded_meta("**General dosage**\n- 400 mg", chunks,
                                  Intent.DOSAGE_QUERY, rf.CONF_HIGH)
    check("adds DailyMed source note", "DailyMed" in out)
    check("names the drug", "Ibuprofen" in out)
    check("high conf -> no caveat", "loose match" not in out)
    low = rf.append_grounded_meta("x", chunks, Intent.DOSAGE_QUERY, rf.CONF_LOW)
    check("low conf -> caveat added", "loose match" in low)
    of = rf.append_grounded_meta("x", [FakeChunk("ranitidine", "general", "openfda", 0.7)],
                                 Intent.FDA_SAFETY_QUERY, rf.CONF_HIGH)
    check("OpenFDA source named", "OpenFDA" in of)


def test_direct_lookups():
    print("\n== direct-lookup formatters ==")
    bg = rf.format_brand_to_generic("zoloft", "sertraline",
                                    {"drug_class": "antidepressant", "brand_names": ["Zoloft"]})
    check("brand->generic names both", "Zoloft" in bg and "Sertraline" in bg)
    check("brand->generic cites RxNorm", "RxNorm" in bg)
    check("brand->generic no raw headings", no_raw_headings(bg))

    gb = rf.format_generic_to_brands("metformin", ["Glucophage", "Riomet"], {})
    check("generic->brands lists brands", "Glucophage" in gb)
    check("generic->brands cites RxNorm", "RxNorm" in gb)

    ing = rf.format_ingredient("acetaminophen", ["Tylenol", "Acetaminophen"])
    check("ingredient lists meds", "Tylenol" in ing)
    check("ingredient cites RxNorm", "RxNorm" in ing)

    dis = rf.format_disease("hypertension", [("lisinopril", "ACE INHIBITORS"),
                                             ("amlodipine", "")])
    check("disease lists drugs", "Lisinopril" in dis)
    check("disease has safety nudge", "doctor or pharmacist" in dis)
    check("disease cites DailyMed", "DailyMed" in dis)


def test_symptom_formatting():
    print("\n== symptom assessment formatting ==")
    wf = WORKFLOWS["headache"]
    collected = {"duration": "3 days", "severity": "severe",
                 "associated": "nausea", "context": "stress"}
    summary = rf.format_assessment_summary(wf, collected, severity_high=True,
                                           duration_long=False)
    # Required structure: empathy, summary, possible explanations, self-care, when to seek
    check("has empathy", "sounds uncomfortable" in summary.lower())
    check("has assessment summary", "Here's what you told me" in summary)
    check("has possible explanations", "Possible explanations" in summary)
    check("has self-care", "Self-care that may help" in summary)
    check("has when-to-seek", "When to seek medical attention" in summary)
    check("no diagnosis claim", "not a diagnosis" in summary)
    check("severe -> escalation note", "severe or long-lasting" in summary)
    check("asks about OTC info", "yes" in summary.lower() and "no" in summary.lower())

    rec = rf.format_recommendation(wf, grounded=["acetaminophen", "ibuprofen"],
                                   ungrounded=["aspirin"])
    check("recommendation lists candidates", "Acetaminophen" in rec)
    check("recommendation flags grounded", "label info available" in rec)
    check("recommendation pharmacist nudge", "pharmacist" in rec)
    check("recommendation not a prescription", "not a recommendation or prescription" in rec)


def test_all_workflows_have_guidance():
    print("\n== every workflow has self-care + when-to-seek ==")
    for key in ["headache", "fever", "cough", "sore throat", "stomach pain"]:
        wf = WORKFLOWS[key]
        check(f"{key}: has self_care", len(wf.self_care) > 0)
        check(f"{key}: has when_to_seek", len(wf.when_to_seek) > 0)
        check(f"{key}: has otc_candidates", len(wf.otc_candidates) > 0)


def main():
    print("=" * 60)
    print("Phase 3 — Response Formatting Tests")
    print("=" * 60)
    test_confidence()
    test_generation_prompts()
    test_grounded_meta()
    test_direct_lookups()
    test_symptom_formatting()
    test_all_workflows_have_guidance()
    print("\n" + "=" * 60)
    if _failures:
        print(f"RESULT: {len(_failures)} FAILURE(S)")
        for f in _failures:
            print(f"  - {f}")
        raise SystemExit(1)
    print("RESULT: ALL TESTS PASSED ✓")
    print("=" * 60)


if __name__ == "__main__":
    main()
