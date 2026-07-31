"""
Badminton single-game scoring rules: race to 21, win by 2, cap at 30.
"""

from dataclasses import dataclass
from typing import Optional


@dataclass
class BadmintonSingleGameScore:
    """Represents a badminton single-game score."""

    entry1_points: int = 0
    entry2_points: int = 0

    @property
    def max_score(self) -> int:
        return max(self.entry1_points, self.entry2_points)

    @property
    def min_score(self) -> int:
        return min(self.entry1_points, self.entry2_points)

    def to_dict(self) -> dict:
        return {"entry1_points": self.entry1_points, "entry2_points": self.entry2_points}

    @classmethod
    def from_dict(cls, data: dict) -> "BadmintonSingleGameScore":
        return cls(
            entry1_points=int(data.get("entry1_points", 0)),
            entry2_points=int(data.get("entry2_points", 0)),
        )


class BadmintonSingleGameRules:
    """
    Badminton single-game (1v1) scoring rules.

    - Race to 21 points.
    - Win by at least 2 points.
    - Hard cap at 30 points (if it goes to 30-29, the player at 30 wins).
    """

    TARGET_SCORE = 21
    WIN_BY = 2
    HARD_CAP = 30

    @classmethod
    def is_valid_score(cls, score: BadmintonSingleGameScore) -> bool:
        """Check if a score is within valid bounds."""
        max_pts = score.max_score
        min_pts = score.min_score

        # Both scores must be non-negative.
        if score.entry1_points < 0 or score.entry2_points < 0:
            return False

        # No score can exceed the hard cap.
        if max_pts > cls.HARD_CAP:
            return False

        # If at or above target, must have win-by-2 margin (unless at hard cap).
        if max_pts >= cls.TARGET_SCORE:
            if max_pts == cls.HARD_CAP:
                # At hard cap, 30-29 is valid.
                return min_pts == cls.HARD_CAP - 1
            # Must have win-by-2 margin.
            return max_pts - min_pts >= cls.WIN_BY

        # Below target, any score is valid (up to target - 1).
        return True

    @classmethod
    def get_winner(cls, score: BadmintonSingleGameScore) -> Optional[int]:
        """
        Determine the winner based on the current score.

        Returns:
            1 if entry1 wins,
            2 if entry2 wins,
            None if no winner yet.
        """
        if not cls.is_valid_score(score):
            return None

        max_pts = score.max_score
        min_pts = score.min_score

        # Must be at target or hard cap with proper margin.
        if max_pts < cls.TARGET_SCORE:
            return None

        # Check win-by-2 or hard cap.
        if max_pts == cls.HARD_CAP:
            # 30-29 is a win for the player at 30.
            if min_pts == cls.HARD_CAP - 1:
                return 1 if score.entry1_points > score.entry2_points else 2
            return None

        if max_pts - min_pts >= cls.WIN_BY:
            return 1 if score.entry1_points > score.entry2_points else 2

        return None

    @classmethod
    def can_add_point(cls, score: BadmintonSingleGameScore, to_entry1: bool) -> bool:
        """
        Check if a point can be added to the given entry.
        Returns False if it would create an invalid score state.
        """
        current_max = score.max_score
        if to_entry1:
            new_score = BadmintonSingleGameScore(
                score.entry1_points + 1, score.entry2_points
            )
        else:
            new_score = BadmintonSingleGameScore(
                score.entry1_points, score.entry2_points + 1
            )

        # If we're already at max with win-by-2, can't add more.
        if current_max >= cls.TARGET_SCORE:
            if current_max >= cls.HARD_CAP:
                return False  # Can't exceed hard cap.
            # If already have win-by-2, can't add to loser.
            if score.max_score - score.min_score >= cls.WIN_BY:
                return False

        return True

    @classmethod
    def validate_score_transition(
        cls, old_score: BadmintonSingleGameScore, new_score: BadmintonSingleGameScore
    ) -> bool:
        """
        Validate that a score transition is legal.

        Legal transitions:
        - Entry1 or Entry2 gains a single point.
        - No score decreases.
        - The new score must be valid.
        """
        # Can't decrease scores.
        if (
            new_score.entry1_points < old_score.entry1_points
            or new_score.entry2_points < old_score.entry2_points
        ):
            return False

        # Can only change by 1 point.
        total_change = (
            (new_score.entry1_points - old_score.entry1_points)
            + (new_score.entry2_points - old_score.entry2_points)
        )
        if total_change != 1:
            return False

        # New score must be valid.
        return cls.is_valid_score(new_score)
