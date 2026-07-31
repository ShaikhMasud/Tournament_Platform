"""
Celery tasks for async PDF generation.
"""
import logging

from celery import shared_task

logger = logging.getLogger(__name__)


@shared_task(bind=True, max_retries=3, default_retry_delay=60)
def generate_result_pdf_task(self, document_id: str):
    """
    Async task to generate a result PDF.

    Retries up to 3 times with exponential backoff on failure.
    """
    from .models import ResultDocument
    from .services import generate_result_pdf

    try:
        document = ResultDocument.objects.get(pk=document_id)
        generate_result_pdf(document)
        logger.info(f"Successfully generated PDF for document {document_id}")
    except ResultDocument.DoesNotExist:
        logger.error(f"ResultDocument {document_id} not found")
        raise
    except Exception as exc:
        logger.error(f"Failed to generate PDF for document {document_id}: {exc}")
        # Retry with exponential backoff.
        raise self.retry(exc=exc)


@shared_task
def cleanup_old_failed_documents():
    """
    Periodic task to clean up old failed documents.

    Documents that have been in FAILED state for more than 7 days
    can be safely deleted.
    """
    from datetime import timedelta
    from django.utils import timezone
    from .models import ResultDocument

    threshold = timezone.now() - timedelta(days=7)
    count, _ = ResultDocument.objects.filter(
        status=ResultDocument.FAILED,
        updated_at__lt=threshold,
    ).delete()
    logger.info(f"Cleaned up {count} old failed result documents")
    return count
