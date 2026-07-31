from django.http import FileResponse, Http404
from django.shortcuts import get_object_or_404
from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from core.permissions import organizer_or_capability
from tournaments.models import Tournament

from .models import ResultDocument
from .serializers import RequestResultsSerializer, ResultDocumentSerializer
from .services import get_or_create_result_document


class TournamentResultsView(APIView):
    """
    POST /api/tournaments/{id}/results/pdf/ — request/reuse a results PDF.

    Returns immediately with a document in PENDING, GENERATING, or READY state.
    Clients should poll /api/results/{id}/status/ to check readiness.
    """

    permission_classes = [IsAuthenticated]

    def post(self, request, tournament_pk):
        tournament = get_object_or_404(Tournament, pk=tournament_pk)
        document, created = get_or_create_result_document(tournament)
        return Response(
            ResultDocumentSerializer(document, context={"request": request}).data,
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )


class ResultStatusView(generics.RetrieveAPIView):
    """GET /api/results/{id}/status/ — check document generation status."""

    serializer_class = ResultDocumentSerializer
    permission_classes = [IsAuthenticated]
    queryset = ResultDocument.objects.all()


class ResultDownloadView(APIView):
    """GET /api/results/{id}/download/ — stream the PDF file."""

    permission_classes = [IsAuthenticated]

    def get(self, request, doc_id):
        document = get_object_or_404(ResultDocument, pk=doc_id)

        if document.status != ResultDocument.READY:
            return Response(
                {"detail": "Document is not ready for download."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if not document.pdf_file:
            return Response(
                {"detail": "PDF file not found."},
                status=status.HTTP_404_NOT_FOUND,
            )

        try:
            response = FileResponse(
                document.pdf_file.open("rb"),
                content_type="application/pdf",
            )
            filename = f"results_{document.tournament.name}_{document.id}.pdf"
            response["Content-Disposition"] = f'attachment; filename="{filename}"'
            return response
        except FileNotFoundError:
            raise Http404("PDF file not found.")
