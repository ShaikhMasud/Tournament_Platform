from django.http import FileResponse, Http404
from django.shortcuts import get_object_or_404
from rest_framework import generics, status
from rest_framework.permissions import BasePermission, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.models import TournamentRole
from tournaments.models import Tournament

from .models import ResultDocument
from .serializers import RequestResultsSerializer, ResultDocumentSerializer
from .services import get_or_create_result_document


class _HasTournamentAccess(BasePermission):
    """Check user has any role on the tournament (organizer or assistant)."""

    def has_permission(self, request, view):
        tournament_pk = view.kwargs.get("tournament_pk")
        if not tournament_pk:
            return False
        return TournamentRole.objects.filter(
            tournament_id=tournament_pk,
            user=request.user,
            is_active=True,
        ).exists()


class _HasDocumentAccess(BasePermission):
    """Check user has access to the result document's tournament."""

    def has_permission(self, request, view):
        doc_id = view.kwargs.get("doc_id")
        if not doc_id:
            return False
        try:
            doc = ResultDocument.objects.get(pk=doc_id)
            return TournamentRole.objects.filter(
                tournament=doc.tournament,
                user=request.user,
                is_active=True,
            ).exists()
        except ResultDocument.DoesNotExist:
            return False


class TournamentResultsView(APIView):
    """
    POST /api/tournaments/{id}/results/pdf/ — request/reuse a results PDF.

    Returns immediately with a document in PENDING, GENERATING, or READY state.
    Clients should poll /api/results/{id}/status/ to check readiness.
    """

    permission_classes = [IsAuthenticated, _HasTournamentAccess]

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
    permission_classes = [IsAuthenticated, _HasDocumentAccess]
    queryset = ResultDocument.objects.all()


class ResultDownloadView(APIView):
    """GET /api/results/{id}/download/ — stream the PDF file."""

    permission_classes = [IsAuthenticated, _HasDocumentAccess]

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
