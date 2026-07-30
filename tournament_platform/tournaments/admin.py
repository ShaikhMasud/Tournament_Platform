from django.contrib import admin

from .models import Category, Court, Tournament


@admin.register(Tournament)
class TournamentAdmin(admin.ModelAdmin):
    list_display = ["name", "organization", "status", "is_public"]
    list_filter = ["status", "is_public"]
    search_fields = ["name"]


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ["name", "tournament", "draw_format", "capacity", "status"]
    list_filter = ["draw_format", "status"]


@admin.register(Court)
class CourtAdmin(admin.ModelAdmin):
    list_display = ["name", "tournament", "is_active"]
