# reminders/models.py

from django.db import models

class AdminReminder(models.Model):

    customer = models.ForeignKey(
        'user.User',
        on_delete=models.CASCADE,
        related_name='admin_reminders',
        null=True,
        blank=True
    )

    # NEW optional fields
    name = models.CharField(max_length=255, null=True, blank=True)
    phone = models.CharField(max_length=20, null=True, blank=True)

    reminder_dates = models.JSONField()
    triggered_dates = models.JSONField(default=list)

    message = models.TextField()
    is_active = models.BooleanField(default=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def get_contact_name(self):
        """
        Priority:
        1. name field
        2. customer.name
        """
        if self.name:
            return self.name
        if self.customer:
            return self.customer.name
        return "Unknown"

    def get_contact_phone(self):
        """
        Priority:
        1. phone field
        2. customer.phone
        """
        if self.phone:
            return self.phone
        if self.customer:
            return self.customer.phone
        return None

    def __str__(self):
        return f"Admin reminder for {self.get_contact_name()}"