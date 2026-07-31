from django.db import transaction
from django.db.models import Q
from rest_framework.exceptions import APIException, ValidationError

from tournaments.models import Court

from .models import Match


class SchedulingConflict(APIException):
    status_code = 409
    default_detail = "This court or time slot is already booked."
    default_code = "scheduling_conflict"


class InvalidMatchState(APIException):
    status_code = 400
    default_detail = "This action is not allowed for matches in the current state."
    default_code = "invalid_state"


class StaleVersion(APIException):
    status_code = 409
    default_detail = "The match has been updated since you loaded it. Please refresh and try again."
    default_code = "stale_version"


class MatchNotLive(APIException):
    status_code = 400
    default_detail = "The match is not currently live."
    default_code = "match_not_live"


def _check_scheduling_conflict(
    court_id=None, scheduled_start=None, scheduled_end=None, exclude_match_id=None
):
    """Check for scheduling conflicts with other matches on the same court/time."""
    qs = Match.objects.filter(status__in=[Match.SCHEDULED, Match.LIVE])

    if exclude_match_id:
        qs = qs.exclude(id=exclude_match_id)

    if court_id and scheduled_start:
        # Same court and overlapping time.
        qs = qs.filter(
            court_id=court_id,
            scheduled_start__lt=scheduled_end,
            scheduled_end__gt=scheduled_start,
        )
        if qs.exists():
            raise SchedulingConflict("This court is already booked during the requested time.")

    if court_id and not scheduled_start:
        # Just checking court availability at any time (for future scheduling).
        if scheduled_end:
            qs = qs.filter(court_id=court_id)
            if qs.exists():
                raise SchedulingConflict("This court has scheduling conflicts.")

    # Check participant conflicts (same players can't play two matches at same time).
    # This requires knowing entry1 and entry2, which we'll check in schedule_match.


def schedule_match(
    *, match: Match, court_id=None, scheduled_start=None, scheduled_end=None
) -> Match:
    """
    Assigns a court and/or time to a match.

    Performs conflict checks:
    - No two matches on the same court at overlapping times.
    - No player plays two matches at the same time.
    """
    with transaction.atomic():
        locked_match = Match.objects.select_for_update().get(pk=match.pk)

        if locked_match.status not in [Match.PENDING, Match.SCHEDULED]:
            raise InvalidMatchState(
                f"Cannot schedule a match with status '{locked_match.status}'."
            )

        if locked_match.status == Match.LIVE:
            raise InvalidMatchState("Cannot reschedule a live match.")

        # Resolve court if provided.
        court = None
        if court_id:
            try:
                court = Court.objects.get(pk=court_id)
            except Court.DoesNotExist:
                raise ValidationError({"court_id": "Court not found."})

        # Check for conflicts.
        if court and scheduled_start:
            # Same court, overlapping time.
            if Match.objects.filter(
                court=court,
                status__in=[Match.SCHEDULED, Match.LIVE],
                scheduled_start__lt=scheduled_end,
                scheduled_end__gt=scheduled_start,
            ).exclude(pk=match.pk).exists():
                raise SchedulingConflict("This court is already booked during the requested time.")

        if scheduled_start and locked_match.entry1_id and locked_match.entry2_id:
            # Same participants at overlapping time.
            participant_ids = [locked_match.entry1_id, locked_match.entry2_id]
            if Match.objects.filter(
                Q(entry1_id__in=participant_ids) | Q(entry2_id__in=participant_ids),
                status__in=[Match.SCHEDULED, Match.LIVE],
                scheduled_start__lt=scheduled_end,
                scheduled_end__gt=scheduled_start,
            ).exclude(pk=match.pk).exists():
                raise SchedulingConflict(
                    "One or more players already have a match at this time."
                )

        # Update the match.
        if court:
            locked_match.court = court
        if scheduled_start:
            locked_match.scheduled_start = scheduled_start
        if scheduled_end:
            locked_match.scheduled_end = scheduled_end
        if court or scheduled_start:
            locked_match.status = Match.SCHEDULED

        locked_match.version += 1
        locked_match.save()

        return locked_match


def start_match(*, match: Match) -> Match:
    """
    Transitions a match from SCHEDULED to LIVE.
    """
    with transaction.atomic():
        locked_match = Match.objects.select_for_update().get(pk=match.pk)

        if locked_match.status != Match.SCHEDULED:
            raise InvalidMatchState(
                f"Cannot start a match with status '{locked_match.status}'."
            )

        if not locked_match.entry1_id or not locked_match.entry2_id:
            raise InvalidMatchState("Cannot start a match without both entries assigned.")

        locked_match.status = Match.LIVE
        locked_match.version += 1
        locked_match.save()

        return locked_match


def apply_score_update(*, match: Match, score: dict, version: int, actor) -> Match:
    """
    Applies a score update with optimistic concurrency control.

    The `version` parameter must match the current match.version, otherwise
    the update is rejected with StaleVersion.
    """
    with transaction.atomic():
        locked_match = Match.objects.select_for_update().get(pk=match.pk)

        if locked_match.version != version:
            raise StaleVersion()

        if locked_match.status != Match.LIVE:
            raise MatchNotLive()

        # Validate and apply score.
        # The score is a dict like: {"entry1_points": 15, "entry2_points": 12}
        # For badminton single-game: race to 21, win by 2, cap at 30.
        # Basic validation - ensure it's a dict with numeric values.
        if not isinstance(score, dict):
            raise ValidationError({"score": "Score must be a dictionary."})

        entry1_score = score.get("entry1_points", 0)
        entry2_score = score.get("entry2_points", 0)

        if not isinstance(entry1_score, (int, float)) or not isinstance(entry2_score, (int, float)):
            raise ValidationError({"score": "Score values must be numeric."})

        # Update match.
        locked_match.score = score
        locked_match.version += 1

        # Check for match completion.
        # Badminton single-game rules: first to 21, win by 2, cap at 30.
        winner = _determine_winner(entry1_score, entry2_score)
        if winner:
            locked_match.status = Match.COMPLETED
            locked_match.winner_entry = (
                locked_match.entry1 if winner == 1 else locked_match.entry2
            )
            # Propagate winner to next match.
            _propagate_winner(locked_match, locked_match.winner_entry)

        locked_match.save()
        return locked_match


def _determine_winner(entry1_score: int, entry2_score: int) -> int | None:
    """
    Determines if there's a winner based on badminton single-game rules.
    Returns 1 (entry1 wins), 2 (entry2 wins), or None (match continues).
    """
    max_score = max(entry1_score, entry2_score)
    min_score = min(entry1_score, entry2_score)

    # Cap at 30.
    if max_score > 30:
        return None  # Invalid score.

    # Win by 2, minimum 21.
    if max_score >= 21 and max_score - min_score >= 2:
        if entry1_score > entry2_score:
            return 1
        else:
            return 2

    # If we reached 30-29 (hard cap), that's also a win.
    if max_score == 30 and min_score == 29:
        if entry1_score > entry2_score:
            return 1
        else:
            return 2

    return None


def _propagate_winner(match: Match, winner_entry):
    """Propagates the winner to the next match in the bracket."""
    if not match.next_match_id or not match.next_match_slot:
        return

    try:
        next_match = Match.objects.get(pk=match.next_match_id)
        if match.next_match_slot == 1:
            next_match.entry1 = winner_entry
        else:
            next_match.entry2 = winner_entry
        next_match.version += 1
        next_match.save()
    except Match.DoesNotExist:
        pass  # No next match (this was the final).
