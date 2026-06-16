# -*- coding: utf-8 -*-
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.shared import Pt, Inches, RGBColor

C = WD_ALIGN_PARAGRAPH.CENTER


def _center(R, text, size=12, bold=False, italic=False, space=6, color=None):
    p = R.doc.add_paragraph()
    p.alignment = C
    p.paragraph_format.space_after = Pt(space)
    r = p.add_run(text)
    r.font.name = "Times New Roman"
    r.font.size = Pt(size)
    r.bold = bold
    r.italic = italic
    if color:
        r.font.color.rgb = color
    return p


def build(R):
    d = R.doc
    blue = RGBColor(0x1F, 0x3B, 0x73)

    # ── COVER PAGE ────────────────────────────────────────────────────────────
    d.add_paragraph().paragraph_format.space_after = Pt(10)
    _center(R, "MediAI — An AI-Powered Online Pharmacy and Smart", 20, bold=True, color=blue, space=2)
    _center(R, "Medication Management System", 20, bold=True, color=blue, space=10)
    _center(R, "(Healthcare E-Commerce Platform with AI Virtual Pharmacist,", 13, italic=True, space=2)
    _center(R, "Prescription OCR, and Medicine Reminder & Stock System)", 13, italic=True, space=20)

    # logo placeholder
    R.image_placeholder("Sir Syed CASE Institute of Technology — Official Logo",
                        height_note="Insert SSCASE institute logo here")

    _center(R, "SUBMITTED BY", 13, bold=True, space=12)
    _center(R, "Ibrahim Farooq" + " " * 8 + "2410-4017", 13, space=4)
    _center(R, "Ahmad Forrukh" + " " * 8 + "2230-0059", 13, space=20)

    _center(R, "A Report Submitted", 12, space=2)
    _center(R, "in Partial Fulfillment of the Requirement", 12, space=2)
    _center(R, "for the Degree of", 12, space=2)
    _center(R, "Bachelor of Science in Software Engineering", 12, bold=True, space=20)

    _center(R, "DEPARTMENT OF COMPUTER SCIENCE", 13, bold=True, space=6)
    _center(R, "Sir Syed CASE Institute of Technology", 13, space=4)
    _center(R, "Islamabad", 12, space=4)
    _center(R, "2026", 12, space=4)

    # ── CERTIFICATE OF APPROVAL ───────────────────────────────────────────────
    d.add_page_break()
    _center(R, "CERTIFICATE OF APPROVAL", 15, bold=True, color=blue, space=14)
    _center(R, "This project titled", 12, space=8)
    _center(R, "MediAI — An AI-Powered Online Pharmacy and Smart Medication "
            "Management System", 12, bold=True, space=10)
    _center(R, "Submitted", 12, space=6)
    _center(R, "For the Degree of", 12, space=6)
    _center(R, "Bachelor of Science in Software Engineering", 12, space=10)
    _center(R, "By", 12, space=8)
    _center(R, "Ibrahim Farooq" + " " * 8 + "2410-4017", 12, space=4)
    _center(R, "Ahmad Forrukh" + " " * 8 + "2230-0059", 12, space=14)
    _center(R, "Has been approved for", 12, space=6)
    _center(R, "Sir Syed CASE Institute of Technology", 12, space=4)
    _center(R, "ISLAMABAD", 12, space=40)

    _signature_block(R)

    # ── DECLARATION ───────────────────────────────────────────────────────────
    d.add_page_break()
    _center(R, "DECLARATION", 15, bold=True, color=blue, space=14)
    R.p("We, Ibrahim Farooq (2410-4017) and Ahmad Forrukh (2230-0059), do hereby "
        "declare that the work presented in this thesis, titled “MediAI — An "
        "AI-Powered Online Pharmacy and Smart Medication Management System,” is "
        "the result of our own individual and joint efforts carried out in the "
        "officially designated time of study.")
    R.p("We affirm that:")
    R.numbered("All research content, design, implementation, and documentation for this "
               "project are fully our own unless clearly cited or referenced to give credit "
               "to external publications.")
    R.numbered("All sources have been acknowledged as per the ethical and academic standards "
               "for both published and unpublished works.")
    R.numbered("We have strictly complied with the HEC prescribed guidelines on plagiarism as "
               "well as the ethical research practices expected from an institution.")
    R.numbered("This work is not plagiarized beyond an acceptable threshold for research work, "
               "and the passages have been checked for compatibility with all kinds of "
               "plagiarism through the official utility.")
    R.p("We assume full responsibility for the integrity and original content of this thesis. "
        "At the same time, in the event of any violation of HEC rules or evidence of unethical "
        "practices, we accept complete responsibility and agree to be subject to disciplinary "
        "action in accordance with the research misconduct, plagiarism, and other subject "
        "policies of HEC and the institution.")
    R.p("Furthermore, this thesis has not been submitted elsewhere, in part or in full, for any "
        "academic or professional purpose.")
    d.add_paragraph().paragraph_format.space_after = Pt(36)
    _two_sign(R, "Ibrahim Farooq", "2410-4017", "BS Software Engineering",
              "Ahmad Forrukh", "2230-0059", "BS Software Engineering")

    # ── CERTIFICATE ───────────────────────────────────────────────────────────
    d.add_page_break()
    _center(R, "CERTIFICATE", 15, bold=True, color=blue, space=14)
    R.p("This is to certify that the Final Year Project (FYP) titled “MediAI — An "
        "AI-Powered Online Pharmacy and Smart Medication Management System,” submitted "
        "by Ibrahim Farooq (2410-4017) and Ahmad Forrukh (2230-0059), has been completed "
        "under my supervision in the Department of Computer Science at Sir Syed CASE Institute "
        "of Technology, Islamabad.")
    R.p("The students have successfully carried out all phases of the project, including "
        "research, system design, development, implementation, and testing, within the "
        "officially allotted time frame. This project represents original work and complies "
        "with the academic standards and guidelines of the department.")
    R.p("I confirm that the students worked diligently under my supervision, and the project "
        "outcomes meet the academic and technical requirements for the completion of their "
        "Bachelor of Science (BS) in Software Engineering degree. The work has been reviewed, "
        "evaluated, and found to be satisfactory for submission to the university.")
    d.add_paragraph().paragraph_format.space_after = Pt(48)
    _signature_block(R)

    # ── ACKNOWLEDGEMENTS ──────────────────────────────────────────────────────
    d.add_page_break()
    _center(R, "ACKNOWLEDGEMENTS", 15, bold=True, color=blue, space=14)
    R.p("All praise and gratitude are due to Allah Almighty, the Most Merciful and "
        "Compassionate, for His countless blessings, guidance, and strength that enabled us to "
        "complete our Final Year Project, “MediAI — An AI-Powered Online Pharmacy and "
        "Smart Medication Management System.” It is solely by His grace that we were able "
        "to collaborate, overcome challenges, and bring this work to a successful conclusion. "
        "We pray that this project may benefit the wider community and contribute positively to "
        "the field of digital healthcare. Ameen.")
    R.p("We are deeply grateful to our supervisor, Sir Abdur Rehman, for his invaluable "
        "guidance, constant encouragement, and expert advice throughout the duration of this "
        "work. His mentorship kept us focused, motivated, and confident even through the most "
        "difficult phases of development. His insistence on engineering discipline, clean "
        "architecture, and a user-centred mindset shaped every module of this system.")
    R.p("We extend our sincere thanks to Sir Hameed, the head of our evaluation panel, whose "
        "thoughtful feedback consistently raised the quality of our work. In particular, we are "
        "thankful for the practical solution he proposed for the spell-checking and normalization "
        "of medicine names — a guidance that directly inspired the fuzzy matching and "
        "RxNorm-based name-resolution approach now powering both the AI pharmacist and the "
        "prescription-scanning pipeline of MediAI.")
    R.p("We would also like to thank the entire faculty of the Department of Computer Science at "
        "Sir Syed CASE Institute of Technology for the knowledge and skills they imparted to us "
        "over the course of our degree, which formed the foundation of this project.")
    R.p("Finally, we are forever indebted to our parents, siblings, friends, and colleagues, "
        "whose unwavering love, prayers, and emotional support have been our pillars of strength "
        "throughout this challenging yet rewarding journey.")
    d.add_paragraph().paragraph_format.space_after = Pt(10)
    p = d.add_paragraph(); p.add_run("Ibrahim Farooq").bold = True
    p2 = d.add_paragraph(); p2.add_run("Ahmad Forrukh").bold = True

    # ── DEDICATION ────────────────────────────────────────────────────────────
    d.add_page_break()
    _center(R, "DEDICATION", 15, bold=True, color=blue, space=14)
    R.p("We dedicate this project, with deep respect and gratitude, to our worthy supervisor, "
        "Sir Abdur Rehman, whose support, patience, and guidance have been an integral part in "
        "the completion of our work. His moral support and technical expertise gave us the "
        "confidence and knowledge to face every challenge with composure.")
    R.p("We also dedicate this effort to Sir Hameed, the head of our evaluation panel, whose "
        "constructive criticism and the elegant solution he shared for spell-checking medicine "
        "names helped us turn a fragile feature into one of the most reliable parts of the "
        "system.")
    R.p("Above all, we dedicate this work to our most beloved parents, who have remained our "
        "unending pillars of inspiration and motivation throughout this journey. This "
        "achievement could not have been possible without their sacrifices, prayers, and "
        "unshakeable faith in us.")

    # ── ABSTRACT ──────────────────────────────────────────────────────────────
    d.add_page_break()
    _center(R, "ABSTRACT", 15, bold=True, color=blue, space=14)
    R.p("Managing personal medication is a deceptively complex task. Patients routinely miss "
        "doses for want of timely reminders, struggle to track prescriptions and refills, run "
        "out of essential medicines at home, and have little convenient access to quick, "
        "trustworthy pharmacist guidance. MediAI is an integrated, AI-powered digital pharmacy "
        "platform designed to address these problems within a single, cohesive ecosystem. The "
        "platform combines a customer-facing Flutter mobile application, a Flutter web "
        "administration panel, a Python (FastAPI) artificial-intelligence backend, and Google "
        "Firebase cloud services.")
    R.p("The mobile application provides a complete online pharmacy with category, brand, and "
        "search-based browsing, a shopping cart, wishlist, coupon-driven checkout, and order "
        "tracking. Beyond commerce, MediAI delivers a genuinely useful health companion: an "
        "offline-first medicine reminder and stock-management system built on a local SQLite "
        "database that fires full-screen alarms even when the device is offline, automatically "
        "decrements household stock as doses are taken, and warns the user before medicines run "
        "out. Prescriptions can be digitized instantly through an optical-character-recognition "
        "pipeline powered by Google Gemini vision models, which extracts medicine names, "
        "frequencies, and durations directly from a photograph of a handwritten prescription.")
    R.p("At the heart of the platform is an AI Virtual Pharmacist — a Retrieval-Augmented "
        "Generation (RAG) chatbot that grounds its answers in authoritative drug labels sourced "
        "from DailyMed and OpenFDA, resolves brand and generic names through RxNorm, and "
        "tolerates misspelled medicine names through approximate matching. A stateful "
        "symptom-triage engine conducts safe, multi-turn assessments, detects medical "
        "emergencies, and refuses to hallucinate clinical advice. A server-authoritative coupon "
        "engine guarantees that all discounts are validated on the backend rather than trusted "
        "from the client.")
    R.p("The administrative panel equips pharmacists and operators with a real-time dashboard, "
        "full catalog and product management, order processing, customer management, "
        "promotional banners, coupon campaigns, prescription-request review, and role-based "
        "admin management. Throughout, MediAI follows a clean, layered architecture with "
        "offline-first data handling, bidirectional synchronization between SQLite and Firestore, "
        "and role-based security enforced through Firestore rules. The results of comprehensive "
        "functional, integration, and usability testing confirm that MediAI is a secure, "
        "reliable, and scalable solution with strong potential to improve medication adherence "
        "and modernize community pharmacy services.")
    R.p("Keywords: Online Pharmacy, Medication Adherence, Flutter, Firebase, "
        "Retrieval-Augmented Generation, Large Language Models, Optical Character Recognition, "
        "Offline-First Architecture, E-Commerce, Healthcare.", italic=True)


def _signature_block(R):
    """Supervisor (left) and Chairperson (right) signature lines."""
    tbl = R.doc.add_table(rows=2, cols=2)
    tbl.autofit = True
    data = [
        ("______________________", "___________________"),
        ("", ""),
    ]
    cells = tbl.rows[0].cells
    cells[0].paragraphs[0].add_run("______________________").bold = False
    cells[0].paragraphs[0].alignment = C
    cells[1].paragraphs[0].add_run("___________________").bold = False
    cells[1].paragraphs[0].alignment = C
    info = [
        ("Supervisor", "Chairperson"),
        ("Sir Abdur Rehman", "Dr. Syed Jawad Hussain"),
        ("Lecturer", "Head of Department"),
        ("Department of Computer Science", "Department of Computer Science"),
    ]
    r = tbl.rows[1].cells
    for col in range(2):
        para = r[col].paragraphs[0]
        para.alignment = C
        for i, (l, rr) in enumerate(info):
            txt = l if col == 0 else rr
            run = para.add_run(txt)
            run.bold = (i == 0)
            run.font.size = Pt(11)
            if i < len(info) - 1:
                para.add_run("\n")
    _no_borders(tbl)


def _two_sign(R, n1, id1, deg1, n2, id2, deg2):
    tbl = R.doc.add_table(rows=2, cols=2)
    a = tbl.rows[0].cells
    a[0].paragraphs[0].add_run("______________________"); a[0].paragraphs[0].alignment = C
    a[1].paragraphs[0].add_run("___________________"); a[1].paragraphs[0].alignment = C
    b = tbl.rows[1].cells
    for col, (n, idn, deg) in enumerate([(n1, id1, deg1), (n2, id2, deg2)]):
        para = b[col].paragraphs[0]; para.alignment = C
        run = para.add_run(n); run.bold = True; run.font.size = Pt(11)
        para.add_run("\n" + idn).font.size = Pt(11)
        para.add_run("\n" + deg).font.size = Pt(11)
    _no_borders(tbl)


def _no_borders(tbl):
    from docx.oxml.ns import qn
    from docx.oxml import OxmlElement
    for row in tbl.rows:
        for cell in row.cells:
            tcPr = cell._tc.get_or_add_tcPr()
            borders = OxmlElement("w:tcBorders")
            for edge in ("top", "left", "bottom", "right"):
                el = OxmlElement(f"w:{edge}")
                el.set(qn("w:val"), "nil")
                borders.append(el)
            tcPr.append(borders)
