from rest_framework import mixins, viewsets
from rest_framework.permissions import IsAuthenticated

from .models import Organization
from .serializers import OrganizationSerializer


class OrganizationViewSet(
    mixins.ListModelMixin,
    mixins.CreateModelMixin,
    mixins.RetrieveModelMixin,
    viewsets.GenericViewSet,
):
    """
    GET  /api/organizations/       -> list the caller's own organizations
    POST /api/organizations/       -> create an org owned by the caller
    GET  /api/organizations/{id}/  -> retrieve one of the caller's own orgs

    No update/delete in Phase 1 per the plan (not listed as an endpoint) —
    add UpdateModelMixin/DestroyModelMixin later if the spec asks for it.
    """

    serializer_class = OrganizationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        # Always filtered to owner=request.user — never return another
        # user's orgs even if they guess an id.
        return Organization.objects.filter(owner=self.request.user).order_by(
            "-created_at"
        )

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)
