import uuid

from django.conf import settings
from django.db import models


class ResultDocument(models.Model):
    """
    Stores generated PDF result documents.

    A unique constraint on fingerprint ensures we never generate the same
    PDF twice for the same match configuration.
    """

    PENDING = "pending"
    GENERATING = "generating"
    READY = "ready"
    FAILED = "failed"
    STATUS_CHOICES = [
        (PENDING, "Pending"),
        (GENERATING, "Generating"),
        (READY, "Ready"),
        (FAILED, "Failed"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    tournament = models.ForeignKey(
        "tournaments.Tournament",
        on_delete=models.CASCADE,
        related_name="result_documents",
    )
    fingerprint = models.CharField(max_length=64, db_index=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=PENDING)
    pdf_file = models.FileField(upload_to="results/", null=True, blank=True)
    error_message = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["tournament", "fingerprint"],
                name="uniq_tournament_fingerprint",
            )
        ]
        indexes = [models.Index(fields=["status", "created_at"])]

    def __str__(self):
        return f"ResultDocument({self.tournament.name}) - {self.status}"
