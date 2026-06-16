# -*- coding: utf-8 -*-
def build(R):
    R.chapter("Abbreviations, Glossary, and References")
    R.p("This final chapter provides quick-reference material: a table of abbreviations used "
        "throughout the report, a glossary of key terms, and the list of references.")

    R.section("Abbreviations")
    R.table("List of Abbreviations", ["Abbreviation", "Full Form", "Explanation"], [
        ["FYP", "Final Year Project", "The academic capstone project, namely MediAI."],
        ["AI", "Artificial Intelligence", "Computer systems performing tasks that normally require human intelligence."],
        ["LLM", "Large Language Model", "A neural network trained to understand and generate natural language."],
        ["RAG", "Retrieval-Augmented Generation", "Grounding an LLM's answers in retrieved source documents."],
        ["OCR", "Optical Character Recognition", "Converting images of text into machine-readable text."],
        ["API", "Application Programming Interface", "A defined interface through which software components communicate."],
        ["UI", "User Interface", "The part of the application the user interacts with."],
        ["UX", "User Experience", "The overall experience of using the product."],
        ["CRUD", "Create, Read, Update, Delete", "The four basic persistent-storage operations."],
        ["RBAC", "Role-Based Access Control", "Access control based on the user's assigned role."],
        ["COD", "Cash on Delivery", "Payment collected when the order is delivered."],
        ["FCM", "Firebase Cloud Messaging", "Google's service for delivering push notifications."],
        ["SQL", "Structured Query Language", "The language used to query relational databases."],
        ["JSON", "JavaScript Object Notation", "A lightweight data-interchange format."],
        ["HTTP", "Hypertext Transfer Protocol", "The protocol used for client-server web communication."],
        ["NoSQL", "Not Only SQL", "Non-relational databases such as Firestore."],
        ["mHealth", "Mobile Health", "Healthcare supported by mobile devices and apps."],
        ["FR", "Functional Requirement", "A required behaviour of the system."],
        ["NFR", "Non-Functional Requirement", "A required quality attribute of the system."],
        ["UC", "Use Case", "A described interaction between an actor and the system."],
        ["TC", "Test Case", "A documented test scenario with expected and actual outcomes."],
        ["RxCUI", "RxNorm Concept Unique Identifier", "A standard identifier for a clinical drug concept in RxNorm."],
    ], col_widths=[1.0, 2.0, 3.27], font_size=9)

    R.section("Glossary")
    R.table("Glossary of Key Terms", ["Term", "Definition"], [
        ["Offline-First", "A design approach in which the local device is the primary source of truth and the cloud is synchronized opportunistically, so the app works without connectivity."],
        ["Embedding", "A numerical vector representation of text that captures its semantic meaning, used for similarity search."],
        ["Vector Database", "A database optimized for storing embeddings and retrieving them by similarity; MediAI uses ChromaDB."],
        ["Cosine Similarity", "A measure of similarity between two vectors based on the angle between them, used to rank retrieved chunks."],
        ["Chunking", "Splitting a document into smaller passages so that relevant portions can be retrieved precisely."],
        ["Grounding", "Constraining an LLM to answer only from supplied source context to prevent hallucination."],
        ["Hallucination", "The generation of plausible but incorrect or fabricated information by a language model."],
        ["On-Demand Ingestion", "Fetching, chunking, embedding, and storing a drug's data the first time a user asks about it."],
        ["Symptom Triage", "A structured, multi-turn assessment of a user's symptoms that provides safe guidance without diagnosing."],
        ["Conflict Resolution", "Deciding which version of a record wins when local and cloud copies diverge; MediAI uses latest-timestamp wins."],
        ["Denormalization", "Storing copies of frequently displayed fields on a record to avoid expensive lookups, trading storage for speed."],
        ["Idempotent Operation", "An operation that produces the same result no matter how many times it is applied, used for exactly-once stock refill."],
        ["Repository Pattern", "A design pattern that abstracts data access behind a uniform interface, decoupling logic from storage."],
        ["Full-Screen Alarm", "A prominent alarm that takes over the screen even when the app is closed, used for dose reminders."],
        ["Server-Authoritative", "A design in which the server is the single source of truth for sensitive computations such as discounts."],
        ["Subcollection", "In Firestore, a collection nested beneath a document, used here for per-user private data."],
        ["RxNorm Approximate Matching", "A lookup that returns the closest valid drug for a misspelled or informal name, enabling spell correction."],
    ], col_widths=[1.6, 4.67], font_size=9)

    R.section("References")
    refs = [
        "S. El Kafhali and K. Salah, “Blockchain-based and AI-assisted healthcare systems: a review,” Journal of Healthcare Informatics, 2024.",
        "World Health Organization, “Adherence to Long-Term Therapies: Evidence for Action,” WHO, Geneva, 2003.",
        "P. Lewis et al., “Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks,” Advances in Neural Information Processing Systems, 2020.",
        "U.S. National Library of Medicine, “DailyMed — Structured Product Labels,” National Institutes of Health. [Online]. Available: https://dailymed.nlm.nih.gov",
        "U.S. Food and Drug Administration, “openFDA Drug Label API.” [Online]. Available: https://open.fda.gov",
        "U.S. National Library of Medicine, “RxNorm.” [Online]. Available: https://www.nlm.nih.gov/research/umls/rxnorm",
        "Google LLC, “Flutter — Build apps for any screen.” [Online]. Available: https://flutter.dev",
        "Google LLC, “Firebase Documentation.” [Online]. Available: https://firebase.google.com/docs",
        "Chroma, “ChromaDB — the open-source embedding database.” [Online]. Available: https://www.trychroma.com",
        "BAAI, “BGE: BAAI General Embedding models,” Hugging Face. [Online]. Available: https://huggingface.co/BAAI",
        "Groq Inc., “Groq — Fast AI Inference.” [Online]. Available: https://groq.com",
        "Google LLC, “Gemini API Documentation.” [Online]. Available: https://ai.google.dev",
        "S. Ramirez, “FastAPI — modern, fast web framework for building APIs with Python.” [Online]. Available: https://fastapi.tiangolo.com",
        "SQLite Consortium, “SQLite — self-contained, serverless SQL database engine.” [Online]. Available: https://www.sqlite.org",
        "J. Nielsen, “10 Usability Heuristics for User Interface Design,” Nielsen Norman Group, 1994 (rev. 2020).",
        "A. Vaswani et al., “Attention Is All You Need,” Advances in Neural Information Processing Systems, 2017.",
        "M. Kleppmann et al., “Local-First Software: You Own Your Data, in Spite of the Cloud,” Onward!, 2019.",
        "T. Brown et al., “Language Models are Few-Shot Learners,” Advances in Neural Information Processing Systems, 2020.",
    ]
    for i, r in enumerate(refs, 1):
        R.rich([(f"[{i}]  ", {}), (r, {})], justify=True, space_after=6)
