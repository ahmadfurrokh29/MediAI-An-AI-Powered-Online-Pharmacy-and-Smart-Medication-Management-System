# -*- coding: utf-8 -*-
def build(R):
    R.chapter("Literature Review")

    R.section("Introduction to the Literature Review")
    R.p("The design of MediAI sits at the confluence of several active research and engineering "
        "fields: digital pharmacy and e-commerce, mobile health (mHealth) and medication "
        "adherence, large language models (LLMs) and Retrieval-Augmented Generation (RAG), "
        "optical character recognition (OCR) for clinical documents, and offline-first "
        "distributed data synchronization. This chapter reviews the most relevant literature "
        "and existing systems across these areas, identifies their strengths and limitations, "
        "and positions MediAI relative to the current state of the art. The aim is not merely to "
        "survey prior work but to extract the design lessons that directly shaped the "
        "architecture and feature set of this project.")
    R.p("The review begins with a consolidated literature matrix summarizing fifteen "
        "representative studies and systems. It then explores each thematic area in depth: "
        "online pharmacy platforms, medication-adherence and reminder systems, conversational "
        "AI and RAG for healthcare, prescription OCR, offline-first architectures, and the "
        "security and usability concerns that cut across all of them. The chapter closes by "
        "articulating the research and engineering gaps that MediAI addresses, and by "
        "summarizing the key insights carried forward into the requirements and design.")

    R.section("Literature Matrix")
    R.p("Table 2.1 presents a comparative matrix of fifteen studies and systems relevant to the "
        "domains MediAI spans. For each, the matrix records the focus area, the approach or "
        "technology used, the key contribution, and the principal limitation or gap. The matrix "
        "deliberately mixes peer-reviewed research with widely deployed commercial systems, "
        "because the design of a practical product must learn from both rigorous studies and "
        "real-world products.")
    rows = [
        ["1", "Online pharmacy e-commerce", "Web/mobile storefront, catalog & cart", "Demonstrates demand and convenience of digital medicine retail", "No adherence support; ordering only"],
        ["2", "Medication adherence (mHealth)", "Reminder apps, push notifications", "Reminders measurably improve adherence", "Reminders fail offline; no stock awareness"],
        ["3", "Smart pill reminders", "Scheduled local notifications", "Simple, low-cost dose prompts", "No auto-decrement of household stock"],
        ["4", "IoT smart pill dispensers", "Hardware + sensors", "Physical confirmation of intake", "Costly hardware; not scalable to all patients"],
        ["5", "Conversational health agents", "Rule-based / intent chatbots", "Quick answers to common questions", "Brittle; cannot generalize beyond scripts"],
        ["6", "LLM medical assistants", "General-purpose large language models", "Fluent, flexible natural-language answers", "Hallucination risk; unverifiable claims"],
        ["7", "Retrieval-Augmented Generation", "Embeddings + vector DB + LLM", "Grounds answers in real documents", "Quality depends on corpus & retrieval tuning"],
        ["8", "Vector databases", "ChromaDB / FAISS cosine search", "Fast semantic retrieval at scale", "Needs careful chunking & score thresholds"],
        ["9", "Sentence embeddings", "BAAI/bge, sentence-transformers", "Compact, accurate semantic vectors", "Domain shift can reduce relevance"],
        ["10", "Pharmaceutical data sources", "DailyMed, OpenFDA, RxNorm", "Authoritative, free drug labels & naming", "Heterogeneous formats; needs normalization"],
        ["11", "Drug-name normalization", "RxNorm approximate matching", "Resolves brands, synonyms, misspellings", "Coverage gaps for local brand names"],
        ["12", "Prescription OCR", "CNN/Vision models on scripts", "Digitizes handwritten prescriptions", "Handwriting variance lowers accuracy"],
        ["13", "Symptom triage systems", "Decision trees / checkers", "Structured pre-clinical guidance", "Safety risk if emergencies missed"],
        ["14", "Offline-first mobile apps", "Local DB + sync queue", "Reliable use without connectivity", "Conflict resolution is non-trivial"],
        ["15", "E-commerce security", "Server-side validation, RBAC", "Prevents client-side tampering", "Requires disciplined rule enforcement"],
    ]
    R.table("Literature Matrix of Relevant Studies and Systems",
            ["#", "Focus Area", "Approach / Technology", "Key Contribution", "Gap / Limitation"],
            rows, col_widths=[0.35, 1.3, 1.35, 1.7, 1.57], font_size=8.5)

    R.section("Online Pharmacy and E-Commerce Systems")
    R.p("Online pharmacy platforms have grown rapidly, driven by consumer demand for "
        "convenience and the broader shift of retail to digital channels. The literature and the "
        "commercial landscape both confirm that customers value the ability to browse a medicine "
        "catalog, compare prices, read product information, and order for home delivery. "
        "Well-designed pharmacy storefronts share common building blocks: a categorized and "
        "searchable catalog, product detail pages with images and reviews, a cart and checkout "
        "flow, order tracking, and promotional mechanisms such as coupons. MediAI implements all "
        "of these, modelling its catalog around categories, subcategories, and brands, and "
        "denormalizing frequently displayed fields to keep the mobile experience fast.")
    R.p("A recurring limitation of pure e-commerce pharmacy apps, however, is that the "
        "relationship with the customer effectively ends at the point of delivery. The app helps "
        "a patient buy a medicine but provides no support for actually taking it correctly or "
        "for re-ordering it before it runs out. This narrow scope leaves the most valuable "
        "outcome — sustained, correct medication use — entirely to the patient. MediAI was "
        "designed specifically to extend the relationship across the whole medication lifecycle, "
        "linking commerce to adherence so that, for example, a delivered order can automatically "
        "replenish the patient's tracked household stock.")

    R.section("Medication Adherence and Reminder Systems")
    R.p("Medication non-adherence is a well-documented and costly problem, especially for "
        "chronic conditions where treatment may continue for years. The literature identifies "
        "forgetfulness, complex regimens, and running out of supply as leading causes. A large "
        "body of mHealth research shows that timely reminders meaningfully improve adherence, "
        "and that simplicity and reliability of the reminder mechanism are decisive: a reminder "
        "that arrives late, or not at all, quickly erodes user trust and is abandoned.")
    R.p("Two limitations recur across existing reminder solutions. First, many rely on "
        "server-pushed notifications and therefore degrade or fail when the device is offline — "
        "precisely the situation in which a patient most needs a dependable local alarm. Second, "
        "almost none of them connect reminders to an awareness of how much medicine the patient "
        "actually has at home; they prompt the patient to take a dose but cannot warn that the "
        "supply is about to be exhausted. MediAI addresses both: its reminder engine is "
        "offline-first, scheduling full-screen alarms on the device through the operating "
        "system's local-notification and background-task facilities so that they fire reliably "
        "regardless of connectivity, and it couples every dose to a household stock model that "
        "decrements automatically and raises a low-stock alert before the medicine runs out.")

    R.section("Conversational AI and Retrieval-Augmented Generation in Healthcare")
    R.p("Conversational agents in healthcare have evolved from rigid, rule-based chatbots to "
        "fluent large language models. Rule-based systems are predictable and safe within their "
        "scripts but cannot generalize beyond them, producing dead ends for any unanticipated "
        "question. General-purpose LLMs solve the flexibility problem but introduce a far more "
        "serious one for healthcare: hallucination — the confident generation of plausible but "
        "incorrect information. In a pharmaceutical context, a hallucinated dosage or a missed "
        "interaction is not a minor error but a potential safety hazard.")
    R.p("Retrieval-Augmented Generation has emerged as the leading mitigation. By retrieving "
        "relevant passages from an authoritative corpus and constraining the model to answer "
        "only from that retrieved context, RAG dramatically reduces hallucination while "
        "retaining the natural-language flexibility of LLMs. The effectiveness of a RAG system "
        "depends on several engineering choices studied in the literature: the quality of the "
        "embedding model, the chunking strategy, the similarity threshold used to filter "
        "irrelevant passages, and the strictness of the system prompt. MediAI applies these "
        "findings directly. It uses a compact, high-quality sentence-embedding model, splits "
        "drug labels into overlapping chunks at sentence boundaries, discards retrieved passages "
        "below an empirically tuned similarity threshold, and instructs the model to refuse to "
        "answer when the context is insufficient. It further extends standard RAG with "
        "on-demand ingestion, fetching and indexing a drug the first time any user asks about "
        "it, so the knowledge base grows to match real usage.")

    R.section("Prescription Optical Character Recognition")
    R.p("Digitizing prescriptions is a long-standing challenge because handwritten clinical "
        "scripts are notoriously variable and often abbreviated. Classical OCR struggles with "
        "handwriting, and even specialized models face accuracy limits. Recent multimodal "
        "vision-language models have substantially improved the extraction of structured "
        "information from document images, including the ability to interpret layout and context "
        "rather than recognizing characters in isolation. MediAI leverages this advance by "
        "using a multimodal vision model to read a photographed prescription and return a "
        "structured list of medicines with their frequencies, durations, and likely conditions, "
        "which then pre-fills the medication form for the user to confirm. Because OCR output is "
        "never perfect, the design keeps a human in the loop: extracted fields are presented for "
        "review and correction, and medicine names are normalized and spell-corrected before "
        "they are used.")

    R.section("Offline-First Architecture and Synchronization")
    R.p("Offline-first design treats the local device as the primary source of truth and the "
        "cloud as an eventually consistent replica, rather than the other way around. The "
        "literature on offline-first and local-first software highlights its benefits for "
        "reliability and responsiveness, but also its central difficulty: synchronizing local "
        "and remote state without losing or duplicating data, particularly when the same record "
        "is edited on multiple devices. Established solutions include operation queues, "
        "last-write-wins conflict resolution using timestamps, and idempotent synchronization. "
        "MediAI adopts this approach for its safety-critical medicine and alarm data: all writes "
        "go first to a local SQLite database, changes are recorded in a pending-changes queue, "
        "and a synchronization service pushes them to Firestore when connectivity is available, "
        "pulling and merging remote changes using update timestamps for conflict resolution.")

    R.section("Security and Usability Considerations")
    R.p("Two cross-cutting concerns dominate the literature on consumer health and commerce "
        "applications: security and usability. On security, the consistent lesson is that the "
        "client must never be trusted for anything that affects money or access. Discounts, "
        "prices, and permissions must be validated on the server, and data access must be "
        "governed by role-based rules enforced at the database layer. MediAI follows this "
        "principle strictly: its coupon engine recomputes and re-validates every discount on the "
        "backend, and Firestore security rules enforce that only authenticated owners can touch "
        "their own data while only administrators can modify catalog and order records. On "
        "usability, the literature emphasizes clarity, feedback, error prevention, and "
        "accessibility — principles especially important for a health app whose users span all "
        "ages and levels of digital literacy. MediAI applies established usability heuristics "
        "with clear step-by-step flows, confirmation prompts, legible typography, and "
        "high-contrast presentation.")

    R.section("Research Gaps and Project Relevance")
    R.p("Synthesizing the literature reveals a set of gaps that no single existing system fully "
        "addresses, and which collectively motivate MediAI:")
    R.numbered("Fragmentation: ordering, reminders, stock tracking, prescription capture, and "
               "AI guidance exist as separate tools, forcing patients to juggle multiple apps "
               "that do not share data. MediAI unifies them in one ecosystem.")
    R.numbered("Offline fragility: most reminder systems fail without connectivity. MediAI makes "
               "its safety-critical features offline-first by design.")
    R.numbered("Untrusted AI: general chatbots risk hallucinating clinical information. MediAI "
               "grounds every answer in authoritative drug labels through RAG and refuses to "
               "answer when evidence is lacking.")
    R.numbered("No stock-commerce link: existing apps cannot connect a delivered order back to a "
               "patient's household supply. MediAI auto-refills tracked stock on delivery.")
    R.numbered("Name fragility: misspelled or brand-named medicines break naive lookups. MediAI "
               "normalizes and spell-corrects names through approximate RxNorm matching.")
    R.p("By addressing these gaps in a single, coherent, offline-resilient, and "
        "safety-conscious platform, MediAI contributes a practical and integrated solution that "
        "advances beyond the piecemeal tools currently available.")

    R.section("Summary of Key Insights")
    R.p("The literature review yields several insights that are carried directly into the "
        "requirements and design of MediAI. Reminders must be reliable and offline-first to be "
        "trusted; adherence support is far more valuable when linked to stock awareness and "
        "easy re-ordering; conversational AI in healthcare must be grounded and safety-gated "
        "rather than merely fluent; prescription OCR must keep a human in the loop; offline-first "
        "data demands disciplined synchronization and conflict resolution; and security must be "
        "enforced on the server and at the database layer rather than trusted from the client. "
        "These principles shape every subsequent chapter of this report.")
