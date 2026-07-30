import uuid

from django.db import models


class Draw(models.Model):
    PENDING = "pending"
    GENERATING = "generating"
    FINALIZED = "finalized"
    FAILED = "failed"
    STATUS_CHOICES = [
        (PENDING, "Pending"),
        (GENERATING, "Generating"),
        (FINALIZED, "Finalized"),
        (FAILED, "Failed"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    category = models.OneToOneField(
        "tournaments.Category", on_delete=models.CASCADE, related_name="draw"
    )
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=PENDING)
    version = models.PositiveIntegerField(default=0)
    fingerprint = models.CharField(max_length=64, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    finalized_at = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"Draw({self.category}) - {self.status}"


class DrawSlot(models.Model):
    """Snapshot of the initial bracket seeding, independent of Match rows,
    so the original draw can always be reconstructed/displayed."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    draw = models.ForeignKey(Draw, on_delete=models.CASCADE, related_name="slots")
    round_number = models.PositiveIntegerField(default=0)
    position = models.PositiveIntegerField()
    entry = models.ForeignKey(
        "entries.Entry", on_delete=models.SET_NULL, null=True, blank=True, related_name="draw_slots"
    )
    is_bye = models.BooleanField(default=False)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["draw", "round_number", "position"], name="uniq_draw_slot_position"
            )
        ]
        ordering = ["round_number", "position"]

    def __str__(self):
        return f"{self.draw} R{self.round_number} P{self.position}"
