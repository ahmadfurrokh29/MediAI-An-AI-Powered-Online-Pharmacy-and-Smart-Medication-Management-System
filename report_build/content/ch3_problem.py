# -*- coding: utf-8 -*-
def build(R):
    R.chapter("Problem Definition")
    R.p("This chapter defines the problem that MediAI sets out to solve, decomposes it into a "
        "precise set of sub-problems, states the boundaries and assumptions of the solution, and "
        "establishes the technical background necessary to understand the design decisions made "
        "in later chapters. A clear problem definition is essential: it grounds the requirements "
        "in real user needs and provides the criteria against which the finished system is "
        "evaluated.")

    R.section("The Current Medication-Management Experience")
    R.p("For most patients, managing medication is a manual, error-prone, and fragmented "
        "process. A patient may visit a doctor and receive a handwritten prescription, take that "
        "paper to a pharmacy, buy the medicines, and then be left entirely on their own to "
        "remember when to take each one, how many remain, and when to buy more. There is no "
        "single place that holds the prescription, the schedule, the remaining stock, and a "
        "source of trustworthy guidance. Reminders, if any, are set in a generic clock app that "
        "knows nothing about the medicine. Refills are remembered only when the last pill is "
        "taken — often too late. Questions about side effects or interactions are either left "
        "unanswered or answered by unreliable internet searches.")
    R.p("Each of these breakdowns has real consequences. A missed dose reduces the effectiveness "
        "of treatment; a missed refill creates a dangerous gap in a chronic regimen; a "
        "misunderstood instruction can cause harm. The underlying problem is not a lack of "
        "individual tools — reminder apps, pharmacy apps, and search engines all exist — but the "
        "absence of an integrated system that connects them and that remains reliable when it "
        "matters most.")

    R.section("Problem Statement")
    R.p("Patients lack a single, reliable, and intelligent system that supports the entire "
        "medication lifecycle — from discovering and ordering medicines, to digitizing "
        "prescriptions, to being reminded of every dose, to tracking household stock and "
        "refilling it in time, to obtaining trustworthy answers to medicine-related questions. "
        "The core challenge addressed by this project is therefore stated as follows:")
    R.p("How can a single, secure, offline-resilient platform be designed and implemented that "
        "unifies online medicine ordering, prescription digitization, dependable medicine "
        "reminders, automatic household-stock management, and a trustworthy AI pharmacist, while "
        "guaranteeing data integrity, user privacy, and safe AI behaviour?", italic=True)
    R.p("This central challenge naturally decomposes into a set of more specific sub-problems, "
        "each of which is treated as a requirement in Chapter 4 and a design concern in later "
        "chapters.")

    R.subsection("Reliability of Reminders")
    R.p("Reminders are only useful if they are perfectly reliable. The system must fire alarms "
        "at the correct times even when the application is closed and the device is offline, and "
        "those alarms must survive a device restart. This rules out any design that depends on a "
        "live server push for the moment-to-moment delivery of dose reminders.")

    R.subsection("Data Integrity and Synchronization")
    R.p("Medicine and alarm data is safety-critical and must never be lost or silently "
        "corrupted. Because the system is offline-first, the same record may be edited while "
        "offline and later need to be reconciled with the cloud. The system must therefore queue "
        "offline operations, synchronize them deterministically, and resolve conflicts in a "
        "predictable way.")

    R.subsection("Trustworthy and Safe AI Guidance")
    R.p("The AI pharmacist must not invent medical facts. It must ground its answers in "
        "authoritative drug information, refuse to answer when it lacks evidence, stay strictly "
        "within the pharmaceutical domain, and escalate immediately when a user describes a "
        "medical emergency. Safety takes precedence over fluency.")

    R.subsection("Security and Privacy")
    R.p("The platform handles personal and health-related data and processes commercial "
        "transactions. It must authenticate users securely, enforce role-based access at the "
        "database layer, validate all pricing and discounts on the server, and ensure that each "
        "user can access only their own private data.")

    R.section("Delimitations")
    R.p("To keep the project focused and achievable within the time available, several "
        "boundaries are deliberately drawn. MediAI is an academic prototype and not a "
        "clinically certified medical device; it provides educational pharmaceutical information "
        "and adherence tooling, not diagnosis or treatment. It does not integrate a live "
        "real-money payment gateway; instead it implements a cash-on-delivery flow together with "
        "a demonstration payment interface, since the engineering of secure ordering, discount "
        "validation, and order tracking is fully exercised without committing to a specific "
        "payment processor. The AI pharmacist's knowledge base is bootstrapped from a curated "
        "baseline of common medicines and grown on demand; it is not an exhaustive global drug "
        "database. The OCR feature targets reasonably legible prescriptions and always keeps the "
        "user in the loop for confirmation. Finally, the discussion of regulatory and legal "
        "frameworks is kept at a practical level appropriate to a prototype rather than a "
        "production medical product.")

    R.section("Technical Background")
    R.p("This section introduces the core technologies and concepts on which MediAI is built, so "
        "that the design and implementation chapters can be read without interruption.")

    R.subsection("Flutter and Dart")
    R.p("Flutter is an open-source UI toolkit from Google for building natively compiled "
        "applications for mobile, web, and desktop from a single codebase, written in the Dart "
        "programming language. Flutter renders its own widgets rather than wrapping native "
        "controls, giving precise control over appearance and smooth performance. MediAI uses "
        "Flutter for both the customer mobile application and the web administration panel, "
        "sharing concepts and patterns across the two. Dart's strong typing, asynchronous "
        "support through futures and streams, and rich standard library make it well suited to a "
        "responsive, data-driven application.")

    R.subsection("GetX State Management")
    R.p("GetX is a lightweight yet powerful framework for Flutter that provides reactive state "
        "management, dependency injection, and route management with minimal boilerplate. In "
        "MediAI, GetX controllers hold the reactive state of each feature — for example, the "
        "cart, the product catalog, and the order history — and automatically rebuild the user "
        "interface when that state changes. Its dependency-injection container makes controllers "
        "and services available throughout the application without manual wiring.")

    R.subsection("Firebase Cloud Services")
    R.p("Firebase is Google's mobile and web application platform. MediAI uses four of its "
        "services. Firebase Authentication manages user identity and supports email/password, "
        "Google, and Facebook sign-in. Cloud Firestore is a flexible, scalable NoSQL document "
        "database with real-time listeners, used as the primary cloud store for users, products, "
        "orders, and other collections. Firebase Storage holds binary media such as product and "
        "banner images. Firebase Cloud Messaging delivers push notifications, for example coupon "
        "offers. Firestore's security rules allow access control to be expressed and enforced "
        "directly at the database layer.")

    R.subsection("SQLite and Offline-First Storage")
    R.p("SQLite is a self-contained, serverless, transactional relational database engine "
        "embedded directly in the application. In MediAI it is the offline-first source of truth "
        "for medicines, alarms, and the synchronization queue. Because SQLite runs entirely on "
        "the device, the reminder and stock features work with zero network dependency. The "
        "application also uses lightweight key-value storage for preferences and session data.")

    R.subsection("Large Language Models and the Groq Inference Platform")
    R.p("A large language model is a neural network trained on vast text corpora to predict and "
        "generate natural language. Modern LLMs can answer questions, summarize, and converse "
        "fluently, but they generate from learned parameters and can produce confident yet "
        "incorrect output — a phenomenon called hallucination. MediAI uses an instruction-tuned "
        "LLM served through Groq, a high-performance inference platform, for its chatbot. The "
        "model is always constrained by a strict system prompt and, wherever possible, by "
        "retrieved grounding context.")

    R.subsection("Retrieval-Augmented Generation, Embeddings, and Vector Databases")
    R.p("Retrieval-Augmented Generation (RAG) combines an information-retrieval step with "
        "language generation. Source documents are split into chunks, each chunk is converted "
        "into a numerical vector (an embedding) that captures its meaning, and the vectors are "
        "stored in a vector database. At query time the user's question is embedded and compared "
        "against the stored vectors using cosine similarity to retrieve the most relevant "
        "chunks, which are injected into the LLM prompt as grounding context. MediAI uses a "
        "compact sentence-embedding model to produce 384-dimensional vectors and ChromaDB as the "
        "persistent vector store, applying a similarity threshold to discard irrelevant passages "
        "so that the model answers only from genuinely relevant evidence.")

    R.subsection("Authoritative Pharmaceutical Data: DailyMed, OpenFDA, and RxNorm")
    R.p("The trustworthiness of the AI pharmacist depends on the quality of its sources. MediAI "
        "draws on three free, authoritative resources maintained by United States health "
        "agencies. DailyMed provides structured product labels (the official prescribing "
        "information) for medicines. OpenFDA exposes drug-label and safety data through an open "
        "API. RxNorm provides normalized naming for clinical drugs, mapping brand names, "
        "generic names, ingredients, and synonyms to standard identifiers, and supports "
        "approximate matching that tolerates misspellings — the basis of MediAI's medicine-name "
        "spell correction.")

    R.subsection("Optical Character Recognition with Vision-Language Models")
    R.p("Optical Character Recognition converts images of text into machine-readable text. "
        "Traditional OCR handles printed text well but struggles with handwriting. MediAI uses a "
        "multimodal vision-language model that interprets a photographed prescription "
        "holistically — reading layout and context, not just isolated characters — and returns a "
        "structured list of medicines with their schedules, which the user then confirms.")

    R.subsection("FastAPI Backend")
    R.p("FastAPI is a modern, high-performance Python web framework for building APIs, with "
        "automatic data validation and interactive documentation. MediAI's AI backend is built "
        "with FastAPI and hosts the chatbot, the RAG pipeline, the symptom-triage engine, the "
        "pharmaceutical index, and the coupon engine. It communicates with the Flutter clients "
        "over simple JSON HTTP endpoints.")

    R.section("Summary")
    R.p("The problem MediAI addresses is the fragmented, unreliable, and unsupported nature of "
        "everyday medication management. The solution must be integrated, offline-resilient, "
        "trustworthy in its AI behaviour, and secure in its handling of personal and commercial "
        "data. The technologies introduced in this chapter — Flutter and GetX on the client, "
        "Firebase and SQLite for data, an LLM with RAG over authoritative pharmaceutical "
        "sources, vision-based OCR, and a FastAPI backend — are the building blocks from which "
        "the requirements of Chapter 4 and the design of Chapter 5 are constructed.")
