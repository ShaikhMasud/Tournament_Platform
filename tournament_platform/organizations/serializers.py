from rest_framework import serializers

from .models import Organization


class OrganizationSerializer(serializers.ModelSerializer):
    """
    Read: id, name, owner (nested minimal info).
    Write: name only — owner is stamped from request.user in the view,
    never accepted from the client, so no one can create an org "owned"
    by someone else.
    """

    owner = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = Organization
        fields = ["id", "name", "owner", "created_at"]
        read_only_fields = ["id", "owner", "created_at"]

    def get_owner(self, obj):
        return {
            "id": obj.owner_id,
            "display_name": getattr(obj.owner, "get_full_name", lambda: None)()
            or getattr(obj.owner, "email", None)
            or str(obj.owner),
        }

    def create(self, validated_data):
        # Defensive: even if 'owner' somehow ends up in validated_data
        # (it shouldn't, since the field is read-only above), strip it.
        validated_data.pop("owner", None)
        request = self.context["request"]
        return Organization.objects.create(owner=request.user, **validated_data)
