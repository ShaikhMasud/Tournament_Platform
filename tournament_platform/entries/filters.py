import django_filters

from .models import Entry


class EntryFilter(django_filters.FilterSet):
    status = django_filters.ChoiceFilter(choices=Entry.Status.choices)
    search = django_filters.CharFilter(method="filter_search")

    class Meta:
        model = Entry
        fields = ["status"]

    def filter_search(self, queryset, name, value):
        # Matches against the player's display name / underlying user
        # name fields — adjust the lookup paths to whatever PlayerProfile
        # actually exposes (display_name vs user__first_name, etc.).
        return queryset.filter(
            player__display_name__icontains=value
        ) | queryset.filter(
            player__user__first_name__icontains=value
        ) | queryset.filter(
            player__user__last_name__icontains=value
        )
