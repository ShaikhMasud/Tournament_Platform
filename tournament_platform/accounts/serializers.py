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


class UserSearchSerializer(serializers.ModelSerializer):
    """Serializer for user search results."""
    
    display_name = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = ["id", "email", "username", "display_name"]
    
    def get_display_name(self, obj):
        try:
            return obj.player_profiles.first().display_name if hasattr(obj, 'player_profiles') else obj.username
        except:
            return obj.username


class AssistantSignupSerializer(serializers.Serializer):
    """Serializer for creating a new assistant user."""
    
    email = serializers.EmailField(required=True)
    username = serializers.CharField(required=True, min_length=3)
    password = serializers.CharField(write_only=True, validators=[validate_password], required=False)
    display_name = serializers.CharField(required=True)
    send_invite = serializers.BooleanField(default=True, help_text="Send invitation email")
    
    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return value
    
    def validate_username(self, value):
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError("This username is already taken.")
        return value
    
    def create(self, validated_data):
        password = validated_data.pop('password', None)
        # Generate password if not provided
        if not password:
            import secrets
            import string
            alphabet = string.ascii_letters + string.digits
            password = ''.join(secrets.choice(alphabet) for _ in range(12))
        
        user = User.objects.create_user(
            email=validated_data['email'],
            username=validated_data['username'],
            password=password,
        )
        PlayerProfile.objects.create(
            user=user, 
            display_name=validated_data['display_name']
        )
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
