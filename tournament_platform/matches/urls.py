from django.urls import path

from .views import (
    LeaderboardView,
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
        "tournaments/<uuid:tournament_pk>/leaderboard/",
        LeaderboardView.as_view(),
        name="tournament-leaderboard",
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
