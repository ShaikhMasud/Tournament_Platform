"""
Player-specific views for the Player experience (Phase 8).
"""
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.models import PlayerProfile
from entries.models import Entry
from tournaments.models import Tournament, Category


class PlayerTournamentsView(APIView):
    """
    GET /api/player/tournaments/
        -> List tournaments the current player has entries in.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user

        # Get player's profiles
        player_profiles = PlayerProfile.objects.filter(user=user)
        if not player_profiles.exists():
            return Response([])

        profile_ids = list(player_profiles.values_list('id', flat=True))

        # Get entries for this player
        entries = Entry.objects.filter(
            player_id__in=profile_ids,
            status=Entry.CONFIRMED
        ).select_related('category', 'category__tournament').order_by('-created_at')

        # Group by tournament
        tournaments_data = {}
        for entry in entries:
            tournament = entry.category.tournament
            if tournament.id not in tournaments_data:
                tournaments_data[tournament.id] = {
                    'id': str(tournament.id),
                    'name': tournament.name,
                    'sport': tournament.sport,
                    'category_name': entry.category.name,
                    'entry_status': entry.status,
                    'draw_status': entry.category.status,
                    'next_match': None,
                }

                # Get next match for this entry if any
                next_match = self._get_next_match(entry, tournament)
                if next_match:
                    tournaments_data[tournament.id]['next_match_id'] = str(next_match.id)
                    tournaments_data[tournament.id]['next_match_time'] = (
                        next_match.scheduled_start.isoformat() if next_match.scheduled_start else None
                    )
                    tournaments_data[tournament.id]['next_match_court'] = (
                        next_match.court.name if next_match.court else None
                    )

        return Response(list(tournaments_data.values()))

    def _get_next_match(self, entry, tournament):
        """Get the next match for this entry in the tournament."""
        from matches.models import Match

        # Find matches where this entry is playing and scheduled/live
        upcoming = Match.objects.filter(
            tournament=tournament,
            status__in=[Match.SCHEDULED, Match.LIVE],
        ).filter(
            entry1=entry
        ).union(
            Match.objects.filter(
                tournament=tournament,
                status__in=[Match.SCHEDULED, Match.LIVE],
            ).filter(entry2=entry)
        ).order_by('scheduled_start').first()

        return upcoming


class PlayerEntriesView(APIView):
    """
    GET /api/player/entries/
        -> List all entries for the current player.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user

        # Get player's profiles
        player_profiles = PlayerProfile.objects.filter(user=user)
        if not player_profiles.exists():
            return Response([])

        profile_ids = list(player_profiles.values_list('id', flat=True))

        # Get entries for this player
        entries = Entry.objects.filter(
            player_id__in=profile_ids,
        ).select_related(
            'category', 'category__tournament'
        ).order_by('-created_at')

        data = []
        for entry in entries:
            data.append({
                'id': str(entry.id),
                'tournament_id': str(entry.category.tournament.id),
                'tournament_name': entry.category.tournament.name,
                'category_id': str(entry.category.id),
                'category_name': entry.category.name,
                'status': entry.status,
                'draw_status': entry.category.status,
            })

        return Response(data)


class PlayerEntryDetailView(APIView):
    """
    GET /api/player/entries/{entry_id}/
        -> Get details about a specific entry including bracket position.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, entry_id):
        user = request.user

        # Get player's profiles
        player_profiles = PlayerProfile.objects.filter(user=user).values_list('id', flat=True)

        # Get the entry ensuring it belongs to this player
        try:
            entry = Entry.objects.select_related(
                'category', 'category__tournament'
            ).get(pk=entry_id, player_id__in=list(player_profiles))
        except Entry.DoesNotExist:
            return Response(
                {'detail': 'Entry not found.'},
                status=status.HTTP_404_NOT_FOUND
            )

        tournament = entry.category.tournament

        data = {
            'id': str(entry.id),
            'tournament_id': str(tournament.id),
            'tournament_name': tournament.name,
            'category_id': str(entry.category.id),
            'category_name': entry.category.name,
            'status': entry.status,
            'draw_status': entry.category.status,
            'bracket_position': 0,  # Would require draw lookup
        }

        # Get next match info
        next_match = self._get_next_match(entry, tournament)
        if next_match:
            data['next_match_id'] = str(next_match.id)
            data['next_match_time'] = (
                next_match.scheduled_start.isoformat() if next_match.scheduled_start else None
            )
            data['next_match_court'] = (
                next_match.court.name if next_match.court else None
            )
            # Get opponent
            if entry == next_match.entry1:
                if next_match.entry2:
                    data['next_opponent_name'] = next_match.entry2.player.display_name
            else:
                if next_match.entry1:
                    data['next_opponent_name'] = next_match.entry1.player.display_name

        return Response(data)

    def _get_next_match(self, entry, tournament):
        """Get the next match for this entry in the tournament."""
        from matches.models import Match

        upcoming = Match.objects.filter(
            tournament=tournament,
            status__in=[Match.SCHEDULED, Match.LIVE],
        ).filter(
            entry1=entry
        ).union(
            Match.objects.filter(
                tournament=tournament,
                status__in=[Match.SCHEDULED, Match.LIVE],
            ).filter(entry2=entry)
        ).order_by('scheduled_start').first()

        return upcoming
