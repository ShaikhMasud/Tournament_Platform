"""
WebSocket URL routing for matches.
"""
from django.urls import re_path

from .consumers import MatchConsumer

websocket_urlpatterns = [
    re_path(r"ws/matches/(?P<match_id>[0-9a-f-]+)/$", MatchConsumer.as_asgi()),
]
