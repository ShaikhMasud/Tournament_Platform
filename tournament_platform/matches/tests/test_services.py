"""
Tests for matches services.
"""
from django.test import TestCase

from matches.services import (
    SchedulingConflict,
    InvalidMatchState,
    StaleVersion,
    MatchNotLive,
    _determine_winner,
)


class SchedulingConflictExceptionTests(TestCase):
    """Tests for SchedulingConflict exception."""

    def test_has_409_status(self):
        """SchedulingConflict should return 409 status."""
        exc = SchedulingConflict()
        self.assertEqual(exc.status_code, 409)

    def test_has_default_detail(self):
        """SchedulingConflict should have a default detail."""
        exc = SchedulingConflict()
        self.assertIn("booked", str(exc.detail).lower())


class InvalidMatchStateExceptionTests(TestCase):
    """Tests for InvalidMatchState exception."""

    def test_has_400_status(self):
        """InvalidMatchState should return 400 status."""
        exc = InvalidMatchState()
        self.assertEqual(exc.status_code, 400)


class StaleVersionExceptionTests(TestCase):
    """Tests for StaleVersion exception."""

    def test_has_409_status(self):
        """StaleVersion should return 409 status."""
        exc = StaleVersion()
        self.assertEqual(exc.status_code, 409)

    def test_mentions_refresh(self):
        """StaleVersion detail should mention refreshing."""
        exc = StaleVersion()
        self.assertIn("refresh", str(exc.detail).lower())


class MatchNotLiveExceptionTests(TestCase):
    """Tests for MatchNotLive exception."""

    def test_has_400_status(self):
        """MatchNotLive should return 400 status."""
        exc = MatchNotLive()
        self.assertEqual(exc.status_code, 400)


class DetermineWinnerTests(TestCase):
    """Tests for the _determine_winner function."""

    def test_entry1_wins_at_21_19(self):
        """Entry 1 wins when they reach 21 and opponent is at 19."""
        result = _determine_winner(21, 19)
        self.assertEqual(result, 1)

    def test_entry2_wins_at_15_21(self):
        """Entry 2 wins when they reach 21 and opponent is at 15."""
        result = _determine_winner(15, 21)
        self.assertEqual(result, 2)

    def test_no_winner_at_18_19(self):
        """No winner when neither has reached winning threshold."""
        result = _determine_winner(18, 19)
        self.assertIsNone(result)

    def test_no_winner_at_20_20(self):
        """No winner when scores are tied at deuce."""
        result = _determine_winner(20, 20)
        self.assertIsNone(result)

    def test_entry1_wins_at_deuce_22_20(self):
        """Entry 1 wins at 22-20 (win by 2)."""
        result = _determine_winner(22, 20)
        self.assertEqual(result, 1)

    def test_hard_cap_30_29(self):
        """30-29 is a win for the player with 30."""
        result = _determine_winner(30, 29)
        self.assertEqual(result, 1)

    def test_no_winner_above_30(self):
        """Scores above 30 are invalid."""
        result = _determine_winner(31, 29)
        self.assertIsNone(result)
