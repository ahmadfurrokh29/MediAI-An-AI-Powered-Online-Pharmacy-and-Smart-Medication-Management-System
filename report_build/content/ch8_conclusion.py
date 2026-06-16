# -*- coding: utf-8 -*-
def build(R):
    R.chapter("Conclusion")
    R.p("This chapter draws together the work presented in the report. It summarizes the "
        "findings, evaluates the project against its objectives, acknowledges its limitations, "
        "sets out a roadmap for future work, and offers concluding remarks on the significance "
        "of MediAI.")

    R.section("Summary of Findings")
    R.p("MediAI set out to solve a fragmented and unreliable medication-management experience by "
        "unifying online medicine ordering, prescription digitization, dependable reminders, "
        "automatic household-stock management, and a trustworthy AI pharmacist into a single, "
        "offline-resilient platform. The project succeeded in delivering all of these "
        "capabilities as an integrated whole. The customer mobile application provides a complete "
        "online pharmacy together with an offline-first reminder and stock subsystem that fires "
        "full-screen alarms even without connectivity, decrements stock automatically as doses "
        "are taken, warns the user before medicines run out, and replenishes tracked stock when "
        "an order is delivered. The prescription-scanning feature digitizes handwritten "
        "prescriptions through a vision-language model while keeping the user in the loop for "
        "confirmation.")
    R.p("The AI Virtual Pharmacist demonstrated that a chatbot in a safety-critical domain can be "
        "both flexible and trustworthy. By grounding answers in authoritative DailyMed and "
        "OpenFDA labels through a Retrieval-Augmented Generation pipeline, resolving names "
        "through RxNorm with tolerance for misspellings, ingesting unknown drugs on demand, "
        "refusing to answer without evidence or outside its domain, and escalating emergencies "
        "through a dedicated triage engine, the assistant avoids the hallucination that "
        "undermines naive LLM deployments. The administration panel gives operators full, "
        "real-time control of the catalog, orders, promotions, prescription requests, and admin "
        "accounts under role-based security, and the server-side coupon engine guarantees that "
        "pricing can never be tampered with from the client. Comprehensive testing confirmed "
        "that all of these behaviours work as designed.")

    R.section("Evaluation of Objectives")
    R.p("The project's objectives, set out in the problem definition and requirements, were each "
        "met. The objective of reliability was achieved through the offline-first SQLite design "
        "and locally scheduled alarms that survive closure and restart, validated by the offline "
        "and post-restart alarm tests. The objective of data integrity and consistency was "
        "achieved through the offline-queue, synced-flag, and timestamp-based conflict-resolution "
        "mechanisms, validated by the synchronization tests. The objective of trustworthy and "
        "safe AI was achieved through grounded generation, refusal behaviour, name resolution, "
        "and emergency triage, validated by the corresponding AI tests. The objective of security "
        "and privacy was achieved through Firebase Authentication, Firestore security rules, and "
        "the server-authoritative coupon engine, validated by the security tests. The objective "
        "of usability and inclusivity was achieved through heuristic-guided interface design, "
        "validated by the usability evaluation.")
    R.p("Compared with the piecemeal tools surveyed in the literature review, MediAI's principal "
        "achievement is integration: it links commerce to adherence, adherence to stock, stock "
        "back to commerce, and overlays the whole with grounded AI guidance — a combination that "
        "no single surveyed system provides. Its second achievement is reliability under poor "
        "connectivity, and its third is the disciplined, safety-first engineering of its AI "
        "layer.")

    R.section("Limitations")
    R.p("Several limitations are acknowledged. MediAI is an academic prototype rather than a "
        "clinically certified product; it provides educational guidance and adherence tooling, "
        "not diagnosis. It does not integrate a live real-money payment gateway, relying instead "
        "on cash-on-delivery and a demonstration payment flow. The AI knowledge base, although "
        "it grows on demand, is bootstrapped from English-language sources curated by United "
        "States agencies and may not cover every locally marketed brand name. Prescription OCR "
        "accuracy depends on the legibility of the image and always requires user confirmation. "
        "The chatbot requires connectivity to the backend, unlike the fully offline reminder "
        "features. Finally, the testing relied substantially on manual end-to-end execution "
        "across a limited set of devices, so the evidence of correctness, while strong, is not "
        "the product of exhaustive automated or field testing.")

    R.section("Future Work")
    R.p("A number of enhancements would extend MediAI toward production readiness and broader "
        "impact:")
    R.numbered("Integrate a real payment gateway with secure tokenization to support live "
               "transactions alongside cash-on-delivery.")
    R.numbered("Add localized and multilingual drug data and interface translations to serve "
               "regional brand names and non-English-speaking users.")
    R.numbered("Expand automated testing with end-to-end UI automation, fuzz testing of the AI "
               "endpoints, and continuous integration.")
    R.numbered("Enhance the AI pharmacist with drug-interaction checking across the user's full "
               "medication list and with personalized, profile-aware guidance.")
    R.numbered("Introduce caregiver and family accounts so that one person can manage reminders "
               "and stock for dependents.")
    R.numbered("Add analytics and adherence reporting for users and, with consent, for "
               "clinicians and chronic-care programs.")
    R.numbered("Support hardware integration such as smart pill dispensers and wearables for "
               "physical confirmation of intake.")
    R.numbered("Strengthen offline capability of the chatbot through an on-device fallback model "
               "for common questions.")

    R.section("Conclusion")
    R.p("MediAI demonstrates that the disparate strands of digital pharmacy — commerce, "
        "adherence, prescription capture, and pharmaceutical guidance — can be woven into a "
        "single, coherent, and trustworthy platform. By making its safety-critical features "
        "offline-first, grounding its AI in authoritative sources, and enforcing security on the "
        "server and at the database, the project addresses precisely the gaps that leave existing "
        "tools fragmented and fragile. The result is a system that does not merely help a patient "
        "buy a medicine, but accompanies them through the entire journey of taking it correctly "
        "and safely. While further work is needed to reach full production maturity, the "
        "foundation laid by this project is robust, extensible, and squarely aimed at the "
        "outcome that matters most in healthcare software: helping people take the right medicine "
        "at the right time, with confidence. We are grateful to our supervisor, Sir Abdur "
        "Rehman, and to our evaluation panel head, Sir Hameed, whose guidance shaped both the "
        "engineering and the spirit of this work.")
