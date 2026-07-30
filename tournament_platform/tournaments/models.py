import uuid

from django.db import models


class Tournament(models.Model):
    STATUS_CHOICES = [("draft", "Draft"), ("active", "Active"), ("completed", "Completed")]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    organization = models.ForeignKey(
        "organizations.Organization", on_delete=models.CASCADE, related_name="tournaments"
    )
    name = models.CharField(max_length=200)
    sport = models.CharField(max_length=50, default="badminton_single_game")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="draft")
    is_public = models.BooleanField(default=False)
    starts_at = models.DateField(null=True, blank=True)
    ends_at = models.DateField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name


class Category(models.Model):
    KNOCKOUT = "knockout"
    ROUND_ROBIN = "round_robin"
    FORMAT_CHOICES = [(KNOCKOUT, "Knockout"), (ROUND_ROBIN, "Round Robin")]

    OPEN = "open"
    DRAW_GENERATED = "draw_generated"
    LOCKED = "locked"
    STATUS_CHOICES = [(OPEN, "Open"), (DRAW_GENERATED, "Draw Generated"), (LOCKED, "Locked")]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    tournament = models.ForeignKey(
        Tournament, on_delete=models.CASCADE, related_name="categories"
    )
    name = models.CharField(max_length=150)
    draw_format = models.CharField(max_length=20, choices=FORMAT_CHOICES, default=KNOCKOUT)
    capacity = models.PositiveIntegerField(default=32)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=OPEN)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["tournament", "name"], name="uniq_category_name")
        ]
        verbose_name_plural = "Categories"

    def __str__(self):
        return f"{self.tournament.name} - {self.name}"


class Court(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    tournament = models.ForeignKey(Tournament, on_delete=models.CASCADE, related_name="courts")
    name = models.CharField(max_length=100)
    is_active = models.BooleanField(default=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["tournament", "name"], name="uniq_court_name")
        ]

    def __str__(self):
        return f"{self.tournament.name} - {self.name}"
