from django.urls import path

from .views import (
    MatchDetailView,
    MatchScheduleView,
    MatchScoreView,
    MatchStartView,
    TournamentMatchListView,
)

urlpatterns = [
    path(
        "tournaments/<uuid:tournament_pk>/matches/",
        TournamentMatchListView.as_view(),
        name="tournament-match-list",
    ),
    path(
        "matches/<uuid:pk>/",
        MatchDetailView.as_view(),
        name="match-detail",
    ),
    path(
        "matches/<uuid:pk>/schedule/",
        MatchScheduleView.as_view(),
        name="match-schedule",
    ),
    path(
        "matches/<uuid:pk>/start/",
        MatchStartView.as_view(),
        name="match-start",
    ),
    path(
        "matches/<uuid:pk>/score/",
        MatchScoreView.as_view(),
        name="match-score",
    ),
]
