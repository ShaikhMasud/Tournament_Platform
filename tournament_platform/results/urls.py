from django.urls import path

from .views import ResultDownloadView, ResultStatusView, TournamentResultsView

urlpatterns = [
    path(
        "tournaments/<uuid:tournament_pk>/results/pdf/",
        TournamentResultsView.as_view(),
        name="tournament-results",
    ),
    path(
        "results/<uuid:doc_id>/status/",
        ResultStatusView.as_view(),
        name="result-status",
    ),
    path(
        "results/<uuid:doc_id>/download/",
        ResultDownloadView.as_view(),
        name="result-download",
    ),
]
