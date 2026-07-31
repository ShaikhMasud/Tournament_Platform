"""
PDF builder for match results using ReportLab.
"""
import io
from collections import defaultdict
from datetime import datetime
from typing import List

from django.utils import timezone
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import (
    Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle
)


# Colors matching the original template
HEADER_BLUE = colors.HexColor('#2563eb')
DARK_BLUE = colors.HexColor('#1e40af')
GRAY = colors.HexColor('#6b7280')
LIGHT_GRAY = colors.HexColor('#f3f4f6')
BORDER_GRAY = colors.HexColor('#e5e7eb')
TABLE_HEADER_BG = colors.HexColor('#f9fafb')
WINNER_GREEN = colors.HexColor('#059669')
ODD_ROW = colors.HexColor('#f9fafb')


def build_match_results_pdf(tournament, matches: List[dict]) -> io.BytesIO:
    """
    Build a PDF document for tournament match results.

    Args:
        tournament: The Tournament object.
        matches: List of match data dictionaries.

    Returns:
        A BytesIO object containing the PDF.
    """
    pdf_buffer = io.BytesIO()
    doc = SimpleDocTemplate(
        pdf_buffer,
        pagesize=A4,
        leftMargin=1.5*cm,
        rightMargin=1.5*cm,
        topMargin=1.5*cm,
        bottomMargin=1.5*cm,
    )

    elements = []
    styles = getSampleStyleSheet()

    # Custom styles
    title_style = ParagraphStyle(
        'Title',
        parent=styles['Heading1'],
        fontSize=22,
        textColor=DARK_BLUE,
        alignment=1,  # center
        spaceAfter=6,
    )
    subtitle_style = ParagraphStyle(
        'Subtitle',
        parent=styles['Normal'],
        fontSize=10,
        textColor=GRAY,
        alignment=1,
        spaceAfter=20,
    )
    section_title_style = ParagraphStyle(
        'SectionTitle',
        parent=styles['Heading2'],
        fontSize=12,
        textColor=colors.white,
        backColor=HEADER_BLUE,
        spaceBefore=15,
        spaceAfter=8,
        leftIndent=5,
        rightIndent=5,
    )

    # Header
    elements.append(Paragraph(tournament.name, title_style))

    subtitle_parts = []
    if tournament.sport:
        subtitle_parts.append(str(tournament.sport))
    if tournament.starts_at:
        subtitle_parts.append(tournament.starts_at.strftime('%B %d, %Y') if hasattr(tournament.starts_at, 'strftime') else str(tournament.starts_at))
    elements.append(Paragraph(' — '.join(subtitle_parts) if subtitle_parts else 'Tournament Results', subtitle_style))

    # Stats bar
    total_matches = len(matches)
    completed_matches = sum(1 for m in matches if m.get("status") == "completed")
    generated_at = timezone.now().strftime('%B %d, %Y %H:%M')

    stats_text = f"<b>Generated:</b> {generated_at} &nbsp;&nbsp;|&nbsp;&nbsp; <b>Total Matches:</b> {total_matches} &nbsp;&nbsp;|&nbsp;&nbsp; <b>Completed:</b> {completed_matches}"
    stats_style = ParagraphStyle('Stats', fontSize=9, textColor=GRAY, spaceBefore=5, spaceAfter=15)
    elements.append(Paragraph(stats_text, stats_style))

    # Group matches by category
    by_category = defaultdict(list)
    for match in matches:
        by_category[match.get('category', 'Uncategorized')].append(match)

    # Table style for all match tables
    table_style = TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), TABLE_HEADER_BG),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.HexColor('#374151')),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 9),
        ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
        ('FONTSIZE', (0, 1), (-1, -1), 9),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('GRID', (0, 0), (-1, -1), 0.5, BORDER_GRAY),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
        ('RIGHTPADDING', (0, 0), (-1, -1), 6),
        ('TOPPADDING', (0, 0), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, ODD_ROW]),
    ])

    # Build table for each category
    for category_name, category_matches in by_category.items():
        elements.append(Paragraph(category_name, section_title_style))

        # Table header
        data = [['#', 'Player 1', 'Score', 'Player 2', 'Status']]

        for match in category_matches:
            round_num = match.get('round', 0)
            slot = match.get('slot', 0)
            entry1 = match.get('entry1', 'BYE')
            entry2 = match.get('entry2', 'BYE')
            winner = match.get('winner', '')
            score = match.get('score', {})
            status = match.get('status', '')

            # Round indicator
            if round_num == 1:
                round_label = f"R1-{slot + 1}"
            elif round_num == 2:
                round_label = 'QF'
            elif round_num == 3:
                round_label = 'SF'
            else:
                round_label = 'F'

            # Score display
            if score and 'entry1_points' in score:
                score_text = f"{score['entry1_points']} - {score['entry2_points']}"
            else:
                score_text = '-'

            # Status display
            if status == 'completed':
                status_text = 'Done'
            else:
                status_text = status.title() if status else ''

            # Player 1 with winner styling
            p1_style = ''
            if winner and winner == entry1:
                p1_style = f'<b><font color="#059669">{entry1}</font></b>'
            else:
                p1_style = entry1

            # Player 2 with winner styling
            p2_style = ''
            if winner and winner == entry2:
                p2_style = f'<b><font color="#059669">{entry2}</font></b>'
            else:
                p2_style = entry2

            row = [round_label, Paragraph(p1_style, styles['Normal']), score_text, Paragraph(p2_style, styles['Normal']), status_text]
            data.append(row)

        table = Table(data, colWidths=[1.2*cm, 5.5*cm, 2.5*cm, 5.5*cm, 1.8*cm])
        table.setStyle(table_style)
        elements.append(table)
        elements.append(Spacer(1, 0.3*cm))

    # Footer
    footer_style = ParagraphStyle(
        'Footer',
        fontSize=8,
        textColor=GRAY,
        alignment=1,
        spaceBefore=20,
    )
    elements.append(Paragraph(
        "This document was automatically generated. For the most up-to-date results, please refer to the official tournament management system.",
        footer_style
    ))

    doc.build(elements)
    pdf_buffer.seek(0)
    return pdf_buffer


def build_category_results_pdf(category, matches: List[dict]) -> io.BytesIO:
    """
    Build a PDF document for a single category's results.
    """
    pdf_buffer = io.BytesIO()
    doc = SimpleDocTemplate(
        pdf_buffer,
        pagesize=A4,
        leftMargin=1.5*cm,
        rightMargin=1.5*cm,
        topMargin=1.5*cm,
        bottomMargin=1.5*cm,
    )

    elements = []
    styles = getSampleStyleSheet()

    # Header
    title_style = ParagraphStyle('Title', fontSize=18, textColor=DARK_BLUE, alignment=1, spaceAfter=6)
    subtitle_style = ParagraphStyle('Subtitle', fontSize=10, textColor=GRAY, alignment=1, spaceAfter=20)

    elements.append(Paragraph(category.name, title_style))
    elements.append(Paragraph(category.tournament.name, subtitle_style))

    # Stats
    total_matches = len(matches)
    completed_matches = sum(1 for m in matches if m.get("status") == "completed")
    generated_at = timezone.now().strftime('%B %d, %Y %H:%M')
    stats_text = f"<b>Generated:</b> {generated_at} &nbsp;&nbsp;|&nbsp;&nbsp; <b>Total Matches:</b> {total_matches} &nbsp;&nbsp;|&nbsp;&nbsp; <b>Completed:</b> {completed_matches}"
    stats_style = ParagraphStyle('Stats', fontSize=9, textColor=GRAY, spaceBefore=5, spaceAfter=15)
    elements.append(Paragraph(stats_text, stats_style))

    # Table
    table_style = TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), TABLE_HEADER_BG),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.HexColor('#374151')),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 9),
        ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
        ('FONTSIZE', (0, 1), (-1, -1), 9),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('GRID', (0, 0), (-1, -1), 0.5, BORDER_GRAY),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
        ('RIGHTPADDING', (0, 0), (-1, -1), 6),
        ('TOPPADDING', (0, 0), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, ODD_ROW]),
    ])

    data = [['#', 'Player 1', 'Score', 'Player 2', 'Status']]

    for match in matches:
        round_num = match.get('round', 0)
        slot = match.get('slot', 0)
        entry1 = match.get('entry1', 'BYE')
        entry2 = match.get('entry2', 'BYE')
        winner = match.get('winner', '')
        score = match.get('score', {})
        status = match.get('status', '')

        if round_num == 1:
            round_label = f"R1-{slot + 1}"
        elif round_num == 2:
            round_label = 'QF'
        elif round_num == 3:
            round_label = 'SF'
        else:
            round_label = 'F'

        if score and 'entry1_points' in score:
            score_text = f"{score['entry1_points']} - {score['entry2_points']}"
        else:
            score_text = '-'

        if status == 'completed':
            status_text = 'Done'
        else:
            status_text = status.title() if status else ''

        p1_style = f'<b><font color="#059669">{entry1}</font></b>' if winner and winner == entry1 else entry1
        p2_style = f'<b><font color="#059669">{entry2}</font></b>' if winner and winner == entry2 else entry2

        row = [round_label, Paragraph(p1_style, styles['Normal']), score_text, Paragraph(p2_style, styles['Normal']), status_text]
        data.append(row)

    table = Table(data, colWidths=[1.2*cm, 5.5*cm, 2.5*cm, 5.5*cm, 1.8*cm])
    table.setStyle(table_style)
    elements.append(table)

    # Footer
    footer_style = ParagraphStyle('Footer', fontSize=8, textColor=GRAY, alignment=1, spaceBefore=20)
    elements.append(Paragraph(
        "This document was automatically generated. For the most up-to-date results, please refer to the official tournament management system.",
        footer_style
    ))

    doc.build(elements)
    pdf_buffer.seek(0)
    return pdf_buffer
