"""
Fingerprint computation for match/tournament results.

The fingerprint uniquely identifies a specific result state so we can:
1. Cache/reuse PDFs for unchanged results.
2. Detect when a new PDF needs to be generated.
"""
import hashlib
import json
from typing import List

from matches.models import Match


def compute_tournament_fingerprint(tournament) -> str:
    """
    Compute a fingerprint for all completed matches in a tournament.

    The fingerprint changes if any completed match's score changes,
    or if the match list changes.
    """
    completed_matches = (
        Match.objects.filter(
            tournament=tournament,
            status=Match.COMPLETED,
        )
        .select_related("entry1__player", "entry2__player", "category")
        .order_by("category__name", "round_number", "slot_position")
    )

    fingerprint_data = []
    for match in completed_matches:
        entry1_name = ""
        entry2_name = ""
        if match.entry1:
            entry1_name = match.entry1.player.display_name
        if match.entry2:
            entry2_name = match.entry2.player.display_name

        match_data = {
            "match_id": str(match.id),
            "category": match.category.name,
            "round": match.round_number,
            "slot": match.slot_position,
            "entry1": entry1_name,
            "entry2": entry2_name,
            "score": match.score or {},
            "winner": str(match.winner_entry_id) if match.winner_entry_id else None,
        }
        fingerprint_data.append(match_data)

    # Create a stable JSON string.
    json_str = json.dumps(fingerprint_data, sort_keys=True, default=str)
    return hashlib.sha256(json_str.encode()).hexdigest()


def compute_category_fingerprint(category) -> str:
    """
    Compute a fingerprint for all completed matches in a category.
    """
    completed_matches = (
        Match.objects.filter(
            category=category,
            status=Match.COMPLETED,
        )
        .select_related("entry1__player", "entry2__player")
        .order_by("round_number", "slot_position")
    )

    fingerprint_data = []
    for match in completed_matches:
        entry1_name = ""
        entry2_name = ""
        if match.entry1:
            entry1_name = match.entry1.player.display_name
        if match.entry2:
            entry2_name = match.entry2.player.display_name

        match_data = {
            "match_id": str(match.id),
            "round": match.round_number,
            "slot": match.slot_position,
            "entry1": entry1_name,
            "entry2": entry2_name,
            "score": match.score or {},
            "winner": str(match.winner_entry_id) if match.winner_entry_id else None,
        }
        fingerprint_data.append(match_data)

    json_str = json.dumps(fingerprint_data, sort_keys=True, default=str)
    return hashlib.sha256(json_str.encode()).hexdigest()
