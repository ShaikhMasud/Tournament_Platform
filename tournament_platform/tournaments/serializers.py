from rest_framework import serializers

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
