from django.contrib import admin

from .models import (
    Category, Court, DashboardStats, Document, DocumentSignature,
    Notification, Official, Registration, Sport, Team, TeamPlayer, Tournament,
    TournamentSettings, Venue,
)


@admin.register(Tournament)
class TournamentAdmin(admin.ModelAdmin):
    list_display = ["name", "organization", "status", "is_public", "start_date", "end_date"]
    list_filter = ["status", "is_public", "sport"]
    search_fields = ["name", "city", "organization__name"]
    readonly_fields = ["created_at", "updated_at"]


@admin.register(Sport)
class SportAdmin(admin.ModelAdmin):
    list_display = ["name", "category", "team_size", "match_type", "is_active"]
    list_filter = ["category", "is_active"]
    search_fields = ["name"]


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ["name", "tournament", "draw_format", "capacity", "status", "entry_fee"]
    list_filter = ["draw_format", "status", "gender"]
    search_fields = ["name", "tournament__name"]


@admin.register(Court)
class CourtAdmin(admin.ModelAdmin):
    list_display = ["name", "tournament", "court_number", "surface", "is_active", "is_available"]
    list_filter = ["surface", "is_active", "is_available"]


@admin.register(Venue)
class VenueAdmin(admin.ModelAdmin):
    list_display = ["name", "tournament", "city", "state", "country", "is_active"]
    list_filter = ["is_active", "is_indoor", "country"]
    search_fields = ["name", "city"]


@admin.register(Team)
class TeamAdmin(admin.ModelAdmin):
    list_display = ["name", "tournament", "status", "wins", "losses", "draws"]
    list_filter = ["status"]
    search_fields = ["name", "tournament__name"]


@admin.register(Registration)
class RegistrationAdmin(admin.ModelAdmin):
    list_display = ["player_profile", "tournament", "category", "status", "is_paid", "registered_at"]
    list_filter = ["status", "is_paid", "tournament"]
    search_fields = ["player_profile__display_name", "tournament__name"]


@admin.register(Official)
class OfficialAdmin(admin.ModelAdmin):
    list_display = ["user", "tournament", "name", "official_type", "status"]
    list_filter = ["official_type", "status"]


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ["title", "user", "tournament", "notification_type", "priority", "status"]
    list_filter = ["notification_type", "priority", "status"]


@admin.register(Document)
class DocumentAdmin(admin.ModelAdmin):
    list_display = ["title", "tournament", "document_type", "is_public", "requires_signature"]
    list_filter = ["document_type", "is_public", "requires_signature"]


@admin.register(DashboardStats)
class DashboardStatsAdmin(admin.ModelAdmin):
    list_display = ["tournament", "total_registrations", "total_matches", "computed_at"]
    readonly_fields = ["computed_at"]


@admin.register(TournamentSettings)
class TournamentSettingsAdmin(admin.ModelAdmin):
    list_display = ["tournament", "best_of_sets", "enable_tie_break"]


# DocumentSignature doesn't need custom admin - it's managed through Document
