from rest_framework import serializers
from user.serializers import UserSerializer
from user.models import User
from .models import AdminReminder


class AdminReminderSerializer(serializers.ModelSerializer):

    customer = UserSerializer(read_only=True)

    customer_id = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.filter(role="customer"),
        write_only=True,
        source="customer",
        required=False,
        allow_null=True
    )

    name = serializers.CharField(
        required=False,
        allow_null=True,
        allow_blank=True
    )

    phone = serializers.CharField(
        required=False,
        allow_null=True,
        allow_blank=True
    )

    class Meta:
        model = AdminReminder

        fields = [
            "id",
            "customer",
            "customer_id",
            "name",
            "phone",
            "reminder_dates",
            "message",
            "is_active",
            "created_at",
            "updated_at",
        ]

        read_only_fields = [
            "id",
            "created_at",
            "updated_at",
        ]

    def validate(self, data):
        request = self.context.get("request")

        customer = data.get("customer")
        name = data.get("name")
        phone = data.get("phone")

        # ==========================================
        # MODE 1: EXISTING CUSTOMER
        # ==========================================
        if customer:

            if request and request.user.role == "admin":

                if customer.region != request.user.region:
                    raise serializers.ValidationError({
                        "customer_id": (
                            "Customer belongs to another region."
                        )
                    })

            return data

        # ==========================================
        # MODE 2: NEW / EXTERNAL CONTACT
        # ==========================================
        if not name or not phone:
            raise serializers.ValidationError(
                "Either customer OR both name and phone must be provided."
            )

        # IMPORTANT:
        # We deliberately do NOT create a User here.

        return data

    def validate_reminder_dates(self, value):

        if not isinstance(value, list) or len(value) == 0:
            raise serializers.ValidationError(
                "reminder_dates must be a non-empty list of ISO datetime strings"
            )

        return value