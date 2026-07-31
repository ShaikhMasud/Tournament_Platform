"""
ASGI config for config project.

It exposes the ASGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/6.0/howto/deployment/asgi/
"""

import os

from channels.auth import AuthMiddlewareStack
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.security.websocket import AllowedHostsOriginValidator
from django.core.asgi import get_asgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

# Initialize Django ASGI application early to ensure the AppRegistry
# is populated before importing code that may import ORM models.
django_asgi_app = get_asgi_application()

# Import routing after Django setup.
from matches.routing import websocket_urlpatterns
from matches.ws_auth import JWTAuthMiddleware

# WebSocket URLs are mounted at /ws/ prefix
ws_urlpatterns = [
    URLRouter([
        # /ws/matches/{match_id}/
        *websocket_urlpatterns,
    ]),
]

application = ProtocolTypeRouter({
    "http": django_asgi_app,
    "websocket": AllowedHostsOriginValidator(
        JWTAuthMiddleware(
            URLRouter(websocket_urlpatterns)  # Mounts directly at /matches/...
            # In production, configure your reverse proxy (nginx) to map /ws/ -> this
        )
    ),
})
