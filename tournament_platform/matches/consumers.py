"""
WebSocket consumers for live match scoring.
"""
import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.layers import get_channel_layer
from asgiref.sync import sync_to_async

from matches.models import Match
from matches.services import apply_score_update
from matches.realtime import (
    ScoreUpdateEvent,
    MatchStartedEvent,
    MatchCompletedEvent,
    MatchScheduledEvent,
)


class MatchConsumer(AsyncWebsocketConsumer):
    """
    WebSocket consumer for live match score updates.

    Clients connect to /ws/matches/{match_id}/ and receive real-time
    updates whenever the match score changes.

    Protocol:
    - Client sends: {"action": "score", "entry": 1|2, "version": <current_version>}
      (server increments the chosen side by 1)
    - Server broadcasts: ScoreUpdateEvent JSON to all connected clients
    - Server sends error: {"error": "<message>"}
    """

    async def connect(self):
        self.match_id = self.scope["url_route"]["kwargs"]["match_id"]
        self.room_group_name = f"match_{self.match_id}"
        self.user = self.scope.get("user")

        # Check if user is authenticated.
        if not self.user or not self.user.is_authenticated:
            await self.close(code=4001)
            return

        # Verify match exists and user has access.
        match_exists = await self._match_exists()
        if not match_exists:
            await self.close(code=4004)
            return

        # Join the match group.
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )
        await self.accept()

        # Send initial state snapshot.
        await self._send_current_state()

    async def disconnect(self, close_code):
        # Leave the match group.
        if hasattr(self, "room_group_name"):
            await self.channel_layer.group_discard(
                self.room_group_name,
                self.channel_name
            )

    async def receive(self, text_data):
        """Handle incoming WebSocket messages."""
        if not self.user or not self.user.is_authenticated:
            await self.send(text_data=json.dumps({"error": "Authentication required."}))
            return

        try:
            data = json.loads(text_data)
        except json.JSONDecodeError:
            await self.send(text_data=json.dumps({"error": "Invalid JSON."}))
            return

        action = data.get("action")

        if action == "ping":
            await self.send(text_data=json.dumps({"event": "pong"}))
            return

        elif action == "score":
            await self._handle_score_action(data)

        elif action == "request_state":
            await self._send_current_state()

        else:
            await self.send(text_data=json.dumps({"error": f"Unknown action: {action}"}))

    async def _handle_score_action(self, data):
        """Handle a score update request."""
        entry = data.get("entry")  # 1 or 2
        version = data.get("version")

        if entry not in [1, 2]:
            await self.send(text_data=json.dumps({"error": "Invalid entry: must be 1 or 2."}))
            return

        if not isinstance(version, int):
            await self.send(text_data=json.dumps({"error": "Invalid version: must be an integer."}))
            return

        try:
            updated_match = await self._apply_score(entry, version)
            event = ScoreUpdateEvent(
                match_id=str(self.match_id),
                entry1_points=updated_match.score.get("entry1_points", 0),
                entry2_points=updated_match.score.get("entry2_points", 0),
                version=updated_match.version,
                status=updated_match.status,
                winner_entry_id=str(updated_match.winner_entry_id) if updated_match.winner_entry_id else None,
            )
            # Broadcast to all clients in the group.
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    "type": "score_update",
                    "message": event.to_json(),
                }
            )
        except Exception as e:
            await self.send(text_data=json.dumps({"error": str(e)}))

    async def score_update(self, event):
        """Handler for score_update group messages."""
        await self.send(text_data=event["message"])

    async def match_started(self, event):
        """Handler for match_started group messages."""
        await self.send(text_data=event["message"])

    async def match_completed(self, event):
        """Handler for match_completed group messages."""
        await self.send(text_data=event["message"])

    async def match_scheduled(self, event):
        """Handler for match_scheduled group messages."""
        await self.send(text_data=event["message"])

    @sync_to_async
    def _match_exists(self) -> bool:
        return Match.objects.filter(pk=self.match_id).exists()

    @sync_to_async
    def _apply_score(self, entry: int, version: int):
        """Apply a score update via the service layer."""
        match = Match.objects.select_for_update().get(pk=self.match_id)
        
        # Build new score.
        current_score = match.score or {}
        entry1_points = current_score.get("entry1_points", 0)
        entry2_points = current_score.get("entry2_points", 0)

        if entry == 1:
            entry1_points += 1
        else:
            entry2_points += 1

        new_score = {"entry1_points": entry1_points, "entry2_points": entry2_points}

        return apply_score_update(
            match=match,
            score=new_score,
            version=version,
            actor=self.user,
        )

    @sync_to_async
    def _get_current_match_state(self) -> dict:
        """Get the current state of the match."""
        try:
            match = Match.objects.select_related(
                "entry1__player", "entry2__player", "court"
            ).get(pk=self.match_id)
            return {
                "match_id": str(match.id),
                "status": match.status,
                "score": match.score or {"entry1_points": 0, "entry2_points": 0},
                "version": match.version,
                "entry1": {
                    "id": str(match.entry1.id) if match.entry1 else None,
                    "name": match.entry1.player.display_name if match.entry1 else None,
                },
                "entry2": {
                    "id": str(match.entry2.id) if match.entry2 else None,
                    "name": match.entry2.player.display_name if match.entry2 else None,
                },
                "court": {
                    "id": str(match.court.id) if match.court else None,
                    "name": match.court.name if match.court else None,
                },
                "winner_entry_id": str(match.winner_entry_id) if match.winner_entry_id else None,
            }
        except Match.DoesNotExist:
            return {}

    async def _send_current_state(self):
        """Send the current match state to the client."""
        state = await self._get_current_match_state()
        await self.send(text_data=json.dumps({
            "event": "state_snapshot",
            **state
        }))


async def broadcast_match_update(match_id: str, event_type: str, data: dict):
    """
    Utility to broadcast a match update to all connected clients.

    Call this from views/services after making changes to a match.
    """
    channel_layer = get_channel_layer()
    group_name = f"match_{match_id}"

    message = json.dumps({
        "event": event_type,
        **data
    })

    await channel_layer.group_send(
        group_name,
        {
            "type": event_type,
            "message": message,
        }
    )
