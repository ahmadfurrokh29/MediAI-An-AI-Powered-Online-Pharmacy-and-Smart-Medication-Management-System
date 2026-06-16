# -*- coding: utf-8 -*-
def build(R):
    R.chapter("Requirement Analysis")
    R.p("This chapter translates the problem definition into a concrete set of requirements. It "
        "begins by stating the assumptions and prerequisites placed on the different categories "
        "of users, then describes the key features of the system, enumerates the functional and "
        "non-functional requirements, presents the toolchain and technology workflow, and "
        "finally models the system's behaviour through a comprehensive set of use cases. The "
        "requirement analysis followed an iterative process: requirements were refined "
        "repeatedly as prototypes were built and evaluated, with each iteration testing the "
        "current design against the goals of reliability, trustworthiness, security, and "
        "usability established in Chapter 3.")

    R.section("Assumptions and Prerequisites")
    R.p("MediAI serves several categories of users, each with its own assumptions and "
        "prerequisites. Understanding these is essential to scoping the requirements correctly.")

    R.subsection("Customer (Patient)")
    R.p("The customer is the primary user of the mobile application. It is assumed that the "
        "customer owns a smartphone capable of running the application and can create an account "
        "using an email address or a Google or Facebook identity. The customer is assumed to be "
        "responsible for entering accurate information about their own medicines, whether "
        "manually or by confirming the output of a prescription scan, and for keeping their "
        "household stock figure up to date when they obtain medicines outside the platform. The "
        "customer is assumed to have intermittent rather than constant internet connectivity, "
        "which is precisely why the reminder and stock features are engineered to work offline. "
        "Customers agree, at registration, to terms that make clear the application provides "
        "informational guidance and convenience tooling and is not a substitute for professional "
        "medical advice.")

    R.subsection("Administrator / Pharmacist")
    R.p("The administrator operates the web administration panel and is assumed to be a trusted "
        "operator of the pharmacy — for example a pharmacist or store manager. Administrators "
        "must authenticate with credentials that are recognized as belonging to the Admins "
        "collection, and their access to data is governed by role-based security rules. The "
        "system distinguishes between higher-privilege administrators who can manage other admin "
        "accounts and lower-privilege staff who perform day-to-day catalog and order operations. "
        "Administrators are responsible for maintaining an accurate catalog, processing orders "
        "honestly and promptly, and reviewing prescription requests responsibly.")

    R.subsection("System (Automated Background Actor)")
    R.p("Several responsibilities are discharged automatically by the system itself, acting as a "
        "background actor with no human in the loop. The system schedules and fires reminders, "
        "monitors connectivity, synchronizes local and cloud data, checks stock levels "
        "periodically, queues offline operations for later processing, and pushes coupon offers. "
        "These automated behaviours are first-class requirements and are modelled explicitly in "
        "the use cases.")

    R.section("Key Features of the System")
    R.subsection("System Overview")
    R.p("MediAI is an integrated digital-pharmacy platform that spans the complete medication "
        "lifecycle. Its features are organized into commerce, adherence, intelligence, and "
        "administration. The following subsections describe the key features that constitute the "
        "foundational capabilities of the platform.")

    R.subsection("Secure Authentication and Account Management")
    R.p("The platform provides secure account creation and sign-in through email and password, "
        "Google, and Facebook, backed by Firebase Authentication. It supports email "
        "verification, password reset, and persistent sessions, and it distinguishes customer "
        "accounts from administrator accounts so that each is routed to the appropriate "
        "experience and granted the appropriate permissions. Personal profile information, "
        "including multiple shipping addresses, is managed securely and is accessible only to "
        "its owner.")

    R.subsection("Online Pharmacy (E-Commerce Module)")
    R.p("The commerce module is a complete online pharmacy. Customers browse a catalog organized "
        "by categories, subcategories, and brands; search and filter products; view detailed "
        "product pages with images, formula names, descriptions, stock status, and customer "
        "reviews; save items to a wishlist; and add items to a cart with quantity controls. The "
        "checkout flow lets the customer choose a shipping address, apply a coupon, select a "
        "payment method, and place an order, after which the order can be tracked through its "
        "lifecycle. Promotional banners and recommended products surface relevant items on the "
        "home screen.")

    R.subsection("Prescription Upload with OCR")
    R.p("Rather than typing each medicine by hand, a customer can photograph a prescription and "
        "let the system read it. A vision-language model extracts the prescribed medicines along "
        "with their dosage frequency, duration, and the condition being treated, and pre-fills "
        "the medication form. The original prescription image is stored alongside the medicines "
        "so that it can be retrieved later, for example when re-ordering. The customer always "
        "reviews and confirms the extracted information before it is saved.")

    R.subsection("Medicine Reminder and Alarm System")
    R.p("For every medicine, the customer can configure one or more daily alarms tied to "
        "specific doses. When an alarm fires, a full-screen alert appears even if the application "
        "is closed, allowing the customer to mark the dose as taken, snooze it, or dismiss it. "
        "Alarms are scheduled through the operating system's local-notification and "
        "background-task facilities so that they are reliable offline and survive device "
        "restarts. Marking a dose as taken automatically decrements the household stock.")

    R.subsection("Stock Management and Auto-Refill")
    R.p("Each medicine carries a household stock figure and an alert threshold. As doses are "
        "taken, stock is decremented automatically; when it falls to or below the configured "
        "threshold, the customer is warned and prompted to re-order. The stock-management screen "
        "presents a clear, colour-coded overview of which medicines are out of stock, running "
        "low, or sufficient. Crucially, the commerce and adherence modules are linked: when an "
        "order containing tracked medicines is delivered, the corresponding household stock is "
        "automatically replenished, closing the loop between buying and taking medicine.")

    R.subsection("AI Virtual Pharmacist (RAG Chatbot)")
    R.p("The AI Virtual Pharmacist answers medicine-related questions through a "
        "Retrieval-Augmented Generation pipeline grounded in authoritative drug labels. It "
        "resolves brand and generic names, tolerates misspellings, fetches and indexes new "
        "drugs on demand, refuses to answer outside the pharmaceutical domain or without "
        "evidence, and cites its sources. A stateful symptom-triage engine conducts safe, "
        "multi-turn symptom assessments and escalates immediately upon detecting an emergency.")

    R.subsection("Admin / Pharmacist Management Panel")
    R.p("The web administration panel gives operators a real-time dashboard and complete control "
        "over the platform: managing categories, subcategories, brands, and products; processing "
        "orders and updating their status; managing customers; creating promotional banners and "
        "coupon campaigns; reviewing prescription requests submitted by customers; and managing "
        "other administrator accounts with role-based privileges.")

    R.section("Functional Requirements")
    R.p("This section enumerates the functional requirements — the specific behaviours the "
        "system must exhibit. They are grouped by module and assigned identifiers for "
        "traceability to the use cases and test cases in later chapters.")

    fr_rows = [
        ["FR-1", "Authentication", "The system shall allow users to register and sign in via email/password, Google, and Facebook, with email verification and password reset."],
        ["FR-2", "Authentication", "The system shall distinguish customer and administrator roles and route each to the appropriate interface and permissions."],
        ["FR-3", "Catalog", "The system shall let customers browse products by category, subcategory, and brand, and search and filter the catalog."],
        ["FR-4", "Catalog", "The system shall display product details including images, formula name, description, price, stock status, and reviews."],
        ["FR-5", "Cart", "The system shall let customers add, update the quantity of, and remove items from a cart that is persisted per user."],
        ["FR-6", "Wishlist", "The system shall let customers save and remove products from a wishlist."],
        ["FR-7", "Checkout", "The system shall let customers select a shipping address, apply a coupon, choose a payment method, and place an order."],
        ["FR-8", "Coupons", "The system shall validate every coupon and recompute every discount on the server before an order is accepted."],
        ["FR-9", "Orders", "The system shall record orders and allow customers to view order history and track order status."],
        ["FR-10", "Reviews", "The system shall let customers submit ratings and reviews for products."],
        ["FR-11", "Prescription OCR", "The system shall extract medicines, frequency, duration, and condition from a photographed prescription and pre-fill the medication form for confirmation."],
        ["FR-12", "Reminders", "The system shall let customers create dose alarms and shall fire full-screen alarms at scheduled times even when offline or after a restart."],
        ["FR-13", "Reminders", "The system shall allow a fired alarm to be taken, snoozed, or dismissed, decrementing stock when a dose is taken."],
        ["FR-14", "Stock", "The system shall track household stock per medicine and warn the customer when stock reaches the alert threshold."],
        ["FR-15", "Stock", "The system shall automatically replenish tracked household stock when a corresponding order is delivered."],
        ["FR-16", "AI Chatbot", "The system shall answer medicine questions grounded in authoritative drug labels and shall refuse to answer outside the pharmaceutical domain or without evidence."],
        ["FR-17", "AI Chatbot", "The system shall resolve brand/generic names, tolerate misspellings, and ingest unknown drugs on demand."],
        ["FR-18", "AI Triage", "The system shall conduct safe multi-turn symptom assessments and shall immediately escalate when an emergency is detected."],
        ["FR-19", "Sync", "The system shall queue offline changes and synchronize medicine and alarm data bidirectionally with the cloud, resolving conflicts by timestamp."],
        ["FR-20", "Admin", "The system shall provide a dashboard with real-time sales, order, and stock metrics, exportable to a spreadsheet."],
        ["FR-21", "Admin", "The system shall allow administrators to perform full CRUD on categories, subcategories, brands, products, banners, and coupons."],
        ["FR-22", "Admin", "The system shall allow administrators to update order and payment status and to review prescription requests."],
        ["FR-23", "Admin", "The system shall allow privileged administrators to create and manage other administrator accounts with assigned roles."],
        ["FR-24", "Notifications", "The system shall send local notifications for reminders and stock alerts and push notifications for coupon offers."],
    ]
    R.table("Functional Requirements", ["ID", "Module", "Requirement"], fr_rows,
            col_widths=[0.6, 1.2, 4.47], font_size=9)

    R.section("Non-Functional Requirements")
    R.p("Non-functional requirements describe the quality attributes the system must satisfy. "
        "While the functional requirements specify what the system does, these specify how well "
        "it must do it.")
    nfr_rows = [
        ["NFR-1", "Reliability", "Safety-critical reminders and stock alerts shall function offline and survive application closure and device restarts."],
        ["NFR-2", "Performance", "Catalog browsing and cart operations shall feel instantaneous through reactive state and denormalized data; cached drug answers shall return within a few seconds."],
        ["NFR-3", "Scalability", "The architecture shall scale with usage through Firebase's managed services and an AI knowledge base that grows on demand rather than by bulk pre-fetch."],
        ["NFR-4", "Security", "All discounts and prices shall be validated server-side; data access shall be governed by role-based Firestore rules; credentials shall be managed by Firebase Authentication."],
        ["NFR-5", "Privacy", "Each user shall access only their own private data; health and personal data shall not be exposed to other users."],
        ["NFR-6", "Safety", "The AI shall never provide diagnoses, shall refuse unsupported or off-topic questions, and shall escalate emergencies immediately."],
        ["NFR-7", "Usability", "The interface shall follow established usability heuristics with clear feedback, confirmation prompts, legible typography, and high-contrast presentation."],
        ["NFR-8", "Maintainability", "The system shall follow a clean, layered architecture with separated concerns and a repository pattern to ease extension and maintenance."],
        ["NFR-9", "Portability", "The client shall run from a single Flutter codebase across Android and other supported platforms; the web panel shall run in modern browsers."],
        ["NFR-10", "Consistency", "Local and cloud data shall converge through deterministic synchronization and timestamp-based conflict resolution."],
    ]
    R.table("Non-Functional Requirements", ["ID", "Attribute", "Requirement"], nfr_rows,
            col_widths=[0.7, 1.3, 4.27], font_size=9)

    R.section("Toolchain and Technology Workflow")
    R.p("MediAI is built from a carefully chosen toolchain in which each technology addresses a "
        "specific need. The customer application and administration panel are built with Flutter "
        "and Dart, using GetX for reactive state management and dependency injection. The AI "
        "backend is built with FastAPI in Python, serving the chatbot and coupon engine over "
        "JSON HTTP. The chatbot grounds its answers using a sentence-embedding model and the "
        "ChromaDB vector store, with the underlying language generation performed by an "
        "instruction-tuned LLM served through Groq. Drug information is sourced from DailyMed, "
        "OpenFDA, and RxNorm. Prescriptions are read by a Gemini vision model. Firebase provides "
        "authentication, the Firestore database, media storage, and push messaging, while SQLite "
        "provides the offline-first local store on the device. Figure 4.1 illustrates how these "
        "technologies fit together, and the high-level component view in Figure 4.2 shows the "
        "request and data flows between the application layers.")
    R.figure("fig_toolchain.png", "Toolchain and Technology Workflow", width=6.2)
    R.figure("fig_component.png", "High-Level Component and Data-Flow Diagram", width=6.2)
    R.p("The typical request flow is as follows. The Flutter client renders the interface and "
        "holds reactive state in GetX controllers. Commerce and profile operations read from and "
        "write to Firestore directly through the repository layer, subject to security rules. "
        "Reminder and stock operations are written first to the local SQLite database and queued "
        "for later synchronization. Chatbot queries are sent to the FastAPI backend, which "
        "classifies intent, retrieves grounding context from ChromaDB, calls the LLM, and "
        "returns a grounded answer with citations. Coupon validation is likewise delegated to "
        "the backend so that no discount is ever trusted from the client. This separation keeps "
        "each concern in the layer best suited to it and underpins the system's reliability and "
        "security guarantees.")

    R.section("Use Cases")
    R.p("This section models the system's behaviour through a set of use cases covering the full "
        "lifecycle of customer and administrator interaction. The use cases are summarized in "
        "the use-case diagram of Figure 4.3 and then detailed individually in tabular form. Each "
        "use case records its identifier, the actors involved, preconditions, the basic flow of "
        "events, and postconditions.")
    R.figure("fig_usecase.png", "MediAI Use-Case Diagram", width=6.2)

    _use_cases(R)


def _uc(R, ucid, name, desc, actors, pre, flow, post):
    rows = [
        ["Use Case ID", ucid],
        ["Use Case Name", name],
        ["Description", desc],
        ["Actors", actors],
        ["Preconditions", pre],
        ["Basic Flow", flow],
        ["Postconditions", post],
    ]
    R.usecase_table(name, ucid, rows)


def _use_cases(R):
    _uc(R, "UC-1", "Register and Login",
        "A new user creates an account or an existing user signs in to access the platform.",
        "Customer, System",
        "1. The application is installed. 2. The user has an email address or a Google/Facebook account.",
        "1. The user opens the app and chooses to register or sign in. 2. The user supplies "
        "credentials or selects a social provider. 3. The system authenticates via Firebase "
        "Authentication. 4. On first registration, a user profile document is created. 5. The "
        "user is routed to the home screen.",
        "The user is authenticated and a session is established; the profile exists in Firestore.")

    _uc(R, "UC-2", "Browse and Search Medicines",
        "A customer explores the catalog by category, brand, or search to find medicines.",
        "Customer, System",
        "1. The user is signed in. 2. The catalog contains active products.",
        "1. The user opens the home or store screen. 2. The user selects a category, brand, or "
        "enters a search term. 3. The system queries Firestore and returns matching products. "
        "4. Results are displayed with images, price, and stock status.",
        "The customer views a filtered list of products relevant to their query.")

    _uc(R, "UC-3", "View Product Details and Reviews",
        "A customer inspects a product's full details and customer reviews before deciding to buy.",
        "Customer, System",
        "1. A product exists and is active.",
        "1. The user taps a product. 2. The system loads the product details, image carousel, "
        "formula name, description, price, stock, and reviews. 3. The user reads the information "
        "and reviews.",
        "The customer has the information needed to make a purchase decision.")

    _uc(R, "UC-4", "Manage Cart and Wishlist",
        "A customer adds items to the cart or wishlist and adjusts quantities.",
        "Customer, System",
        "1. The user is signed in. 2. The selected product is in stock.",
        "1. The user adds a product to the cart or wishlist. 2. The system updates the reactive "
        "state and persists the change to the user's cart/wishlist subcollection. 3. The user "
        "may change quantities or remove items.",
        "The cart and wishlist reflect the user's selections and are persisted across sessions.")

    _uc(R, "UC-5", "Checkout and Place Order",
        "A customer completes a purchase by selecting an address, applying a coupon, choosing "
        "payment, and placing the order.",
        "Customer, System",
        "1. The cart contains at least one item. 2. The user has a shipping address.",
        "1. The user proceeds to checkout. 2. The system computes subtotal, shipping, and tax. "
        "3. The user selects an address and optionally enters a coupon. 4. The system validates "
        "the coupon and recomputes the discount on the server. 5. The user chooses a payment "
        "method and confirms. 6. The system creates an order document and clears the cart.",
        "An order is recorded with status Pending; the cart is emptied; the user sees a success "
        "screen.")

    _uc(R, "UC-6", "Track Orders",
        "A customer views the status and details of their past and current orders.",
        "Customer, System",
        "1. The user has placed at least one order.",
        "1. The user opens the orders screen. 2. The system loads the user's orders from "
        "Firestore. 3. The user selects an order to view its items, totals, and current status.",
        "The customer is informed of the progress of their orders.")

    _uc(R, "UC-7", "Add Medicine via Manual Entry or OCR",
        "A customer adds a medicine to their schedule either by typing the details or by "
        "scanning a prescription.",
        "Customer, System, OCR Service",
        "1. The user is signed in. 2. For OCR, the user has a photograph of a prescription.",
        "1. The user chooses to add a medicine manually or by scanning. 2. For OCR, the system "
        "sends the image to the vision model and receives structured medicine data. 3. The "
        "medication form is pre-filled or left blank for manual entry. 4. The user confirms the "
        "details and sets alarms. 5. The system saves the medicine and alarms to SQLite and "
        "queues them for sync.",
        "The medicine and its alarms are stored locally and scheduled; the prescription image is "
        "retained if provided.")

    _uc(R, "UC-8", "Receive and Respond to Dose Alarm",
        "The system alerts the customer at a scheduled dose time and the customer responds.",
        "Customer, System",
        "1. An active alarm is scheduled for the current time.",
        "1. The system fires a full-screen alarm at the scheduled time, even if the app is "
        "closed. 2. The user marks the dose as taken, snoozes, or dismisses it. 3. If taken, the "
        "system decrements the household stock and checks the alert threshold.",
        "The dose is acknowledged; stock is updated; a low-stock alert is raised if necessary.")

    _uc(R, "UC-9", "Manage Medicine Stock",
        "A customer views and updates the household stock of their medicines.",
        "Customer, System",
        "1. The user has at least one medicine.",
        "1. The user opens the stock-management screen. 2. The system displays medicines "
        "colour-coded by stock status. 3. The user updates a stock quantity or alert threshold. "
        "4. The system saves the change and re-evaluates alerts.",
        "Stock figures and thresholds are updated; alerts reflect the new values.")

    _uc(R, "UC-10", "Consult the AI Pharmacist",
        "A customer asks the AI pharmacist a medicine-related question and receives a grounded "
        "answer.",
        "Customer, System, AI Backend",
        "1. The user is signed in. 2. The AI backend is reachable.",
        "1. The user types a question. 2. The client sends it to the RAG endpoint with a session "
        "id. 3. The backend checks for emergencies, classifies intent, retrieves grounding "
        "context (ingesting the drug on demand if needed), and calls the LLM. 4. A grounded "
        "answer with citations is returned, or the client falls back to the general endpoint if "
        "ungrounded.",
        "The customer receives a trustworthy, source-cited answer or a safe refusal.")

    _uc(R, "UC-11", "Symptom Triage",
        "A customer describes symptoms and the system conducts a safe, structured assessment.",
        "Customer, System, AI Backend",
        "1. The user is signed in. 2. The AI backend is reachable.",
        "1. The user describes a symptom. 2. The backend detects no emergency and starts a "
        "triage session. 3. It asks structured follow-up questions one at a time. 4. It "
        "summarizes findings and offers general medication information only with consent. 5. If "
        "an emergency is detected at any point, it abandons triage and returns urgent guidance.",
        "The customer receives structured, safe guidance and, with consent, grounded medication "
        "information.")

    _uc(R, "UC-12", "Request Prescription Medicine",
        "A customer submits a request for a medicine that requires a prescription, attaching the "
        "prescription for admin review.",
        "Customer, System, Admin",
        "1. The user is signed in. 2. The user has a prescription image.",
        "1. The user opens the prescription-request screen and submits details with an image. "
        "2. The system records the request for administrative review. 3. An administrator "
        "reviews and approves or rejects it.",
        "A prescription request is recorded and routed to administrators for review.")

    _uc(R, "UC-13", "Administer Catalog",
        "An administrator manages categories, subcategories, brands, and products.",
        "Admin, System",
        "1. The administrator is authenticated and authorized.",
        "1. The admin opens the relevant management page. 2. The admin creates, edits, or "
        "deletes records and toggles featured/active flags. 3. The system validates and persists "
        "the changes to Firestore.",
        "The catalog reflects the administrator's changes in real time across the platform.")

    _uc(R, "UC-14", "Process Orders",
        "An administrator advances orders through their lifecycle and updates payment status.",
        "Admin, System",
        "1. Orders exist. 2. The administrator is authorized.",
        "1. The admin opens the orders page. 2. The admin updates an order's status (Pending → "
        "Processing → Shipped → Delivered) and payment status. 3. The system persists the change "
        "and, on delivery, triggers downstream effects such as stock refill on the customer side.",
        "Order and payment statuses are updated; customers see the new status.")

    _uc(R, "UC-15", "Manage Promotions",
        "An administrator creates and manages promotional banners and coupon campaigns.",
        "Admin, System",
        "1. The administrator is authorized.",
        "1. The admin creates a banner or coupon with its parameters (discount type, value, "
        "limits, dates). 2. The system stores it. 3. Coupons are validated server-side at "
        "checkout; banners are displayed within their active date range.",
        "Active promotions are available to customers and enforced by the server.")

    _uc(R, "UC-16", "Manage Administrators",
        "A privileged administrator creates and manages other administrator accounts.",
        "Admin (privileged), System",
        "1. The acting administrator has sufficient privileges.",
        "1. The admin opens the admins page and creates a new admin via a secondary Firebase "
        "app instance (so the current session is not disturbed). 2. A role is assigned. 3. The "
        "system records the admin account and its active status.",
        "A new administrator account exists with the assigned role and privileges.")

    _uc(R, "UC-17", "Synchronize Data (System)",
        "The system synchronizes local SQLite data with Firestore when connectivity allows.",
        "System",
        "1. There are pending local changes or remote updates. 2. Connectivity is available.",
        "1. The connectivity service detects a connection. 2. The sync service pushes queued "
        "local changes to Firestore. 3. It pulls remote changes and merges them into SQLite. "
        "4. Conflicts are resolved using update timestamps.",
        "Local and cloud data converge to a consistent state.")
