import io
import re
from datetime import datetime
from collections import defaultdict
from typing import List

from reportlab.lib.pagesizes import letter
from reportlab.platypus import (
    SimpleDocTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
    PageBreak,
    Flowable,
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors
from reportlab.pdfgen import canvas

from app.models.statement import Statement
from app.models.transaction import Transaction
from app.services.visualization_service import VisualizationService
from app.services.insights_service import InsightsService


class NumberedCanvas(canvas.Canvas):
    """
    Two-pass canvas to dynamically compute and stamp 'Page X of Y' page numbers
    and professional running headers/footers onto every page.
    """
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super().showPage()
        super().save()

    def draw_page_decorations(self, page_count):
        self.saveState()
        
        # We suppress running headers on Page 1 (Title Cover)
        if self._pageNumber > 1:
            # Running Header
            self.setFont("Helvetica-Bold", 8)
            self.setFillColor(colors.HexColor("#475569"))
            self.drawString(54, 750, "StatementX AI \u2014 PERSONAL FINANCE EXECUTIVE ANALYSIS")
            
            self.setStrokeColor(colors.HexColor("#CBD5E1"))
            self.setLineWidth(0.5)
            self.line(54, 742, 558, 742)

        # Running Footer (All pages)
        self.setStrokeColor(colors.HexColor("#E2E8F0"))
        self.setLineWidth(0.5)
        self.line(54, 54, 558, 54)

        self.setFont("Helvetica-Bold", 8)
        self.setFillColor(colors.HexColor("#64748B"))
        self.drawString(54, 38, "CONFIDENTIAL")
        
        self.setFont("Helvetica", 8)
        self.drawString(130, 38, "\u2014 GENERATED AUTOMATICALLY BY STATEMENTX INTEL LAYERS")
        
        page_text = f"Page {self._pageNumber} of {page_count}"
        self.drawRightString(558, 38, page_text)
        
        self.restoreState()


class HorizontalProgressBar(Flowable):
    """
    Dynamic visual bar representation drawn directly inside ReportLab table cells.
    """
    def __init__(self, width: float, height: float, percentage: float, color_hex: str):
        super().__init__()
        self.width = width
        self.height = height
        self.percentage = max(0.0, min(100.0, percentage))
        self.color_hex = color_hex

    def wrap(self, availWidth, availHeight):
        return self.width, self.height

    def draw(self):
        self.canv.saveState()
        
        # Track Background
        self.canv.setFillColor(colors.HexColor("#F1F5F9"))
        self.canv.setStrokeColor(colors.HexColor("#E2E8F0"))
        self.canv.setLineWidth(0.5)
        self.canv.roundRect(0, 2, self.width, self.height, self.height / 2, fill=True, stroke=True)
        
        # Fill Progress
        fill_w = self.width * (self.percentage / 100.0)
        if fill_w > 0:
            self.canv.setFillColor(colors.HexColor(self.color_hex))
            self.canv.roundRect(0, 2, fill_w, self.height, self.height / 2, fill=True, stroke=False)
            
        self.canv.restoreState()


class PDFReportService:
    @staticmethod
    def generate_pdf_report(db, statement_id: str) -> io.BytesIO:
        # 1. Fetch visualization & insights structures
        vis_data = VisualizationService.calculate_visualization_data(db, statement_id)
        raw_statement = db.query(Statement).filter(Statement.statement_id == statement_id).first()
        
        # Fetch chronological transaction ledger
        transactions = (
            db.query(Transaction)
            .filter(Transaction.statement_id == statement_id)
            .order_by(Transaction.date.asc())
            .all()
        )
        
        # Fallback to visual insights dynamic defaults for summaries
        ai_summary = "No detailed narrative summary generated."
        ai_recs = []
        if raw_statement and isinstance(raw_statement.raw_ai_output, dict):
            cached_insights = raw_statement.raw_ai_output.get("ai_insights")
            if cached_insights:
                ai_summary = cached_insights.get("summary", ai_summary)
                ai_recs = cached_insights.get("recommendations", [])

        # Buffer allocation
        pdf_buffer = io.BytesIO()
        
        # Page size setup (Letter: 612x792 pt). 0.75in Margin = 54pt. Printable width = 504pt
        doc = SimpleDocTemplate(
            pdf_buffer,
            pagesize=letter,
            leftMargin=54,
            rightMargin=54,
            topMargin=72,
            bottomMargin=72
        )

        styles = getSampleStyleSheet()
        
        # Base colors
        c_primary = colors.HexColor("#1A365D")   # Deep Corporate Navy
        c_secondary = colors.HexColor("#0D9488") # Muted Teal
        c_dark = colors.HexColor("#1E293B")      # Slate Dark
        c_light = colors.HexColor("#F8FAFC")     # Soft White Slate
        c_border = colors.HexColor("#E2E8F0")    # Soft Grey Border

        # Styles definition
        title_style = ParagraphStyle(
            "CoverTitle",
            parent=styles["Title"],
            fontName="Helvetica-Bold",
            fontSize=22,
            leading=28,
            textColor=colors.white,
            alignment=0, # Left-aligned inside banner
            spaceAfter=6
        )
        
        subtitle_style = ParagraphStyle(
            "CoverSub",
            fontName="Helvetica-Bold",
            fontSize=10,
            leading=14,
            textColor=colors.HexColor("#94A3B8"),
            spaceAfter=2
        )

        h1_style = ParagraphStyle(
            "SectionHeader",
            parent=styles["Heading1"],
            fontName="Helvetica-Bold",
            fontSize=14,
            leading=18,
            textColor=c_primary,
            spaceBefore=14,
            spaceAfter=8,
            keepWithNext=True
        )

        h2_style = ParagraphStyle(
            "SubSectionHeader",
            parent=styles["Heading2"],
            fontName="Helvetica-Bold",
            fontSize=11,
            leading=15,
            textColor=c_secondary,
            spaceBefore=8,
            spaceAfter=4,
            keepWithNext=True
        )

        body_style = ParagraphStyle(
            "BodyStandard",
            parent=styles["Normal"],
            fontName="Helvetica",
            fontSize=9.5,
            leading=14,
            textColor=c_dark,
            spaceAfter=8
        )

        summary_style = ParagraphStyle(
            "ExecutiveSummary",
            parent=body_style,
            fontSize=10,
            leading=15,
            textColor=colors.HexColor("#334155")
        )

        cell_style = ParagraphStyle(
            "TableCell",
            parent=styles["Normal"],
            fontName="Helvetica",
            fontSize=8.5,
            leading=11,
            textColor=c_dark
        )

        cell_bold_style = ParagraphStyle(
            "TableCellBold",
            parent=cell_style,
            fontName="Helvetica-Bold"
        )
        
        card_label_style = ParagraphStyle(
            "CardLabel",
            fontName="Helvetica-Bold",
            fontSize=9,
            leading=11,
            textColor=colors.HexColor("#475569")
        )

        card_val_style = ParagraphStyle(
            "CardVal",
            fontName="Helvetica-Bold",
            fontSize=14,
            leading=16,
            textColor=c_primary
        )

        story = []

        # =========================================================================
        # PAGE 1: TITLE BANNER & EXECUTIVE SUMMARY
        # =========================================================================
        # Premium title block using a single-cell table for header padding background
        title_para = Paragraph("EXECUTIVE FINANCIAL REPORT", title_style)
        sub_para = Paragraph("STATEMENTX AUTOMATED INTELLIGENCE PARSING ENGINE", subtitle_style)
        bank_para = Paragraph(f"INSTITUTION: {vis_data.bank_name.upper()} | METRIC AUDIT DRAFT", subtitle_style)
        
        title_block_data = [[title_para], [sub_para], [bank_para]]
        title_table = Table(title_block_data, colWidths=[504])
        title_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, -1), c_primary),
            ('TOPPADDING', (0, 0), (-1, -1), 24),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 24),
            ('LEFTPADDING', (0, 0), (-1, -1), 18),
            ('RIGHTPADDING', (0, 0), (-1, -1), 18),
            ('BOTTOMPADDING', (0, 2), (-1, 2), 24),
        ]))
        story.append(title_table)
        story.append(Spacer(1, 16))

        # Metadata Table
        metadata_data = [
            [Paragraph("<b>File Name:</b>", cell_style), Paragraph(raw_statement.file_name if raw_statement else "N/A", cell_style),
             Paragraph("<b>Audit Date:</b>", cell_style), Paragraph(datetime.now().strftime("%d/%m/%Y"), cell_style)],
            [Paragraph("<b>Statement ID:</b>", cell_style), Paragraph(statement_id[:18] + "...", cell_style),
             Paragraph("<b>Source Bank:</b>", cell_style), Paragraph(vis_data.bank_name, cell_style)]
        ]
        metadata_table = Table(metadata_data, colWidths=[90, 162, 90, 162])
        metadata_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, -1), c_light),
            ('INNERGRID', (0, 0), (-1, -1), 0.5, c_border),
            ('BOX', (0, 0), (-1, -1), 0.5, c_border),
            ('PADDING', (0, 0), (-1, -1), 6),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ]))
        story.append(metadata_table)
        story.append(Spacer(1, 24))

        # Executive Summary Section
        story.append(Paragraph("1. Executive Summary & Core Cash Flow", h1_style))
        
        # Format markdown elements cleanly into ReportLab compliant XML
        summary_lines = []
        for line in ai_summary.split("\n"):
            line = line.strip()
            if line.startswith("###"):
                heading_text = line.replace("###", "").strip()
                summary_lines.append(f"<br/><font color='#1A365D'><b>{heading_text}</b></font><br/>")
            elif line.startswith("-"):
                bullet_text = line.replace("-", "").strip()
                summary_lines.append(f"&bull; {bullet_text}<br/>")
            elif line.startswith("*"):
                bullet_text = line.replace("*", "").strip()
                summary_lines.append(f"&bull; {bullet_text}<br/>")
            elif line:
                summary_lines.append(f"{line}<br/>")
            else:
                summary_lines.append("<br/>")
        summary_clean = "".join(summary_lines)
        
        # Replace **bold** markdown with <b>bold</b> tags
        summary_clean = re.sub(r"\*\*(.*?)\*\*", r"<b>\1</b>", summary_clean)
        summary_clean = summary_clean.replace("`", "")

        story.append(Paragraph(summary_clean, summary_style))
        
        story.append(PageBreak())

        # =========================================================================
        # PAGE 2: FINANCIAL HEALTH SCORECARD & 50/30/20 BUDGET RULE
        # =========================================================================
        story.append(Paragraph("2. Financial Health Scorecard", h1_style))
        story.append(Paragraph(
            "Our algorithms analyze spending speed, saving consistency, anomalous distributions, and debt burn factors to generate key financial indicators.",
            body_style
        ))
        story.append(Spacer(1, 4))

        hi = vis_data.health_indicators
        rating_color = "#047857" if hi.health_rating == "Excellent" else ("#0D9488" if hi.health_rating == "Good" else ("#D97706" if hi.health_rating == "Fair" else "#B91C1C"))
        
        # Grid of Indicators rendered using a Table
        indicators_data = [
            [
                Table([[Paragraph("HEALTH SCORE", card_label_style)], [Paragraph(f"<font color='{rating_color}'><b>{hi.health_score}/100</b> ({hi.health_rating})</font>", card_val_style)]], colWidths=[244]),
                Table([[Paragraph("SAVINGS RATE", card_label_style)], [Paragraph(f"{hi.savings_rate}%", card_val_style)]], colWidths=[244])
            ],
            [Spacer(1, 10), Spacer(1, 10)],
            [
                Table([[Paragraph("BURN RATE (EXPENSE/INCOME)", card_label_style)], [Paragraph(f"{hi.burn_rate}%", card_val_style)]], colWidths=[244]),
                Table([[Paragraph("LIQUIDITY COVERAGE", card_label_style)], [Paragraph(f"{hi.liquidity_ratio} months", card_val_style)]], colWidths=[244])
            ],
            [Spacer(1, 10), Spacer(1, 10)],
            [
                Table([[Paragraph("AVG DAILY BURN", card_label_style)], [Paragraph(f"INR {hi.average_daily_expense:.2f}", card_val_style)]], colWidths=[244]),
                Table([[Paragraph("INFLOW CONSISTENCY", card_label_style)], [Paragraph(f"{hi.savings_consistency:.1f}%", card_val_style)]], colWidths=[244])
            ]
        ]
        
        indicators_table = Table(indicators_data, colWidths=[252, 252])
        for row_idx in [0, 2, 4]:
            indicators_table.setStyle(TableStyle([
                ('BACKGROUND', (0, row_idx), (0, row_idx), c_light),
                ('BACKGROUND', (1, row_idx), (1, row_idx), c_light),
                ('BOX', (0, row_idx), (0, row_idx), 0.5, c_border),
                ('BOX', (1, row_idx), (1, row_idx), 0.5, c_border),
                ('PADDING', (0, row_idx), (-1, row_idx), 0),
            ]))
        story.append(indicators_table)
        story.append(Spacer(1, 24))

        # 50/30/20 Budgeting Section
        story.append(Paragraph("3. 50/30/20 Budget Compliance Audit", h1_style))
        story.append(Paragraph(
            "The 50/30/20 budget framework divides net cash flow into Essential Needs (50%), Discretionary Wants (30%), and Savings (20%). Outlining actual allocations exposes budget structural deficits.",
            body_style
        ))
        
        ba = vis_data.budget_allocation
        budget_headers = [Paragraph("<b>Framework Sector</b>", cell_bold_style), Paragraph("<b>Spent (INR)</b>", cell_bold_style), Paragraph("<b>Actual %</b>", cell_bold_style), Paragraph("<b>Target %</b>", cell_bold_style), Paragraph("<b>Allocation Bar</b>", cell_bold_style)]
        
        needs_bar = HorizontalProgressBar(140, 8, ba.needs_percentage, "#1565C0")
        wants_bar = HorizontalProgressBar(140, 8, ba.wants_percentage, "#E65100")
        savings_bar = HorizontalProgressBar(140, 8, ba.savings_percentage, "#047857")

        budget_rows = [
            budget_headers,
            [Paragraph("Essential Needs", cell_style), Paragraph(f"INR {ba.needs_amount:.2f}", cell_style), Paragraph(f"{ba.needs_percentage}%", cell_style), Paragraph("50.0%", cell_style), needs_bar],
            [Paragraph("Discretionary Wants", cell_style), Paragraph(f"INR {ba.wants_amount:.2f}", cell_style), Paragraph(f"{ba.wants_percentage}%", cell_style), Paragraph("30.0%", cell_style), wants_bar],
            [Paragraph("Net Savings / Surplus", cell_style), Paragraph(f"INR {ba.savings_amount:.2f}", cell_style), Paragraph(f"{ba.savings_percentage}%", cell_style), Paragraph("20.0%", cell_style), savings_bar]
        ]
        
        budget_table = Table(budget_rows, colWidths=[110, 84, 54, 54, 202])
        budget_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), c_light),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 6),
            ('TOPPADDING', (0, 0), (-1, 0), 6),
            ('LINEBELOW', (0, 0), (-1, 0), 1, c_primary),
            ('INNERGRID', (0, 0), (-1, -1), 0.5, c_border),
            ('BOX', (0, 0), (-1, -1), 0.5, c_border),
            ('PADDING', (0, 1), (-1, -1), 8),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ]))
        story.append(budget_table)
        
        story.append(PageBreak())

        # =========================================================================
        # PAGE 3: CATEGORY SPENDING BREAKDOWN WITH PROGRESS BARS
        # =========================================================================
        story.append(Paragraph("4. Spend Category Distribution Analysis", h1_style))
        story.append(Paragraph(
            "Categorized summary of all debits. Progression bars reflect each category's relative size compared to your total expenditure, revealing cost concentration centers.",
            body_style
        ))
        story.append(Spacer(1, 4))

        cat_headers = [
            Paragraph("<b>Category</b>", cell_bold_style),
            Paragraph("<b>Transactions</b>", cell_bold_style),
            Paragraph("<b>Spent (INR)</b>", cell_bold_style),
            Paragraph("<b>Expense Share</b>", cell_bold_style),
            Paragraph("<b>Visual Share Bar</b>", cell_bold_style)
        ]
        
        cat_rows = [cat_headers]
        for idx, item in enumerate(vis_data.category_breakdown):
            bar = HorizontalProgressBar(140, 8, item.percentage, item.color)
            cat_rows.append([
                Paragraph(item.category, cell_style),
                Paragraph(str(item.transaction_count), cell_style),
                Paragraph(f"INR {item.amount:.2f}", cell_style),
                Paragraph(f"{item.percentage}%", cell_style),
                bar
            ])

        cat_table = Table(cat_rows, colWidths=[130, 74, 84, 74, 142])
        cat_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), c_light),
            ('LINEBELOW', (0, 0), (-1, 0), 1, c_primary),
            ('INNERGRID', (0, 0), (-1, -1), 0.5, c_border),
            ('BOX', (0, 0), (-1, -1), 0.5, c_border),
            ('PADDING', (0, 0), (-1, -1), 6),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ]))
        story.append(cat_table)
        story.append(Spacer(1, 16))

        # Highlight primary sector
        if vis_data.category_breakdown:
            top_cat = vis_data.category_breakdown[0]
            summary_box_data = [[
                Paragraph(
                    f"<b>Cost Concentration Alert:</b> Your primary spending sector resides in <b>'{top_cat.category}'</b>, accounting for "
                    f"<b>{top_cat.percentage}%</b> of all statement expenses (INR {top_cat.amount:.2f} spent across {top_cat.transaction_count} transactions). "
                    f"Targeting budget trims here will maximize cash flow release speed.",
                    cell_style
                )
            ]]
            summary_box = Table(summary_box_data, colWidths=[504])
            summary_box.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor("#FEF3C7")), # Warm warning amber background
                ('BOX', (0, 0), (-1, -1), 0.5, colors.HexColor("#F59E0B")),
                ('PADDING', (0, 0), (-1, -1), 8),
            ]))
            story.append(summary_box)

        story.append(PageBreak())

        # =========================================================================
        # PAGE 4: SUBSCRIPTIONS & FORENSIC ANOMALY AUDIT
        # =========================================================================
        story.append(Paragraph("5. Detected Recurring Subscriptions", h1_style))
        story.append(Paragraph(
            "Subscriptions represent repeating periodic cash outflows. Underutilized monthly subscription commitments are critical savings leaks.",
            body_style
        ))
        
        subscriptions = InsightsService._detect_subscriptions(transactions)
        
        if subscriptions:
            sub_headers = [
                Paragraph("<b>Subscription Vendor</b>", cell_bold_style),
                Paragraph("<b>Average Billing</b>", cell_bold_style),
                Paragraph("<b>Frequency</b>", cell_bold_style),
                Paragraph("<b>Last Billing Date</b>", cell_bold_style)
            ]
            sub_rows = [sub_headers]
            for sub in subscriptions:
                sub_rows.append([
                    Paragraph(sub.vendor, cell_style),
                    Paragraph(f"INR {sub.average_amount:.2f}", cell_style),
                    Paragraph(sub.frequency.capitalize(), cell_style),
                    Paragraph(sub.last_transaction_date, cell_style)
                ])
            sub_table = Table(sub_rows, colWidths=[150, 110, 114, 130])
            sub_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), c_light),
                ('LINEBELOW', (0, 0), (-1, 0), 1, c_primary),
                ('INNERGRID', (0, 0), (-1, -1), 0.5, c_border),
                ('BOX', (0, 0), (-1, -1), 0.5, c_border),
                ('PADDING', (0, 0), (-1, -1), 6),
                ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ]))
            story.append(sub_table)
        else:
            story.append(Paragraph("<i>No recurring subscriptions or bill patterns detected in the parsed period.</i>", body_style))
        
        story.append(Spacer(1, 16))

        # Forensic Anomaly Audit
        story.append(Paragraph("6. Forensic Security & Operational Risk Audit", h1_style))
        story.append(Paragraph(
            "Forensic scans highlight transactions flagged as duplicated, statistically significant high-value outliers, or suspicious late-night activities.",
            body_style
        ))

        debit_transactions = [t for t in transactions if float(t.debit) > 0]
        debit_amounts = [float(t.debit) for t in debit_transactions]
        anomalies = InsightsService._detect_anomalies(debit_transactions, debit_amounts)

        if anomalies:
            for anom in anomalies[:4]: # Limit to top 4 anomalies on this page
                a_color = "#B91C1C" if anom.type == "high_value" else "#D97706"
                anom_card_data = [[
                    Paragraph(f"<b>TYPE: {anom.type.upper().replace('_', ' ')}</b>", ParagraphStyle("TypeS", fontName="Helvetica-Bold", fontSize=8, leading=10, textColor=colors.HexColor(a_color))),
                    Paragraph(f"<b>DATE:</b> {anom.date} | <b>AMOUNT:</b> INR {anom.amount:.2f}", ParagraphStyle("DateS", fontName="Helvetica", fontSize=8, leading=10, alignment=2))
                ], [
                    Paragraph(f"<b>Narration:</b> {anom.narration}", cell_style), ""
                ], [
                    Paragraph(f"<b>Flag Reason:</b> {anom.reason}", cell_style), ""
                ]]
                
                anom_card = Table(anom_card_data, colWidths=[360, 144])
                anom_card.setStyle(TableStyle([
                    ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor("#FEF2F2" if anom.type == "high_value" else "#FFFBEB")),
                    ('BOX', (0, 0), (-1, -1), 0.5, colors.HexColor("#FECECE" if anom.type == "high_value" else "#FDE68A")),
                    ('SPAN', (0, 1), (1, 1)),
                    ('SPAN', (0, 2), (1, 2)),
                    ('PADDING', (0, 0), (-1, -1), 4),
                    ('BOTTOMPADDING', (0, 2), (-1, 2), 6),
                ]))
                story.append(anom_card)
                story.append(Spacer(1, 8))
        else:
            story.append(Paragraph("<i>No suspicious transaction anomalies or high-value outliers flagged.</i>", body_style))

        story.append(PageBreak())

        # =========================================================================
        # PAGE 5: STRATEGIC ACTION ROADMAP
        # =========================================================================
        story.append(Paragraph("7. Strategic Financial Health Blueprint", h1_style))
        story.append(Paragraph(
            "Actionable financial coaching recommendations statically compiled and optimized for instant cash flow adjustments.",
            body_style
        ))
        story.append(Spacer(1, 4))

        if ai_recs:
            for rec in ai_recs[:4]: # Render top 4 recommendations
                r_title = rec.get("title", "Plan Action")
                r_desc = rec.get("description", "")
                r_impact = rec.get("impact", "Medium")
                r_action = rec.get("action_item", "")
                r_cat = rec.get("target_category", "Financial Services")

                badge_color = "#047857" if r_impact == "High" else ("#475569" if r_impact == "Medium" else "#1D4ED8")
                
                rec_card_data = [[
                    Paragraph(f"<b>{r_title.upper()}</b>", ParagraphStyle("TitleR", fontName="Helvetica-Bold", fontSize=9, leading=11, textColor=c_primary)),
                    Paragraph(f"<b>IMPACT: {r_impact}</b>", ParagraphStyle("ImpactB", fontName="Helvetica-Bold", fontSize=8, leading=10, textColor=colors.HexColor(badge_color), alignment=2))
                ], [
                    Paragraph(f"<b>Focus Area:</b> {r_cat} | <b>Guidance:</b> {r_desc}", cell_style), ""
                ], [
                    Paragraph(f"<b>Action Item:</b> <i>{r_action}</i>", cell_style), ""
                ]]
                
                rec_card = Table(rec_card_data, colWidths=[380, 124])
                rec_card.setStyle(TableStyle([
                    ('BACKGROUND', (0, 0), (-1, -1), c_light),
                    ('BOX', (0, 0), (-1, -1), 0.5, c_border),
                    ('SPAN', (0, 1), (1, 1)),
                    ('SPAN', (0, 2), (1, 2)),
                    ('PADDING', (0, 0), (-1, -1), 5),
                    ('BOTTOMPADDING', (0, 2), (-1, 2), 6),
                ]))
                story.append(rec_card)
                story.append(Spacer(1, 10))
        else:
            # Fallback static roadmap card
            rec_card_data = [[
                Paragraph("<b>IMPLEMENT A 50/30/20 CASH FLOW BLUEPRINT</b>", ParagraphStyle("TitleR", fontName="Helvetica-Bold", fontSize=9, leading=11, textColor=c_primary)),
                Paragraph("<b>IMPACT: HIGH</b>", ParagraphStyle("ImpactB", fontName="Helvetica-Bold", fontSize=8, leading=10, textColor=colors.HexColor("#047857"), alignment=2))
            ], [
                Paragraph("Your savings rate falls short of the recommended 20% standard. You need to structure budgets immediately to establish a cash flow buffer.", cell_style), ""
            ], [
                Paragraph("<b>Action Item:</b> Limit all non-essential spends (wants) to less than 30% of income next month.", cell_style), ""
            ]]
            rec_card = Table(rec_card_data, colWidths=[380, 124])
            rec_card.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, -1), c_light),
                ('BOX', (0, 0), (-1, -1), 0.5, c_border),
                ('SPAN', (0, 1), (1, 1)),
                ('SPAN', (0, 2), (1, 2)),
                ('PADDING', (0, 0), (-1, -1), 5),
                ('BOTTOMPADDING', (0, 2), (-1, 2), 6),
            ]))
            story.append(rec_card)
            story.append(Spacer(1, 10))

        story.append(Spacer(1, 16))
        
        # Closing Signature Block
        sig_data = [
            [Paragraph("Report Compiled Automatically by <b>StatementX Engine Core</b>", ParagraphStyle("SigS", fontName="Helvetica", fontSize=8, leading=10, textColor=colors.HexColor("#64748B")))]
        ]
        sig_table = Table(sig_data, colWidths=[504])
        sig_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor("#F1F5F9")),
            ('PADDING', (0, 0), (-1, -1), 6),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ]))
        story.append(sig_table)

        # Build Document
        doc.build(story, canvasmaker=NumberedCanvas)
        pdf_buffer.seek(0)
        return pdf_buffer
