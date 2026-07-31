from django.shortcuts import get_object_or_404
from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from core.permissions import organizer_or_capability
from tournaments.models import Category

from .models import Draw
from .serializers import DrawGenerateSerializer, DrawSerializer
from .services import generate_knockout_draw, get_draw_for_category


class DrawGenerateView(APIView):
    """POST /api/categories/{id}/draw/generate/ — generate knockout draw."""

    permission_classes = [IsAuthenticated, organizer_or_capability("entry_management")]

    def post(self, request, category_pk):
        category = get_object_or_404(Category, pk=category_pk)

        draw = generate_knockout_draw(category=category)
        return Response(
            DrawSerializer(draw).data,
            status=status.HTTP_201_CREATED,
        )


class DrawDetailView(generics.RetrieveAPIView):
    """GET /api/categories/{id}/draw/ — retrieve draw with slots."""

    serializer_class = DrawSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        category_pk = self.kwargs["category_pk"]
        category = get_object_or_404(Category, pk=category_pk)
        return get_draw_for_category(category)

