"""
Real-time event types for live match scoring via WebSocket.
"""
import json
from dataclasses import asdict, dataclass
from typing import Optional


@dataclass
class ScoreUpdateEvent:
    """Broadcast when a score update is applied."""

    event: str = "score_update"
    match_id: str = ""
    entry1_points: int = 0
    entry2_points: int = 0
    version: int = 0
    status: str = ""
    winner_entry_id: Optional[str] = None

    def to_json(self) -> str:
        return json.dumps(asdict(self))


@dataclass
class MatchStartedEvent:
    """Broadcast when a match transitions to LIVE."""

    event: str = "match_started"
    match_id: str = ""
    scheduled_start: Optional[str] = None
    court_name: Optional[str] = None

    def to_json(self) -> str:
        return json.dumps(asdict(self))


@dataclass
class MatchCompletedEvent:
    """Broadcast when a match is completed."""

    event: str = "match_completed"
    match_id: str = ""
    winner_entry_id: Optional[str] = None
    score: dict = None

    def to_json(self) -> str:
        data = asdict(self)
        if self.score:
            data["score"] = self.score
        else:
            data["score"] = {}
        return json.dumps(data)


@dataclass
class MatchScheduledEvent:
    """Broadcast when a match is scheduled."""

    event: str = "match_scheduled"
    match_id: str = ""
    court_id: Optional[str] = None
    court_name: Optional[str] = None
    scheduled_start: Optional[str] = None
    scheduled_end: Optional[str] = None

    def to_json(self) -> str:
        return json.dumps(asdict(self))


def parse_message(message: str) -> dict:
    """Parse an incoming WebSocket message."""
    try:
        return json.loads(message)
    except json.JSONDecodeError:
        return {}
