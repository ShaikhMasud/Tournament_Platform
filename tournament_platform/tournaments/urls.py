from django.urls import include, path
from rest_framework.routers import DefaultRouter
from rest_framework_nested import routers as nested_routers

from .views import CategoryViewSet, CourtViewSet, TournamentViewSet

# Requires drf-nested-routers (pip install drf-nested-routers) — this is
# the simplest way to get /api/tournaments/{tournament_pk}/categories/ and
# /api/tournaments/{tournament_pk}/courts/ without hand-rolling path()
# entries. If you'd rather not add the dependency, see the plain-Django
# alternative commented below.

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
]

# --- Plain-Django alternative (no drf-nested-routers dependency) ---
# from django.urls import path
# from .views import CategoryViewSet, CourtViewSet, TournamentViewSet
#
# urlpatterns = [
#     path("tournaments/", TournamentViewSet.as_view({"get": "list", "post": "create"})),
#     path("tournaments/<int:pk>/", TournamentViewSet.as_view({"get": "retrieve"})),
#     path(
#         "tournaments/<int:tournament_pk>/categories/",
#         CategoryViewSet.as_view({"get": "list", "post": "create"}),
#     ),
#     path(
#         "tournaments/<int:tournament_pk>/courts/",
#         CourtViewSet.as_view({"get": "list", "post": "create"}),
#     ),
# ]
