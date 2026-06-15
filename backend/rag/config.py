"""
RAG pipeline configuration.
All tuneable values in one place — no magic numbers scattered across files.
"""
from __future__ import annotations

import os
from pathlib import Path

# ── Paths ─────────────────────────────────────────────────────────────────────

# Root of the backend/ directory, regardless of CWD
_BACKEND_ROOT = Path(__file__).resolve().parent.parent

# ChromaDB stores its SQLite + binary files here (persisted across restarts)
CHROMA_PERSIST_DIR: str = str(_BACKEND_ROOT / "rag" / "data" / "chroma_db")

# ── Embedding model ───────────────────────────────────────────────────────────
# BAAI/bge-small-en-v1.5 — 33 MB, 384-dim, fast, good semantic quality
EMBEDDING_MODEL_NAME: str = os.getenv(
    "RAG_EMBEDDING_MODEL", "BAAI/bge-small-en-v1.5"
)

# ── ChromaDB collection ────────────────────────────────────────────────────────
CHROMA_COLLECTION_NAME: str = "pharma_knowledge"

# ── Retrieval ─────────────────────────────────────────────────────────────────
# Number of chunks returned per query
TOP_K: int = int(os.getenv("RAG_TOP_K", "5"))

# Minimum cosine similarity score (0–1). Chunks below this are discarded.
# Empirically with BAAI/bge-small-en-v1.5 + query prefix: genuinely relevant
# pharma chunks score ~0.75-0.87, while off-topic queries bottom out around
# ~0.47. A 0.50 floor cleanly separates the two, so unsupported questions fall
# through to the "not in my knowledge base" grounding fallback instead of
# injecting irrelevant context.
MIN_SCORE: float = float(os.getenv("RAG_MIN_SCORE", "0.50"))

# Maximum characters per injected context block (keeps prompts under token limit)
MAX_CONTEXT_CHARS: int = int(os.getenv("RAG_MAX_CONTEXT_CHARS", "3000"))

# ── Chunking ──────────────────────────────────────────────────────────────────
# Approximate characters per chunk (split at sentence boundaries when possible)
CHUNK_SIZE: int = int(os.getenv("RAG_CHUNK_SIZE", "600"))
CHUNK_OVERLAP: int = int(os.getenv("RAG_CHUNK_OVERLAP", "80"))

# ── Drugs to ingest ───────────────────────────────────────────────────────────
# Curated baseline of the ~200 most commonly prescribed / OTC medicines, by
# generic name (the form both DailyMed `drug_name` and OpenFDA `generic_name`
# search recognise). These are pre-ingested by `python -m rag.ingest`.
#
# This is only the *baseline*. Any drug NOT in this list is fetched, chunked and
# embedded automatically the first time a user asks about it (on-demand
# ingestion — see rag/chat_service.py), so coverage is effectively unbounded.
TARGET_DRUGS: list[str] = [
    # ── Analgesics / NSAIDs / pain ──────────────────────────────────────────
    "ibuprofen", "acetaminophen", "aspirin", "naproxen", "diclofenac",
    "celecoxib", "ketorolac", "indomethacin", "meloxicam", "tramadol",
    "codeine", "morphine", "oxycodone", "hydrocodone", "fentanyl",
    "gabapentin", "pregabalin",
    # ── Antibiotics ─────────────────────────────────────────────────────────
    "amoxicillin", "azithromycin", "ciprofloxacin", "doxycycline", "cephalexin",
    "clindamycin", "metronidazole", "levofloxacin", "penicillin", "ampicillin",
    "clarithromycin", "erythromycin", "trimethoprim", "sulfamethoxazole",
    "nitrofurantoin", "vancomycin", "gentamicin", "ceftriaxone", "cefuroxime",
    "minocycline", "tetracycline", "linezolid",
    # ── Antifungals / antivirals ────────────────────────────────────────────
    "fluconazole", "ketoconazole", "terbinafine", "nystatin", "itraconazole",
    "acyclovir", "valacyclovir", "oseltamivir", "clotrimazole",
    # ── Antidiabetics ───────────────────────────────────────────────────────
    "metformin", "glipizide", "glimepiride", "glyburide", "sitagliptin",
    "insulin", "pioglitazone", "empagliflozin", "dapagliflozin", "liraglutide",
    "canagliflozin",
    # ── Cardiac / antihypertensive ──────────────────────────────────────────
    "lisinopril", "amlodipine", "losartan", "metoprolol", "atenolol",
    "carvedilol", "hydrochlorothiazide", "furosemide", "spironolactone",
    "valsartan", "enalapril", "ramipril", "diltiazem", "verapamil",
    "propranolol", "clonidine", "hydralazine", "nifedipine", "irbesartan",
    "candesartan", "bisoprolol", "labetalol", "digoxin",
    "isosorbide mononitrate",
    # ── Anticoagulants / antiplatelets ──────────────────────────────────────
    "warfarin", "clopidogrel", "apixaban", "rivaroxaban", "enoxaparin",
    "dabigatran", "ticagrelor", "heparin",
    # ── Lipid-lowering / statins ────────────────────────────────────────────
    "atorvastatin", "simvastatin", "rosuvastatin", "pravastatin", "lovastatin",
    "ezetimibe", "fenofibrate", "gemfibrozil",
    # ── GI / acid / antiemetic ──────────────────────────────────────────────
    "omeprazole", "pantoprazole", "esomeprazole", "lansoprazole", "famotidine",
    "ranitidine", "ondansetron", "metoclopramide", "loperamide", "sucralfate",
    "dicyclomine", "bisacodyl", "docusate", "promethazine",
    # ── Antihistamines / allergy ────────────────────────────────────────────
    "cetirizine", "loratadine", "fexofenadine", "diphenhydramine", "hydroxyzine",
    "levocetirizine", "desloratadine", "chlorpheniramine",
    # ── Respiratory / corticosteroids ───────────────────────────────────────
    "albuterol", "montelukast", "fluticasone", "budesonide", "ipratropium",
    "tiotropium", "salmeterol", "theophylline", "prednisone", "prednisolone",
    "methylprednisolone", "dexamethasone",
    # ── Psychiatric / CNS / neurology ───────────────────────────────────────
    "sertraline", "fluoxetine", "escitalopram", "citalopram", "paroxetine",
    "venlafaxine", "duloxetine", "bupropion", "mirtazapine", "trazodone",
    "amitriptyline", "nortriptyline", "alprazolam", "lorazepam", "diazepam",
    "clonazepam", "buspirone", "quetiapine", "risperidone", "olanzapine",
    "aripiprazole", "haloperidol", "lithium", "lamotrigine", "levetiracetam",
    "phenytoin", "carbamazepine", "topiramate", "zolpidem", "valproic acid",
    # ── Thyroid / hormones ──────────────────────────────────────────────────
    "levothyroxine", "methimazole", "estradiol", "progesterone", "testosterone",
    "hydrocortisone", "medroxyprogesterone", "norethindrone",
    # ── Bone / rheumatology / gout ──────────────────────────────────────────
    "alendronate", "raloxifene", "allopurinol", "colchicine", "febuxostat",
    "hydroxychloroquine", "methotrexate", "sulfasalazine", "azathioprine",
    "leflunomide",
    # ── Urology / men's health ──────────────────────────────────────────────
    "tamsulosin", "finasteride", "oxybutynin", "sildenafil", "tadalafil",
    "dutasteride",
    # ── Muscle relaxants ────────────────────────────────────────────────────
    "cyclobenzaprine", "baclofen", "tizanidine", "methocarbamol",
    # ── Ophthalmic ──────────────────────────────────────────────────────────
    "latanoprost", "timolol", "brimonidine",
    # ── Migraine / misc neuro ───────────────────────────────────────────────
    "sumatriptan", "rizatriptan", "amantadine",
    # ── Vitamins / electrolytes / supplements ───────────────────────────────
    "folic acid", "cyanocobalamin", "ferrous sulfate", "potassium chloride",
    "calcium carbonate", "ergocalciferol", "thiamine", "pyridoxine",
    # ── Miscellaneous ───────────────────────────────────────────────────────
    "varenicline", "naltrexone", "lidocaine", "epinephrine",
]

# ── External APIs ─────────────────────────────────────────────────────────────
DAILYMED_BASE_URL: str = "https://dailymed.nlm.nih.gov/dailymed/services/v2"
OPENFDA_BASE_URL: str = "https://api.fda.gov/drug"

# Per-request timeout (seconds) for DailyMed / OpenFDA calls
API_TIMEOUT: int = int(os.getenv("API_TIMEOUT", "20"))
