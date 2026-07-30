"""
Every protected view resolves the tournament from the URL-matched object —
never from a client-supplied field — then checks these relationships against
the DB. Compose these on views instead of writing inline role checks.
"""
from rest_framework.permissions import BasePermission

from accounts.models import AssistantCapability, TournamentRole


def _has_active_role(user, tournament_id, role):
    return TournamentRole.objects.filter(
        user=user, tournament_id=tournament_id, role=role, is_active=True
    ).exists()


def _has_capability(user, tournament_id, capability):
    return AssistantCapability.objects.filter(
        tournament_role__user=user,
        tournament_role__tournament_id=tournament_id,
        tournament_role__role=TournamentRole.ASSISTANT,
        tournament_role__is_active=True,
        capability=capability,
        is_active=True,
    ).exists()


class IsOrganizerOfTournament(BasePermission):
    """Object must resolve `.tournament_id` (or be a Tournament itself)."""

    def has_object_permission(self, request, view, obj):
        tournament_id = getattr(obj, "tournament_id", None) or obj.id
        return _has_active_role(request.user, tournament_id, TournamentRole.ORGANIZER)


class HasAssistantCapability(BasePermission):
    """Usage: permission_classes = [HasAssistantCapability('scheduling')]"""

    def __init__(self, capability):
        self.capability = capability

    def __call__(self):
        # DRF instantiates permission classes with no args, so this class is
        # meant to be used via the factory function below instead.
        return self

    def has_object_permission(self, request, view, obj):
        tournament_id = getattr(obj, "tournament_id", None) or obj.id
        return _has_capability(request.user, tournament_id, self.capability)


def has_capability_factory(capability):
    """DRF permission classes must be zero-arg constructible, so build a
    fresh class per capability rather than instantiating with args."""

    class _Permission(BasePermission):
        def has_object_permission(self, request, view, obj):
            tournament_id = getattr(obj, "tournament_id", None) or obj.id
            return _has_capability(request.user, tournament_id, capability)

    return _Permission


class IsOrganizerOrCapableAssistant(BasePermission):
    """Usage: permission_classes = [organizer_or_capability('scheduling')]"""

    capability = None

    def has_object_permission(self, request, view, obj):
        tournament_id = getattr(obj, "tournament_id", None) or obj.id
        if _has_active_role(request.user, tournament_id, TournamentRole.ORGANIZER):
            return True
        if self.capability:
            return _has_capability(request.user, tournament_id, self.capability)
        return False


def organizer_or_capability(capability):
    class _Permission(IsOrganizerOrCapableAssistant):
        pass

    _Permission.capability = capability
    return _Permission


class IsEntryOwner(BasePermission):
    """Player may only touch their own entry."""

    def has_object_permission(self, request, view, obj):
        return obj.player.user_id == request.user.id
