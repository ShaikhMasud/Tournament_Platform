from rest_framework import serializers

from entries.models import Entry

from .models import Draw, DrawSlot


class DrawSlotSerializer(serializers.ModelSerializer):
    """Read-only serializer for draw slots — no writes after initial generation."""

    entry_display_name = serializers.SerializerMethodField()
    entry_id = serializers.UUIDField(source="entry.id", read_only=True, allow_null=True)

    class Meta:
        model = DrawSlot
        fields = [
            "id",
            "round_number",
            "position",
            "entry_id",
            "entry_display_name",
            "is_bye",
        ]
        read_only_fields = fields

    def get_entry_display_name(self, obj):
        if not obj.entry:
            return None
        return (
            getattr(obj.entry.player, "display_name", None)
            or getattr(obj.entry.player.user, "get_full_name", lambda: None)()
            or getattr(obj.entry.player.user, "email", None)
            or str(obj.entry.player)
        )


class DrawSerializer(serializers.ModelSerializer):
    """Read-only serializer for draw data."""

    slots = DrawSlotSerializer(many=True, read_only=True)
    category_name = serializers.CharField(source="category.name", read_only=True)

    class Meta:
        model = Draw
        fields = [
            "id",
            "category",
            "category_name",
            "status",
            "version",
            "fingerprint",
            "created_at",
            "finalized_at",
            "slots",
        ]
        read_only_fields = fields


class DrawGenerateSerializer(serializers.Serializer):
    """Empty serializer for POST /categories/{id}/draw/generate/."""

    pass
