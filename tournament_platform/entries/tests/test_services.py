"""
Tests for entries services.
"""
from unittest.mock import MagicMock, patch

from django.test import TestCase

from entries.services import (
    DuplicateEntry,
    CategoryFull,
    CategoryLocked,
    DrawAlreadyFinalized,
)


class EntryServiceExceptionsTests(TestCase):
    """Tests for entry service exception classes."""

    def test_duplicate_entry_has_default_detail(self):
        """DuplicateEntry should have a default detail message."""
        exc = DuplicateEntry()
        self.assertIn("already has an active entry", str(exc.detail))

    def test_duplicate_entry_has_code(self):
        """DuplicateEntry should have a default code."""
        exc = DuplicateEntry()
        self.assertEqual(exc.default_code, "duplicate_entry")

    def test_category_full_has_default_detail(self):
        """CategoryFull should have a default detail message."""
        exc = CategoryFull()
        self.assertIn("capacity", str(exc.detail).lower())

    def test_category_locked_has_default_detail(self):
        """CategoryLocked should have a default detail message."""
        exc = CategoryLocked()
        self.assertIn("not open", str(exc.detail).lower())

    def test_draw_already_finalized_has_409_status(self):
        """DrawAlreadyFinalized should return 409 status."""
        exc = DrawAlreadyFinalized()
        self.assertEqual(exc.status_code, 409)
