from django.urls import include, path
from rest_framework.routers import DefaultRouter
from rest_framework_nested import routers as nested_routers

from .views import (
    CategoryViewSet,
    CourtViewSet,
    TournamentRoleCapabilitiesView,
    TournamentRoleDetailView,
    TournamentRoleListView,
    TournamentViewSet,
)

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
    path("", include(router.urls)),
    path("", include(tournaments_router.urls)),
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
]
