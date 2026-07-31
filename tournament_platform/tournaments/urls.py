from django.urls import include, path
from rest_framework.routers import DefaultRouter
from rest_framework_nested import routers as nested_routers

from .views import (
    AssignExistingUserView,
    CategoryViewSet,
    CourtViewSet,
    PublicTournamentsView,
    TournamentCreateView,
    TournamentRoleCapabilitiesView,
    TournamentRoleDetailView,
    TournamentRoleListView,
    TournamentViewSet,
)
from players.views import PlayerTournamentsView

router = DefaultRouter()
router.register(r"tournaments", TournamentViewSet, basename="tournament")

tournaments_router = nested_routers.NestedDefaultRouter(
    router, r"tournaments", lookup="tournament"
)
tournaments_router.register(
    r"categories", CategoryViewSet, basename="tournament-categories"
)
tournaments_router.register(r"courts", CourtViewSet, basename="tournament-courts")

urlpatterns = [
    # Additional tournament endpoints (must come before router to avoid being overridden)
    path(
        "tournaments/public/",
        PublicTournamentsView.as_view(),
        name="tournament-public",
    ),
    path(
        "tournaments/my/",
        PlayerTournamentsView.as_view(),
        name="tournament-my",
    ),
    path(
        "tournaments/create/",
        TournamentCreateView.as_view(),
        name="tournament-create",
    ),
    # Role management endpoints
    path(
        "tournaments/<uuid:tournament_pk>/roles/",
        TournamentRoleListView.as_view(),
        name="tournament-roles",
    ),
    path(
        "tournaments/<uuid:tournament_pk>/roles/<uuid:role_id>/",
        TournamentRoleDetailView.as_view(),
        name="tournament-role-detail",
    ),
    path(
        "tournaments/<uuid:tournament_pk>/roles/<uuid:role_id>/capabilities/",
        TournamentRoleCapabilitiesView.as_view(),
        name="tournament-role-capabilities",
    ),
    path(
        "tournaments/<uuid:tournament_pk>/assign-user/",
        AssignExistingUserView.as_view(),
        name="tournament-assign-user",
    ),
    path("", include(router.urls)),
    path("", include(tournaments_router.urls)),
]
