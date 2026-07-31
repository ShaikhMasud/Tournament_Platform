from django.contrib import admin

from .models import ResultDocument


@admin.register(ResultDocument)
class ResultDocumentAdmin(admin.ModelAdmin):
    list_display = ["id", "tournament", "status", "created_at"]
    list_filter = ["status"]
    readonly_fields = ["created_at", "pdf_file"]

