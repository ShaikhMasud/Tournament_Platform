from rest_framework.permissions import SAFE_METHODS, BasePermission

from accounts.models import TournamentRole

# NOTE: this wraps the project's existing core/permissions.py helpers per
# the plan (Phase 1 table says "wraps core/permissions.py's helpers").
# Your actual helper names may differ — the two most likely candidates are
# something like `user_has_active_role(user, tournament, role)` or
# `organizer_or_capability(capability)`. Swap the body of
# `_is_active_organizer` below for that helper once you confirm the name;
# the standalone version here is a correct, self-contained fallback so
# Phase 1 isn't blocked on it.


def _is_active_organizer(user, tournament) -> bool:
    if not user or not user.is_authenticated:
        return False
    return TournamentRole.objects.filter(
        tournament=tournament,
        user=user,
        role=TournamentRole.ORGANIZER,
        is_active=True,
    ).exists()


class IsOrganizerOfOrganization(BasePermission):
    """
    Object-level check for Organization instances: only the owner may
    write to their own organization (list/create at the viewset level is
    already scoped by queryset, this covers retrieve/update/delete if
    those are added later).
    """

    def has_object_permission(self, request, view, obj):
        if request.method in SAFE_METHODS:
            return obj.owner_id == request.user.id
        return obj.owner_id == request.user.id


class IsOrganizerOfTournament(BasePermission):
    """
    - Safe methods (GET): allowed for any authenticated user if the
      tournament is public; otherwise only for an active Organizer/role
      holder on that tournament. Public-read is enforced in the view's
      get_queryset, not here — this permission focuses on writes.
    - Unsafe methods (POST/PUT/PATCH/DELETE): require an active
      TournamentRole(role=ORGANIZER) on that specific tournament.
    """

    message = "You must be an active organizer of this tournament to do that."

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        if request.method in SAFE_METHODS:
            return True
        tournament = view.get_tournament()
        return _is_active_organizer(request.user, tournament)

    def has_object_permission(self, request, view, obj):
        if request.method in SAFE_METHODS:
            return True
        tournament = obj if hasattr(obj, "organization_id") else obj.tournament
        return _is_active_organizer(request.user, tournament)
