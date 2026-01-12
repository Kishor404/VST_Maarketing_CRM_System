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
        source='customer'
    )

    class Meta:
        model = AdminReminder
        fields = [
            'id',
            'customer',
            'customer_id',
            'reminder_dates',
            'message',
            'is_active',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def validate_reminder_dates(self, value):
        if not isinstance(value, list) or len(value) == 0:
            raise serializers.ValidationError(
                "reminder_dates must be a non-empty list of ISO datetime strings"
            )
        return value
