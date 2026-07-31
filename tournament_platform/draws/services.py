import hashlib
import math
from typing import List

from django.db import transaction
from rest_framework.exceptions import APIException, ValidationError

from entries.models import Entry
from tournaments.models import Category

from .models import Draw, DrawSlot


class DrawAlreadyExists(APIException):
    status_code = 409
    default_detail = "A draw already exists for this category."
    default_code = "draw_exists"


class CategoryNotOpen(APIException):
    status_code = 400
    default_detail = "Cannot generate a draw for a category that is not open."
    default_code = "category_not_open"


class NotEnoughEntries(APIException):
    status_code = 400
    default_detail = "Need at least 2 entries to generate a draw."
    default_code = "not_enough_entries"


def _compute_fingerprint(entries: List[Entry]) -> str:
    """Stable fingerprint based on entry IDs in sorted order."""
    ids = sorted(str(e.id) for e in entries)
    return hashlib.sha256("|".join(ids).encode()).hexdigest()


def _next_power_of_2(n: int) -> int:
    """Smallest power of 2 >= n."""
    return 1 << (n - 1).bit_length()


def generate_knockout_draw(*, category: Category) -> Draw:
    """
    Generates a knockout draw for the given category.

    Concurrency-safe: uses select_for_update on the Category row to
    ensure only one request can generate a draw even if multiple
    requests arrive simultaneously.
    """
    if category.status != Category.OPEN:
        raise CategoryNotOpen()

    entries = list(
        Entry.objects.eligible_for_draw()
        .filter(category=category)
        .select_related("player", "player__user")
        .order_by("id")
    )

    if len(entries) < 2:
        raise NotEnoughEntries()

    with transaction.atomic():
        # Lock the category row to prevent concurrent draw generation.
        locked_category = (
            Category.objects.select_for_update().filter(pk=category.pk).first()
        )
        if not locked_category or locked_category.status != Category.OPEN:
            raise CategoryNotOpen()

        # Check if a draw already exists (race window after commit).
        if Draw.objects.filter(category=category).exists():
            raise DrawAlreadyExists()

        fingerprint = _compute_fingerprint(entries)

        # Check if there's an existing finalized draw with the same fingerprint
        # (allow regeneration only if something changed).
        existing = Draw.objects.filter(category=category, fingerprint=fingerprint).first()
        if existing and existing.status == Draw.FINALIZED:
            # Return existing draw unchanged.
            return existing

        # Delete any existing draw/slots for this category.
        Draw.objects.filter(category=category).delete()

        # Calculate bracket size (next power of 2 >= num_entries).
        bracket_size = _next_power_of_2(len(entries))
        num_rounds = int(math.log2(bracket_size))

        # Create the draw.
        draw = Draw.objects.create(
            category=category,
            status=Draw.FINALIZED,
            version=1,
            fingerprint=fingerprint,
        )

        # Shuffle entries for random seeding.
        import random
        seeded_entries = list(entries)
        random.seed(fingerprint)  # Deterministic shuffle based on fingerprint.
        random.shuffle(seeded_entries)

        # Create round 1 slots.
        slots_by_position = []
        for position in range(bracket_size):
            if position < len(seeded_entries):
                slot = DrawSlot.objects.create(
                    draw=draw,
                    round_number=1,
                    position=position,
                    entry=seeded_entries[position],
                    is_bye=False,
                )
            else:
                # Bye slot - will be assigned winner automatically.
                slot = DrawSlot.objects.create(
                    draw=draw,
                    round_number=1,
                    position=position,
                    entry=None,
                    is_bye=True,
                )
            slots_by_position.append(slot)

        # Create bye assignments for first round.
        # In a power-of-2 bracket, byes go to the top seeds (first positions).
        bye_count = bracket_size - len(entries)
        for i in range(bye_count):
            slots_by_position[i].entry = seeded_entries[i]
            slots_by_position[i].is_bye = True
            slots_by_position[i].save()

        # Create subsequent rounds.
        for round_num in range(2, num_rounds + 1):
            matches_in_round = bracket_size // (2 ** (round_num - 1))
            for position in range(matches_in_round):
                DrawSlot.objects.create(
                    draw=draw,
                    round_number=round_num,
                    position=position,
                    entry=None,
                    is_bye=False,
                )

        # Now create the Match objects linking slots to bracket structure.
        _create_matches_from_slots(draw, category, num_rounds, bracket_size)

        # Update category status.
        locked_category.status = Category.DRAW_GENERATED
        locked_category.save()

        return draw


def _create_matches_from_slots(draw: Draw, category: Category, num_rounds: int, bracket_size: int):
    """Create Match objects from the draw slots."""
    from matches.models import Match

    # Get all slots for this draw.
    slots = list(DrawSlot.objects.filter(draw=draw).order_by("round_number", "position"))

    # Group by round.
    slots_by_round = {}
    for slot in slots:
        if slot.round_number not in slots_by_round:
            slots_by_round[slot.round_number] = []
        slots_by_round[slot.round_number].append(slot)

    # Create matches for each round except the final.
    for round_num in range(1, num_rounds):
        round_slots = slots_by_round.get(round_num, [])
        next_round_slots = slots_by_round.get(round_num + 1, [])

        for slot_idx, slot in enumerate(round_slots):
            # Calculate which slot in the next round receives the winner.
            next_slot_idx = slot_idx // 2

            # Determine which slot in next round (1 or 2).
            next_match_slot = 1 if slot_idx % 2 == 0 else 2

            match = Match.objects.create(
                tournament=category.tournament,
                category=category,
                draw=draw,
                round_number=round_num,
                slot_position=slot_idx,
                entry1=slot.entry if not slot.is_bye else None,
                entry2=None,
                status=Match.PENDING if not slot.is_bye else Match.BYE,
                next_match=next_round_slots[next_slot_idx].id if next_slot_idx < len(next_round_slots) else None,
                next_match_slot=next_match_slot if next_slot_idx < len(next_round_slots) else None,
            )

            # Update slot with match reference.
            slot.match = match
            slot.save()

    # Create the final match.
    final_round_slots = slots_by_round.get(num_rounds, [])
    if final_round_slots:
        # Final has no next match.
        Match.objects.create(
            tournament=category.tournament,
            category=category,
            draw=draw,
            round_number=num_rounds,
            slot_position=0,
            entry1=None,
            entry2=None,
            status=Match.PENDING,
        )


def get_draw_for_category(category: Category) -> Draw:
    """Get existing draw for a category, raising appropriate errors."""
    try:
        return Draw.objects.get(category=category)
    except Draw.DoesNotExist:
        raise ValidationError("No draw exists for this category.")
