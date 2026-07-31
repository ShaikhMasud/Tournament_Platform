from django.db import transaction
from django.db.models import Q
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import mixins, status, viewsets
from rest_framework.decorators import action
from rest_framework.filters import SearchFilter, OrderingFilter
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from django_filters.rest_framework import DjangoFilterBackend

from accounts.models import AssistantCapability, TournamentRole, User
from core.permissions import organizer_or_capability

from .models import (
    Category, Court, DashboardStats, Document, DocumentSignature,
    Notification, Official, Registration, Team, TeamPlayer, Tournament,
    TournamentSettings, Venue, Sport,
)
from .permissions import IsOrganizerOfTournament
from .serializers import (
    AssignRoleSerializer, CategoryCreateSerializer, CategorySerializer,
    CourtCreateSerializer, CourtLegacySerializer, CourtSerializer,
    DashboardStatsSerializer, DocumentCreateSerializer, DocumentSerializer,
    OfficialCreateSerializer, OfficialSerializer,
    RegistrationCreateSerializer, RegistrationSerializer,
    SportListSerializer, SportSerializer,
    TeamCreateSerializer, TeamPlayerSerializer, TeamSerializer,
    TournamentCreateSerializer, TournamentDetailSerializer,
    TournamentLegacySerializer, TournamentListSerializer,
    TournamentRoleSerializer, TournamentSettingsSerializer,
    TournamentUpdateSerializer, UpdateCapabilitiesSerializer,
    VenueCreateSerializer, VenueSerializer,
)


# =============================================================================
# SPORT VIEWS
# =============================================================================

class SportViewSet(viewsets.ModelViewSet):
    """CRUD for sports."""
    queryset = Sport.objects.filter(is_active=True)
    serializer_class = SportSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [SearchFilter, OrderingFilter]
    search_fields = ['name', 'category']
    ordering_fields = ['name', 'created_at']
    ordering = ['name']
    
    def get_serializer_class(self):
        if self.action == 'list':
            return SportListSerializer
        return SportSerializer
    
    def get_queryset(self):
        return Sport.objects.filter(is_active=True)
    
    @action(detail=False, methods=['get'])
    def by_category(self, request):
        """Get sports grouped by category."""
        sports = Sport.objects.filter(is_active=True)
        categories = {}
        for sport in sports:
            if sport.category not in categories:
                categories[sport.category] = []
            categories[sport.category].append({
                'id': str(sport.id),
                'name': sport.name,
                'team_size': sport.team_size,
                'match_type': sport.match_type,
            })
        return Response(categories)


# =============================================================================
# VENUE VIEWS
# =============================================================================

class VenueViewSet(_NestedUnderTournamentMixin, viewsets.ModelViewSet):
    """CRUD for venues."""
    serializer_class = VenueSerializer
    permission_classes = [IsAuthenticated, IsOrganizerOfTournament]
    filter_backends = [SearchFilter, OrderingFilter]
    search_fields = ['name', 'city']
    ordering_fields = ['name', 'created_at']
    
    def get_queryset(self):
        return Venue.objects.filter(
            tournament_id=self.kwargs["tournament_pk"]
        ).order_by('name')
    
    def get_serializer_class(self):
        if self.action in ['create', 'update', 'partial_update']:
            return VenueCreateSerializer
        return VenueSerializer
    
    def perform_create(self, serializer):
        tournament = self.get_tournament()
        serializer.save(tournament=tournament)


class CourtViewSet(_NestedUnderTournamentMixin, viewsets.ModelViewSet):
    """CRUD for courts."""
    serializer_class = CourtSerializer
    permission_classes = [IsAuthenticated, IsOrganizerOfTournament]
    filter_backends = [SearchFilter, OrderingFilter]
    search_fields = ['name']
    ordering_fields = ['name', 'created_at']
    
    def get_queryset(self):
        return Court.objects.filter(
            tournament_id=self.kwargs["tournament_pk"]
        ).order_by('name')
    
    def get_serializer_class(self):
        if self.action in ['create', 'update', 'partial_update']:
            return CourtCreateSerializer
        return CourtSerializer


# =============================================================================
# CATEGORY VIEWS  
# =============================================================================

class CategoryViewSet(_NestedUnderTournamentMixin, viewsets.ModelViewSet):
    """CRUD for categories."""
    serializer_class = CategorySerializer
    permission_classes = [IsAuthenticated, IsOrganizerOfTournament]
    filter_backends = [SearchFilter, OrderingFilter]
    search_fields = ['name']
    ordering_fields = ['name', 'capacity', 'created_at']
    
    def get_queryset(self):
        return Category.objects.filter(
            tournament_id=self.kwargs["tournament_pk"]
        ).order_by('name')
    
    def get_serializer_class(self):
        if self.action in ['create', 'update', 'partial_update']:
            return CategoryCreateSerializer
        return CategorySerializer
    
    @action(detail=True, methods=['post'])
    def lock(self, request, tournament_pk, pk):
        """Lock a category draw."""
        category = self.get_object()
        category.is_locked = True
        category.save()
        return Response(CategorySerializer(category).data)
    
    @action(detail=True, methods=['post'])
    def unlock(self, request, tournament_pk, pk):
        """Unlock a category draw."""
        category = self.get_object()
        category.is_locked = False
        category.save()
        return Response(CategorySerializer(category).data)
    
    @action(detail=True, methods=['post'])
    def publish(self, request, tournament_pk, pk):
        """Publish a category."""
        category = self.get_object()
        category.is_published = True
        category.save()
        return Response(CategorySerializer(category).data)


# =============================================================================
# TEAM VIEWS
# =============================================================================

class TeamViewSet(_NestedUnderTournamentMixin, viewsets.ModelViewSet):
    """CRUD for teams."""
    serializer_class = TeamSerializer
    permission_classes = [IsAuthenticated, IsOrganizerOfTournament]
    filter_backends = [SearchFilter, OrderingFilter]
    search_fields = ['name', 'short_name']
    ordering_fields = ['name', 'created_at']
    
    def get_queryset(self):
        return Team.objects.filter(
            tournament_id=self.kwargs["tournament_pk"]
        ).prefetch_related('members').order_by('name')
    
    def get_serializer_class(self):
        if self.action in ['create', 'update', 'partial_update']:
            return TeamCreateSerializer
        return TeamSerializer
    
    @action(detail=True, methods=['post'])
    def approve(self, request, tournament_pk, pk):
        """Approve a team."""
        team = self.get_object()
        team.status = Team.APPROVED
        team.save()
        return Response(TeamSerializer(team).data)
    
    @action(detail=True, methods=['post'])
    def reject(self, request, tournament_pk, pk):
        """Reject a team."""
        team = self.get_object()
        team.status = Team.REJECTED
        team.save()
        return Response(TeamSerializer(team).data)


class TeamPlayerViewSet(viewsets.ModelViewSet):
    """CRUD for team players."""
    serializer_class = TeamPlayerSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        team_id = self.kwargs.get('team_pk')
        if team_id:
            return TeamPlayer.objects.filter(team_id=team_id)
        return TeamPlayer.objects.none()


# =============================================================================
# OFFICIAL VIEWS
# =============================================================================

class OfficialViewSet(_NestedUnderTournamentMixin, viewsets.ModelViewSet):
    """CRUD for officials."""
    serializer_class = OfficialSerializer
    permission_classes = [IsAuthenticated, IsOrganizerOfTournament]
    filter_backends = [SearchFilter, OrderingFilter]
    search_fields = ['name', 'email']
    ordering_fields = ['official_type', 'created_at']
    
    def get_queryset(self):
        return Official.objects.filter(
            tournament_id=self.kwargs["tournament_pk"]
        ).order_by('official_type', 'name')
    
    def get_serializer_class(self):
        if self.action in ['create', 'update', 'partial_update']:
            return OfficialCreateSerializer
        return OfficialSerializer
    
    @action(detail=True, methods=['post'])
    def approve(self, request, tournament_pk, pk):
        """Approve an official."""
        official = self.get_object()
        official.status = Official.APPROVED
        official.save()
        return Response(OfficialSerializer(official).data)


# =============================================================================
# REGISTRATION VIEWS
# =============================================================================

class RegistrationViewSet(_NestedUnderTournamentMixin, viewsets.ModelViewSet):
    """CRUD for registrations."""
    serializer_class = RegistrationSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [SearchFilter, OrderingFilter]
    search_fields = ['player_profile__display_name', 'team__name']
    ordering_fields = ['status', 'registered_at']
    
    def get_queryset(self):
        user = self.request.user
        tournament = self.get_tournament()
        
        # Check if user is organizer
        is_organizer = TournamentRole.objects.filter(
            tournament=tournament,
            user=user,
            role=TournamentRole.ORGANIZER,
            is_active=True
        ).exists()
        
        if is_organizer:
            return Registration.objects.filter(
                tournament=tournament
            ).select_related('player_profile', 'team', 'category')
        
        # Players only see their own registrations
        player = user.player_profiles.first()
        if player:
            return Registration.objects.filter(
                tournament=tournament,
                player_profile=player
            ).select_related('player_profile', 'team', 'category')
        
        return Registration.objects.none()
    
    def get_serializer_class(self):
        if self.action in ['create']:
            return RegistrationCreateSerializer
        return RegistrationSerializer
    
    @action(detail=True, methods=['post'])
    def approve(self, request, tournament_pk, pk):
        """Approve a registration."""
        registration = self.get_object()
        tournament = self.get_tournament()
        
        # Check permission
        if not organizer_or_capability('entry_management')(request, tournament):
            return Response(
                {"detail": "Permission denied"},
                status=status.HTTP_403_FORBIDDEN
            )
        
        registration.status = Registration.STATUS_APPROVED
        registration.approved_by = request.user
        registration.approved_at = timezone.now()
        registration.save()
        return Response(RegistrationSerializer(registration).data)
    
    @action(detail=True, methods=['post'])
    def reject(self, request, tournament_pk, pk):
        """Reject a registration."""
        registration = self.get_object()
        tournament = self.get_tournament()
        
        if not organizer_or_capability('entry_management')(request, tournament):
            return Response(
                {"detail": "Permission denied"},
                status=status.HTTP_403_FORBIDDEN
            )
        
        registration.status = Registration.STATUS_REJECTED
        registration.save()
        return Response(RegistrationSerializer(registration).data)


# =============================================================================
# DOCUMENT VIEWS
# =============================================================================

class DocumentViewSet(_NestedUnderTournamentMixin, viewsets.ModelViewSet):
    """CRUD for documents."""
    serializer_class = DocumentSerializer
    permission_classes = [IsAuthenticated, IsOrganizerOfTournament]
    filter_backends = [SearchFilter, OrderingFilter]
    search_fields = ['title']
    ordering_fields = ['document_type', 'created_at']
    
    def get_queryset(self):
        tournament = self.get_tournament()
        user = self.request.user
        
        # Public documents or organizer
        is_organizer = TournamentRole.objects.filter(
            tournament=tournament,
            user=user,
            role=TournamentRole.ORGANIZER,
            is_active=True
        ).exists()
        
        if is_organizer:
            return Document.objects.filter(tournament=tournament)
        
        return Document.objects.filter(
            tournament=tournament,
            is_public=True
        )
    
    def get_serializer_class(self):
        if self.action in ['create', 'update', 'partial_update']:
            return DocumentCreateSerializer
        return DocumentSerializer


class DocumentSignatureView(APIView):
    """Sign a document."""
    permission_classes = [IsAuthenticated]
    
    def post(self, request, document_id):
        document = get_object_or_404(Document, pk=document_id)
        
        signature, created = DocumentSignature.objects.get_or_create(
            document=document,
            user=request.user
        )
        signature.is_signed = True
        signature.signed_at = timezone.now()
        signature.ip_address = self.get_client_ip(request)
        signature.user_agent = request.META.get('HTTP_USER_AGENT', '')[:500]
        signature.save()
        
        return Response({
            'signed': True,
            'signed_at': signature.signed_at
        })
    
    def get_client_ip(self, request):
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip


# =============================================================================
# NOTIFICATION VIEWS
# =============================================================================

class NotificationViewSet(viewsets.ModelViewSet):
    """CRUD for notifications."""
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [SearchFilter, OrderingFilter]
    search_fields = ['title', 'message']
    ordering_fields = ['created_at', 'status']
    
    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user)
    
    @action(detail=True, methods=['post'])
    def mark_read(self, request, pk=None):
        """Mark notification as read."""
        notification = self.get_object()
        notification.status = Notification.READ
        notification.read_at = timezone.now()
        notification.save()
        return Response(NotificationSerializer(notification).data)
    
    @action(detail=False, methods=['post'])
    def mark_all_read(self, request):
        """Mark all notifications as read."""
        Notification.objects.filter(
            user=request.user,
            status=Notification.UNREAD
        ).update(
            status=Notification.READ,
            read_at=timezone.now()
        )
        return Response({'status': 'all marked as read'})
    
    @action(detail=False, methods=['delete'])
    def clear_all(self, request):
        """Clear all notifications."""
        Notification.objects.filter(
            user=request.user
        ).delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


# =============================================================================
# SETTINGS VIEWS
# =============================================================================

class TournamentSettingsView(_NestedUnderTournamentMixin, viewsets.ModelViewSet):
    """CRUD for tournament settings."""
    serializer_class = TournamentSettingsSerializer
    permission_classes = [IsAuthenticated, IsOrganizerOfTournament]
    
    def get_queryset(self):
        return TournamentSettings.objects.filter(
            tournament_id=self.kwargs["tournament_pk"]
        )
    
    def perform_create(self, serializer):
        tournament = self.get_tournament()
        serializer.save(tournament=tournament)


# =============================================================================
# DASHBOARD STATS VIEWS
# =============================================================================

class DashboardStatsView(_NestedUnderTournamentMixin, APIView):
    """Get dashboard statistics."""
    permission_classes = [IsAuthenticated, IsOrganizerOfTournament]
    
    def get(self, request, tournament_pk):
        tournament = self.get_tournament()
        
        # Try to get cached stats
        try:
            stats = DashboardStats.objects.get(tournament=tournament)
        except DashboardStats.DoesNotExist:
            stats = self.compute_stats(tournament)
        
        return Response(DashboardStatsSerializer(stats).data)
    
    def compute_stats(self, tournament):
        """Compute fresh statistics."""
        stats, _ = DashboardStats.objects.get_or_create(tournament=tournament)
        
        stats.total_registrations = tournament.registrations.count()
        stats.approved_registrations = tournament.registrations.filter(
            status=Registration.STATUS_APPROVED
        ).count()
        stats.pending_registrations = tournament.registrations.filter(
            status=Registration.STATUS_PENDING
        ).count()
        stats.total_teams = tournament.teams.count()
        
        # Get match counts from matches app
        try:
            from matches.models import Match
            stats.total_matches = Match.objects.filter(tournament=tournament).count()
            stats.completed_matches = Match.objects.filter(
                tournament=tournament,
                status='COMPLETED'
            ).count()
        except:
            pass
        
        stats.total_courts = tournament.courts.count()
        
        # Revenue
        stats.collected_fees = sum(
            r.entry_fee for r in tournament.registrations.filter(is_paid=True)
        )
        stats.save()
        
        return stats


# =============================================================================
# TOURNAMENT VIEWS (UPDATED)
# =============================================================================

class TournamentViewSet(viewsets.ModelViewSet):
    """Full CRUD for tournaments."""
    permission_classes = [IsAuthenticated, IsOrganizerOfTournament]
    filter_backends = [SearchFilter, OrderingFilter]
    search_fields = ['name', 'city', 'organization__name']
    ordering_fields = ['name', 'start_date', 'created_at', 'status']
    ordering = ['-created_at']
    
    def get_tournament(self):
        return None
    
    def get_queryset(self):
        user = self.request.user
        active_role_tournament_ids = TournamentRole.objects.filter(
            user=user, is_active=True
        ).values_list("tournament_id", flat=True)
        
        queryset = Tournament.objects.filter(
            Q(is_public=True) | Q(id__in=active_role_tournament_ids)
        ).select_related("organization", "created_by")
        
        # Filter by status
        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        # Filter by organization
        org_filter = self.request.query_params.get('organization')
        if org_filter:
            queryset = queryset.filter(organization_id=org_filter)
        
        return queryset.distinct()
    
    def get_serializer_class(self):
        if self.action == 'list':
            return TournamentListSerializer
        if self.action in ['create']:
            return TournamentCreateSerializer
        if self.action in ['update', 'partial_update']:
            return TournamentUpdateSerializer
        return TournamentDetailSerializer
    
    def get_serializer_context(self):
        context = super().get_serializer_context()
        org_id = self.request.data.get('organization') or self.request.query_params.get('organization')
        if org_id:
            from organizations.models import Organization
            try:
                context['organization'] = Organization.objects.get(pk=org_id)
            except Organization.DoesNotExist:
                pass
        return context
    
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)
    
    @action(detail=True, methods=['post'])
    def publish(self, request, pk=None):
        """Publish a tournament."""
        tournament = self.get_object()
        tournament.status = Tournament.STATUS_PUBLISHED
        tournament.save()
        return Response(TournamentDetailSerializer(tournament).data)
    
    @action(detail=True, methods=['post'])
    def start(self, request, pk=None):
        """Start a tournament."""
        tournament = self.get_object()
        tournament.status = Tournament.STATUS_IN_PROGRESS
        tournament.save()
        return Response(TournamentDetailSerializer(tournament).data)
    
    @action(detail=True, methods=['post'])
    def complete(self, request, pk=None):
        """Complete a tournament."""
        tournament = self.get_object()
        tournament.status = Tournament.STATUS_COMPLETED
        tournament.save()
        return Response(TournamentDetailSerializer(tournament).data)
    
    @action(detail=True, methods=['post'])
    def cancel(self, request, pk=None):
        """Cancel a tournament."""
        tournament = self.get_object()
        tournament.status = Tournament.STATUS_CANCELLED
        tournament.save()
        return Response(TournamentDetailSerializer(tournament).data)


# =============================================================================
# MIXIN FOR NESTED UNDER TOURNAMENT
# =============================================================================

class _NestedUnderTournamentMixin:
    """Shared plumbing for viewsets nested under tournaments."""
    
    def get_tournament(self):
        return get_object_or_404(Tournament, pk=self.kwargs.get("tournament_pk"))
    
    def get_serializer_context(self):
        context = super().get_serializer_context()
        context["tournament"] = self.get_tournament()
        context["request"] = self.request
        return context
