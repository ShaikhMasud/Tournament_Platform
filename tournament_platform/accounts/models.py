import uuid

from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    """Custom user, email-based login. Never store role info on this model —
    roles live in TournamentRole/AssistantCapability so nothing here can be
    trusted as an authorization claim by itself."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True)

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["username"]

    def __str__(self):
        return self.email


class PlayerProfile(models.Model):
    """A player identity. One user can (rarely) manage more than one player
    profile (e.g. a guardian); default case is one-to-one."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="player_profiles")
    display_name = models.CharField(max_length=150)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.display_name


class TournamentRole(models.Model):
    """The single source of truth for who is an Organizer or Assistant on a
    given tournament. Nothing else in the system grants access."""

    ORGANIZER = "organizer"
    ASSISTANT = "assistant"
    ROLE_CHOICES = [(ORGANIZER, "Organizer"), (ASSISTANT, "Assistant")]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="tournament_roles")
    tournament = models.ForeignKey(
        "tournaments.Tournament", on_delete=models.CASCADE, related_name="roles"
    )
    role = models.CharField(max_length=20, choices=ROLE_CHOICES)
    is_active = models.BooleanField(default=True)
    granted_by = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, blank=True, related_name="granted_roles"
    )
    granted_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["user", "tournament", "role"], name="uniq_user_tournament_role"
            )
        ]
        indexes = [models.Index(fields=["tournament", "role", "is_active"])]

    def __str__(self):
        return f"{self.user.email} - {self.role} @ {self.tournament_id}"


class AssistantCapability(models.Model):
    """Explicit, granular grants for an Assistant's TournamentRole. An
    assistant with zero rows here can do nothing but view."""

    ENTRY_MANAGEMENT = "entry_management"
    SCHEDULING = "scheduling"
    SCORE_MANAGEMENT = "score_management"
    CAPABILITY_CHOICES = [
        (ENTRY_MANAGEMENT, "Entry Management"),
        (SCHEDULING, "Scheduling"),
        (SCORE_MANAGEMENT, "Score Management"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    tournament_role = models.ForeignKey(
        TournamentRole, on_delete=models.CASCADE, related_name="capabilities"
    )
    capability = models.CharField(max_length=30, choices=CAPABILITY_CHOICES)
    is_active = models.BooleanField(default=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["tournament_role", "capability"], name="uniq_role_capability"
            )
        ]

    def __str__(self):
        return f"{self.tournament_role} - {self.capability}"
