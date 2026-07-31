from django.db import transaction
from rest_framework.exceptions import APIException, ValidationError

from .models import Entry


class DuplicateEntry(ValidationError):
    default_detail = "This player already has an active entry in this category."
    default_code = "duplicate_entry"


class CategoryFull(ValidationError):
    default_detail = "This category is already at capacity."
    default_code = "category_full"


class CategoryLocked(ValidationError):
    default_detail = "This category is not open for entries right now."
    default_code = "category_locked"


class DrawAlreadyFinalized(APIException):
    status_code = 409
    default_detail = "Entries can't be removed after the draw has been finalized."
    default_code = "draw_finalized"


def add_entry(*, category, player, actor) -> Entry:
    """
    Adds one confirmed entry for `player` in `category`.

    Everything happens inside one transaction with the Category row
    locked, so two near-simultaneous add requests can't both slip past
    the capacity check and overshoot it, and can't both create a
    duplicate entry for the same player in a race.
    """
    with transaction.atomic():
        locked_category = category.__class__.objects.select_for_update().get(
            pk=category.pk
        )

        if locked_category.status != locked_category.Status.OPEN:
            raise CategoryLocked()

        active_qs = Entry.objects.filter(
            category=locked_category, status=Entry.Status.CONFIRMED
        )

        if active_qs.filter(player=player).exists():
            raise DuplicateEntry()

        if active_qs.count() >= locked_category.capacity:
            raise CategoryFull()

        entry = Entry.objects.create(
            category=locked_category,
            player=player,
            status=Entry.Status.CONFIRMED,
            created_by=actor,
        )
        return entry


def remove_entry(*, entry: Entry, actor) -> None:
    """
    Removes an entry, unless the category's draw has already been
    finalized — once a draw exists, the entry list must stay stable so
    bracket slots stay meaningful.
    """
    category = entry.category
    if category.status != category.Status.OPEN:
        raise DrawAlreadyFinalized()

    with transaction.atomic():
        locked_category = category.__class__.objects.select_for_update().get(
            pk=category.pk
        )
        if locked_category.status != locked_category.Status.OPEN:
            raise DrawAlreadyFinalized()
        entry.delete()
