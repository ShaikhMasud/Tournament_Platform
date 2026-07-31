"""
WebSocket URL routing for matches.
Clients connect to /ws/matches/{match_id}/
"""
from django.urls import re_path

from .consumers import MatchConsumer

websocket_urlpatterns = [
    # Route matches the full path: /ws/matches/{match_id}/
    re_path(r"^ws/matches/(?P<match_id>[0-9a-f-]+)/$", MatchConsumer.as_asgi()),
]
