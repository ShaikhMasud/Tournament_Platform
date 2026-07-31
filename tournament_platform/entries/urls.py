from django.urls import path

from .views import EntryCreateView, EntryDeleteView, EntryListView

# Mounted from config/urls.py, e.g.:
#   path("api/", include("entries.urls"))
urlpatterns = [
    path(
        "categories/<uuid:category_pk>/entries/",
        EntryListView.as_view(),
        name="entry-list",
    ),
    path(
        "categories/<uuid:category_pk>/entries/",
        EntryCreateView.as_view(),
        name="entry-create",
    ),
    path("entries/<uuid:pk>/", EntryDeleteView.as_view(), name="entry-delete"),
]
