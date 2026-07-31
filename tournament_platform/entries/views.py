from django.shortcuts import get_object_or_404
from rest_framework import generics, status
from rest_framework.exceptions import PermissionDenied
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.models import AssistantCapability, TournamentRole
from tournaments.models import Category

from .filters import EntryFilter
from .models import Entry
from .serializers import EntryCreateSerializer, EntrySerializer
from .services import add_entry, remove_entry

# NOTE: same situation as tournaments/permissions.py in Phase 1 — this
# wraps what the plan calls core/permissions.py's
# organizer_or_capability('entry_management') helper. Swap the body of
# `_actor_is_privileged` for your real helper once you confirm its name;
# this version is self-contained against TournamentRole/AssistantCapability
# so Phase 2 isn't blocked on it.


def _actor_is_privileged(user, tournament) -> bool:
    """True if `user` is an active Organizer of `tournament`, or an active
    Assistant with the 'entry_management' capability on it."""
    if not user or not user.is_authenticated:
        return False

    is_organizer = TournamentRole.objects.filter(
        tournament=tournament,
        user=user,
        role=TournamentRole.Role.ORGANIZER,
        is_active=True,
    ).exists()
    if is_organizer:
        return True

    return AssistantCapability.objects.filter(
        tournament_role__tournament=tournament,
        tournament_role__user=user,
        tournament_role__role=TournamentRole.Role.ASSISTANT,
        tournament_role__is_active=True,
        capability="entry_management",
        is_active=True,
    ).exists()


class EntryListView(generics.ListAPIView):
    """
    GET /api/categories/{id}/entries/?search=&status=&page=

    Paginated + filtered + searchable. Uses the project default
    PageNumberPagination from settings.py — never returns an unbounded
    "all entries" payload.
    """

    serializer_class = EntrySerializer
    permission_classes = [IsAuthenticated]
    filterset_class = EntryFilter

    def get_category(self):
        return get_object_or_404(Category, pk=self.kwargs["category_pk"])

    def get_queryset(self):
        category = self.get_category()
        qs = Entry.objects.filter(category=category).select_related(
            "player", "player__user"
        )

        tournament = category.tournament
        if _actor_is_privileged(self.request.user, tournament):
            return qs.order_by("-created_at")

        # A non-privileged caller (a Player) only ever sees their own
        # entry in this category, never the full roster.
        player = getattr(self.request.user, "playerprofile", None)
        if player is None:
            return qs.none()
        return qs.filter(player=player)


class EntryCreateView(APIView):
    """POST /api/categories/{id}/entries/ — add a player entry."""

    permission_classes = [IsAuthenticated]

    def post(self, request, category_pk):
        category = get_object_or_404(Category, pk=category_pk)
        tournament = category.tournament
        is_privileged = _actor_is_privileged(request.user, tournament)

        serializer = EntryCreateSerializer(
            data=request.data,
            context={
                "request": request,
                "category": category,
                "actor_is_privileged": is_privileged,
            },
        )
        serializer.is_valid(raise_exception=True)

        entry = add_entry(
            category=serializer.validated_data["resolved_category"],
            player=serializer.validated_data["resolved_player"],
            actor=request.user,
        )
        return Response(
            EntrySerializer(entry).data, status=status.HTTP_201_CREATED
        )


class EntryDeleteView(APIView):
    """DELETE /api/entries/{id}/ — remove an entry."""

    permission_classes = [IsAuthenticated]

    def delete(self, request, pk):
        entry = get_object_or_404(
            Entry.objects.select_related("category__tournament", "player"), pk=pk
        )
        tournament = entry.category.tournament
        is_privileged = _actor_is_privileged(request.user, tournament)
        is_owner = getattr(request.user, "playerprofile", None) == entry.player

        if not (is_privileged or is_owner):
            raise PermissionDenied(
                "You can only remove your own entry, or entries you manage."
            )

        remove_entry(entry=entry, actor=request.user)
        return Response(status=status.HTTP_204_NO_CONTENT)
