"""
PDF builder for match results using WeasyPrint.
"""
import io
from datetime import datetime
from typing import List

from django.contrib.staticfiles import finders
from django.template.loader import render_to_string
from django.utils import timezone
from weasyprint import HTML


def build_match_results_pdf(tournament, matches: List[dict]) -> io.BytesIO:
    """
    Build a PDF document for tournament match results.

    Args:
        tournament: The Tournament object.
        matches: List of match data dictionaries.

    Returns:
        A BytesIO object containing the PDF.
    """
    context = {
        "tournament": {
            "name": tournament.name,
            "sport": tournament.sport,
            "starts_at": tournament.starts_at,
            "ends_at": tournament.ends_at,
        },
        "matches": matches,
        "generated_at": timezone.now(),
        "total_matches": len(matches),
        "completed_matches": sum(1 for m in matches if m.get("status") == "completed"),
    }

    # Render HTML template.
    html_string = render_to_string("results/match_results.html", context)

    # Generate PDF.
    pdf_buffer = io.BytesIO()
    HTML(string=html_string).write_pdf(pdf_buffer)
    pdf_buffer.seek(0)

    return pdf_buffer


def build_category_results_pdf(category, matches: List[dict]) -> io.BytesIO:
    """
    Build a PDF document for a single category's results.
    """
    context = {
        "category": {
            "name": category.name,
            "tournament_name": category.tournament.name,
        },
        "matches": matches,
        "generated_at": timezone.now(),
        "total_matches": len(matches),
        "completed_matches": sum(1 for m in matches if m.get("status") == "completed"),
    }

    html_string = render_to_string("results/match_results.html", context)
    pdf_buffer = io.BytesIO()
    HTML(string=html_string).write_pdf(pdf_buffer)
    pdf_buffer.seek(0)

    return pdf_buffer
