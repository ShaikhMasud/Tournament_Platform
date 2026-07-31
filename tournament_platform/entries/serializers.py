from rest_framework import serializers

from accounts.models import PlayerProfile, TournamentRole

from .models import Entry


class EntrySerializer(serializers.ModelSerializer):
    """Read-only representation used by the list/detail endpoints."""

    player_display_name = serializers.SerializerMethodField()

    class Meta:
        model = Entry
        fields = [
            "id",
            "category",
            "player_id",
            "player_display_name",
            "status",
            "created_at",
        ]
        read_only_fields = fields

    def get_player_display_name(self, obj):
        player = obj.player
        return (
            getattr(player, "display_name", None)
            or getattr(player.user, "get_full_name", lambda: None)()
            or getattr(player.user, "email", None)
            or str(player)
        )


class EntryCreateSerializer(serializers.Serializer):
    """
    Write shape for POST /api/categories/{id}/entries/.

    - A Player caller may only ever create an entry for their own
      PlayerProfile — 'player' is ignored/overridden for them even if
      sent.
    - An Organizer or a capable Assistant may supply 'player' to add
      someone else, but the id is validated to be a real PlayerProfile
      before anything is created.
    """

    player = serializers.UUIDField(required=False)

    def validate(self, attrs):
        request = self.context["request"]
        category = self.context["category"]
        actor = request.user

        is_privileged = self.context.get("actor_is_privileged", False)
        player_id = attrs.get("player")

        if player_id:
            # Explicit player ID provided - validate it exists
            try:
                player = PlayerProfile.objects.get(pk=player_id)
            except PlayerProfile.DoesNotExist as exc:
                raise serializers.ValidationError({"player": "No such player."}) from exc
        elif is_privileged:
            # Privileged caller without player ID - use their own profile
            try:
                player = actor.player_profiles.first()
            except Exception:
                raise serializers.ValidationError(
                    {"player": "You don't have a player profile to enter with."}
                )
            if not player:
                raise serializers.ValidationError(
                    {"player": "You don't have a player profile to enter with."}
                )
        else:
            # Non-privileged callers must enter themselves
            try:
                player = actor.player_profiles.first()
            except Exception:
                raise serializers.ValidationError(
                    "You don't have a player profile to enter with."
                )
            if not player:
                raise serializers.ValidationError(
                    "You don't have a player profile to enter with."
                )

        attrs["resolved_player"] = player
        attrs["resolved_category"] = category
        return attrs
