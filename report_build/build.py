# -*- coding: utf-8 -*-
"""
Builds the complete MediAI FYP report into a single .docx file.

Two-pass strategy:
  Pass 1 runs the whole build on a throwaway Report just to collect the ordered
  figure and table captions (numbering is deterministic).
  Pass 2 builds the real document, inserting the Table of Contents, List of
  Figures, and List of Tables in the front matter using the collected captions.
"""
import os
import sys
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_TAB_ALIGNMENT, WD_TAB_LEADER
from docx.shared import Pt, Inches, RGBColor

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

from docx_helpers import Report
from content import (front_matter, ch1_introduction, ch2_literature, ch3_problem,
                     ch4_requirements, ch5_design, ch6_implementation, ch7_testing,
                     ch8_conclusion, ch9_glossary)

CHAPTERS = [ch1_introduction, ch2_literature, ch3_problem, ch4_requirements,
            ch5_design, ch6_implementation, ch7_testing, ch8_conclusion, ch9_glossary]
BLUE = RGBColor(0x1F, 0x3B, 0x73)


def build_chapters(R):
    for ch in CHAPTERS:
        ch.build(R)


def _list_page(R, title, entries):
    """entries: list of (label, bookmark_name) tuples. Renders a dotted-leader
    line with a PAGEREF field so Word shows the real page number once fields
    are updated (Ctrl+A then F9, or Word will prompt to update on open)."""
    R.page_break()
    R.plain_heading(title, level=1, size=15, center=False)
    R.doc.add_paragraph()
    for label, bookmark in entries:
        p = R.doc.add_paragraph()
        p.paragraph_format.space_after = Pt(4)
        p.paragraph_format.tab_stops.add_tab_stop(
            Inches(6.27), alignment=WD_TAB_ALIGNMENT.RIGHT, leader=WD_TAB_LEADER.DOTS)
        run = p.add_run(label)
        run.font.name = "Times New Roman"
        run.font.size = Pt(11)
        p.add_run("\t")
        R.add_pageref(p, bookmark)


def _toc_page(R):
    R.page_break()
    R.plain_heading("Table of Contents", level=1, size=15, center=False)
    R.doc.add_paragraph()
    R.toc()


def main():
    out = os.path.abspath(os.path.join(HERE, "..", "MediAI_FYP_Report.docx"))

    # ── Pass 1: collect captions ──────────────────────────────────────────────
    probe = Report()
    build_chapters(probe)
    fig_caps = list(probe.fig_captions)
    tbl_caps = list(probe.tbl_captions)
    print(f"Collected {len(fig_caps)} figures and {len(tbl_caps)} tables.")

    # ── Pass 2: real document ─────────────────────────────────────────────────
    R = Report()
    front_matter.build(R)
    _toc_page(R)
    _list_page(R, "List of Figures", fig_caps)
    _list_page(R, "List of Tables", tbl_caps)
    build_chapters(R)
    R.add_page_numbers()
    R.save(out)
    print("Saved:", out)


if __name__ == "__main__":
    main()
