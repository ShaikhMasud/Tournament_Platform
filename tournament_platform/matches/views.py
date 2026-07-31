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


class LeaderboardView(APIView):
    """
    GET /api/tournaments/{id}/leaderboard/?category=
    Returns player rankings based on match points and wins.
    """

    permission_classes = [IsAuthenticated]

    def get(self, request, tournament_pk):
        from accounts.models import TournamentRole
        from entries.models import Entry
        from django.db.models import Sum, Count, F, Q
        from django.db.models.functions import Coalesce
        
        tournament = get_object_or_404(Tournament, pk=tournament_pk)
        
        # Check access: public tournament or user has a role
        if not tournament.is_public:
            if not request.user.is_authenticated:
                return Response({"detail": "Authentication required"}, status=401)
            if not TournamentRole.objects.filter(
                user=request.user, 
                tournament=tournament, 
                is_active=True
            ).exists():
                # Check if user has a player entry in this tournament
                user_player = request.user.player_profiles.first()
                if not user_player:
                    return Response({"detail": "Not authorized"}, status=403)
                has_entry = Entry.objects.filter(
                    category__tournament=tournament,
                    player=user_player
                ).exists()
                if not has_entry:
                    return Response({"detail": "Not authorized"}, status=403)
        
        category_id = request.query_params.get('category')
        
        # Build leaderboard data
        # For each player, calculate: matches played, matches won, points
        matches = Match.objects.filter(
            tournament=tournament,
            status='COMPLETED'
        ).select_related('entry1__player', 'entry2__player')
        
        if category_id:
            matches = matches.filter(category_id=category_id)
        
        # Build player stats
        player_stats = {}
        
        for match in matches:
            # Parse score to determine winner
            winner_entry = None
            if match.winner_entry_id:
                winner_entry = match.entry1_id if match.winner_entry_id == match.entry1_id else match.entry2_id
            
            for entry in [match.entry1, match.entry2]:
                if entry and entry.player:
                    player_id = entry.player_id
                    if player_id not in player_stats:
                        player_stats[player_id] = {
                            'player_id': player_id,
                            'display_name': entry.player.display_name,
                            'matches_played': 0,
                            'matches_won': 0,
                            'points': 0,
                        }
                    
                    player_stats[player_id]['matches_played'] += 1
                    
                    # Winner gets 3 points
                    if winner_entry == entry.id:
                        player_stats[player_id]['matches_won'] += 1
                        player_stats[player_id]['points'] += 3
                    else:
                        # Loser gets 0 points (or 1 for participation)
                        player_stats[player_id]['points'] += 0
        
        # Sort by points, then by wins
        sorted_stats = sorted(
            player_stats.values(),
            key=lambda x: (x['points'], x['matches_won']),
            reverse=True
        )
        
        # Add rank
        leaderboard = []
        for i, stats in enumerate(sorted_stats):
            stats['rank'] = i + 1
            leaderboard.append(stats)
        
        return Response({
            'tournament_id': str(tournament.id),
            'tournament_name': tournament.name,
            'category_id': category_id,
            'leaderboard': leaderboard
        })

