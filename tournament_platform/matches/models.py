import uuid

from django.db import models


class Match(models.Model):
    PENDING = "pending"
    SCHEDULED = "scheduled"
    LIVE = "live"
    COMPLETED = "completed"
    BYE = "bye"
    STATUS_CHOICES = [
        (PENDING, "Pending"),
        (SCHEDULED, "Scheduled"),
        (LIVE, "Live"),
        (COMPLETED, "Completed"),
        (BYE, "Bye"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    tournament = models.ForeignKey(
        "tournaments.Tournament", on_delete=models.CASCADE, related_name="matches"
    )
    category = models.ForeignKey(
        "tournaments.Category", on_delete=models.CASCADE, related_name="matches"
    )
    draw = models.ForeignKey("draws.Draw", on_delete=models.CASCADE, related_name="matches")

    round_number = models.PositiveIntegerField()
    slot_position = models.PositiveIntegerField()

    entry1 = models.ForeignKey(
        "entries.Entry", on_delete=models.SET_NULL, null=True, blank=True, related_name="matches_as_p1"
    )
    entry2 = models.ForeignKey(
        "entries.Entry", on_delete=models.SET_NULL, null=True, blank=True, related_name="matches_as_p2"
    )

    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=PENDING)
    court = models.ForeignKey(
        "tournaments.Court", on_delete=models.SET_NULL, null=True, blank=True, related_name="matches"
    )
    scheduled_start = models.DateTimeField(null=True, blank=True)
    scheduled_end = models.DateTimeField(null=True, blank=True)

    winner_entry = models.ForeignKey(
        "entries.Entry", on_delete=models.SET_NULL, null=True, blank=True, related_name="matches_won"
    )
    score = models.JSONField(default=dict, blank=True)

    # Optimistic-concurrency / ordering value — incremented on every accepted
    # mutation (schedule change, score update, completion).
    version = models.PositiveIntegerField(default=0)

    # Bracket progression pointer.
    next_match = models.ForeignKey(
        "self", on_delete=models.SET_NULL, null=True, blank=True, related_name="feeder_matches"
    )
    next_match_slot = models.PositiveSmallIntegerField(null=True, blank=True)  # 1 or 2

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=["tournament", "category", "status"]),
            models.Index(fields=["court", "scheduled_start"]),
            models.Index(fields=["tournament", "status", "scheduled_start"]),
        ]

    def __str__(self):
        return f"{self.category} R{self.round_number} #{self.slot_position}"
