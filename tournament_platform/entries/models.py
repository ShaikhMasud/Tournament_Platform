import uuid

from django.conf import settings
from django.db import models
from django.db.models import Q


class EntryQuerySet(models.QuerySet):
    def eligible_for_draw(self):
        """The only entries that may ever feed draw generation."""
        return self.filter(status=Entry.CONFIRMED)


class Entry(models.Model):
    CONFIRMED = "confirmed"
    CANCELLED = "cancelled"
    WITHDRAWN = "withdrawn"
    REFUNDED = "refunded"
    WAITLIST = "waitlist"
    STATUS_CHOICES = [
        (CONFIRMED, "Confirmed"),
        (CANCELLED, "Cancelled"),
        (WITHDRAWN, "Withdrawn"),
        (REFUNDED, "Refunded"),
        (WAITLIST, "Waitlist"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    category = models.ForeignKey(
        "tournaments.Category", on_delete=models.CASCADE, related_name="entries"
    )
    player = models.ForeignKey(
        "accounts.PlayerProfile", on_delete=models.CASCADE, related_name="entries"
    )
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=CONFIRMED)
    created_at = models.DateTimeField(auto_now_add=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="created_entries",
    )

    objects = EntryQuerySet.as_manager()

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["category", "player"],
                condition=Q(status="confirmed"),
                name="uniq_active_entry_per_category",
            )
        ]
        indexes = [models.Index(fields=["category", "status"])]
        verbose_name_plural = "Entries"

    def __str__(self):
        return f"{self.player.display_name} - {self.category}"
