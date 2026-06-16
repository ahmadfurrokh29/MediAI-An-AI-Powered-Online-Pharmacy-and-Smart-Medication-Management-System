# -*- coding: utf-8 -*-
"""
Formatting helpers for the MediAI FYP report (python-docx).

Implements the layout rules from the supervisor's guideline image:
  * Figures centred; figure caption centred BELOW the figure.
  * Tables full text width; table caption LEFT-aligned ABOVE the table.
  * Headings bold and decimally numbered (1, 1.1, 1.1.1).
  * Body text justified, Times New Roman 12 pt.
"""
import os
from docx import Document
from docx.shared import Pt, Inches, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_LINE_SPACING, WD_TAB_ALIGNMENT, WD_TAB_LEADER
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

FONT = "Times New Roman"
BODY_SIZE = 12
HEADING_BLUE = RGBColor(0x1F, 0x3B, 0x73)


class Report:
    """Wraps a Document and tracks heading numbering + figure/table counters."""

    def __init__(self):
        self.doc = Document()
        self._setup_styles()
        self._setup_page()
        self.ch = 0          # chapter counter
        self.sec = 0         # section counter
        self.sub = 0         # subsection counter
        self.fig_no = 0
        self.tbl_no = 0
        self.lst_no = 0
        self.fig_captions = []   # collected (label, bookmark_name) tuples
        self.tbl_captions = []   # collected (label, bookmark_name) tuples
        self._bm_id = 0
        self.images_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "images")

    # ── document setup ────────────────────────────────────────────────────────
    def _setup_styles(self):
        st = self.doc.styles["Normal"]
        st.font.name = FONT
        st.font.size = Pt(BODY_SIZE)
        st.element.rPr.rFonts.set(qn("w:eastAsia"), FONT)
        pf = st.paragraph_format
        pf.line_spacing_rule = WD_LINE_SPACING.MULTIPLE
        pf.line_spacing = 1.4
        pf.space_after = Pt(8)

        for name in ("Heading 1", "Heading 2", "Heading 3"):
            s = self.doc.styles[name]
            s.font.name = FONT
            s.font.color.rgb = HEADING_BLUE
            s.element.rPr.rFonts.set(qn("w:eastAsia"), FONT)

    def _setup_page(self):
        sec = self.doc.sections[0]
        sec.page_height = Inches(11.69)   # A4
        sec.page_width = Inches(8.27)
        sec.top_margin = Inches(1.0)
        sec.bottom_margin = Inches(1.0)
        sec.left_margin = Inches(1.0)
        sec.right_margin = Inches(1.0)

    # ── low-level paragraph builders ──────────────────────────────────────────
    def p(self, text="", justify=True, italic=False, bold=False, size=BODY_SIZE,
          align=None, space_after=8, color=None):
        para = self.doc.add_paragraph()
        if align is not None:
            para.alignment = align
        elif justify:
            para.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
        para.paragraph_format.space_after = Pt(space_after)
        if text:
            run = para.add_run(text)
            run.font.name = FONT
            run.font.size = Pt(size)
            run.italic = italic
            run.bold = bold
            if color:
                run.font.color.rgb = color
        return para

    def rich(self, segments, justify=True, space_after=8):
        """segments: list of (text, {bold,italic}) tuples."""
        para = self.doc.add_paragraph()
        para.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY if justify else WD_ALIGN_PARAGRAPH.LEFT
        para.paragraph_format.space_after = Pt(space_after)
        for text, fmt in segments:
            r = para.add_run(text)
            r.font.name = FONT
            r.font.size = Pt(BODY_SIZE)
            r.bold = fmt.get("bold", False)
            r.italic = fmt.get("italic", False)
        return para

    def bullet(self, text, level=0, bold_lead=None):
        para = self.doc.add_paragraph(style="List Bullet")
        para.paragraph_format.left_indent = Inches(0.3 + 0.3 * level)
        para.paragraph_format.space_after = Pt(4)
        para.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
        if bold_lead:
            r = para.add_run(bold_lead)
            r.bold = True
            r.font.name = FONT
            r.font.size = Pt(BODY_SIZE)
        r2 = para.add_run(text)
        r2.font.name = FONT
        r2.font.size = Pt(BODY_SIZE)
        return para

    def numbered(self, text, bold_lead=None):
        para = self.doc.add_paragraph(style="List Number")
        para.paragraph_format.left_indent = Inches(0.3)
        para.paragraph_format.space_after = Pt(4)
        para.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
        if bold_lead:
            r = para.add_run(bold_lead); r.bold = True
            r.font.name = FONT; r.font.size = Pt(BODY_SIZE)
        r2 = para.add_run(text); r2.font.name = FONT; r2.font.size = Pt(BODY_SIZE)
        return para

    # ── headings (numbered) ───────────────────────────────────────────────────
    def chapter(self, title, page_break=True):
        self.ch += 1
        self.sec = 0
        self.sub = 0
        self.lst_no = 0
        if page_break:
            self.doc.add_page_break()
        h = self.doc.add_heading(level=1)
        h.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = h.add_run(f"CHAPTER {self.ch}")
        r.bold = True
        r.font.name = FONT
        r.font.size = Pt(16)
        r.font.color.rgb = HEADING_BLUE
        h2 = self.doc.add_heading(level=1)
        h2.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r2 = h2.add_run(f"{self.ch}.  {title.upper()}")
        r2.bold = True
        r2.font.name = FONT
        r2.font.size = Pt(15)
        r2.font.color.rgb = HEADING_BLUE
        self.doc.add_paragraph()
        return self.ch

    def section(self, title):
        self.sec += 1
        self.sub = 0
        h = self.doc.add_heading(level=2)
        r = h.add_run(f"{self.ch}.{self.sec}  {title}")
        r.bold = True
        r.font.name = FONT
        r.font.size = Pt(13)
        r.font.color.rgb = HEADING_BLUE
        return f"{self.ch}.{self.sec}"

    def subsection(self, title):
        self.sub += 1
        h = self.doc.add_heading(level=3)
        r = h.add_run(f"{self.ch}.{self.sec}.{self.sub}  {title}")
        r.bold = True
        r.font.name = FONT
        r.font.size = Pt(12)
        r.font.color.rgb = HEADING_BLUE
        return f"{self.ch}.{self.sec}.{self.sub}"

    def plain_heading(self, title, level=1, size=15, center=True):
        h = self.doc.add_heading(level=level)
        if center:
            h.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = h.add_run(title)
        r.bold = True
        r.font.name = FONT
        r.font.size = Pt(size)
        r.font.color.rgb = HEADING_BLUE
        return h

    # ── figures ───────────────────────────────────────────────────────────────
    def figure(self, filename, caption, width=6.0):
        self.fig_no += 1
        path = os.path.join(self.images_dir, filename)
        p = self.doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        if os.path.exists(path):
            run = p.add_run()
            run.add_picture(path, width=Inches(width))
        else:
            p.add_run(f"[Image not found: {filename}]").italic = True
        cap = self.doc.add_paragraph()
        cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
        cap.paragraph_format.space_before = Pt(2)
        cap.paragraph_format.space_after = Pt(12)
        label = f"Figure {self.ch}.{self.fig_no}: {caption}"
        r = cap.add_run(label)
        r.italic = True
        r.font.name = FONT
        r.font.size = Pt(10)
        bookmark = f"FIG_{self.ch}_{self.fig_no}"
        self._add_bookmark(cap, bookmark)
        self.fig_captions.append((label, bookmark))
        return self.fig_no

    def image_placeholder(self, caption, height_note="Insert screenshot here"):
        """A bordered placeholder box recommending an image to be added manually."""
        self.fig_no += 1
        tbl = self.doc.add_table(rows=1, cols=1)
        tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
        cell = tbl.cell(0, 0)
        cell.width = Inches(5.5)
        para = cell.paragraphs[0]
        para.alignment = WD_ALIGN_PARAGRAPH.CENTER
        para.paragraph_format.space_before = Pt(26)
        para.paragraph_format.space_after = Pt(26)
        r = para.add_run(f"[ {height_note} ]")
        r.italic = True
        r.font.size = Pt(10)
        r.font.color.rgb = RGBColor(0x88, 0x88, 0x88)
        self._set_cell_border(cell)
        cap = self.doc.add_paragraph()
        cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
        cap.paragraph_format.space_after = Pt(12)
        label = f"Figure {self.ch}.{self.fig_no}: {caption}"
        rr = cap.add_run(label)
        rr.italic = True
        rr.font.size = Pt(10)
        bookmark = f"FIG_{self.ch}_{self.fig_no}"
        self._add_bookmark(cap, bookmark)
        self.fig_captions.append((label, bookmark))
        return self.fig_no

    # ── tables ────────────────────────────────────────────────────────────────
    def table(self, caption, headers, rows, col_widths=None, font_size=10,
              header_fill="1F3B73"):
        """Full-width table with left-aligned caption ABOVE it."""
        self.tbl_no += 1
        cap = self.doc.add_paragraph()
        cap.alignment = WD_ALIGN_PARAGRAPH.LEFT
        cap.paragraph_format.space_before = Pt(6)
        cap.paragraph_format.space_after = Pt(3)
        label = f"Table {self.ch}.{self.tbl_no}: {caption}"
        r = cap.add_run(label)
        r.bold = True
        r.font.name = FONT
        r.font.size = Pt(10)
        bookmark = f"TBL_{self.ch}_{self.tbl_no}"
        self._add_bookmark(cap, bookmark)
        self.tbl_captions.append((label, bookmark))

        ncols = len(headers)
        tbl = self.doc.add_table(rows=1, cols=ncols)
        tbl.style = "Table Grid"
        tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
        tbl.autofit = False
        total = 6.27
        if col_widths is None:
            col_widths = [total / ncols] * ncols
        # header
        hdr = tbl.rows[0].cells
        for i, htext in enumerate(headers):
            hdr[i].text = ""
            para = hdr[i].paragraphs[0]
            run = para.add_run(htext)
            run.bold = True
            run.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
            run.font.size = Pt(font_size)
            run.font.name = FONT
            self._shade_cell(hdr[i], header_fill)
        # body
        for row in rows:
            cells = tbl.add_row().cells
            for i, val in enumerate(row):
                cells[i].text = ""
                para = cells[i].paragraphs[0]
                run = para.add_run(str(val))
                run.font.size = Pt(font_size)
                run.font.name = FONT
        # widths
        for i, w in enumerate(col_widths):
            for row in tbl.rows:
                row.cells[i].width = Inches(w)
        self.doc.add_paragraph().paragraph_format.space_after = Pt(4)
        return self.tbl_no

    def usecase_table(self, caption, ucid, rows):
        """Two-column attribute/details table used for use cases & test cases."""
        return self.table(caption, ["Attribute", "Details"], rows,
                          col_widths=[1.7, 4.57], font_size=10)

    # ── code listings ─────────────────────────────────────────────────────────
    def code(self, caption, code_text, lang="dart"):
        """A shaded, monospaced code listing with a 'Listing X.Y' caption above."""
        self.lst_no += 1
        cap = self.doc.add_paragraph()
        cap.alignment = WD_ALIGN_PARAGRAPH.LEFT
        cap.paragraph_format.space_before = Pt(6)
        cap.paragraph_format.space_after = Pt(2)
        r = cap.add_run(f"Listing {self.ch}.{self.lst_no}: {caption}")
        r.bold = True
        r.font.name = FONT
        r.font.size = Pt(10)

        tbl = self.doc.add_table(rows=1, cols=1)
        tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
        cell = tbl.cell(0, 0)
        cell.width = Inches(6.27)
        self._shade_cell(cell, "F4F4F4")
        self._set_solid_border(cell)
        # clear default paragraph
        cell.paragraphs[0].text = ""
        lines = code_text.strip("\n").split("\n")
        for i, line in enumerate(lines):
            para = cell.paragraphs[0] if i == 0 else cell.add_paragraph()
            para.paragraph_format.space_after = Pt(0)
            para.paragraph_format.space_before = Pt(0)
            para.paragraph_format.line_spacing = 1.0
            run = para.add_run(line if line else " ")
            run.font.name = "Consolas"
            run.font.size = Pt(8.5)
            run.font.color.rgb = RGBColor(0x1A, 0x1A, 0x1A)
        self.doc.add_paragraph().paragraph_format.space_after = Pt(4)
        return self.lst_no

    def chapter_reset_listing(self):
        self.lst_no = 0

    # ── helpers for shading / borders ─────────────────────────────────────────
    @staticmethod
    def _shade_cell(cell, hexcolor):
        tcPr = cell._tc.get_or_add_tcPr()
        shd = OxmlElement("w:shd")
        shd.set(qn("w:val"), "clear")
        shd.set(qn("w:color"), "auto")
        shd.set(qn("w:fill"), hexcolor)
        tcPr.append(shd)

    @staticmethod
    def _set_cell_border(cell):
        tcPr = cell._tc.get_or_add_tcPr()
        borders = OxmlElement("w:tcBorders")
        for edge in ("top", "left", "bottom", "right"):
            el = OxmlElement(f"w:{edge}")
            el.set(qn("w:val"), "dashed")
            el.set(qn("w:sz"), "6")
            el.set(qn("w:color"), "999999")
            borders.append(el)
        tcPr.append(borders)

    @staticmethod
    def _set_solid_border(cell):
        tcPr = cell._tc.get_or_add_tcPr()
        borders = OxmlElement("w:tcBorders")
        for edge in ("top", "left", "bottom", "right"):
            el = OxmlElement(f"w:{edge}")
            el.set(qn("w:val"), "single")
            el.set(qn("w:sz"), "4")
            el.set(qn("w:color"), "CCCCCC")
            borders.append(el)
        tcPr.append(borders)

    def _add_bookmark(self, paragraph, name):
        """Wrap a paragraph's content in a named bookmark so PAGEREF fields can target it."""
        self._bm_id += 1
        start = OxmlElement("w:bookmarkStart")
        start.set(qn("w:id"), str(self._bm_id))
        start.set(qn("w:name"), name)
        end = OxmlElement("w:bookmarkEnd")
        end.set(qn("w:id"), str(self._bm_id))
        paragraph._p.insert(0, start)
        paragraph._p.append(end)

    def add_pageref(self, paragraph, bookmark):
        """Append a PAGEREF field run to a paragraph, resolving to a bookmark's page number."""
        run = paragraph.add_run()
        run.font.name = FONT
        run.font.size = Pt(11)
        fld = OxmlElement("w:fldSimple")
        fld.set(qn("w:instr"), f"PAGEREF {bookmark} \\h")
        run._r.append(fld)
        return run

    # ── front matter / page features ──────────────────────────────────────────
    def page_break(self):
        self.doc.add_page_break()

    def add_page_numbers(self):
        """Add 'Page X' centred in the footer of every section."""
        for section in self.doc.sections:
            footer = section.footer
            p = footer.paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            run = p.add_run()
            fld1 = OxmlElement("w:fldSimple")
            fld1.set(qn("w:instr"), "PAGE")
            run._r.append(fld1)

    def toc(self):
        """Insert a Word Table-of-Contents field (updates on open / F9)."""
        para = self.doc.add_paragraph()
        run = para.add_run()
        fldBegin = OxmlElement("w:fldChar")
        fldBegin.set(qn("w:fldCharType"), "begin")
        instr = OxmlElement("w:instrText")
        instr.set(qn("xml:space"), "preserve")
        instr.text = 'TOC \\o "1-3" \\h \\z \\u'
        fldSep = OxmlElement("w:fldChar")
        fldSep.set(qn("w:fldCharType"), "separate")
        t = OxmlElement("w:t")
        t.text = "Right-click and choose 'Update Field' to build the Table of Contents."
        fldEnd = OxmlElement("w:fldChar")
        fldEnd.set(qn("w:fldCharType"), "end")
        run._r.append(fldBegin)
        run._r.append(instr)
        run._r.append(fldSep)
        run._r.append(t)
        run._r.append(fldEnd)

    def _set_update_fields_on_open(self):
        """Tell Word to recompute all fields (TOC, PAGEREF, PAGE) automatically on open."""
        settings = self.doc.settings.element
        upd = OxmlElement("w:updateFields")
        upd.set(qn("w:val"), "true")
        settings.append(upd)

    def save(self, path):
        self._set_update_fields_on_open()
        self.doc.save(path)
