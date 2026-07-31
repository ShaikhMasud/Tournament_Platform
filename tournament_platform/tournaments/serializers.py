from rest_framework import serializers

from accounts.models import AssistantCapability, TournamentRole, User
from organizations.models import Organization

from .models import Category, Court, Tournament


class CourtSerializer(serializers.ModelSerializer):
    class Meta:
        model = Court
        fields = ["id", "tournament", "name"]
        read_only_fields = ["id", "tournament"]

    def create(self, validated_data):
        # tournament is injected by the view from the URL, never trusted
        # from the request body.
        tournament = self.context["tournament"]
        return Court.objects.create(tournament=tournament, **validated_data)


class CategorySerializer(serializers.ModelSerializer):
    courts = CourtSerializer(many=True, read_only=True, source="tournament.courts")

    class Meta:
        model = Category
        fields = [
            "id",
            "tournament",
            "name",
            "draw_format",
            "capacity",
            "status",
        ]
        read_only_fields = ["id", "tournament", "status"]

    def create(self, validated_data):
        tournament = self.context["tournament"]
        return Category.objects.create(tournament=tournament, **validated_data)


class TournamentSerializer(serializers.ModelSerializer):
    """
    Read: nested categories + courts for convenience on the detail view.
    Write: organization is validated against the caller's own orgs in the
    view/permission layer — never taken at face value just because an id
    was posted.
    """

    categories = CategorySerializer(many=True, read_only=True)
    courts = CourtSerializer(many=True, read_only=True)

    class Meta:
        model = Tournament
        fields = [
            "id",
            "organization",
            "name",
            "sport",
            "is_public",
            "created_at",
            "categories",
            "courts",
        ]
        read_only_fields = ["id", "created_at"]
        # 'sport' defaults to "badminton_single_game" at the model level
        # per the plan's Section 2 decision — not re-defaulted here so the
        # model stays the single source of truth.

    def validate_organization(self, organization: Organization):
        request = self.context["request"]
        if organization.owner_id != request.user.id:
            # Never let someone create a tournament under an org they
            # don't own, even if they guess a valid organization id.
            raise serializers.ValidationError(
                "You can only create tournaments under your own organization."
            )
        return organization


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
    capabilities = serializers.SerializerMethodField()

    class Meta:
        model = TournamentRole
        fields = ["id", "user_id", "user_email", "role", "is_active", "capabilities"]
        read_only_fields = fields

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
