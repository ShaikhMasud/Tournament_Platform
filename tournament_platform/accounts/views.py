from django.contrib.auth import get_user_model
from django.db.models import Q as models_Q
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from .serializers import (
    AssistantSignupSerializer,
    SessionSerializer,
    SignupSerializer,
    UserSearchSerializer,
)

User = get_user_model()


class SignupView(generics.CreateAPIView):
    """POST /auth/signup — creates User + PlayerProfile, returns tokens
    directly so the client doesn't need a second login round-trip."""

    permission_classes = [permissions.AllowAny]
    serializer_class = SignupSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        refresh = RefreshToken.for_user(user)
        return Response(
            {
                "access": str(refresh.access_token),
                "refresh": str(refresh),
                "user": SessionSerializer(user).data,
            },
            status=201,
        )


class UserSearchView(APIView):
    """GET /auth/users/search?q=email_or_name — search for users to add as assistants."""

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        query = request.query_params.get('q', '').strip()
        if len(query) < 2:
            return Response({"results": []})
        
        # Search by email or username or display name
        users = User.objects.filter(
            models_Q(email__icontains=query) |
            models_Q(username__icontains=query) |
            models_Q(player_profiles__display_name__icontains=query)
        ).distinct()[:10]  # Limit to 10 results
        
        # Exclude current user
        users = users.exclude(id=request.user.id)
        
        serializer = UserSearchSerializer(users, many=True)
        return Response({"results": serializer.data})


class AssistantSignupView(APIView):
    """POST /auth/assistant-signup — Organizer creates a new assistant account.
    This creates the user AND assigns them as an assistant to a tournament."""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = AssistantSignupSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        user = serializer.save()
        
        # Optionally assign to tournament if tournament_id provided
        tournament_id = request.data.get('tournament_id')
        if tournament_id:
            from tournaments.models import Tournament
            from accounts.models import TournamentRole, AssistantCapability
            
            try:
                tournament = Tournament.objects.get(pk=tournament_id)
                # Check if user is organizer of this tournament
                if not TournamentRole.objects.filter(
                    user=request.user, 
                    tournament=tournament, 
                    role=TournamentRole.ORGANIZER,
                    is_active=True
                ).exists():
                    return Response(
                        {"detail": "You are not an organizer of this tournament."},
                        status=status.HTTP_403_FORBIDDEN
                    )
                
                # Create assistant role
                role = TournamentRole.objects.create(
                    user=user,
                    tournament=tournament,
                    role=TournamentRole.ASSISTANT,
                    is_active=True,
                    granted_by=request.user,
                )
                
                # Add capabilities if provided
                capabilities = request.data.get('capabilities', [])
                for cap in capabilities:
                    AssistantCapability.objects.create(
                        tournament_role=role,
                        capability=cap,
                        is_active=True,
                    )
                
            except Tournament.DoesNotExist:
                pass  # Just create the user, don't assign
        
        return Response(
            {
                "id": str(user.id),
                "email": user.email,
                "username": user.username,
                "message": "Assistant account created successfully."
            },
            status=status.HTTP_201_CREATED,
        )


class SessionView(APIView):
    """GET /auth/session — the payload the Flutter app uses to decide which
    screens/role-switcher options to show. Always resolved from DB relations,
    never trusts anything client-supplied beyond 'who is this token for'."""

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        return Response(SessionSerializer(request.user).data)


class LogoutView(APIView):
    """POST /auth/logout — blacklists the refresh token so it can't be reused.
    Requires rest_framework_simplejwt.token_blacklist in INSTALLED_APPS."""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        refresh = request.data.get("refresh")
        if not refresh:
            return Response({"detail": "refresh token required"}, status=400)
        try:
            RefreshToken(refresh).blacklist()
        except Exception:
            return Response({"detail": "invalid or already-blacklisted token"}, status=400)
        return Response(status=204)
