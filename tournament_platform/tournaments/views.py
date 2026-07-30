from django.db.models import Q
from django.shortcuts import get_object_or_404
from rest_framework import mixins, viewsets
from rest_framework.permissions import IsAuthenticated

from accounts.models import TournamentRole

from .models import Category, Court, Tournament
from .permissions import IsOrganizerOfTournament
from .serializers import CategorySerializer, CourtSerializer, TournamentSerializer


class TournamentViewSet(
    mixins.ListModelMixin,
    mixins.CreateModelMixin,
    mixins.RetrieveModelMixin,
    viewsets.GenericViewSet,
):
    """
    GET  /api/tournaments/       -> public tournaments + any tournament the
                                     caller holds an active role on
    POST /api/tournaments/       -> create a tournament under one of the
                                     caller's own organizations
    GET  /api/tournaments/{id}/  -> detail (same visibility rule as list)
    """

    serializer_class = TournamentSerializer
    permission_classes = [IsAuthenticated, IsOrganizerOfTournament]

    def get_tournament(self):
        # Used by IsOrganizerOfTournament.has_permission() on create,
        # where there's no existing object yet — for POST, "the
        # tournament" doesn't exist, so this is only meaningful for the
        # nested Category/Court viewsets below. Left as a stub here.
        return None

    def get_queryset(self):
        user = self.request.user
        active_role_tournament_ids = TournamentRole.objects.filter(
            user=user, is_active=True
        ).values_list("tournament_id", flat=True)
        return (
            Tournament.objects.filter(
                Q(is_public=True) | Q(id__in=active_role_tournament_ids)
            )
            .select_related("organization")
            .prefetch_related("categories", "courts")
            .distinct()
            .order_by("-created_at")
        )

    def perform_create(self, serializer):
        # organization is validated in the serializer (must belong to
        # request.user); no further permission gate needed here since
        # owning the org is what makes you an Organizer of anything
        # created under it.
        serializer.save()


class _NestedUnderTournamentMixin:
    """
    Shared plumbing for Category/Court viewsets nested at
    /api/tournaments/{tournament_pk}/<resource>/.
    """

    def get_tournament(self):
        return get_object_or_404(Tournament, pk=self.kwargs["tournament_pk"])

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context["tournament"] = self.get_tournament()
        return context


class CategoryViewSet(
    _NestedUnderTournamentMixin,
    mixins.ListModelMixin,
    mixins.CreateModelMixin,
    mixins.RetrieveModelMixin,
    viewsets.GenericViewSet,
):
    """
    GET  /api/tournaments/{tournament_pk}/categories/
    POST /api/tournaments/{tournament_pk}/categories/
    """

    serializer_class = CategorySerializer
    permission_classes = [IsAuthenticated, IsOrganizerOfTournament]

    def get_queryset(self):
        return Category.objects.filter(
            tournament_id=self.kwargs["tournament_pk"]
        ).order_by("id")


class CourtViewSet(
    _NestedUnderTournamentMixin,
    mixins.ListModelMixin,
    mixins.CreateModelMixin,
    mixins.RetrieveModelMixin,
    viewsets.GenericViewSet,
):
    """
    GET  /api/tournaments/{tournament_pk}/courts/
    POST /api/tournaments/{tournament_pk}/courts/
    """

    serializer_class = CourtSerializer
    permission_classes = [IsAuthenticated, IsOrganizerOfTournament]

    def get_queryset(self):
        return Court.objects.filter(
            tournament_id=self.kwargs["tournament_pk"]
        ).order_by("id")
