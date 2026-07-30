from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as DjangoUserAdmin

from .models import AssistantCapability, PlayerProfile, TournamentRole, User


@admin.register(User)
class UserAdmin(DjangoUserAdmin):
    ordering = ["email"]
    list_display = ["email", "username", "is_staff", "is_active"]


@admin.register(PlayerProfile)
class PlayerProfileAdmin(admin.ModelAdmin):
    list_display = ["display_name", "user"]
    search_fields = ["display_name", "user__email"]


@admin.register(TournamentRole)
class TournamentRoleAdmin(admin.ModelAdmin):
    list_display = ["user", "tournament", "role", "is_active", "granted_at"]
    list_filter = ["role", "is_active"]


@admin.register(AssistantCapability)
class AssistantCapabilityAdmin(admin.ModelAdmin):
    list_display = ["tournament_role", "capability", "is_active"]
    list_filter = ["capability", "is_active"]
