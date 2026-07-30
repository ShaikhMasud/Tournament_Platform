from django.contrib import admin

from .models import Match


@admin.register(Match)
class MatchAdmin(admin.ModelAdmin):
    list_display = [
        "category", "round_number", "slot_position", "entry1", "entry2",
        "status", "court", "scheduled_start", "version",
    ]
    list_filter = ["status", "category"]
