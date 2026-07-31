from django.db import transaction
from django.db.models import Q
from django.shortcuts import get_object_or_404
from rest_framework import mixins, status, viewsets
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.models import AssistantCapability, TournamentRole, User

from .models import Category, Court, Tournament
from .permissions import IsOrganizerOfTournament
from .serializers import (
    AssignRoleSerializer,
    CategorySerializer,
    CourtSerializer,
    TournamentRoleSerializer,
    TournamentSerializer,
    UpdateCapabilitiesSerializer,
)


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


class TournamentRoleListView(APIView):
    """
    GET /api/tournaments/{tournament_pk}/roles/
        -> List all roles for a tournament (organizers and assistants).
    POST /api/tournaments/{tournament_pk}/roles/assign/
        -> Assign a new role to a user.
    """

    permission_classes = [IsAuthenticated, IsOrganizerOfTournament]

    def get(self, request, tournament_pk):
        tournament = get_object_or_404(Tournament, pk=tournament_pk)
        roles = TournamentRole.objects.filter(
            tournament=tournament
        ).select_related("user").prefetch_related("capabilities")
        serializer = TournamentRoleSerializer(roles, many=True)
        return Response(serializer.data)

    def post(self, request, tournament_pk):
        tournament = get_object_or_404(Tournament, pk=tournament_pk)
        serializer = AssignRoleSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data["email"]
        role = serializer.validated_data["role"]
        capabilities = serializer.validated_data.get("capabilities", [])

        user = User.objects.get(email=email)

        with transaction.atomic():
            # Check if role already exists
            existing_role = TournamentRole.objects.filter(
                user=user, tournament=tournament, role=role
            ).first()

            if existing_role:
                # Reactivate if inactive
                if not existing_role.is_active:
                    existing_role.is_active = True
                    existing_role.granted_by = request.user
                    existing_role.save()
                    role_obj = existing_role
                else:
                    return Response(
                        {"detail": f"User already has an active {role} role."},
                        status=status.HTTP_400_BAD_REQUEST,
                    )
            else:
                # Create new role
                role_obj = TournamentRole.objects.create(
                    user=user,
                    tournament=tournament,
                    role=role,
                    is_active=True,
                    granted_by=request.user,
                )

            # Set capabilities for assistants
            if role == TournamentRole.ASSISTANT:
                # Remove existing capabilities
                role_obj.capabilities.all().delete()
                # Add new capabilities
                for cap in capabilities:
                    AssistantCapability.objects.create(
                        tournament_role=role_obj,
                        capability=cap,
                        is_active=True,
                    )

        return Response(
            TournamentRoleSerializer(role_obj).data,
            status=status.HTTP_201_CREATED,
        )


class TournamentRoleDetailView(APIView):
    """
    DELETE /api/tournaments/{tournament_pk}/roles/{role_id}/
        -> Revoke (deactivate) a role.
    """

    permission_classes = [IsAuthenticated, IsOrganizerOfTournament]

    def delete(self, request, tournament_pk, role_id):
        tournament = get_object_or_404(Tournament, pk=tournament_pk)
        role = get_object_or_404(TournamentRole, pk=role_id, tournament=tournament)

        # Prevent removing your own organizer role
        if role.user_id == request.user.id and role.role == TournamentRole.ORGANIZER:
            return Response(
                {"detail": "You cannot remove your own organizer role."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        role.is_active = False
        role.save()
        return Response(status=status.HTTP_204_NO_CONTENT)


class TournamentRoleCapabilitiesView(APIView):
    """
    POST /api/tournaments/{tournament_pk}/roles/{role_id}/capabilities/
        -> Update capabilities for an assistant role.
    """

    permission_classes = [IsAuthenticated, IsOrganizerOfTournament]

    def post(self, request, tournament_pk, role_id):
        tournament = get_object_or_404(Tournament, pk=tournament_pk)
        role = get_object_or_404(TournamentRole, pk=role_id, tournament=tournament)

        if role.role != TournamentRole.ASSISTANT:
            return Response(
                {"detail": "Only assistant roles have capabilities."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        serializer = UpdateCapabilitiesSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        new_capabilities = serializer.validated_data["capabilities"]

        with transaction.atomic():
            # Remove existing capabilities
            role.capabilities.all().delete()
            # Add new capabilities
            for cap in new_capabilities:
                AssistantCapability.objects.create(
                    tournament_role=role,
                    capability=cap,
                    is_active=True,
                )

        role.refresh_from_db()
        return Response(TournamentRoleSerializer(role).data)
