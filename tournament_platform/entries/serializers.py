from rest_framework import serializers

from accounts.models import PlayerProfile, TournamentRole

from .models import Entry


class EntrySerializer(serializers.ModelSerializer):
    """Read-only representation used by the list/detail endpoints."""

    player_display_name = serializers.SerializerMethodField()
    player_id = serializers.UUIDField(source="player_id", read_only=True)

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

    player = serializers.IntegerField(required=False)

    def validate(self, attrs):
        request = self.context["request"]
        category = self.context["category"]
        actor = request.user

        is_privileged = self.context.get("actor_is_privileged", False)

        if is_privileged:
            player_id = attrs.get("player")
            if not player_id:
                raise serializers.ValidationError(
                    {"player": "player id is required when adding on someone else's behalf."}
                )
            try:
                player = PlayerProfile.objects.get(pk=player_id)
            except PlayerProfile.DoesNotExist as exc:
                raise serializers.ValidationError({"player": "No such player."}) from exc
        else:
            # Non-privileged callers can only enter themselves — 'player'
            # in the request body is never trusted here.
            try:
                player = actor.playerprofile
            except PlayerProfile.DoesNotExist as exc:
                raise serializers.ValidationError(
                    "You don't have a player profile to enter with."
                ) from exc

        attrs["resolved_player"] = player
        attrs["resolved_category"] = category
        return attrs
