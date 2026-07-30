from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/auth/", include("accounts.urls")),
    path("api/", include("organizations.urls")),
    path("api/", include("tournaments.urls")),
    # As you build each phase, wire these in:
    # path("api/", include("entries.urls")),
    # path("api/", include("draws.urls")),
    # path("api/", include("matches.urls")),
]
