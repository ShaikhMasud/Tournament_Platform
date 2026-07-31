from django.shortcuts import get_object_or_404
from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from core.permissions import organizer_or_capability
from tournaments.models import Tournament

from .filters import MatchFilter
from .models import Match
from .serializers import (
    MatchSerializer,
    ScheduleSerializer,
    ScoreUpdateSerializer,
    StartMatchSerializer,
)
from .services import (
    apply_score_update,
    schedule_match,
    start_match,
)


class TournamentMatchListView(generics.ListAPIView):
    """
    GET /api/tournaments/{id}/matches/?status=&round_number=&page=

    Paginated + filtered match list for a tournament.
    """

    serializer_class = MatchSerializer
    permission_classes = [IsAuthenticated]
    filterset_class = MatchFilter

    def get_queryset(self):
        tournament_pk = self.kwargs["tournament_pk"]
        return (
            Match.objects.filter(tournament_id=tournament_pk)
            .select_related("entry1__player", "entry2__player", "court", "tournament", "category")
            .order_by("round_number", "slot_position")
        )


class MatchDetailView(generics.RetrieveAPIView):
    """GET /api/matches/{id}/ — match detail."""

    serializer_class = MatchSerializer
    permission_classes = [IsAuthenticated]
    queryset = Match.objects.select_related(
        "entry1__player", "entry2__player", "court", "tournament", "category"
    )


class MatchScheduleView(APIView):
    """
    POST /api/matches/{id}/schedule/
    Assign court and/or time to a match.
    """

    permission_classes = [IsAuthenticated, organizer_or_capability("scheduling")]

    def post(self, request, pk):
        match = get_object_or_404(Match, pk=pk)
        serializer = ScheduleSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        updated_match = schedule_match(
            match=match,
            court_id=serializer.validated_data.get("court_id"),
            scheduled_start=serializer.validated_data.get("scheduled_start"),
            scheduled_end=serializer.validated_data.get("scheduled_end"),
        )
        return Response(MatchSerializer(updated_match).data)


class MatchStartView(APIView):
    """POST /api/matches/{id}/start/ — transition from SCHEDULED to LIVE."""

    permission_classes = [IsAuthenticated, organizer_or_capability("score_management")]

    def post(self, request, pk):
        match = get_object_or_404(Match, pk=pk)
        updated_match = start_match(match=match)
        return Response(MatchSerializer(updated_match).data)


class MatchScoreView(APIView):
    """POST /api/matches/{id}/score/ — submit/update score (versioned)."""

    permission_classes = [IsAuthenticated, organizer_or_capability("score_management")]

    def post(self, request, pk):
        match = get_object_or_404(Match, pk=pk)
        serializer = ScoreUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        updated_match = apply_score_update(
            match=match,
            score=serializer.validated_data["score"],
            version=serializer.validated_data["version"],
            actor=request.user,
        )
        return Response(MatchSerializer(updated_match).data)

