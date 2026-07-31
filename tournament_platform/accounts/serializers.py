from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers

from .models import AssistantCapability, PlayerProfile, TournamentRole

User = get_user_model()


class SignupSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, validators=[validate_password])
    display_name = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ["email", "username", "password", "display_name"]

    def create(self, validated_data):
        display_name = validated_data.pop("display_name")
        password = validated_data.pop("password")
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        # Every signed-up user gets a PlayerProfile by default — Organizer/
        # Assistant access is granted later via explicit TournamentRole rows,
        # never inferred at signup time.
        PlayerProfile.objects.create(user=user, display_name=display_name)
        return user


class CapabilitySerializer(serializers.ModelSerializer):
    class Meta:
        model = AssistantCapability
        fields = ["capability", "is_active"]


class TournamentRoleSerializer(serializers.ModelSerializer):
    tournament_name = serializers.CharField(source="tournament.name", read_only=True)
    user_email = serializers.CharField(source="user.email", read_only=True)
    capabilities = CapabilitySerializer(many=True, read_only=True)

    class Meta:
        model = TournamentRole
        fields = ["id", "tournament", "tournament_name", "user_email", "role", "is_active", "capabilities"]


class SessionSerializer(serializers.ModelSerializer):
    """Shape the Flutter client keys its nav/route-guarding off of."""

    player_profiles = serializers.SerializerMethodField()
    tournament_roles = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ["id", "email", "username", "player_profiles", "tournament_roles"]

    def get_player_profiles(self, obj):
        return list(obj.player_profiles.values("id", "display_name"))

    def get_tournament_roles(self, obj):
        roles = obj.tournament_roles.filter(is_active=True).select_related("tournament")
        return TournamentRoleSerializer(roles, many=True).data
