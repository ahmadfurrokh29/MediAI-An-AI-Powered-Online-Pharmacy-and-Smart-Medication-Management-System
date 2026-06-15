# MediAI RAG Pipeline — Setup Guide

## What was built

A complete RAG (Retrieval-Augmented Generation) pipeline wired into the existing
FastAPI backend. The original `/chat` endpoint is **untouched**. A new `/chat/rag`
endpoint handles grounded pharmaceutical Q&A.

```
backend/
├── main.py                  ← Updated: /chat/rag + /rag/status endpoints added
├── requirements.txt         ← Updated: httpx, sentence-transformers, chromadb
├── .env.example             ← Template for environment variables
├── coupon/                  ← Unchanged
└── rag/                     ← NEW — entire RAG package
    ├── __init__.py
    ├── config.py            ← All tunable settings in one place
    ├── schema.py            ← PharmChunk dataclass (shared data contract)
    ├── chunker.py           ← Text → overlapping chunks
    ├── embedder.py          ← BAAI/bge-small-en-v1.5 singleton
    ├── vector_store.py      ← ChromaDB persistent client wrapper
    ├── retrieval.py         ← Query → top-K chunks (with score filtering)
    ├── chat_service.py      ← Full RAG chat pipeline
    ├── ingest.py            ← CLI ingestion script
    ├── data/
    │   └── chroma_db/       ← Created automatically on first run (gitignore this)
    └── ingestion/
        ├── __init__.py
        ├── dailymed.py      ← DailyMed SPL label ingestion
        └── openfda.py       ← OpenFDA drug label ingestion
```

---

## Step 1 — Install dependencies

```powershell
cd "C:\Users\HP\MediAI - Final\MediAI\backend"

# Create / activate your virtual environment (if not already done)
python -m venv venv
.\venv\Scripts\Activate.ps1

# Install all dependencies (this will download PyTorch CPU + model ~1 GB total)
pip install -r requirements.txt
```

> **Note:** `sentence-transformers` pulls in PyTorch. On a CPU-only machine the
> install is ~700 MB. This is a one-time download.

---

## Step 2 — Configure environment variables

```powershell
copy .env.example .env
# Then edit .env and fill in your actual API keys
```

---

## Step 3 — Run the ingestion pipeline

This fetches data for all 7 target drugs from DailyMed and OpenFDA,
generates embeddings, and stores everything in ChromaDB.

```powershell
# From the backend/ directory with venv active:
python -m rag.ingest

# Options:
python -m rag.ingest --force            # Re-ingest even if data exists
python -m rag.ingest --drug ibuprofen   # Ingest a single drug
```

Expected output:
```
08:12:01 [INFO] MediAI RAG Ingestion Pipeline
08:12:01 [INFO] Target drugs: ibuprofen, acetaminophen, ...
08:12:02 [INFO] [Embedder] Loading model 'BAAI/bge-small-en-v1.5' ...
08:12:08 [INFO] [DailyMed] 'ibuprofen' → set_id=abc123, 18 sections
08:12:08 [INFO]   ✓ DailyMed → 42 chunks
08:12:09 [INFO]   ✓ OpenFDA  → 31 chunks
08:12:09 [INFO]   💾 Stored 73 chunks for 'ibuprofen'
...
08:15:30 [INFO] Total chunks stored: 487
08:15:30 [INFO] Total chunks in DB:  487
```

---

## Step 4 — Start the server

```powershell
# Use `python -m uvicorn` (the bare `uvicorn` command may not be on PATH)
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

> **LLM note:** the chat endpoints try OpenAI (`gpt-4o-mini`) first and fall
> back to Gemini (`gemini-2.5-flash-lite`). If your OpenAI key has no quota
> (HTTP 429), everything still works automatically on Gemini.

---

## Step 5 — Test the RAG endpoint

### Via Swagger UI
Open http://localhost:8000/docs → `POST /chat/rag`

### Via curl
```powershell
curl -X POST http://localhost:8000/chat/rag `
  -H "Content-Type: application/json" `
  -d '{"message": "What are the side effects of ibuprofen?"}'
```

### Example response
```json
{
  "reply": "Common side effects of ibuprofen include:\n- Stomach upset, nausea, or heartburn\n- Dizziness or headache\n- ...\n\nConsult a healthcare professional for serious conditions.",
  "sources": [
    {"drug_name": "ibuprofen", "section": "side_effects", "source": "dailymed", "score": 0.872},
    {"drug_name": "ibuprofen", "section": "warnings",     "source": "openfda",  "score": 0.741}
  ],
  "rag_used": true
}
```

### Check vector store status
```powershell
curl http://localhost:8000/rag/status
```

---

## Flutter integration  ✅ already wired

`lib/features/chatbot/services/chat_service.dart` already implements a **hybrid**
strategy:

1. Sends the question to `/chat/rag` (grounded answer + embedded citations).
2. If the question is outside the ingested 7-drug knowledge base
   (`rag_used == false`), it automatically falls back to the general `/chat`
   endpoint so the user still gets a useful pharmaceutical answer.

```dart
// chat_service.dart (already implemented):
final ragResponse = await http.post(
  Uri.parse('$_baseUrl/chat/rag'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'message': message}),   // optional: 'drug_filter', 'top_k'
);
// → if rag_used == true  → return grounded reply (citations embedded)
// → if rag_used == false → fall back to POST /chat
```

> **Important — set the right base URL** in `chat_service.dart`:
> - Physical phone on Wi-Fi: your PC's LAN IP, e.g. `http://192.168.18.109:8000`
>   (the backend must run on that PC, phone on the same network).
> - Android emulator: `http://10.0.2.2:8000`
> - iOS simulator / desktop: `http://localhost:8000`

---

## How the RAG pipeline works

```
User: "What are the side effects of ibuprofen?"
         │
         ▼
  ┌─────────────────┐
  │  embed_query()  │  BAAI/bge-small-en-v1.5 → 384-dim query vector
  └────────┬────────┘
           │
           ▼
  ┌─────────────────────────┐
  │  ChromaDB cosine search │  Top-5 nearest chunks from 500+ stored passages
  └────────┬────────────────┘
           │
           ▼  (filter chunks below 0.30 similarity)
  ┌──────────────────────────┐
  │  build_context_block()   │  Format citations + text ≤ 3000 chars
  └────────┬─────────────────┘
           │
           ▼
  ┌────────────────────────────────────────────────────────┐
  │  RAG System Prompt + [PHARMACEUTICAL CONTEXT] + Query  │
  └────────┬───────────────────────────────────────────────┘
           │
           ▼
  OpenAI gpt-4o-mini  (fallback → Gemini 2.5-flash-lite)
           │
           ▼
  Grounded response + source citations
```

---

## Adding more drugs later

1. Add the drug name to `TARGET_DRUGS` in `rag/config.py`
2. Run `python -m rag.ingest --drug <name>`

No server restart needed — ChromaDB is persistent.

---

## Data storage

ChromaDB data is stored locally at:
```
backend/rag/data/chroma_db/
```

Add this to `.gitignore` to avoid committing embeddings to git:
```
backend/rag/data/
```
