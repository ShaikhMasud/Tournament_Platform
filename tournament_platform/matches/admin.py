from django.contrib import admin

from .models import Match


@admin.register(Match)
class MatchAdmin(admin.ModelAdmin):
    list_display = [
        "id", "category", "round_number", "slot_position", "entry1", "entry2",
        "status", "court", "scheduled_start", "version",
    ]
    list_filter = ["status", "category", "round_number"]
    search_fields = ["entry1__player__display_name", "entry2__player__display_name"]
    readonly_fields = ["created_at", "updated_at"]
