import django_filters

from .models import Match


class MatchFilter(django_filters.FilterSet):
    status = django_filters.ChoiceFilter(choices=Match.STATUS_CHOICES)
    round_number = django_filters.NumberFilter()
    category = django_filters.UUIDFilter()

    class Meta:
        model = Match
        fields = ["status", "round_number", "category"]
