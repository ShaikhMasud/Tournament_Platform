from rest_framework import serializers

from .models import ResultDocument


class ResultDocumentSerializer(serializers.ModelSerializer):
    """Serializer for result document metadata."""

    download_url = serializers.SerializerMethodField()
    tournament_name = serializers.CharField(source="tournament.name", read_only=True)

    class Meta:
        model = ResultDocument
        fields = [
            "id",
            "tournament",
            "tournament_name",
            "fingerprint",
            "status",
            "download_url",
            "error_message",
            "created_at",
            "updated_at",
        ]
        read_only_fields = fields

    def get_download_url(self, obj):
        if obj.status != ResultDocument.READY:
            return None
        request = self.context.get("request")
        if request:
            return request.build_absolute_uri(f"/api/results/{obj.id}/download/")
        return None


class RequestResultsSerializer(serializers.Serializer):
    """Empty serializer for POST /tournaments/{id}/results/pdf/."""

    pass
