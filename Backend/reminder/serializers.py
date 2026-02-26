# reminders/serializers.py

from rest_framework import serializers
from user.serializers import UserSerializer
from user.models import User
from .models import AdminReminder


class AdminReminderSerializer(serializers.ModelSerializer):

    customer = UserSerializer(read_only=True)

    customer_id = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.all(),
        write_only=True,
        source='customer',
        required=False,
        allow_null=True
    )

    name = serializers.CharField(required=False, allow_null=True, allow_blank=True)
    phone = serializers.CharField(required=False, allow_null=True, allow_blank=True)

    class Meta:
        model = AdminReminder
        fields = [
            'id',
            'customer',
            'customer_id',
            'name',
            'phone',
            'reminder_dates',
            'message',
            'is_active',
            'created_at',
            'updated_at',
        ]

        read_only_fields = ['id', 'created_at', 'updated_at']

    def validate(self, data):

        customer = data.get("customer")
        name = data.get("name")
        phone = data.get("phone")

        if not customer and not (name and phone):
            raise serializers.ValidationError(
                "Either customer OR both name and phone must be provided."
            )

        return data


    def validate_reminder_dates(self, value):

        if not isinstance(value, list) or len(value) == 0:
            raise serializers.ValidationError(
                "reminder_dates must be a non-empty list of ISO datetime strings"
            )

        return value