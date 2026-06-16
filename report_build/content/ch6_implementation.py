# -*- coding: utf-8 -*-
def build(R):
    R.chapter("Implementation")
    R.p("This chapter describes the technical implementation of MediAI in depth, module by "
        "module. It covers the system architecture as realized in code, the development "
        "environment, and the detailed implementation of every subsystem: authentication and "
        "user management, the e-commerce store, prescription OCR, the medicine reminder and "
        "alarm system, stock management and auto-refill, offline-first synchronization, the AI "
        "Virtual Pharmacist and its Retrieval-Augmented Generation pipeline, the symptom-triage "
        "engine, the server-side coupon engine, the administration panel, the notification "
        "subsystem, and the security model. The chapter closes with the user interfaces and the "
        "principal challenges encountered during development together with their solutions. "
        "Wherever a screenshot would aid understanding, a clearly labelled placeholder has been "
        "left for the authors to insert the relevant image.")

    R.section("System Architecture in Practice")
    R.p("In the implemented system the customer application is a Flutter project organized by "
        "feature. Each feature — authentication, shop, personalization, and chatbot — contains "
        "its own screens, controllers, models, and, where relevant, services, following a "
        "feature-first folder structure. Cross-cutting code lives in shared common widgets, "
        "utilities, and a data layer of repositories. The administration panel is a separate "
        "Flutter web project with the same feature-first organization. The AI backend is a "
        "FastAPI application whose responsibilities are partitioned into a retrieval-augmented "
        "generation package and a coupon package. The customer app talks to Firestore directly "
        "for commerce and profile data through the repository layer, to SQLite directly for "
        "medical data, and to the FastAPI backend over HTTP for chatbot and coupon operations.")
    R.p("The application bootstraps in a deliberate order. On startup it initializes local "
        "key-value storage, preserves the native splash screen, initializes Firebase and the "
        "authentication repository, configures the notification service, initializes "
        "connectivity monitoring, and registers push messaging. After the first frame is "
        "rendered it processes any pending notification, re-schedules all alarms from the local "
        "database so they survive restarts, checks stock levels and emits one-time low-stock "
        "alerts, registers a periodic background stock check that runs even when the app is "
        "closed, and triggers an initial synchronization of any pending local changes. This "
        "ordered startup guarantees that the safety-critical reminder and stock features are "
        "armed as early as possible in the application lifecycle.")

    R.section("Development Environment and Toolchain")
    R.p("MediAI was developed in Visual Studio Code with the Flutter and Dart toolchains for the "
        "client applications and a Python virtual environment for the FastAPI backend. The "
        "client depends on a curated set of packages: GetX for state management and navigation; "
        "the Firebase suite (core, authentication, Firestore, storage, and messaging) for cloud "
        "services; the image picker for capturing prescriptions; sqflite for the local database; "
        "flutter_local_notifications, timezone, and workmanager for reliable alarms and "
        "background tasks; connectivity_plus for network monitoring; and a number of UI helper "
        "packages for carousels, ratings, indicators, and animations. The backend depends on "
        "FastAPI and Uvicorn for the web layer, the Groq client for language generation, "
        "sentence-transformers for embeddings, ChromaDB for the vector store, httpx for "
        "asynchronous calls to external pharmaceutical APIs, and firebase-admin for server-side "
        "access to Firestore where required.")
    R.p("Version control was maintained with Git. Configuration secrets such as API keys are "
        "supplied through environment files that are excluded from version control, with example "
        "templates committed for reference. The backend exposes interactive API documentation "
        "automatically, which accelerated integration testing between the Flutter clients and "
        "the server.")

    R.section("Authentication and User Management")
    R.p("Authentication is implemented through an authentication repository that wraps Firebase "
        "Authentication and is registered in the GetX dependency container at startup. The "
        "repository exposes registration, email/password sign-in, Google sign-in, Facebook "
        "sign-in, email verification, password reset, and sign-out. On first registration the "
        "system creates a corresponding user document in the Users collection containing the "
        "user's name, email, phone, profile fields, role, loyalty points, and an addresses "
        "array. The repository also determines, on launch, whether a user is already "
        "authenticated and routes them accordingly, and it sets a concrete authentication locale "
        "to suppress spurious locale warnings.")
    R.p("The personalization feature builds on this foundation. It lets a customer view and edit "
        "their profile, upload a profile picture to Firebase Storage, manage multiple shipping "
        "addresses with a selected default, and view their notifications and medical history. "
        "Administrators authenticate through the separate panel, where the authentication "
        "controller additionally verifies that the signing-in account exists in the Admins "
        "collection before granting access, ensuring that ordinary customers cannot reach "
        "administrative functions.")
    R.figure("login.jpeg", "Customer login screen")
    R.figure("signup.jpeg", "Customer registration screen")
    R.figure("personalization.jpeg", "Customer profile and personalization screen")

    R.section("E-Commerce Store Implementation")
    R.subsection("Catalog: Categories, Brands, and Products")
    R.p("The catalog is driven by a set of GetX controllers — for the home screen, categories, "
        "brands, and products — that fetch data from Firestore and expose it reactively to the "
        "user interface. The home controller assembles the home screen from active promotional "
        "banners, featured categories, and recommended products. The category and brand "
        "controllers provide category- and brand-based navigation, with brands supporting "
        "assignment to multiple categories through a category-identifier array. The product "
        "controller handles fetching, searching, and filtering of products and exposes featured "
        "and recommended subsets for prominent placement. Each product stores denormalized "
        "category, subcategory, and brand names so that listings render without additional "
        "lookups.")
    R.figure("home.jpeg", "Home screen with banners, categories, and recommended products")
    R.figure("store.jpeg", "Store screen with category and brand navigation")
    R.figure("product detail.jpeg", "Product details screen")

    R.subsection("Shopping Cart")
    R.p("The cart is managed by a cart controller that holds the cart as a reactive list. "
        "Adding, removing, and changing the quantity of items updates this list and immediately "
        "persists the change to the user's cart subcollection in Firestore, so the cart survives "
        "across sessions and devices. The controller continuously recomputes the subtotal and "
        "exposes the running totals to the cart and checkout screens. Because the cart is "
        "reactive, the user interface updates instantly as items change, satisfying the "
        "performance and usability requirements.")

    R.subsection("Checkout, Addresses, and Payment")
    R.p("The checkout flow composes several controllers. The cart controller supplies the "
        "subtotal and the computed shipping and tax; the address controller supplies the chosen "
        "shipping address; the coupon controller validates and applies any discount; and the "
        "payment controller captures the chosen payment method. When the customer confirms, the "
        "order controller assembles an order document — embedding the line items, the totals, "
        "the coupon details, the shipping address, and the initial Pending status — writes it to "
        "the Orders collection, and clears the cart. A demonstration payment flow stands in for a "
        "live payment gateway, while cash-on-delivery is fully supported, including automatic "
        "marking of payment as received when a cash order is delivered.")
    R.figure("cart.jpeg", "Shopping cart screen")
    R.figure("chekout.jpeg", "Checkout screen with coupon entry")

    R.subsection("Orders and Tracking")
    R.p("The order controller also fetches the signed-in customer's order history and exposes it "
        "to the orders screen, where each order can be opened to view its items, totals, and "
        "current status. The same controller hosts the delivered-order stock-refill logic "
        "described later in this chapter, demonstrating how the commerce and adherence modules "
        "are linked in code rather than merely in concept.")

    R.subsection("Reviews and Wishlist")
    R.p("Customers can rate and review products; reviews are stored in a per-product subcollection "
        "and aggregated into an average rating shown on the product page, with the reviewer's "
        "name denormalized for display. The wishlist controller mirrors the cart pattern, "
        "maintaining a reactive list synchronized to the user's wishlist subcollection so that "
        "saved products are available across sessions.")

    R.section("Prescription OCR Implementation")
    R.p("The prescription-scanning feature lets a customer photograph a prescription and have "
        "its contents extracted automatically. The scan screen lets the user pick an image from "
        "the camera or gallery and then submits it to an OCR utility that calls a Google Gemini "
        "vision model. The model is prompted to act as an expert medical assistant, to read the "
        "prescription, and to return a strict JSON list of medicines, each with a medicine name, "
        "the condition being treated, a dosage frequency, a duration, a start date, and a chronic "
        "flag. The utility requests structured JSON output and a low generation temperature for "
        "determinism, and it automatically falls back from the primary vision model to a lighter "
        "model if the primary is overloaded or rate-limited.")
    R.p("The extracted medicines are passed to the medication form, where the user reviews and "
        "corrects each field before saving. The original prescription image is encoded and "
        "stored alongside the medicines in a dedicated local table, so it can later be retrieved "
        "— for example, to attach to a re-order or a prescription request. Keeping the human in "
        "the loop in this way reconciles the convenience of automatic extraction with the safety "
        "requirement that medication data be accurate.")
    R.figure("ocr scan.jpeg", "Prescription scan screen")
    R.figure("medication form.jpeg", "Auto-filled medication form after OCR extraction")

    R.section("Medicine Reminder and Alarm System")
    R.p("The reminder system is built on a local SQLite database and the device's "
        "local-notification and background-task facilities. The local database defines a "
        "medicines table and an alarms table, with each medicine able to own multiple alarms "
        "tied to specific doses and times. When a medicine is saved, its alarms are written to "
        "SQLite and scheduled through the notification service, which uses the timezone package "
        "(configured for the local zone) to fire each alarm at the correct local time. Alarms "
        "are scheduled as full-screen notifications so that, when a dose is due, a prominent "
        "alarm screen appears even if the application is closed or the device is locked.")
    R.p("When an alarm fires, the alarm-trigger screen offers the user three actions: take the "
        "dose, snooze it for a short interval, or dismiss it. Taking the dose decrements the "
        "household stock for that medicine and triggers a stock-threshold check. Because the "
        "alarms are persisted in SQLite, the application re-schedules all of them from the local "
        "database on startup, guaranteeing that reminders survive application closure and device "
        "restarts. A periodic background task, registered through the work-manager facility, "
        "additionally ensures that stock checks continue to run even when the application is not "
        "open.")
    R.figure("medication.jpeg", "Medication list screen")
    R.figure("alrm trigger.jpeg", "Full-screen alarm trigger screen")

    R.section("Stock Management and Auto-Refill")
    R.p("Every medicine carries a total course size, a current available-stock figure, and an "
        "alert-before-days threshold. The stock-management screen presents the user's medicines "
        "grouped and colour-coded by status: out of stock, running low, or sufficient. The "
        "low-stock logic is sensitive to whether a medicine is chronic. For a chronic medicine, "
        "an alert is raised whenever the remaining stock falls within the threshold window, "
        "because the treatment continues indefinitely. For a non-chronic medicine whose stock "
        "still covers the remaining course, no alert is raised. This nuance prevents both missed "
        "warnings for long-term medicines and unnecessary nagging for short courses.")
    R.p("The auto-refill feature links delivered orders back to the patient's tracked stock. "
        "When the order controller observes that an order has been delivered, it matches the "
        "order's line items against the user's tracked medicines by name (using a "
        "case-insensitive containment check that tolerates minor naming differences) and "
        "increases the available stock of each matching medicine by the delivered quantity. To "
        "guarantee that this happens exactly once per order, a dedicated local table records the "
        "identifiers of orders whose stock has already been refilled, and the routine checks "
        "this table before acting. This idempotent design is essential because the delivered "
        "order may be observed multiple times as the order list refreshes.")
    R.figure("stock refill.jpeg", "Stock-management overview with colour-coded status")

    R.section("Offline-First Synchronization")
    R.p("MediAI's medical data is offline-first: every write goes to SQLite first and is "
        "synchronized to Firestore opportunistically. Three cooperating services implement this. "
        "The connectivity service monitors the network state and triggers synchronization when a "
        "connection becomes available. The offline-queue service records each create, update, or "
        "delete operation in a pending-changes table, deliberately removing any earlier queued "
        "operation for the same entity so that conflicting operations do not accumulate. The "
        "synchronization service pushes queued local changes to Firestore, pulls remote changes "
        "back into SQLite, and resolves conflicts using each record's local-update timestamp on "
        "a last-write-wins basis.")
    R.p("Each medicine and alarm row carries a synced flag that distinguishes locally modified "
        "records that still need to be pushed from records already mirrored in the cloud. The "
        "synchronization routine fetches the unsynced records, writes them to the user's "
        "Firestore subcollections, and marks them synced on success. This design keeps the "
        "safety-critical features fully functional offline while ensuring that, once "
        "connectivity returns, the local and cloud copies converge to a consistent state — "
        "satisfying both the reliability and the consistency requirements.")

    R.section("AI Virtual Pharmacist: Retrieval-Augmented Generation")
    R.p("The AI Virtual Pharmacist is implemented as a FastAPI backend exposing a general chat "
        "endpoint and a retrieval-augmented chat endpoint, with the Flutter client preferring "
        "the grounded endpoint and falling back to the general one only when no grounded answer "
        "is available. The general endpoint sends the question, wrapped in a strict system "
        "prompt that confines the assistant to pharmaceutical topics, to an instruction-tuned "
        "LLM served through Groq. The grounded endpoint runs the full RAG pipeline.")

    R.subsection("Embedding and Vector Store")
    R.p("Source drug labels are split into overlapping chunks at sentence boundaries and "
        "embedded with a compact, high-quality sentence-embedding model that produces "
        "384-dimensional vectors. The vectors, together with metadata identifying the drug, the "
        "label section, and the source, are stored in a persistent ChromaDB collection. At query "
        "time the user's question is embedded and compared against the stored vectors using "
        "cosine similarity. Retrieved chunks below an empirically chosen similarity threshold are "
        "discarded, so that genuinely irrelevant passages are never injected as context and "
        "unsupported questions fall through to a safe refusal.")

    R.subsection("Intent Classification and Query Routing")
    R.p("Before retrieval, each query is classified by intent and passed through a routing "
        "table. Direct-lookup intents — such as asking for the generic name of a brand, the "
        "brands of a generic, or the medicines containing an ingredient — are answered "
        "immediately from a pharmaceutical index without invoking the LLM at all, which is both "
        "faster and perfectly accurate. Section-aware intents, such as questions about dosage or "
        "side effects, are given retrieval hints that focus the search on the relevant label "
        "section. Symptom queries are handed to the triage engine, and clearly off-topic queries "
        "are refused by the general guardrail.")

    R.subsection("The Pharmaceutical Index and Medicine-Name Spell Correction")
    R.p("A persistent pharmaceutical index stores RxNorm-enriched metadata for every ingested "
        "medicine and provides fast lookups from brand to generic, generic to brands, ingredient "
        "to medicines, and synonym to canonical name. Building this index relies on RxNorm's "
        "naming service, which is also the foundation of the medicine-name spell correction — the "
        "feature whose elegant solution was suggested by the evaluation panel head. When a "
        "medicine name is looked up, the system first attempts a normalized match that already "
        "tolerates plurals, case differences, and minor spelling variation; if that fails, it "
        "falls back to RxNorm's approximate-term matching, which returns the closest valid drug "
        "for a misspelled or informal name. This two-stage resolution means that a user who types "
        "a slightly wrong medicine name — whether in the chatbot or after a prescription scan — "
        "is still understood and served the correct information.")

    R.subsection("On-Demand Ingestion")
    R.p("MediAI pre-ingests a curated baseline of roughly two hundred of the most commonly "
        "prescribed and over-the-counter medicines, but it does not stop there. When a user asks "
        "about a drug that is not yet in the vector store, the system extracts the drug name from "
        "the question, fetches its label data live from DailyMed and OpenFDA, chunks and embeds "
        "it, and stores it — all within the same request — before retrying retrieval and "
        "answering. This on-demand ingestion is serialized so the same drug is never fetched "
        "twice concurrently, and names that genuinely do not exist on the public sources are "
        "remembered so the system does not repeatedly query for them. The practical effect is "
        "that the knowledge base grows to cover whatever users actually ask about, giving the "
        "assistant effectively unbounded coverage without an impractical bulk pre-fetch.")

    R.subsection("Grounded Generation and Citations")
    R.p("Once relevant context is retrieved, it is assembled into a bounded context block and "
        "passed, with the question and an intent-specific patient-friendly system prompt, to the "
        "LLM at a low temperature for factual, non-creative output. The prompt instructs the "
        "model to answer only from the provided context, to state explicitly when the context is "
        "insufficient, to refuse off-topic questions, to keep answers concise, to recommend "
        "professional consultation for serious symptoms, and never to provide prescriptions. The "
        "system detects when the model signals that it could not answer from the context and, in "
        "that case, attempts on-demand ingestion of the specific drug before giving up, after "
        "which it reports the answer as ungrounded so the client can fall back gracefully. "
        "Grounded answers are returned with source citations identifying the drug, the label "
        "section, and the source.")
    R.figure("ai pharmacist.jpeg", "AI Virtual Pharmacist chat screen with a grounded, cited answer")

    R.section("Symptom-Triage Engine")
    R.p("Layered on top of the stateless chatbot is a stateful symptom-triage engine that "
        "conducts safe, multi-turn assessments. An emergency-detection check runs on every "
        "message: certain phrases are always treated as emergencies, while others are treated as "
        "emergencies only when expressed in the first person and present tense rather than as "
        "general information questions. On any emergency the engine abandons the assessment "
        "immediately and returns urgent guidance, including the advice to contact local "
        "emergency services, with specialized handling for self-harm that points the user to "
        "crisis helplines.")
    R.p("For non-emergency symptoms the engine starts an assessment, asks a short series of "
        "structured questions one at a time, and records the answers in the conversation state. "
        "It then produces a patient-friendly summary, flags high severity or long duration, and "
        "asks the user's consent before offering any medication information. Crucially, "
        "conversation state takes precedence over intent classification at the consent step, so "
        "that an answer like \"tell me\" is correctly interpreted as consent rather than "
        "misread as a new drug lookup. When the user consents, the engine presents a curated set "
        "of over-the-counter options for that symptom and grounds each against the knowledge "
        "base for citations, deliberately avoiding raw symptom-to-drug semantic search because "
        "it is too noisy to be safe. The user can cancel the assessment at any time, and a "
        "clear topic switch to a medicine question abandons the assessment in favour of the "
        "normal pipeline.")
    R.figure("ai pharmacist (2).jpeg", "AI Virtual Pharmacist — symptom-triage conversation")

    R.section("Server-Side Coupon Engine")
    R.p("To guarantee that discounts can never be tampered with from the client, all coupon "
        "logic resides in the FastAPI backend, which is treated as the single source of truth "
        "for pricing. The coupon engine validates a coupon against a complete set of rules — "
        "active status, start and expiry dates, global usage limit, per-user limit, and minimum "
        "order amount — and only then computes the discount. Percentage and flat discounts are "
        "both supported, and the computed discount is capped so that it can never exceed the "
        "order subtotal. The engine exposes separate validation, application, and redemption "
        "operations, with redemption serving as the final server-side gate immediately before an "
        "order is placed to prevent race conditions and replay. Because the discount is always "
        "recomputed on the server, the client's displayed figures are advisory and the "
        "authoritative total is the one the server returns.")

    R.section("Administration Panel Implementation")
    R.p("The administration panel is a Flutter web application organized into the same "
        "feature-first structure as the mobile app. A persistent sidebar provides navigation "
        "between the dashboard and each management area, and reusable table and form widgets give "
        "the panel a consistent look and feel.")
    R.subsection("Dashboard and Analytics")
    R.p("The dashboard presents real-time operational metrics computed by its controller from "
        "Firestore data: the day's sales total, the average order value, the number of orders, "
        "the number of products sold, a breakdown of orders by status, a list of recent orders, "
        "and low-stock alerts for products at or below a stock threshold. The metrics can be "
        "exported to a spreadsheet for offline reporting.")
    R.figure("WhatsApp Image 2026-06-17 at 01.04.16.jpeg",
             "Admin dashboard with sales metrics, charts, and low-stock alerts")
    R.subsection("Catalog Management")
    R.p("Dedicated pages provide full create-read-update-delete management of categories, "
        "subcategories, brands, and products. Categories and subcategories carry featured and "
        "active toggles that control their visibility and prominence in the mobile app. Brands "
        "support assignment to multiple categories. Products are managed through a triple filter "
        "of search, category, and brand, with stock levels colour-coded for quick scanning and "
        "with featured and recommended flags controlling their placement. A separate page manages "
        "the recommended-products selection per category, and product images are uploaded to "
        "Firebase Storage.")
    R.figure("WhatsApp Image 2026-06-17 at 01.05.02.jpeg",
             "Product management page with triple filter and stock colour coding")
    R.subsection("Order, Customer, and Prescription Management")
    R.p("The orders page lists all orders and lets administrators advance each through its "
        "lifecycle from Pending to Processing, Shipped, and Delivered, and update its payment "
        "status, with cash orders marked paid automatically on delivery. The customers page "
        "lists customer profiles, their order histories, and loyalty points, and allows account "
        "removal. A prescription-requests area lets administrators review the prescription-backed "
        "medicine requests submitted by customers, inspecting the attached prescription image "
        "before approving or rejecting each request.")
    R.figure("WhatsApp Image 2026-06-17 at 01.05.23.jpeg",
             "Order management and prescription-request review pages")
    R.subsection("Promotions and Administrator Management")
    R.p("Administrators create and manage promotional banners — with images, redirect targets, "
        "active date ranges, and view/click tracking — and coupon campaigns with flat or "
        "percentage discounts, usage limits, and expiry dates that the server-side engine then "
        "enforces. The admins page lets a privileged administrator create additional "
        "administrator accounts. To avoid signing out the current administrator when creating a "
        "new one, the panel creates the new account through a secondary Firebase application "
        "instance, then records the new admin with its assigned role and active status.")
    R.figure("WhatsApp Image 2026-06-17 at 01.06.03.jpeg",
             "Admin panel — promotions and coupon management page")
    R.figure("WhatsApp Image 2026-06-17 at 01.06.38.jpeg",
             "Admin panel — administrator account management page")

    R.section("Notification Subsystem")
    R.p("MediAI uses two complementary notification channels. Local notifications, scheduled on "
        "the device, drive the safety-critical dose alarms and stock alerts; because they are "
        "local, they do not depend on connectivity and fire reliably even offline. Firebase "
        "Cloud Messaging drives push notifications such as coupon offers that originate from the "
        "server. The notification service centralizes the scheduling of alarms, the presentation "
        "of full-screen alerts, the re-scheduling of alarms on startup, the emission of one-time "
        "low-stock alerts, and the registration of the periodic background stock check, while a "
        "separate messaging service initializes push notifications at startup.")

    R.section("Security Implementation")
    R.p("Security is enforced primarily at the database layer through Firestore security rules. "
        "Helper predicates establish whether a caller is authenticated and whether a caller is an "
        "administrator by checking for the existence of a corresponding document in the Admins "
        "collection. Public catalog data such as categories, brands, and banners is readable by "
        "anyone but writable only by administrators. Each user's private data — their profile, "
        "cart, wishlist, notifications, medicines, and alarms — is readable and writable only by "
        "that user. Orders are creatable by the owning customer and manageable by administrators. "
        "This rule-based model ensures that even a malicious client cannot read another user's "
        "health data or modify the catalog, complementing the server-side coupon validation that "
        "protects pricing integrity.")

    R.section("User Interfaces")
    R.p("The user interfaces of MediAI were designed for clarity, consistency, and "
        "accessibility, following established usability heuristics. The customer application "
        "presents a clean home screen, an organized store, detailed product pages, a "
        "straightforward cart and checkout, an intuitive medication and stock area, and a "
        "conversational chat screen. The administration panel presents a dense but navigable "
        "dashboard and consistent management tables and forms. Representative screenshots of "
        "every screen described above are shown in the relevant sections throughout this "
        "chapter.")

    _code_walkthrough(R)

    R.section("Challenges and Solutions")
    R.p("Several substantial challenges arose during implementation, each of which prompted a "
        "concrete engineering solution.")
    R.subsection("Reliable Offline Alarms")
    R.p("Ensuring that dose alarms fire reliably even when the application is closed and the "
        "device is offline proved difficult, because operating systems aggressively limit "
        "background activity. The solution combined locally scheduled full-screen notifications "
        "with timezone-aware scheduling and a periodic background task, plus re-scheduling of all "
        "alarms from the local database on every startup so that no alarm is lost across "
        "restarts.")
    R.subsection("Offline-First Synchronization Conflicts")
    R.p("Reconciling local and cloud copies of medicine and alarm data without losing or "
        "duplicating records required careful design. The solution was an offline-queue table "
        "that coalesces conflicting operations on the same entity, a synced flag on each record, "
        "and last-write-wins conflict resolution driven by per-record update timestamps.")
    R.subsection("Preventing AI Hallucination")
    R.p("A general LLM will confidently invent pharmaceutical facts. The solution was the full "
        "RAG pipeline with a strict, evidence-only system prompt, a similarity threshold that "
        "discards weak context, detection of ungrounded answers, and a graceful fallback — so "
        "the assistant is grounded when it can be and honest about its limits when it cannot.")
    R.subsection("Medicine-Name Variability")
    R.p("Users and prescriptions routinely contain misspelled, abbreviated, or brand-named "
        "medicines. The solution, guided by the evaluation panel head, was a two-stage RxNorm "
        "resolution: a normalized match that tolerates minor spelling differences, backed by "
        "approximate-term matching that recovers the correct drug from a misspelling, together "
        "with a brand/generic/synonym index for instant canonicalization.")
    R.subsection("Discount Integrity")
    R.p("Trusting the client for discount calculations would expose the system to tampering. The "
        "solution was to move all coupon validation and discount computation to the backend and "
        "to re-validate at the moment of redemption, making the server the single source of "
        "truth for pricing.")
    R.subsection("Creating Admins Without Disrupting the Session")
    R.p("Creating a new administrator account through Firebase Authentication would normally sign "
        "the current administrator out. The solution was to perform the creation through a "
        "secondary Firebase application instance, leaving the acting administrator's session "
        "untouched.")
    R.p("Collectively, these solutions reflect the project's guiding priorities: reliability for "
        "safety-critical features, trustworthiness for AI behaviour, and integrity and security "
        "for commerce and data. The lessons learned — favour offline-first designs for "
        "critical features, ground AI in authoritative sources, and never trust the client for "
        "security-sensitive logic — informed the iterative refinement of the system into its "
        "final, robust form.")


def _code_walkthrough(R):
    R.section("Source-Code Walkthrough")
    R.p("This section presents annotated extracts of the actual source code of MediAI, grouped "
        "by subsystem. The listings are abridged for clarity but faithful to the implementation, "
        "and each is preceded by a short explanation of what it does and why it is written that "
        "way. Together they document the most important and instructive parts of the codebase.")

    R.subsection("Application Startup and Service Initialization")
    R.p("The application's entry point initializes services in a deliberate order so that the "
        "safety-critical reminder and stock features are armed as early as possible, then "
        "re-schedules all alarms from the local database after the first frame so they survive "
        "restarts. Listing 6.1 shows the core of this startup sequence.")
    R.code("Ordered service initialization in main.dart",
           "Future<void> main() async {\n"
           "  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();\n"
           "  await GetStorage.init();\n"
           "  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);\n"
           "  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)\n"
           "      .then((value) => Get.put(AuthenticationRepository()));\n"
           "  FirebaseAuth.instance.setLanguageCode('en');\n"
           "  // Notifications & alarms\n"
           "  await NotificationService.init();\n"
           "  await NotificationService.cacheInitialNotification();\n"
           "  // Offline-first connectivity monitoring + push notifications\n"
           "  await ConnectivityService.initialize();\n"
           "  await FCMNotificationService.init();\n"
           "  runApp(const App());\n"
           "  WidgetsBinding.instance.addPostFrameCallback((_) {\n"
           "    NotificationService.processPendingNotification();\n"
           "    NotificationService.scheduleAllFromLocal();   // survive restarts\n"
           "    NotificationService.checkAndSendStockAlerts();\n"
           "    NotificationService.registerBackgroundStockCheck();\n"
           "    SyncService.trySyncNow();                      // push pending changes\n"
           "  });\n"
           "}")

    R.subsection("Local Database Schema")
    R.p("The offline-first store is an on-device SQLite database. Listing 6.2 shows the creation "
        "of the three core tables — medicines, alarms, and the pending-changes offline queue — "
        "including the synchronization-metadata columns (synced and local_updated_at) that drive "
        "the sync engine.")
    R.code("SQLite schema creation in local_db.dart",
           "await db.execute('''\n"
           "  CREATE TABLE medicines(\n"
           "    uid TEXT, medId TEXT PRIMARY KEY,\n"
           "    medicine_name TEXT, disease_name TEXT DEFAULT '',\n"
           "    frequency TEXT, duration TEXT, start_date TEXT,\n"
           "    chronic INTEGER, total_no_of_doses INTEGER,\n"
           "    available_stock INTEGER, alert_before_days INTEGER DEFAULT 3,\n"
           "    synced INTEGER DEFAULT 0, local_updated_at INTEGER\n"
           "  )''');\n"
           "await db.execute('''\n"
           "  CREATE TABLE alarms(\n"
           "    alarmId TEXT PRIMARY KEY, uid TEXT, medId TEXT,\n"
           "    specific_dose TEXT, time_hour INTEGER, time_minute INTEGER,\n"
           "    duration TEXT, isActive INTEGER,\n"
           "    synced INTEGER DEFAULT 0, local_updated_at INTEGER\n"
           "  )''');\n"
           "await db.execute('''\n"
           "  CREATE TABLE pending_changes(\n"
           "    id INTEGER PRIMARY KEY AUTOINCREMENT,\n"
           "    operation_type TEXT NOT NULL, entity_type TEXT NOT NULL,\n"
           "    entity_id TEXT NOT NULL, entity_data TEXT,\n"
           "    timestamp INTEGER NOT NULL, synced INTEGER DEFAULT 0\n"
           "  )''');")

    R.subsection("Offline Queue and Bidirectional Synchronization")
    R.p("Every offline change is queued, and conflicting operations on the same entity are "
        "coalesced so that, for example, a delete followed by an update does not recreate a "
        "record on the server. Listing 6.3 shows the queueing logic, and Listing 6.4 shows the "
        "top-level bidirectional sync routine.")
    R.code("Coalescing offline operations in local_db.dart",
           "static Future<void> queuePendingChange({\n"
           "  required String operationType, required String entityType,\n"
           "  required String entityId, Map<String, dynamic>? entityData,\n"
           "}) async {\n"
           "  final db = await database;\n"
           "  // Remove earlier queued ops for this entity to avoid conflicts\n"
           "  await db.delete('pending_changes',\n"
           "      where: 'entity_type = ? AND entity_id = ?',\n"
           "      whereArgs: [entityType, entityId]);\n"
           "  await db.insert('pending_changes', {\n"
           "    'operation_type': operationType, 'entity_type': entityType,\n"
           "    'entity_id': entityId, 'entity_data': /* serialized */ null,\n"
           "    'timestamp': DateTime.now().millisecondsSinceEpoch, 'synced': 0,\n"
           "  });\n"
           "}")
    R.code("Bidirectional sync entry point in sync_service.dart",
           "static Future<void> syncAll() async {\n"
           "  if (_isSyncing) return;\n"
           "  final user = FirebaseAuth.instance.currentUser;\n"
           "  if (user == null) return;\n"
           "  _isSyncing = true;\n"
           "  try {\n"
           "    await _pushLocalChangesToFirebase(user.uid);  // local -> cloud\n"
           "    await _pullFirebaseChangesToLocal(user.uid);  // cloud -> local\n"
           "    await OfflineQueueService.clearProcessed();\n"
           "  } finally {\n"
           "    _isSyncing = false;\n"
           "  }\n"
           "}")

    R.subsection("Reliable Alarm Scheduling")
    R.p("Dose alarms are scheduled as timezone-aware, full-screen notifications. Chronic "
        "medicines repeat daily forever; non-chronic medicines schedule individual alarms within "
        "their date range. Listing 6.5 shows the chronic-medicine branch of the scheduler.")
    R.code("Timezone-aware alarm scheduling in notification_service.dart",
           "static Future<void> scheduleAlarm(int id, String title, String body,\n"
           "    int hour, int minute, {DateTime? startDate, DateTime? endDate,\n"
           "    bool isChronic = true, String? payload}) async {\n"
           "  final now = tz.TZDateTime.now(tz.local);\n"
           "  await _notificationsPlugin.cancel(id: id);\n"
           "  await _notificationsPlugin.cancel(id: id + 1);\n"
           "  if (isChronic || endDate == null) {\n"
           "    // CHRONIC: daily repeat forever (alarmClock mode = reliable)\n"
           "    await _scheduleDailyRepeat(id, title, body, hour, minute,\n"
           "        payload: payload);\n"
           "    return;\n"
           "  }\n"
           "  // NON-CHRONIC: schedule an alarm for each day in the range ...\n"
           "}")

    R.subsection("Background Stock Checking")
    R.p("A WorkManager background task runs periodically even when the app is killed, computing "
        "low-stock warnings with logic that differs for chronic and non-chronic medicines. "
        "Listing 6.6 shows the heart of this background dispatcher.")
    R.code("Background low-stock computation in notification_service.dart",
           "@pragma('vm:entry-point')\n"
           "void callbackDispatcher() {\n"
           "  Workmanager().executeTask((taskName, inputData) async {\n"
           "    final uid = inputData?['uid'] as String?;\n"
           "    if (uid == null) return Future.value(true);\n"
           "    final allMedicines = await LocalDB.getUserMedicines(uid);\n"
           "    for (var med in allMedicines) {\n"
           "      int currentStock = int.tryParse('${med['available_stock']}') ?? 0;\n"
           "      int alertDays  = int.tryParse('${med['alert_before_days']}') ?? 0;\n"
           "      bool isChronic = med['chronic'] == 1;\n"
           "      if (alertDays <= 0) continue;\n"
           "      if (currentStock != 0) {\n"
           "        if (!isChronic) {\n"
           "          int total = int.tryParse('${med['total_no_of_doses']}') ?? 0;\n"
           "          if (currentStock >= total) continue;   // course still covered\n"
           "        }\n"
           "        int freq = /* parse 'n/day' */ 1;\n"
           "        if (currentStock > freq * alertDays) continue;\n"
           "      }\n"
           "      // ... show 'Low Stock' / 'Out of stock' notification + log to Firestore\n"
           "    }\n"
           "    return Future.value(true);\n"
           "  });\n"
           "}")

    R.subsection("Linking Commerce to Adherence: Auto-Refill")
    R.p("When an order is delivered, the system replenishes the patient's tracked household "
        "stock for matching medicines, exactly once per order. Listing 6.7 shows the refill "
        "routine, which matches order items to medicines by a tolerant name comparison and uses "
        "a refilled-orders table for idempotency.")
    R.code("Idempotent delivered-order stock refill in order_controller.dart",
           "Future<void> _refillStockForDeliveredOrder(OrderModel order) async {\n"
           "  if (order.id.isEmpty) return;\n"
           "  if (await LocalDB.isOrderStockRefilled(order.id)) return;  // once only\n"
           "  final medicines = await LocalDB.getUserMedicines(uid);\n"
           "  for (final item in order.items) {\n"
           "    final perUnit = item.tabletsInPack > 0 ? item.tabletsInPack : 1;\n"
           "    final toAdd = item.quantity * perUnit;\n"
           "    final productName = item.productName.toLowerCase().trim();\n"
           "    for (final med in medicines) {\n"
           "      final medName = (med['medicine_name'] ?? '').toLowerCase().trim();\n"
           "      if (medName.contains(productName) || productName.contains(medName)) {\n"
           "        final stock = (med['available_stock'] as num? ?? 0).toInt();\n"
           "        await LocalDB.updateMedicineStats(med['medId'],\n"
           "            (med['total_no_of_doses'] as num? ?? 0).toInt(), stock + toAdd);\n"
           "        break;  // refill only the first matching medicine\n"
           "      }\n"
           "    }\n"
           "  }\n"
           "  await LocalDB.markOrderStockRefilled(order.id);\n"
           "}")

    R.subsection("Prescription OCR Extraction")
    R.p("The OCR utility sends a prescription photograph to a Gemini vision model with a strict "
        "prompt that requests structured JSON, and falls back to a lighter model if the primary "
        "is overloaded. Listing 6.8 shows the prompt and request construction.")
    R.code("Prescription extraction prompt in ocr_utils.dart",
           "final promptText = '''\n"
           "You are an expert medical assistant. Read this handwritten prescription image.\n"
           "Extract the prescribed medicines and return a JSON list of objects with keys:\n"
           "  medicine_name, disease_name, frequency, duration, start_date, chronic.\n"
           "If a field cannot be read, leave it as an empty string.''';\n"
           "final body = jsonEncode({\n"
           "  'contents': [{'parts': [\n"
           "    {'text': promptText},\n"
           "    {'inlineData': {'mimeType': 'image/jpeg', 'data': base64Image}},\n"
           "  ]}],\n"
           "  'generationConfig': {'temperature': 0.2,\n"
           "                       'responseMimeType': 'application/json'},\n"
           "});\n"
           "// Try gemini-2.5-flash, fall back to flash-lite on 429/500/503.")

    R.subsection("Hybrid Chatbot Client")
    R.p("The Flutter chat service first tries the grounded RAG endpoint and falls back to the "
        "general endpoint only when the answer is not grounded — while always passing triage and "
        "emergency replies straight through. Listing 6.9 shows this hybrid strategy.")
    R.code("Hybrid RAG-first chat client in chat_service.dart",
           "final ragResponse = await http.post(Uri.parse('$_baseUrl/chat/rag'),\n"
           "  headers: {'Content-Type': 'application/json'},\n"
           "  body: jsonEncode({'message': message, 'session_id': _sessionId}),\n"
           ").timeout(_timeout);\n"
           "if (ragResponse.statusCode == 200) {\n"
           "  final data = jsonDecode(ragResponse.body);\n"
           "  final ragUsed = data['rag_used'] ?? false;\n"
           "  final triageActive = data['triage_active'] ?? false;\n"
           "  final emergency = data['emergency'] ?? false;\n"
           "  final reply = (data['reply'] ?? '').trim();\n"
           "  if (reply.isNotEmpty && (ragUsed || triageActive || emergency)) {\n"
           "    return reply;   // grounded / triage / emergency -> use directly\n"
           "  }\n"
           "}\n"
           "// else fall through to the general /chat endpoint")

    R.subsection("Database-Layer Security Rules")
    R.p("Access control is enforced at the database layer. Listing 6.10 shows the helper "
        "predicates and a representative set of rules: public catalog read, admin-only writes, "
        "and strict per-user isolation of private data.")
    R.code("Firestore security rules (firestore.rules)",
           "function isAuth()  { return request.auth != null; }\n"
           "function isAdmin() { return isAuth() &&\n"
           "  exists(/databases/$(database)/documents/Admins/$(request.auth.uid)); }\n"
           "\n"
           "match /Products/{doc} {\n"
           "  allow read: if true;                 // public catalog\n"
           "  allow create, update, delete: if isAdmin();\n"
           "}\n"
           "match /Users/{uid} {\n"
           "  allow read, write: if isAuth() && request.auth.uid == uid;\n"
           "  match /{sub=**} {                    // cart, wishlist, medicines, alarms\n"
           "    allow read, write: if isAuth() && request.auth.uid == uid;\n"
           "  }\n"
           "}", lang="js")

    R.subsection("FastAPI Chat Endpoint and System Prompt")
    R.p("On the backend, the general chat endpoint constrains the LLM with a strict "
        "pharmaceutical-only system prompt. Listing 6.11 shows an abridged form of that prompt "
        "and the endpoint.")
    R.code("General chat endpoint and guardrail prompt in main.py",
           "SYSTEM_PROMPT = (\n"
           "  'You are a pharmaceutical assistant AI in the MediAI app. '\n"
           "  'Answer ONLY medicine/drug questions. If asked anything outside '\n"
           "  'pharmaceutical topics, reply EXACTLY: \"I can only assist with '\n"
           "  'pharmaceutical and medicine-related questions.\" Keep answers concise, '\n"
           "  'use bullet points, and for serious symptoms end with '\n"
           "  '\"Consult a healthcare professional for serious conditions.\"')\n"
           "\n"
           "@app.post('/chat', response_model=ChatResponse)\n"
           "async def chat(request: ChatRequest):\n"
           "    response = groq_client.chat.completions.create(\n"
           "        model='llama-3.3-70b-versatile',\n"
           "        messages=[{'role': 'system', 'content': SYSTEM_PROMPT},\n"
           "                  {'role': 'user', 'content': request.message}],\n"
           "        max_tokens=300, temperature=0.3)\n"
           "    return ChatResponse(reply=response.choices[0].message.content.strip())",
           lang="python")

    R.subsection("The RAG Pipeline")
    R.p("The grounded pipeline routes the query, retrieves context, ingests the drug on demand "
        "if nothing is found, and generates a grounded answer. Listing 6.12 shows the abridged "
        "pipeline.")
    R.code("Retrieval-augmented pipeline in chat_service.py",
           "def _rag_pipeline(user_query, top_k=TOP_K, min_score=MIN_SCORE,\n"
           "                  drug_filter=None, router_result=None):\n"
           "    if router_result is None:\n"
           "        router_result = route_query(user_query)\n"
           "    # Direct-lookup intents answered with no LLM call\n"
           "    if router_result.routed and router_result.answer:\n"
           "        return {'reply': router_result.answer, 'sources': [],\n"
           "                'rag_used': True, 'intent': router_result.intent.value}\n"
           "    chunks = retrieve_context(user_query, top_k=top_k, min_score=min_score,\n"
           "                 drug_filter=drug_filter,\n"
           "                 section_filter=router_result.section_filter)\n"
           "    if not chunks:                          # try on-demand ingestion\n"
           "        drug = _extract_drug_name(user_query)\n"
           "        if drug and _ingest_on_demand(drug):\n"
           "            chunks = retrieve_context(user_query, drug_filter=drug)\n"
           "    if not chunks:\n"
           "        return {'reply': _NO_CONTEXT_FALLBACK, 'sources': [],\n"
           "                'rag_used': False, 'intent': router_result.intent.value}\n"
           "    reply, grounded = _generate_grounded(user_query, chunks,\n"
           "                          intent=router_result.intent)\n"
           "    return {'reply': reply, 'sources': [...], 'rag_used': grounded, ...}",
           lang="python")

    R.subsection("On-Demand Drug Ingestion")
    R.p("When a question concerns a drug not yet indexed, the system fetches, chunks, embeds, "
        "and stores it live, with thread-safety and a not-found cache. Listing 6.13 shows the "
        "core of this routine.")
    R.code("Thread-safe on-demand ingestion in chat_service.py",
           "_ingest_lock = threading.Lock()\n"
           "_not_found_cache = set()\n"
           "\n"
           "def _ingest_on_demand(drug):\n"
           "    drug = (drug or '').lower().strip()\n"
           "    if not drug or drug in _not_found_cache: return False\n"
           "    if drug_exists(drug): return True\n"
           "    with _ingest_lock:\n"
           "        if drug_exists(drug): return True\n"
           "        stored = ingest_drug(drug)   # DailyMed + OpenFDA -> embed -> store\n"
           "        if stored > 0: return True\n"
           "        _not_found_cache.add(drug)    # avoid hammering public APIs\n"
           "        return False",
           lang="python")

    R.subsection("Query Routing and Direct Lookups")
    R.p("Brand/generic and ingredient questions are answered straight from the pharmaceutical "
        "index without the LLM. Listing 6.14 shows the routing decision.")
    R.code("Direct-lookup routing in query_router.py",
           "def route_query(query):\n"
           "    ir = classify(query)                 # intent + entity\n"
           "    plan = get_route(ir.intent)          # strategy + source hints\n"
           "    if plan.strategy == STRATEGY_SYMPTOM_WORKFLOW:\n"
           "        return RouterResult(intent=ir.intent, routed=False, entity=ir.entity)\n"
           "    if plan.strategy == STRATEGY_DIRECT_LOOKUP:\n"
           "        direct = _try_direct_lookup(ir)  # from PharmaIndex, no LLM\n"
           "        if direct is not None: return direct\n"
           "    return RouterResult(intent=ir.intent,\n"
           "        section_filter=plan.section_filter,\n"
           "        source_filter=plan.source_filter, routed=False)",
           lang="python")

    R.subsection("Medicine-Name Spell Correction")
    R.p("Name resolution first tries a normalized RxNorm match that tolerates minor spelling, "
        "then falls back to approximate matching — the panel-suggested solution to misspelled "
        "medicine names. Listing 6.15 shows this two-stage lookup.")
    R.code("Two-stage RxNorm name resolution in rxnorm.py",
           "def fetch_rxcui(drug_name):\n"
           "    # 1) Normalised match (handles plurals, case, minor spelling)\n"
           "    data = _get(f'{_RXNORM_BASE}/rxcui.json',\n"
           "                params={'name': drug_name, 'search': 1})\n"
           "    if data and data.get('idGroup', {}).get('rxnormId'):\n"
           "        return data['idGroup']['rxnormId'][0]\n"
           "    # 2) Approximate match for misspelled / informal names\n"
           "    data = _get(f'{_RXNORM_BASE}/approximateTerm.json',\n"
           "                params={'term': drug_name, 'maxEntries': 1})\n"
           "    cands = data.get('approximateGroup', {}).get('candidate', []) if data else []\n"
           "    return cands[0].get('rxcui') if cands else None",
           lang="python")

    R.subsection("Pharmaceutical Index Lookups")
    R.p("The persistent index resolves brand names, synonyms, and generics to a canonical name. "
        "Listing 6.16 shows the resolution method.")
    R.code("Canonical name resolution in pharma_index.py",
           "def get_generic(self, name):\n"
           "    key = name.lower().strip()\n"
           "    with self._lock:\n"
           "        drug = self._data['drugs'].get(key)\n"
           "        if drug: return drug.get('generic_name', key)\n"
           "        generic = self._data['brand_to_generic'].get(key)\n"
           "        if generic: return generic\n"
           "        return self._data['synonym_to_medicine'].get(key)",
           lang="python")

    R.subsection("Emergency Detection")
    R.p("Before any triage, an emergency check runs on every message. Always-urgent phrases fire "
        "regardless of phrasing; gated phrases fire only with first-person, present-tense framing "
        "that is not an information question. Listing 6.17 shows the detector.")
    R.code("Emergency detection in symptom_triage.py",
           "def detect_emergency(message):\n"
           "    if not message: return None\n"
           "    text = message.lower()\n"
           "    for category, patterns in _EMERGENCY_ALWAYS.items():\n"
           "        for pat in patterns:\n"
           "            if re.search(pat, text): return category\n"
           "    # Gated: require first-person framing AND not an info query\n"
           "    if _RX_FIRST_PERSON_EMERG.search(text) and not _RX_INFO_QUERY.search(text):\n"
           "        for category, patterns in _EMERGENCY_GATED.items():\n"
           "            for pat in patterns:\n"
           "                if re.search(pat, text): return category\n"
           "    return None",
           lang="python")

    R.subsection("Triage Consent Parsing")
    R.p("At the medication-consent step, conversation state takes precedence over intent "
        "classification, so replies like 'tell me' count as yes. Negatives are checked first so "
        "'no thanks' is not caught by a stray yes token. Listing 6.18 shows the parser.")
    R.code("Affirmative/negative parsing in symptom_triage.py",
           "def _is_affirmative(message):\n"
           "    if _RX_NO.search(message):  return False   # 'no thanks', 'maybe later'\n"
           "    if _RX_YES.search(message): return True    # 'tell me', 'go ahead', 'sure'\n"
           "    return None                                # unclear -> re-ask",
           lang="python")

    R.subsection("Server-Authoritative Coupon Validation")
    R.p("All discount logic lives on the server. Listing 6.19 shows the stateless rule check, "
        "and Listing 6.20 shows the discount calculation that caps the discount at the subtotal.")
    R.code("Coupon rule validation in validator.py",
           "def _validate_coupon_rules(coupon, order_subtotal, user_redemption_count):\n"
           "    now = _now_utc()\n"
           "    if not coupon.is_active:\n"
           "        return False, ERR_INACTIVE, 'This coupon is no longer active.'\n"
           "    if coupon.start_date and now < coupon.start_date:\n"
           "        return False, ERR_NOT_STARTED, 'This coupon is not yet valid.'\n"
           "    if coupon.end_date and now > coupon.end_date:\n"
           "        return False, ERR_EXPIRED, 'This coupon has expired.'\n"
           "    if coupon.usage_limit > 0 and coupon.usage_count >= coupon.usage_limit:\n"
           "        return False, ERR_USAGE_LIMIT, 'Usage limit reached.'\n"
           "    if coupon.per_user_limit > 0 and \\\n"
           "       user_redemption_count >= coupon.per_user_limit:\n"
           "        return False, ERR_PER_USER_LIMIT, 'Per-user limit reached.'\n"
           "    if coupon.min_order_amount > 0 and order_subtotal < coupon.min_order_amount:\n"
           "        return False, ERR_MIN_ORDER, 'Minimum order amount not met.'\n"
           "    return True, '', 'Coupon is valid.'",
           lang="python")
    R.code("Discount calculation capped at subtotal in validator.py",
           "def _calculate_discount(coupon, order_subtotal):\n"
           "    if coupon.type == DiscountType.PERCENTAGE:\n"
           "        discount = order_subtotal * (coupon.discount_value / 100.0)\n"
           "    else:\n"
           "        discount = float(coupon.discount_value)\n"
           "    return min(discount, order_subtotal)   # never exceed the subtotal",
           lang="python")
    R.p("These listings together evidence the engineering discipline behind MediAI: offline-first "
        "data with disciplined synchronization, reliable timezone-aware alarms, an "
        "idempotent commerce-to-adherence link, a grounded and safety-gated AI layer with "
        "on-demand learning and spell-tolerant name resolution, and server-authoritative pricing "
        "behind database-enforced access control.")
