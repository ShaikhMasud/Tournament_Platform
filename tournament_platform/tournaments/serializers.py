from rest_framework import serializers

from accounts.models import AssistantCapability, TournamentRole, User
from organizations.models import Organization

from .models import (
    Category, Court, DashboardStats, Document, DocumentSignature,
    Notification, Official, Registration, Sport, Team, TeamPlayer, Tournament,
    TournamentSettings, Venue,
)


# =============================================================================
# SPORT SERIALIZERS
# =============================================================================

class SportSerializer(serializers.ModelSerializer):
    class Meta:
        model = Sport
        fields = [
            'id', 'name', 'category', 'team_size', 'match_type',
            'icon', 'rules', 'is_active', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class SportListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for dropdowns."""
    class Meta:
        model = Sport
        fields = ['id', 'name', 'category', 'team_size', 'match_type', 'icon']


# =============================================================================
# VENUE SERIALIZERS
# =============================================================================

class VenueSerializer(serializers.ModelSerializer):
    courts_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Venue
        fields = [
            'id', 'tournament', 'name', 'description', 'address',
            'city', 'state', 'country', 'postal_code', 'total_capacity',
            'viewing_capacity', 'has_parking', 'has_cafe', 'has_wifi',
            'is_indoor', 'is_accessible', 'contact_name', 'contact_phone',
            'contact_email', 'is_active', 'courts_count', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_courts_count(self, obj):
        return obj.courts.count()


class VenueCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Venue
        fields = [
            'name', 'description', 'address', 'city', 'state',
            'country', 'postal_code', 'total_capacity', 'viewing_capacity',
            'has_parking', 'has_cafe', 'has_wifi', 'is_indoor',
            'is_accessible', 'contact_name', 'contact_phone', 'contact_email'
        ]


# =============================================================================
# COURT SERIALIZERS
# =============================================================================

class CourtSerializer(serializers.ModelSerializer):
    class Meta:
        model = Court
        fields = [
            'id', 'venue', 'tournament', 'name', 'court_number',
            'surface', 'seating_capacity', 'is_active', 'is_available',
            'notes', 'opening_time', 'closing_time', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class CourtCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Court
        fields = [
            'venue', 'name', 'court_number', 'surface',
            'seating_capacity', 'is_active', 'is_available', 'notes',
            'opening_time', 'closing_time'
        ]


# =============================================================================
# CATEGORY SERIALIZERS
# =============================================================================

class CategorySerializer(serializers.ModelSerializer):
    """Serializer for Category."""
    tournament_name = serializers.CharField(source='tournament.name', read_only=True)
    entries_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Category
        fields = [
            'id', 'tournament', 'tournament_name', 'name', 'description',
            'draw_format', 'capacity', 'min_capacity', 'gender',
            'min_age', 'max_age', 'status', 'is_locked',
            'is_published', 'is_seeded', 'seed_count', 'entry_fee', 'entries_count',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_entries_count(self, obj):
        return obj.entries.filter(status='confirmed').count()


class CategoryCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = [
            'name', 'description', 'draw_format', 'capacity', 'min_capacity',
            'gender', 'min_age', 'max_age', 'status',
            'is_seeded', 'seed_count', 'entry_fee'
        ]


# =============================================================================
# TEAM & PLAYER SERIALIZERS
# =============================================================================

class TeamPlayerSerializer(serializers.ModelSerializer):
    player_name = serializers.SerializerMethodField()
    
    class Meta:
        model = TeamPlayer
        fields = ['id', 'team', 'player', 'player_name', 'position', 'is_captain']
    
    def get_player_name(self, obj):
        if obj.player:
            return obj.player.display_name
        return None


class TeamSerializer(serializers.ModelSerializer):
    members = TeamPlayerSerializer(many=True, read_only=True)
    members_count = serializers.SerializerMethodField()
    tournament_name = serializers.CharField(source='tournament.name', read_only=True)
    
    class Meta:
        model = Team
        fields = [
            'id', 'tournament', 'tournament_name', 'name', 'short_name',
            'description', 'logo', 'status', 'seed_number', 'members',
            'members_count', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_members_count(self, obj):
        return obj.members.count()


class TeamCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Team
        fields = [
            'name', 'short_name', 'description', 'logo', 'status', 'seed_number'
        ]


# =============================================================================
# OFFICIAL SERIALIZERS
# =============================================================================

class OfficialSerializer(serializers.ModelSerializer):
    user_name = serializers.SerializerMethodField()
    tournament_name = serializers.CharField(source='tournament.name', read_only=True)
    
    class Meta:
        model = Official
        fields = [
            'id', 'tournament', 'tournament_name', 'user', 'user_name',
            'name', 'email', 'phone', 'official_type', 'status',
            'certification', 'years_experience', 'notes',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_user_name(self, obj):
        if obj.user:
            return obj.user.get_full_name() or obj.user.email
        return obj.name


class OfficialCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Official
        fields = [
            'user', 'name', 'email', 'phone', 'official_type',
            'certification', 'years_experience', 'notes'
        ]


# =============================================================================
# REGISTRATION SERIALIZERS
# =============================================================================

class RegistrationSerializer(serializers.ModelSerializer):
    player_name = serializers.SerializerMethodField()
    team_name = serializers.CharField(source='team.name', read_only=True)
    category_name = serializers.CharField(source='category.name', read_only=True)
    tournament_name = serializers.CharField(source='tournament.name', read_only=True)
    
    class Meta:
        model = Registration
        fields = [
            'id', 'tournament', 'tournament_name', 'player', 'player_name',
            'team', 'team_name', 'category', 'category_name', 'status',
            'entry_fee', 'is_paid', 'payment_status', 'payment_reference',
            'registered_at', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'registered_at', 'created_at', 'updated_at']
    
    def get_player_name(self, obj):
        if obj.player:
            return obj.player.display_name
        return None


class RegistrationCreateSerializer(serializers.Serializer):
    """Serializer for creating tournament registrations."""
    
    player = serializers.UUIDField(required=False)
    team = serializers.UUIDField(required=False, allow_null=True)
    category = serializers.UUIDField(required=False, allow_null=True)
    entry_fee = serializers.DecimalField(max_digits=10, decimal_places=2, required=False)
    
    def validate(self, data):
        tournament = self.context.get('tournament')
        team_id = data.get('team')
        
        if tournament and tournament.tournament_type == 'team' and not team_id:
            raise serializers.ValidationError(
                {"team": "Team is required for team registration."}
            )
        return data


# =============================================================================
# NOTIFICATION SERIALIZERS
# =============================================================================

class NotificationSerializer(serializers.ModelSerializer):
    tournament_name = serializers.CharField(source='tournament.name', read_only=True)
    
    class Meta:
        model = Notification
        fields = [
            'id', 'user', 'notification_type', 'title', 'message',
            'tournament', 'tournament_name', 'status', 'action_url',
            'action_text', 'priority', 'is_email_sent', 'is_push_sent',
            'created_at', 'read_at'
        ]
        read_only_fields = ['id', 'user', 'created_at']


class NotificationCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = [
            'notification_type', 'title', 'message', 'tournament',
            'action_url', 'action_text', 'priority'
        ]


# =============================================================================
# DOCUMENT SERIALIZERS
# =============================================================================

class DocumentSerializer(serializers.ModelSerializer):
    signatures_count = serializers.SerializerMethodField()
    is_signed_by_user = serializers.SerializerMethodField()
    
    class Meta:
        model = Document
        fields = [
            'id', 'tournament', 'title', 'document_type', 'description',
            'file', 'file_name', 'file_size', 'file_type', 'is_public',
            'requires_signature', 'is_mandatory', 'signatures_count',
            'is_signed_by_user', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_signatures_count(self, obj):
        return obj.signatures.filter(is_signed=True).count()
    
    def get_is_signed_by_user(self, obj):
        user = self.context.get('request').user if self.context.get('request') else None
        if user:
            return obj.signatures.filter(user=user, is_signed=True).exists()
        return False


class DocumentCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Document
        fields = [
            'title', 'document_type', 'description', 'file', 'file_name',
            'file_size', 'file_type', 'is_public', 'requires_signature',
            'is_mandatory'
        ]


# =============================================================================
# SETTINGS SERIALIZERS
# =============================================================================

class TournamentSettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = TournamentSettings
        fields = [
            'id', 'tournament', 'best_of_sets', 'points_per_set',
            'tie_break_points', 'min_points_difference', 'enable_tie_break',
            'warmup_time', 'changeover_time', 'tie_break_time', 'injury_time',
            'enable_let', 'enable_advantage', 'max_consecutive_points',
            'enable_pause', 'pause_duration', 'show_names', 'show_scores',
            'enable_live_streaming', 'streaming_url', 'enable_prizes',
            'prize_details', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


# =============================================================================
# DASHBOARD STATS SERIALIZERS
# =============================================================================

class DashboardStatsSerializer(serializers.ModelSerializer):
    tournament_name = serializers.CharField(source='tournament.name', read_only=True)
    
    class Meta:
        model = DashboardStats
        fields = [
            'id', 'tournament', 'tournament_name', 'total_registrations',
            'approved_registrations', 'pending_registrations', 'total_teams',
            'total_matches', 'completed_matches', 'total_courts',
            'total_revenue', 'collected_fees', 'computed_at'
        ]


# =============================================================================
# TOURNAMENT SERIALIZERS
# =============================================================================

class TournamentListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for lists."""
    organization_name = serializers.CharField(source='organization.name', read_only=True)
    categories_count = serializers.SerializerMethodField()
    registrations_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Tournament
        fields = [
            'id', 'name', 'status', 'is_public', 'start_date', 'end_date',
            'organization', 'organization_name', 'sport_name', 'city',
            'categories_count', 'registrations_count', 'created_at'
        ]
    
    def get_categories_count(self, obj):
        return obj.categories.count()
    
    def get_registrations_count(self, obj):
        return obj.registrations.count()


class TournamentDetailSerializer(serializers.ModelSerializer):
    """Full tournament detail with nested data."""
    organization_name = serializers.CharField(source='organization.name', read_only=True)
    created_by_name = serializers.CharField(source='created_by.get_full_name', read_only=True)
    categories = CategorySerializer(many=True, read_only=True)
    venues = VenueSerializer(many=True, read_only=True)
    courts = CourtSerializer(many=True, read_only=True)
    documents_count = serializers.SerializerMethodField()
    registrations_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Tournament
        fields = [
            'id', 'organization', 'organization_name', 'name', 'description',
            'sport', 'sport_name', 'tournament_type', 'format',
            'location', 'venue', 'address', 'city', 'state', 'country',
            'postal_code', 'timezone', 'start_date', 'end_date',
            'registration_start', 'registration_end', 'max_players',
            'min_players', 'max_teams', 'entry_fee', 'currency', 'prize_pool',
            'banner', 'logo', 'contact_email', 'contact_phone', 'website',
            'rules', 'terms', 'consent_form', 'status', 'is_public',
            'visibility', 'created_by', 'created_by_name', 'created_at',
            'updated_at', 'categories', 'venues', 'courts',
            'documents_count', 'registrations_count'
        ]
        read_only_fields = [
            'id', 'created_by', 'created_at', 'updated_at',
            'documents_count', 'registrations_count'
        ]
    
    def get_documents_count(self, obj):
        return obj.documents.count()
    
    def get_registrations_count(self, obj):
        return obj.registrations.count()


class TournamentCreateSerializer(serializers.ModelSerializer):
    """Serializer for tournament creation."""
    
    organization = serializers.PrimaryKeyRelatedField(read_only=True)
    
    class Meta:
        model = Tournament
        fields = [
            'organization', 'name', 'description', 'sport', 'sport_name', 'tournament_type',
            'format', 'location', 'venue', 'address', 'city', 'state',
            'country', 'postal_code', 'timezone', 'start_date', 'end_date',
            'registration_start', 'registration_end', 'max_players',
            'min_players', 'max_teams', 'entry_fee', 'currency', 'prize_pool',
            'banner', 'logo', 'contact_email', 'contact_phone', 'website',
            'rules', 'terms', 'consent_form', 'status', 'is_public', 'visibility'
        ]
    
    def create(self, validated_data):
        # organization is passed by the view via save()
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)


class TournamentUpdateSerializer(serializers.ModelSerializer):
    """Serializer for tournament updates."""
    
    class Meta:
        model = Tournament
        fields = [
            'name', 'description', 'sport', 'sport_name', 'tournament_type',
            'format', 'location', 'venue', 'address', 'city', 'state',
            'country', 'postal_code', 'timezone', 'start_date', 'end_date',
            'registration_start', 'registration_end', 'max_players',
            'min_players', 'max_teams', 'entry_fee', 'currency', 'prize_pool',
            'banner', 'logo', 'contact_email', 'contact_phone', 'website',
            'rules', 'terms', 'consent_form', 'status', 'is_public', 'visibility'
        ]


# =============================================================================
# ROLE & CAPABILITY SERIALIZERS
# =============================================================================

class AssignRoleSerializer(serializers.Serializer):
    """Request body for POST /tournaments/{id}/roles/assign/."""

    email = serializers.EmailField(required=True)
    role = serializers.ChoiceField(
        choices=[TournamentRole.ORGANIZER, TournamentRole.ASSISTANT],
        required=True,
    )
    capabilities = serializers.ListField(
        child=serializers.ChoiceField(choices=AssistantCapability.CAPABILITY_CHOICES),
        required=False,
        default=list,
    )

    def validate_email(self, value):
        try:
            User.objects.get(email=value)
        except User.DoesNotExist:
            raise serializers.ValidationError("No user found with this email address.")
        return value


class TournamentRoleSerializer(serializers.ModelSerializer):
    """Read-only serializer for tournament roles."""

    user_email = serializers.EmailField(source="user.email", read_only=True)
    user_id = serializers.UUIDField(source="user.id", read_only=True)
    user_name = serializers.SerializerMethodField()
    capabilities = serializers.SerializerMethodField()

    class Meta:
        model = TournamentRole
        fields = ["id", "user_id", "user_email", "user_name", "role", "is_active", "capabilities"]
        read_only_fields = fields

    def get_user_name(self, obj):
        if obj.user:
            full_name = obj.user.get_full_name()
            return full_name if full_name else obj.user.email
        return None

    def get_capabilities(self, obj):
        if obj.role != TournamentRole.ASSISTANT:
            return []
        caps = obj.capabilities.all()
        return [
            {
                "capability": c.capability,
                "is_active": c.is_active,
            }
            for c in caps
        ]


class UpdateCapabilitiesSerializer(serializers.Serializer):
    """Request body for POST /tournaments/{id}/roles/{role_id}/capabilities/."""

    capabilities = serializers.ListField(
        child=serializers.ChoiceField(choices=AssistantCapability.CAPABILITY_CHOICES),
        required=True,
    )


# =============================================================================
# LEGACY SERIALIZERS (for backward compatibility)
# =============================================================================

class CourtLegacySerializer(serializers.ModelSerializer):
    class Meta:
        model = Court
        fields = ["id", "tournament", "name"]
        read_only_fields = ["id", "tournament"]

    def create(self, validated_data):
        tournament = self.context["tournament"]
        return Court.objects.create(tournament=tournament, **validated_data)


class CategoryLegacySerializer(serializers.ModelSerializer):
    courts = CourtLegacySerializer(many=True, read_only=True, source="tournament.courts")

    class Meta:
        model = Category
        fields = [
            "id", "tournament", "name", "draw_format", "capacity", "status",
        ]
        read_only_fields = ["id", "tournament", "status"]

    def create(self, validated_data):
        tournament = self.context["tournament"]
        return Category.objects.create(tournament=tournament, **validated_data)


class TournamentLegacySerializer(serializers.ModelSerializer):
    categories = CategoryLegacySerializer(many=True, read_only=True)
    courts = CourtLegacySerializer(many=True, read_only=True)

    class Meta:
        model = Tournament
        fields = [
            "id", "organization", "name", "sport", "is_public", "created_at",
            "categories", "courts",
        ]
        read_only_fields = ["id", "created_at"]
