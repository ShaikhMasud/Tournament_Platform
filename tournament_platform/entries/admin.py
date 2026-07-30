from django.contrib import admin

from .models import Entry


@admin.register(Entry)
class EntryAdmin(admin.ModelAdmin):
    list_display = ["player", "category", "status", "created_at"]
    list_filter = ["status"]
    search_fields = ["player__display_name"]
