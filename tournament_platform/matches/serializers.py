from rest_framework import serializers

from entries.models import Entry
from tournaments.models import Court

from .models import Match


class MatchEntrySerializer(serializers.ModelSerializer):
    """Minimal entry representation for match display."""

    player_display_name = serializers.SerializerMethodField()
    player_id = serializers.UUIDField(source="player.id", read_only=True)

    class Meta:
        model = Entry
        fields = ["id", "player_id", "player_display_name"]
        read_only_fields = fields

    def get_player_display_name(self, obj):
        return (
            getattr(obj.player, "display_name", None)
            or getattr(obj.player.user, "get_full_name", lambda: None)()
            or getattr(obj.player.user, "email", None)
            or str(obj.player)
        )


class CourtSerializer(serializers.ModelSerializer):
    class Meta:
        model = Court
        fields = ["id", "name"]


class MatchSerializer(serializers.ModelSerializer):
    """Full match serializer with nested entry and court info."""

    entry1 = MatchEntrySerializer(read_only=True, allow_null=True)
    entry2 = MatchEntrySerializer(read_only=True, allow_null=True)
    court = CourtSerializer(read_only=True, allow_null=True)
    tournament_name = serializers.CharField(source="tournament.name", read_only=True)
    category_name = serializers.CharField(source="category.name", read_only=True)

    class Meta:
        model = Match
        fields = [
            "id",
            "tournament",
            "tournament_name",
            "category",
            "category_name",
            "round_number",
            "slot_position",
            "entry1",
            "entry2",
            "status",
            "court",
            "scheduled_start",
            "scheduled_end",
            "winner_entry",
            "score",
            "version",
            "created_at",
        ]
        read_only_fields = fields


class ScheduleSerializer(serializers.Serializer):
    """Request shape for POST /matches/{id}/schedule/."""

    court_id = serializers.UUIDField(required=False, allow_null=True)
    scheduled_start = serializers.DateTimeField(required=False, allow_null=True)
    scheduled_end = serializers.DateTimeField(required=False, allow_null=True)

    def validate(self, attrs):
        if not any([attrs.get("court_id"), attrs.get("scheduled_start")]):
            raise serializers.ValidationError(
                "At least one of court_id or scheduled_start is required."
            )
        return attrs


class ScoreUpdateSerializer(serializers.Serializer):
    """Request shape for POST /matches/{id}/score/."""

    score = serializers.DictField(required=True)
    version = serializers.IntegerField(required=True)

    def validate_score(self, value):
        if not isinstance(value, dict):
            raise serializers.ValidationError("Score must be a dictionary.")
        return value


class StartMatchSerializer(serializers.Serializer):
    """Empty serializer for POST /matches/{id}/start/."""

    pass
