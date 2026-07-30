from django.contrib import admin

from .models import Draw, DrawSlot


class DrawSlotInline(admin.TabularInline):
    model = DrawSlot
    extra = 0


@admin.register(Draw)
class DrawAdmin(admin.ModelAdmin):
    list_display = ["category", "status", "version", "finalized_at"]
    list_filter = ["status"]
    inlines = [DrawSlotInline]
