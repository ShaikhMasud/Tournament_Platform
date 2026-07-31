"""
Service layer for result document generation.
"""
import io
from typing import Optional

from django.db import transaction

from matches.models import Match
from tournaments.models import Tournament

from .fingerprint import compute_tournament_fingerprint
from .models import ResultDocument
from .pdf_builder import build_match_results_pdf


class ResultDocumentExists( Exception):
    """Raised when a result document already exists for the given fingerprint."""

    def __init__(self, document: ResultDocument):
        self.document = document
        super().__init__("Result document already exists.")


def request_result_document(tournament: Tournament) -> ResultDocument:
    """
    Request a result PDF for a tournament.

    If a document with the same fingerprint already exists and is ready,
    returns that document. Otherwise creates a new pending document
    and queues generation.

    Thread-safe: uses select_for_update to prevent race conditions.
    """
    fingerprint = compute_tournament_fingerprint(tournament)

    with transaction.atomic():
        # Check for existing document with this fingerprint.
        existing = ResultDocument.objects.filter(
            tournament=tournament,
            fingerprint=fingerprint,
        ).select_for_update().first()

        if existing:
            if existing.status == ResultDocument.READY:
                return existing
            elif existing.status == ResultDocument.GENERATING:
                # Generation in progress, return the existing document.
                return existing
            elif existing.status == ResultDocument.FAILED:
                # Retry failed generation.
                existing.status = ResultDocument.PENDING
                existing.save()
                return existing

        # Create new document.
        document = ResultDocument.objects.create(
            tournament=tournament,
            fingerprint=fingerprint,
            status=ResultDocument.PENDING,
        )

        return document


def generate_result_pdf(document: ResultDocument) -> ResultDocument:
    """
    Generate the PDF for a result document.

    This should be called asynchronously via Celery.
    """
    with transaction.atomic():
        locked_doc = ResultDocument.objects.select_for_update().get(pk=document.pk)

        if locked_doc.status == ResultDocument.READY:
            return locked_doc  # Already generated.

        locked_doc.status = ResultDocument.GENERATING
        locked_doc.save()

        try:
            # Gather match data.
            tournament = locked_doc.tournament
            matches = (
                Match.objects.filter(
                    tournament=tournament,
                    status=Match.COMPLETED,
                )
                .select_related("entry1__player", "entry2__player", "category")
                .order_by("category__name", "round_number", "slot_position")
            )

            match_data = []
            for match in matches:
                entry1_name = ""
                entry2_name = ""
                if match.entry1:
                    entry1_name = match.entry1.player.display_name
                if match.entry2:
                    entry2_name = match.entry2.player.display_name

                winner_name = ""
                if match.winner_entry_id:
                    if match.winner_entry_id == match.entry1_id:
                        winner_name = entry1_name
                    else:
                        winner_name = entry2_name

                match_data.append({
                    "id": str(match.id),
                    "category": match.category.name,
                    "round": match.round_number,
                    "slot": match.slot_position,
                    "entry1": entry1_name,
                    "entry2": entry2_name,
                    "score": match.score or {},
                    "winner": winner_name,
                    "status": match.status,
                    "court": match.court.name if match.court else None,
                    "scheduled_start": match.scheduled_start,
                })

            # Generate PDF.
            pdf_buffer = build_match_results_pdf(tournament, match_data)

            # Save PDF to document.
            filename = f"results/{tournament.slug}_{locked_doc.id}.pdf"
            locked_doc.pdf_file.save(filename, pdf_buffer, save=False)
            locked_doc.status = ResultDocument.READY
            locked_doc.save()

            return locked_doc

        except Exception as e:
            locked_doc.status = ResultDocument.FAILED
            locked_doc.error_message = str(e)
            locked_doc.save()
            raise


def get_or_create_result_document(tournament: Tournament) -> tuple[ResultDocument, bool]:
    """
    Get or create a result document, triggering generation if needed.

    Returns:
        Tuple of (document, created_new).
    """
    document = request_result_document(tournament)

    if document.status == ResultDocument.PENDING:
        # Trigger async generation.
        from .tasks import generate_result_pdf_task
        generate_result_pdf_task.delay(str(document.id))
        return document, True

    return document, False
