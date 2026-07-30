from rest_framework import generics, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from .serializers import SessionSerializer, SignupSerializer


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
