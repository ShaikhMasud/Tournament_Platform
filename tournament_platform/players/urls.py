from django.urls import path

from .views import PlayerTournamentsView, PlayerEntriesView, PlayerEntryDetailView

urlpatterns = [
    path('tournaments/', PlayerTournamentsView.as_view(), name='player-tournaments'),
    path('entries/', PlayerEntriesView.as_view(), name='player-entries'),
    path('entries/<str:entry_id>/', PlayerEntryDetailView.as_view(), name='player-entry-detail'),
]
