"""
Tests for core permissions.
"""
from unittest.mock import MagicMock, patch

from django.test import TestCase

from core.permissions import (
    IsOrganizerOfTournament,
    organizer_or_capability,
)


class OrganizerOrCapabilityPermissionTests(TestCase):
    """Tests for organizer_or_capability permission class."""

    def test_returns_true_for_organizer(self):
        """Organizers should always have access."""
        mock_perm = organizer_or_capability("entry_management")

        mock_request = MagicMock()
        mock_request.user.is_authenticated = True
        mock_request.user.has_perm = MagicMock(return_value=False)

        # Mock a view with tournament lookup
        mock_view = MagicMock()
        mock_view.kwargs = {"tournament_pk": "123"}

        with patch("core.permissions.get_tournament_role") as mock_get_role:
            mock_get_role.return_value = MagicMock(role="organizer")
            result = mock_perm.has_permission(mock_request, mock_view)
            self.assertTrue(result)

    def test_returns_true_for_assistant_with_capability(self):
        """Assistants with the required capability should have access."""
        mock_perm = organizer_or_capability("entry_management")

        mock_request = MagicMock()
        mock_request.user.is_authenticated = True

        mock_view = MagicMock()
        mock_view.kwargs = {"tournament_pk": "123"}

        with patch("core.permissions.get_tournament_role") as mock_get_role:
            mock_role = MagicMock(role="assistant")
            mock_cap = MagicMock()
            mock_cap.capability = "entry_management"
            mock_cap.is_active = True
            mock_role.capabilities.filter.return_value.exists.return_value = True
            mock_role.capabilities.filter.return_value.first.return_value = mock_cap
            mock_get_role.return_value = mock_role

            result = mock_perm.has_permission(mock_request, mock_view)
            self.assertTrue(result)

    def test_returns_false_for_unauthenticated(self):
        """Unauthenticated users should be denied."""
        mock_perm = organizer_or_capability("entry_management")

        mock_request = MagicMock()
        mock_request.user.is_authenticated = False

        mock_view = MagicMock()
        result = mock_perm.has_permission(mock_request, mock_view)
        self.assertFalse(result)


class IsOrganizerOfTournamentTests(TestCase):
    """Tests for IsOrganizerOfTournament permission class."""

    def test_allows_organizer_access(self):
        """Organizers should be allowed."""
        mock_perm = IsOrganizerOfTournament()

        mock_request = MagicMock()
        mock_request.user.is_authenticated = True

        mock_view = MagicMock()
        mock_view.get_tournament = MagicMock(return_value=None)  # create action

        result = mock_perm.has_permission(mock_request, mock_view)
        self.assertTrue(result)

    def test_denies_unauthenticated(self):
        """Unauthenticated users should be denied."""
        mock_perm = IsOrganizerOfTournament()

        mock_request = MagicMock()
        mock_request.user.is_authenticated = False

        mock_view = MagicMock()

        result = mock_perm.has_permission(mock_request, mock_view)
        self.assertFalse(result)
