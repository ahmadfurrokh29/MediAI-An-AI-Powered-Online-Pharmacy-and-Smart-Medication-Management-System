# -*- coding: utf-8 -*-
def build(R):
    R.chapter("Introduction")
    R.p("This chapter introduces the MediAI project — an AI-powered online pharmacy and smart "
        "medication-management platform designed and developed as a Final Year Project in the "
        "Department of Computer Science at Sir Syed CASE Institute of Technology. Healthcare is "
        "one of the most personal and high-stakes domains in which software can make a "
        "difference, and the safe, timely management of medicines sits at its very centre. "
        "Despite the proliferation of e-commerce and mobile health applications, most existing "
        "tools address only a fragment of the medication journey: some let a patient buy "
        "medicines online, others set simple reminders, and a few attempt to answer health "
        "questions. Very few bring these capabilities together into one coherent, trustworthy, "
        "and offline-resilient experience. MediAI was conceived to close exactly this gap.")
    R.p("The platform unifies four pillars into a single ecosystem: a complete online pharmacy "
        "for purchasing medicines; an offline-first reminder and household stock-management "
        "system that ensures patients never miss a dose or run out of medicine unexpectedly; an "
        "AI Virtual Pharmacist that answers medicine-related questions using grounded, "
        "authoritative drug information rather than unverified generation; and a prescription "
        "digitization feature that reads a photographed prescription and auto-fills the user's "
        "medication schedule. A separate web administration panel allows pharmacists and "
        "operators to manage the catalog, process orders, run promotions, and review "
        "prescription requests. This chapter establishes the purpose, scope, conventions, "
        "audience, and business rationale of the project, and provides an overview of the "
        "complete system.")

    R.section("Purpose")
    R.p("The primary purpose of this document is to analyze, specify, and evaluate the "
        "functional and non-functional requirements of the MediAI platform and to present the "
        "complete engineering process behind its design, implementation, and testing. The "
        "document explains why such a system is necessary, the real-world problems it solves, "
        "the stakeholders it serves, and the technical decisions that shaped each module. It is "
        "intended to serve simultaneously as a software requirements specification, a design "
        "blueprint, and a complete record of the project for academic evaluation.")
    R.p("Concretely, the purpose of MediAI itself is to improve medication adherence and "
        "convenience for patients while giving pharmacies a modern digital storefront and an "
        "intelligent assistant layer. By bringing ordering, reminders, stock tracking, "
        "prescription scanning, and AI-assisted pharmaceutical guidance into one application, "
        "the project aims to reduce missed doses, avoid dangerous gaps in chronic treatment, "
        "and make trustworthy medicine information accessible at the moment a patient needs it.")

    R.section("Document Conventions")
    R.p("This report uses a consistent set of typographic and structural conventions to aid "
        "readability. Chapter titles are centred and capitalized; section and subsection "
        "headings are numbered decimally (for example, 1.1 Purpose, 1.1.1 Sub-topic) and set in "
        "bold. The body text is justified and set in a serif typeface for comfortable extended "
        "reading. Figures are centred with their captions placed beneath them, while tables span "
        "the full text width with their captions placed above and aligned to the left. Source "
        "code identifiers, file names, API endpoints, and class names are referred to in plain "
        "text within sentences. Where a screenshot or photograph is recommended but must be "
        "inserted manually by the authors, a clearly labelled placeholder box has been left in "
        "place.")

    R.section("Intended Audience and Reading Suggestions")
    R.p("This document is intended for a broad range of readers, including the project "
        "supervisor and evaluation panel, software developers, testers, technical reviewers, "
        "and any future maintainers who wish to extend the system. Readers primarily interested "
        "in the motivation and value of the system should focus on Chapters 1 to 3. Readers "
        "interested in what the system does and how it behaves should read Chapter 4 "
        "(Requirement Analysis) and Chapter 5 (Design and Architecture). Developers and "
        "maintainers will find the deepest technical detail in Chapter 6 (Implementation) and "
        "Chapter 7 (Testing). Chapter 8 summarizes findings and outlines future work, and "
        "Chapter 9 provides a glossary, abbreviations, and references for quick lookup.")

    R.section("Project Scope")
    R.p("This document applies to the MediAI platform developed by the authors as a Final Year "
        "Project at Sir Syed CASE Institute of Technology. The scope of the system spans three "
        "deployable applications and a cloud backend that work together as one product:")
    R.bullet("a customer-facing cross-platform mobile application built with Flutter, providing "
             "the online pharmacy, medicine reminders, stock management, prescription scanning, "
             "and the AI pharmacist chatbot;", bold_lead="Mobile application — ")
    R.bullet("a Flutter web administration panel that gives pharmacists and operators full "
             "control over the catalog, orders, customers, promotions, prescription requests, "
             "and other administrators;", bold_lead="Administration panel — ")
    R.bullet("a Python FastAPI backend that hosts the Retrieval-Augmented Generation chatbot, "
             "the symptom-triage engine, the pharmaceutical knowledge index, and the "
             "server-authoritative coupon engine;", bold_lead="AI backend — ")
    R.bullet("Google Firebase services (Authentication, Firestore, Storage, and Cloud "
             "Messaging) that provide identity, the primary cloud database, media storage, and "
             "push notifications.", bold_lead="Cloud backend — ")
    R.p("The system is designed for real-world community-pharmacy use and is engineered to work "
        "reliably even when network connectivity is intermittent — a deliberate decision given "
        "that the most safety-critical features (medicine reminders and stock alerts) must never "
        "depend on a live connection. The scope explicitly includes secure authentication, "
        "an online ordering workflow with coupons and order tracking, an offline-first reminder "
        "and stock subsystem, AI-assisted pharmaceutical guidance grounded in authoritative "
        "sources, and a complete administrative back office. The scope explicitly excludes "
        "real-money payment-gateway integration (a cash-on-delivery and demonstration payment "
        "flow is provided instead), clinical diagnosis, and the dispensing of controlled "
        "substances, all of which fall outside the remit of an academic prototype.")

    R.section("Overview")
    R.p("In today's healthcare landscape, the gap between owning medicines and actually taking "
        "them correctly remains stubbornly wide. Studies of medication adherence consistently "
        "show that a large fraction of patients — particularly those on long-term, chronic "
        "regimens — miss doses, take incorrect amounts, or stop treatment early. The "
        "consequences range from reduced therapeutic benefit to serious clinical deterioration "
        "and avoidable hospital admissions. At the same time, patients increasingly expect the "
        "same convenience from healthcare that they enjoy in other digital services: the ability "
        "to order what they need, get answers instantly, and have the system remember things on "
        "their behalf.")
    R.p("MediAI responds to these expectations with a single application that a patient can use "
        "across the full lifecycle of a medicine. A user can discover and order a product, scan "
        "the prescription that justifies it, schedule reminders for every dose, watch household "
        "stock decrement automatically as doses are taken, receive a warning before the medicine "
        "runs out, re-order it from within the same app, and ask the built-in AI pharmacist any "
        "questions about side effects, interactions, or usage along the way. Because the "
        "reminder and stock subsystems are built offline-first on a local database, these "
        "safety-critical features continue to function flawlessly even with no internet "
        "connection, synchronizing transparently to the cloud whenever connectivity returns.")
    R.p("The AI pharmacist is deliberately engineered to be trustworthy rather than merely "
        "fluent. Instead of allowing a large language model to answer from its unverifiable "
        "internal memory, MediAI retrieves relevant passages from authoritative, "
        "government-curated drug labels (DailyMed and OpenFDA), injects them into the model as "
        "grounding context, and constrains the model to answer strictly from that context. When "
        "a user asks about a drug not yet in the knowledge base, the system fetches and indexes "
        "it on demand. When a user describes symptoms, a dedicated triage engine conducts a "
        "safe, structured assessment and escalates immediately if it detects an emergency. This "
        "combination of grounding, on-demand learning, and safety gating is what elevates MediAI "
        "above a generic chatbot.")

    R.section("Relevance to the Course Module")
    R.p("MediAI draws directly on the full breadth of the Software Engineering curriculum. The "
        "online pharmacy and administration panel exercise the web and mobile development "
        "courses, applying responsive UI construction, state management, and client-server "
        "integration. The clean, layered architecture — with clearly separated presentation, "
        "application, data, and background-service layers, and a repository pattern over the "
        "data sources — applies the principles taught in Software Construction and Development "
        "and Software Design and Architecture. The interface design follows established "
        "usability heuristics studied in Human-Computer Interaction, including clear feedback, "
        "error prevention, consistency, and accessibility considerations such as high-contrast "
        "presentation and large, legible touch targets.")
    R.p("The artificial-intelligence backend applies concepts from data structures, algorithms, "
        "and information retrieval through its use of vector embeddings, cosine-similarity "
        "search, chunking, and intent classification. The offline-first synchronization "
        "subsystem applies database concepts and distributed-systems reasoning, including "
        "conflict resolution, idempotent operations, and an offline operation queue. The "
        "rigorous requirements analysis, use-case modelling, design documentation, and test "
        "planning presented in this report apply the discipline of Software Requirements "
        "Engineering and Software Quality Assurance. The integration of these academic "
        "principles with a genuine, end-to-end product demonstrates the significance of the "
        "coursework in building robust, real-world software systems.")

    R.section("Business Opportunity")
    R.p("MediAI is positioned at the intersection of two large and growing markets: online "
        "pharmacy retail and digital health. The platform's combination of commerce, adherence "
        "tooling, and AI-assisted guidance creates several concrete business opportunities for "
        "pharmacies, health-tech companies, and institutions:")
    R.numbered("Offering MediAI as a turnkey digital storefront and adherence platform to "
               "independent and chain pharmacies that lack the resources to build their own "
               "mobile presence.")
    R.numbered("Providing the AI Virtual Pharmacist as a value-added service that increases "
               "customer engagement and trust, differentiating a pharmacy from generic "
               "e-commerce competitors.")
    R.numbered("Monetizing the adherence and auto-refill features through subscription tiers, "
               "loyalty points, and timely re-order prompts that increase repeat purchases.")
    R.numbered("Licensing the prescription-OCR and medicine-normalization pipeline to clinics, "
               "telemedicine providers, and electronic health-record vendors.")
    R.numbered("Partnering with insurers and chronic-care programs that benefit measurably from "
               "improved medication adherence among their members.")
    R.p("Because the platform is built on widely available, cost-effective cloud services and "
        "open pharmaceutical data sources, its operating costs scale gently with usage, making "
        "it viable for deployment even in price-sensitive markets. The modular architecture "
        "further allows individual capabilities — such as the chatbot or the reminder engine — "
        "to be offered independently, broadening the range of commercial arrangements possible.")
