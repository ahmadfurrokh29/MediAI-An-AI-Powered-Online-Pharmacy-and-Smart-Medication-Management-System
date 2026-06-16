# -*- coding: utf-8 -*-
def build(R):
    R.chapter("Testing")
    R.p("This chapter describes the testing performed to validate that MediAI meets the "
        "functional and non-functional requirements established in Chapter 4. It states the "
        "testing objectives and methodology, presents the test-case design and the test cases "
        "themselves, summarizes the execution and results, analyses the findings against the "
        "requirements, and reflects on the challenges encountered during testing. Testing "
        "combined unit testing of backend logic, integration testing across the client and "
        "backend, end-to-end testing of complete user journeys, and focused security and "
        "usability testing.")

    R.section("Testing Objectives")
    R.p("The primary objective of testing was to confirm that MediAI delivers a secure, "
        "reliable, and trustworthy experience across all of its modules. Specific objectives "
        "were: to verify that authentication, ordering, and coupon validation behave correctly "
        "and securely; to confirm that reminders fire reliably, including offline and after a "
        "restart; to confirm that stock decrements, low-stock alerts, and auto-refill behave "
        "correctly; to verify that offline changes synchronize correctly and resolve conflicts "
        "deterministically; to confirm that the AI pharmacist stays grounded, refuses unsupported "
        "and off-topic questions, and escalates emergencies; to confirm that prescription OCR "
        "extracts usable data with a human confirmation step; and to verify that the "
        "administration panel manages the catalog, orders, promotions, and prescription requests "
        "correctly under role-based access control.")

    R.section("Testing Methodology")
    R.p("Four complementary testing approaches were used. Unit testing targeted discrete backend "
        "logic such as coupon validation, discount calculation, intent classification, emergency "
        "detection, and the response formatter, where deterministic inputs could be checked "
        "against expected outputs. Integration testing verified the interactions between the "
        "Flutter clients, Firebase, the local SQLite database, and the FastAPI backend — for "
        "example, that a chatbot query travels correctly from the client through retrieval and "
        "generation and back with citations, and that a medicine saved offline appears in "
        "Firestore after synchronization. End-to-end testing exercised complete user journeys "
        "such as registering, ordering with a coupon, scanning a prescription, scheduling and "
        "responding to an alarm, and consulting the AI pharmacist. Security testing probed access "
        "control and discount integrity, and usability testing evaluated the clarity and "
        "accessibility of the interfaces. Each test case follows a standard template, shown in "
        "Table 7.1.")

    R.section("Test-Case Design")
    R.subsection("Test-Case Template")
    R.table("Test-Case Template", ["Field", "Description"], [
        ["Test ID", "Unique identifier for the test case (e.g., TC-1)."],
        ["Requirement / Use Case", "The requirement or use case validated (e.g., FR-7 / UC-5)."],
        ["Description", "The purpose of the test."],
        ["Preconditions", "Conditions that must hold before execution."],
        ["Test Steps", "The actions performed."],
        ["Expected Outcome", "The expected result."],
        ["Actual Outcome", "The observed result."],
        ["Status", "Pass or Fail."],
    ], col_widths=[1.7, 4.57], font_size=10)

    R.section("Test Cases")
    _tc(R, "TC-1", "FR-1 / UC-1", "Verify registration and login via email, Google, and Facebook.",
        "The app is installed; the AI and Firebase services are reachable.",
        "1. Register a new account with email and password. 2. Verify email. 3. Sign out and "
        "sign back in. 4. Repeat with Google and Facebook providers.",
        "The account is created, a user profile document appears in Firestore, and sign-in "
        "succeeds for all three providers.",
        "Account created and profile document present; all three providers signed in successfully.",
        "Pass")
    _tc(R, "TC-2", "FR-2 / UC-1", "Verify role separation between customers and administrators.",
        "A customer account and an admin account exist.",
        "1. Sign in as a customer in the mobile app. 2. Attempt to access an admin function. "
        "3. Sign in to the admin panel with the admin account.",
        "The customer cannot access admin functions; the admin panel admits only accounts in the "
        "Admins collection.",
        "Customer blocked from admin functions; admin panel admitted only the admin account.",
        "Pass")
    _tc(R, "TC-3", "FR-3 / UC-2", "Verify catalog browsing, search, and filtering.",
        "The catalog contains active products across categories and brands.",
        "1. Browse by category and brand. 2. Search by a product name. 3. Apply filters.",
        "Matching products are returned with correct images, price, and stock status.",
        "Correct, filtered product lists returned for all queries.",
        "Pass")
    _tc(R, "TC-4", "FR-5 / UC-4", "Verify cart add, update, remove, and persistence.",
        "The user is signed in; products are in stock.",
        "1. Add products to the cart. 2. Change quantities. 3. Remove an item. 4. Restart the app.",
        "The cart updates reactively, totals recompute, and the cart persists across the restart.",
        "Cart updated and persisted correctly across restart; totals correct.",
        "Pass")
    _tc(R, "TC-5", "FR-7 / UC-5", "Verify checkout and order placement.",
        "The cart has items; the user has a shipping address.",
        "1. Proceed to checkout. 2. Select address and payment. 3. Place the order.",
        "An order document is created with Pending status, the cart is cleared, and a success "
        "screen is shown.",
        "Order created with correct items and totals; cart cleared; success screen shown.",
        "Pass")
    _tc(R, "TC-6", "FR-8 / UC-15", "Verify server-side coupon validation and discount calculation.",
        "An active percentage coupon and an expired coupon exist.",
        "1. Apply the active coupon at checkout. 2. Apply the expired coupon. 3. Attempt to "
        "tamper with the discount on the client.",
        "The active coupon discount is computed and capped on the server; the expired coupon is "
        "rejected; client tampering has no effect on the authoritative total.",
        "Active coupon applied and capped correctly; expired coupon rejected; server total "
        "unaffected by client tampering.",
        "Pass")
    _tc(R, "TC-7", "FR-9 / UC-6", "Verify order history and status tracking.",
        "The user has placed orders; an admin updates a status.",
        "1. View order history. 2. Open an order. 3. Have an admin advance the status and "
        "re-check.",
        "Orders are listed with correct details and the updated status is reflected on the "
        "customer side.",
        "Order history and updated statuses displayed correctly.",
        "Pass")
    _tc(R, "TC-8", "FR-11 / UC-7", "Verify prescription OCR extraction and confirmation.",
        "A legible prescription image is available.",
        "1. Scan the prescription. 2. Review the extracted medicines. 3. Confirm and save.",
        "Medicines, frequency, and duration are extracted into the form for confirmation; the "
        "saved medicines and the prescription image are stored.",
        "Fields extracted and editable; medicines and image saved after confirmation.",
        "Pass")
    _tc(R, "TC-9", "FR-12 / UC-8", "Verify dose alarms fire offline and after restart.",
        "An alarm is scheduled for the near future.",
        "1. Schedule an alarm. 2. Close the app and disable connectivity. 3. Restart the device "
        "before the alarm time.",
        "A full-screen alarm fires at the scheduled time despite the app being closed, offline, "
        "and restarted.",
        "Full-screen alarm fired on time offline and after restart.",
        "Pass")
    _tc(R, "TC-10", "FR-13 / UC-8", "Verify dose actions and stock decrement.",
        "An alarm fires for a medicine with known stock.",
        "1. Mark the dose as taken. 2. Re-open the medicine. 3. Repeat with snooze and dismiss.",
        "Taking a dose decrements stock; snooze re-schedules; dismiss leaves stock unchanged.",
        "Stock decremented on take; snooze re-scheduled; dismiss left stock unchanged.",
        "Pass")
    _tc(R, "TC-11", "FR-14 / UC-9", "Verify low-stock alert logic for chronic and non-chronic medicines.",
        "A chronic and a non-chronic medicine exist near their thresholds.",
        "1. Reduce stock toward the threshold for each. 2. Observe alerts.",
        "The chronic medicine alerts within the threshold window; the non-chronic medicine does "
        "not alert while stock covers the remaining course.",
        "Alerts raised exactly as specified for both cases.",
        "Pass")
    _tc(R, "TC-12", "FR-15 / UC-14", "Verify auto-refill of stock on order delivery (idempotent).",
        "A tracked medicine exists and a matching order is delivered.",
        "1. Mark the order delivered. 2. Re-observe the order list multiple times.",
        "The matching medicine's stock increases once by the delivered quantity and is not "
        "refilled again on subsequent observations.",
        "Stock increased exactly once; repeated observations caused no further change.",
        "Pass")
    _tc(R, "TC-13", "FR-19 / UC-17", "Verify offline-first synchronization and conflict resolution.",
        "Medicine data is edited offline on the device.",
        "1. Edit a medicine offline. 2. Restore connectivity. 3. Compare local and cloud copies.",
        "Queued changes push to Firestore, remote changes merge into SQLite, and conflicts "
        "resolve by latest timestamp.",
        "Local and cloud copies converged; latest-timestamp record won as expected.",
        "Pass")
    _tc(R, "TC-14", "FR-16 / UC-10", "Verify grounded answers and refusal behaviour of the AI pharmacist.",
        "The AI backend is reachable.",
        "1. Ask about side effects of a known drug. 2. Ask an off-topic question. 3. Ask about a "
        "drug with no available data.",
        "The known drug yields a grounded, cited answer; the off-topic question is refused; the "
        "unknown drug yields a safe 'not in knowledge base' response.",
        "Grounded cited answer; off-topic refused; safe fallback for unknown drug.",
        "Pass")
    _tc(R, "TC-15", "FR-17 / UC-10", "Verify brand/generic resolution and misspelling tolerance.",
        "The AI backend is reachable.",
        "1. Ask using a brand name. 2. Ask using a misspelled generic name.",
        "The brand resolves to the correct generic, and the misspelled name resolves to the "
        "correct drug via approximate matching.",
        "Brand resolved to generic; misspelled name resolved correctly.",
        "Pass")
    _tc(R, "TC-16", "FR-17 / UC-10", "Verify on-demand ingestion of an unknown drug.",
        "A drug not in the baseline is chosen and the AI backend is reachable.",
        "1. Ask about the unknown drug. 2. Ask a second question about the same drug.",
        "The first query ingests the drug live and answers from it; the second query is served "
        "quickly from the now-cached data.",
        "First query ingested and answered; second query served quickly from cache.",
        "Pass")
    _tc(R, "TC-17", "FR-18 / UC-11", "Verify multi-turn symptom triage and consent handling.",
        "The AI backend is reachable.",
        "1. Describe a non-emergency symptom. 2. Answer the follow-up questions. 3. Reply 'tell "
        "me' to the consent prompt.",
        "The engine asks structured questions, summarizes, and on consent provides grounded "
        "over-the-counter information rather than misreading 'tell me' as a new lookup.",
        "Triage progressed correctly; 'tell me' treated as consent; grounded info provided.",
        "Pass")
    _tc(R, "TC-18", "FR-18 / UC-11", "Verify emergency detection and escalation.",
        "The AI backend is reachable.",
        "1. Send a message describing crushing chest pain spreading to the arm. 2. Send a "
        "self-harm message.",
        "Both immediately abandon any assessment and return urgent guidance, with the self-harm "
        "case pointing to crisis helplines.",
        "Urgent guidance returned immediately in both cases; helplines provided for self-harm.",
        "Pass")
    _tc(R, "TC-19", "FR-20 / UC-13", "Verify the admin dashboard metrics and export.",
        "Orders and products exist; the admin is authorized.",
        "1. Open the dashboard. 2. Compare metrics against known data. 3. Export to a spreadsheet.",
        "Sales, order, and product metrics and low-stock alerts are correct, and the export "
        "succeeds.",
        "Metrics matched known data; low-stock alerts correct; export succeeded.",
        "Pass")
    _tc(R, "TC-20", "FR-21 / UC-13", "Verify catalog CRUD and visibility toggles.",
        "The admin is authorized.",
        "1. Create, edit, and delete a category, brand, and product. 2. Toggle featured and "
        "active flags.",
        "Changes persist to Firestore and are reflected in the mobile app's visibility and "
        "prominence in real time.",
        "All CRUD operations and toggles persisted and reflected in the app.",
        "Pass")
    _tc(R, "TC-21", "FR-22 / UC-12", "Verify prescription-request review by an admin.",
        "A customer has submitted a prescription request.",
        "1. Open the prescription-requests page. 2. Inspect the attached image. 3. Approve or "
        "reject.",
        "The request and its image are visible and the decision is recorded.",
        "Request and image displayed; decision recorded correctly.",
        "Pass")
    _tc(R, "TC-22", "FR-23 / UC-16", "Verify admin creation without disrupting the session.",
        "A privileged admin is signed in.",
        "1. Create a new admin account from the admins page. 2. Confirm the current session "
        "remains active.",
        "The new admin is created via a secondary app instance and the acting admin stays signed "
        "in.",
        "New admin created; acting admin session uninterrupted.",
        "Pass")
    _tc(R, "TC-23", "NFR-4 / NFR-5", "Verify Firestore security rules for data isolation.",
        "Two customer accounts and an admin account exist.",
        "1. As customer A, attempt to read customer B's private data. 2. As a customer, attempt "
        "to modify the catalog.",
        "Cross-user reads of private data are denied and catalog writes by non-admins are denied.",
        "All unauthorized reads and writes were denied by the rules.",
        "Pass")
    _tc(R, "TC-24", "NFR-7", "Verify usability and accessibility of key flows.",
        "Representative users of varying digital literacy are available.",
        "1. Have users complete ordering, scheduling an alarm, and asking the chatbot. 2. Gather "
        "feedback on clarity.",
        "Users complete the flows with minimal confusion; feedback confirms clear feedback, "
        "confirmation prompts, and legible presentation.",
        "Flows completed successfully; feedback positive on clarity and legibility.",
        "Pass")

    R.section("Test Execution")
    R.p("Backend unit tests were executed with the project's Python test suite, exercising the "
        "coupon engine, intent classification, emergency detection, and response formatting "
        "against deterministic inputs. Integration and end-to-end tests were executed manually "
        "against a running backend and a local Firebase project, using a physical device on the "
        "same network as the backend to validate the chatbot, alarms, and synchronization under "
        "realistic conditions. Security tests were executed by attempting unauthorized reads, "
        "writes, and discount tampering. Each test case was run, its actual outcome recorded, "
        "and its status assigned by comparing the actual outcome to the expected outcome.")

    R.section("Test Results")
    R.p("All twenty-four documented test cases passed. The grounded-answer, refusal, and "
        "emergency-escalation behaviours of the AI pharmacist performed as designed, including "
        "the correct handling of consent during symptom triage and the live ingestion of "
        "previously unknown drugs. The offline alarm and synchronization tests confirmed that "
        "the safety-critical features function without connectivity and converge correctly once "
        "connectivity returns. The auto-refill test confirmed the idempotent, exactly-once "
        "behaviour of stock replenishment on delivery. The security tests confirmed that "
        "Firestore rules isolate user data and protect the catalog, and that the server-side "
        "coupon engine cannot be bypassed from the client.")

    R.section("Analysis and Validation")
    R.p("The test results validate that MediAI satisfies its functional and non-functional "
        "requirements. Reliability is demonstrated by the offline and post-restart alarm tests; "
        "consistency by the synchronization and conflict-resolution tests; safety by the "
        "grounding, refusal, and emergency tests; integrity and security by the coupon and "
        "Firestore-rule tests; and usability by the accessibility evaluation. The few issues "
        "uncovered during testing — for example, an early tendency for the consent step to "
        "misclassify affirmative replies, and the need to coalesce conflicting offline "
        "operations — were resolved during iterative development, and the corresponding "
        "behaviours now pass. The principal limitation of the testing is that it relied on "
        "manual end-to-end execution and a limited set of devices and prescriptions; broader "
        "automated and field testing is identified as future work.")

    R.section("Testing Challenges")
    R.p("Testing the system presented several challenges. Verifying offline alarms required "
        "deliberately closing the app, disabling connectivity, and restarting the device, then "
        "waiting for real scheduled times. Testing the AI required crafting questions that probe "
        "grounding, refusal, brand/generic resolution, misspelling tolerance, and emergency "
        "detection, and confirming that on-demand ingestion behaves correctly the first time a "
        "drug is requested. Testing prescription OCR required a range of prescription images of "
        "varying legibility. Testing synchronization required orchestrating edits across "
        "connectivity transitions. These challenges were addressed by scripting deterministic "
        "backend tests where possible and by following carefully designed manual procedures for "
        "the inherently device- and timing-dependent features. The result is a body of evidence "
        "that the system behaves correctly and safely across its full range of features.")


def _tc(R, tcid, req, desc, pre, steps, expected, actual, status):
    rows = [
        ["Test ID", tcid],
        ["Requirement / Use Case", req],
        ["Description", desc],
        ["Preconditions", pre],
        ["Test Steps", steps],
        ["Expected Outcome", expected],
        ["Actual Outcome", actual],
        ["Status", status],
    ]
    R.table(f"{tcid} — {desc}", ["Field", "Details"], rows,
            col_widths=[1.7, 4.57], font_size=9.5)
