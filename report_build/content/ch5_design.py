# -*- coding: utf-8 -*-
def build(R):
    R.chapter("Design and Architecture")
    R.p("The design phase translates the requirements of Chapter 4 into a structured blueprint "
        "for implementation. This chapter presents the architecture of MediAI and models its "
        "structure and behaviour through a set of complementary diagrams: a layered "
        "system-architecture diagram, an entity-relationship diagram of the data model, a "
        "flowchart of the reminder-and-stock workflow, a sequence diagram of the AI chatbot "
        "interaction, and an activity diagram of the e-commerce order process. Together these "
        "views capture the system's static structure, its data, and its dynamic behaviour, and "
        "they serve as the bridge between the abstract requirements and the concrete "
        "implementation described in Chapter 6.")

    R.section("Architectural Overview")
    R.p("MediAI follows a clean, layered architecture with a clear separation of concerns. The "
        "presentation layer comprises the Flutter customer application and the Flutter web "
        "administration panel. The application layer holds the GetX controllers and the business "
        "logic that coordinate features. The data layer abstracts the data sources behind a "
        "repository pattern and spans both local storage (SQLite and key-value storage) and "
        "cloud storage (Firebase Firestore, Authentication, and Storage), as well as the AI "
        "knowledge base (the ChromaDB vector store and the pharmaceutical index). A dedicated AI "
        "service layer, implemented as a FastAPI backend, hosts the chatbot, the RAG pipeline, "
        "the symptom-triage engine, and the coupon engine. Finally, a background-services layer "
        "runs the notification, synchronization, connectivity, offline-queue, and stock-alert "
        "services that keep the system reliable and consistent. Figure 5.1 shows this layered "
        "architecture.")
    R.figure("fig_architecture.png", "MediAI Layered System Architecture", width=6.3)
    R.p("This layering yields several benefits. It isolates the user interface from the data "
        "sources, so that, for example, the reminder feature can read from SQLite while the "
        "catalog reads from Firestore without either being aware of the other's storage. It "
        "concentrates safety-critical logic in dedicated background services that continue to "
        "function independently of the user interface. And it places trust-sensitive logic — "
        "discount validation and AI grounding — in the backend service layer, where it cannot be "
        "tampered with from the client.")

    R.section("Data Model and Entity-Relationship Design")
    R.p("MediAI's data is distributed across two complementary stores. Firestore is the cloud "
        "system of record for commerce and profile data and the cloud backup for medical data, "
        "while SQLite is the offline-first source of truth for medicines, alarms, and the "
        "synchronization queue. Figure 5.2 presents the entity-relationship diagram spanning "
        "both stores, including the bidirectional synchronization between the SQLite and "
        "Firestore copies of the medicine and alarm data.")
    R.figure("fig_erd.png", "Entity-Relationship Diagram (Firestore and SQLite)", width=6.3)
    R.p("The Firestore model centres on the Users collection, under which each user owns private "
        "subcollections for their cart, wishlist, notifications, medicines, and (nested beneath "
        "each medicine) alarms. The catalog is modelled as Categories, Subcategories, Brands, "
        "and Products, with Reviews stored as a subcollection of each product. Orders embed their "
        "line items for fast display and reference the purchasing user. Promotions are modelled "
        "as Banners and Coupons, and administrators live in a separate Admins collection that "
        "the security rules consult to authorize privileged operations. To keep the mobile "
        "experience fast and avoid expensive joins, frequently displayed fields such as category, "
        "brand, and customer names are denormalized onto the records that display them, with the "
        "understanding that these copies are refreshed when their source changes.")
    R.p("The SQLite model mirrors the medical data with a medicines table, an alarms table, and "
        "a pending-changes table that records queued offline operations. Each medicine and alarm "
        "row carries a synced flag and a local-update timestamp, which together drive the "
        "synchronization and conflict-resolution logic. Additional lightweight tables track "
        "prescription images and the orders whose stock has already been refilled, the latter "
        "ensuring that a delivered order replenishes stock exactly once.")

    R.section("Flowchart Diagram")
    R.p("A flowchart captures the step-by-step logic of a process, including its decision "
        "points. Figure 5.3 presents the flowchart of MediAI's most distinctive workflow: the "
        "reminder-and-stock cycle. It begins with user authentication and the addition of a "
        "medicine — either typed manually or extracted by the OCR pipeline. The medicine and its "
        "alarms are written to SQLite and scheduled locally, then queued for synchronization to "
        "the cloud. When an alarm time is reached, a full-screen alarm appears and the user takes, "
        "snoozes, or dismisses the dose. Taking a dose decrements stock and triggers a check "
        "against the low-stock threshold; if stock is low, the user is notified and prompted to "
        "re-order, closing the loop with the commerce module.")
    R.figure("fig_flowchart.png", "Reminder and Stock-Management Workflow Flowchart", width=4.8)
    R.p("The decision points in the flowchart correspond directly to the conditional logic in "
        "the implementation: whether OCR was used, whether the alarm time has been reached, and "
        "whether the remaining stock has fallen to or below the alert threshold. The branch that "
        "fetches data from the vision model is shown as a side path that rejoins the main flow "
        "once the extracted fields are confirmed by the user.")

    R.section("Sequence Diagram")
    R.p("A sequence diagram shows how components collaborate over time to fulfil a request. "
        "Figure 5.4 models the AI chatbot interaction — the most elaborate inter-component "
        "exchange in the system. The user types a question, which the Flutter chat service sends "
        "to the FastAPI RAG endpoint together with a conversation session identifier. The "
        "backend first checks for medical emergencies and conversation control, then classifies "
        "the query's intent and selects a route. It embeds the query and performs a "
        "cosine-similarity search over the ChromaDB vector store; if the relevant drug is not yet "
        "indexed, it ingests it on demand from DailyMed and OpenFDA before retrying. The "
        "retrieved context is assembled into a grounding block and passed, with the question, to "
        "the LLM, which returns a grounded answer. The backend attaches source citations and "
        "returns the result; the client displays it, or, if the answer was not grounded, falls "
        "back to the general chat endpoint.")
    R.figure("fig_sequence.png", "AI Chatbot (RAG) Sequence Diagram", width=6.3)
    R.p("The diagram makes explicit the two alternative paths that give the chatbot its "
        "robustness: on-demand ingestion when a drug is unknown, and the client-side fallback to "
        "the general endpoint when retrieval yields no grounded answer. These alternatives ensure "
        "the user rarely reaches a dead end while preserving the guarantee that grounded answers "
        "are backed by real evidence.")

    R.section("Activity Diagram")
    R.p("An activity diagram models the flow of activities and the order in which they occur. "
        "Figure 5.5 presents the activity diagram for the e-commerce order process, from "
        "browsing the store through to the automatic refill of household stock upon delivery. "
        "The customer browses and selects products, manages the cart, and proceeds through "
        "checkout, where address selection, server-validated coupon application, and payment "
        "selection occur in sequence. Placing the order writes it to Firestore, clears the cart, "
        "and shows a success screen. The administrator then advances the order through its "
        "lifecycle, and upon delivery the system automatically refills the customer's tracked "
        "household stock for the medicines in the order.")
    R.figure("fig_activity.png", "E-Commerce Order Activity Diagram", width=4.6)
    R.p("This diagram highlights the design decision that distinguishes MediAI from a plain "
        "online store: the final activity is not the delivery of the order but the replenishment "
        "of the patient's medication supply, reflecting the platform's adherence-centred "
        "philosophy.")

    R.section("Retrieval-Augmented Generation Pipeline Design")
    R.p("Because the AI pharmacist is central to MediAI's value, its internal pipeline is "
        "designed in detail. Figure 5.6 shows the stages a question passes through: an emergency "
        "and cancellation pre-check, intent classification and routing, an optional direct index "
        "lookup that answers brand/generic and ingredient questions without invoking the LLM, "
        "query embedding, cosine-similarity retrieval with a similarity-score filter, on-demand "
        "ingestion when nothing relevant is found, construction of the grounding context block, "
        "LLM generation, and the appending of citations and a confidence note. This staged "
        "design lets cheap, deterministic paths short-circuit before the expensive generation "
        "step, improving both speed and reliability.")
    R.figure("fig_rag.png", "Retrieval-Augmented Generation Pipeline Design", width=4.6)

    R.section("Data Dictionary")
    R.p("This section documents the principal data structures of MediAI field by field. Each "
        "table lists the fields of a Firestore collection or SQLite table together with their "
        "types and a brief description. The data dictionary serves as the authoritative "
        "reference for developers and is the basis for the entity-relationship design above.")

    R.subsection("Users Collection")
    R.table("Users (Firestore) — field definitions",
            ["Field", "Type", "Description"], [
        ["id (uid)", "String (PK)", "Firebase Authentication user identifier."],
        ["FirstName / LastName", "String", "The user's given and family names."],
        ["Email", "String", "The account email address."],
        ["PhoneNumber", "String", "Contact phone number."],
        ["Gender", "String", "Optional gender field."],
        ["DateOfBirth", "Timestamp", "Optional date of birth."],
        ["ProfilePicture", "String (URL)", "Storage URL of the profile photo."],
        ["role", "String", "User role; 'Customer' for app users."],
        ["points", "Number", "Loyalty points balance."],
        ["orderCount", "Number", "Total number of orders placed."],
        ["isEmailVerified", "Boolean", "Whether the email has been verified."],
        ["addresses[]", "Array", "List of saved shipping addresses."],
        ["selectedAddressIndex", "Number", "Index of the default address."],
        ["CreatedAt", "Timestamp", "Account creation timestamp."],
    ], col_widths=[1.6, 1.3, 3.37], font_size=9)

    R.subsection("Products Collection")
    R.table("Products (Firestore) — field definitions",
            ["Field", "Type", "Description"], [
        ["id", "String (PK)", "Unique product identifier."],
        ["Name", "String", "Product (medicine) name."],
        ["FormulaName", "String", "Generic / formula name."],
        ["Description", "String", "Product description."],
        ["Price / SalePrice", "Number", "List price and discounted price."],
        ["Stock", "Number", "Available inventory quantity."],
        ["Images[]", "Array", "Storage URLs of product images."],
        ["CategoryId / CategoryName", "String", "Foreign key and denormalized name."],
        ["SubcategoryId / SubcategoryName", "String", "Foreign key and denormalized name."],
        ["BrandId / BrandName", "String", "Foreign key and denormalized name."],
        ["IsFeatured / IsRecommended", "Boolean", "Placement flags."],
        ["IsActive", "Boolean", "Whether shown in the store."],
        ["CreatedAt / UpdatedAt", "Timestamp", "Audit timestamps."],
    ], col_widths=[2.0, 1.0, 3.27], font_size=9)

    R.subsection("Orders Collection")
    R.table("Orders (Firestore) — field definitions",
            ["Field", "Type", "Description"], [
        ["id", "String (PK)", "Unique order identifier."],
        ["customerId", "String (FK)", "References the purchasing user."],
        ["customerName / customerEmail", "String", "Denormalized customer details."],
        ["items[]", "Array<OrderItem>", "Embedded line items (productId, name, price, quantity, tabletsInPack)."],
        ["orderStatus", "String", "Pending / Processing / Shipped / Delivered."],
        ["paymentStatus", "String", "Unpaid / Paid."],
        ["paymentMethod", "String", "Chosen payment method (e.g., COD)."],
        ["subtotal / totalAmount", "Number", "Pre- and post-adjustment totals."],
        ["couponCode / couponDiscount", "String / Number", "Applied coupon and discount value."],
        ["shippingFee", "Number", "Delivery charge."],
        ["shippingAddress{}", "Map", "Snapshot of the delivery address."],
        ["CreatedAt", "Timestamp", "Order placement time."],
    ], col_widths=[2.0, 1.3, 2.97], font_size=9)

    R.subsection("Catalog and Promotion Collections")
    R.table("Categories, Subcategories, Brands, Coupons, Banners — key fields",
            ["Collection", "Key Fields", "Notes"], [
        ["Categories", "id, Name, Image, IsFeatured, IsActive", "Top-level catalog grouping."],
        ["Subcategories", "id, CategoryId, CategoryName, Name, IsFeatured", "Child of a category."],
        ["Brands", "id, Name, CategoryIds[], IsFeatured, ProductCount", "Many-to-many with categories."],
        ["Coupons", "id, Code, DiscountValue, Type, StartDate, EndDate, UsageLimit", "Server-validated discounts."],
        ["Banners", "id, image, title, redirect, isActive, views, clicks, startDate, endDate", "Promotional banners with tracking."],
        ["Reviews (sub)", "id, productId, userId, userName, rating, comment", "Per-product review subcollection."],
        ["Admins", "id, FirstName, LastName, Email, role, IsActive", "Separate admin identity collection."],
    ], col_widths=[1.4, 3.2, 1.67], font_size=9)

    R.subsection("SQLite Local Tables")
    R.table("SQLite — medicines, alarms, and pending_changes tables",
            ["Table.Field", "Type", "Description"], [
        ["medicines.medId", "TEXT (PK)", "Unique medicine identifier."],
        ["medicines.uid", "TEXT", "Owning user."],
        ["medicines.medicine_name", "TEXT", "Medicine name."],
        ["medicines.disease_name", "TEXT", "Comma-separated conditions."],
        ["medicines.frequency", "TEXT", "Doses per day (e.g., '3/day')."],
        ["medicines.duration", "TEXT", "Course length or 'chronic'."],
        ["medicines.start_date", "TEXT", "Treatment start date."],
        ["medicines.chronic", "INTEGER", "1 if chronic, else 0."],
        ["medicines.total_no_of_doses", "INTEGER", "Total doses for full course."],
        ["medicines.available_stock", "INTEGER", "Current household stock."],
        ["medicines.alert_before_days", "INTEGER", "Low-stock alert window (default 3)."],
        ["medicines.synced", "INTEGER", "1 if mirrored to Firestore."],
        ["medicines.local_updated_at", "INTEGER", "Timestamp for conflict resolution."],
        ["alarms.alarmId", "TEXT (PK)", "Unique alarm identifier."],
        ["alarms.medId", "TEXT (FK)", "Links to medicines."],
        ["alarms.specific_dose", "TEXT", "Dose description (e.g., '1 tablet')."],
        ["alarms.time_hour / time_minute", "INTEGER", "Alarm time of day."],
        ["alarms.isActive / synced", "INTEGER", "Enabled and sync flags."],
        ["pending_changes.operation_type", "TEXT", "INSERT / UPDATE / DELETE."],
        ["pending_changes.entity_type", "TEXT", "MEDICINE / ALARM."],
        ["pending_changes.entity_data", "TEXT", "Serialized payload."],
        ["pending_changes.synced", "INTEGER", "Processed flag."],
    ], col_widths=[2.2, 1.1, 2.97], font_size=8.5)

    R.section("Design Rationale and Quality Attributes")
    R.p("Every major design decision in MediAI traces back to a quality attribute identified in "
        "the requirements. The offline-first SQLite design serves reliability. The repository "
        "pattern and layered architecture serve maintainability. The server-side coupon engine "
        "and Firestore security rules serve security and integrity. The RAG grounding, emergency "
        "detection, and refusal behaviour serve safety. Denormalization and reactive state serve "
        "performance and usability. Timestamp-based conflict resolution serves consistency. By "
        "tracing each design choice to a concrete attribute, the architecture remains coherent "
        "and justifiable rather than incidental, and it provides a stable foundation for the "
        "implementation detailed in the next chapter.")
