from django.urls import path

from .views import EntryCreateView, EntryDeleteView, EntryListView

# Mounted from config/urls.py, e.g.:
#   path("api/", include("entries.urls"))
urlpatterns = [
    path(
        "categories/<int:category_pk>/entries/",
        EntryListView.as_view(),
        name="entry-list",
    ),
    path(
        "categories/<int:category_pk>/entries/create/",
        EntryCreateView.as_view(),
        name="entry-create",
    ),
    path("entries/<int:pk>/", EntryDeleteView.as_view(), name="entry-delete"),
]

# NOTE on the create route: the plan's endpoint table lists a single
# "POST /api/categories/{id}/entries/" (same path as the GET list). If you
# want that exact shape instead of the separate /create/ suffix above,
# collapse EntryListView and EntryCreateView into one APIView with both
# get() and post() methods, or use a ListCreateAPIView subclass that
# overrides perform_create to call entries/services.py's add_entry(). The
# two-view split here is functionally identical, just a different URL.
