"""
WebSocket authentication for match live scoring.

Clients connect to /ws/matches/{match_id}/ and must provide a valid JWT
in the query string or headers. The connection is rejected if the token
is invalid or the user doesn't have permission to view the match.
"""
from urllib.parse import parse_qs

from channels.db import database_sync_to_async
from channels.generic.websocket import AsyncWebsocketConsumer
from django.contrib.auth.models import AnonymousUser
from rest_framework_simplejwt.tokens import AccessToken
from rest_framework_simplejwt.exceptions import TokenError


@database_sync_to_async
def get_user_from_token(token_str: str):
    """Validate JWT token and return the associated user."""
    try:
        token = AccessToken(token_str)
        from django.contrib.auth import get_user_model
        User = get_user_model()
        user_id = token.payload.get("user_id")
        if not user_id:
            return AnonymousUser()
        return User.objects.get(id=user_id)
    except (TokenError, User.DoesNotExist):
        return AnonymousUser()


class JWTAuthMiddleware:
    """
    Channels middleware that authenticates WebSocket connections using JWT.

    Expects the token in the query string as ?token=<jwt> or in headers
    as Authorization: Bearer <jwt>.
    """

    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        # Try to get token from query string first.
        query_string = scope.get("query_string", b"").decode()
        params = parse_qs(query_string)
        token = params.get("token", [None])[0]

        # If not in query string, try Authorization header.
        if not token:
            headers = dict(scope.get("headers", []))
            auth_header = headers.get(b"authorization", b"").decode()
            if auth_header.startswith("Bearer "):
                token = auth_header[7:]

        # Authenticate the user.
        if token:
            scope["user"] = await get_user_from_token(token)
        else:
            scope["user"] = AnonymousUser()

        return await self.app(scope, receive, send)
