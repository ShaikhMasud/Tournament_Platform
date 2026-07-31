from django.urls import path

from .views import DrawDetailView, DrawGenerateView

urlpatterns = [
    path(
        "categories/<uuid:category_pk>/draw/generate/",
        DrawGenerateView.as_view(),
        name="draw-generate",
    ),
    path(
        "categories/<uuid:category_pk>/draw/",
        DrawDetailView.as_view(),
        name="draw-detail",
    ),
]
