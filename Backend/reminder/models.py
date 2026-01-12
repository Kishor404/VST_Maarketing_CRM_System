# reminders/models.py

from django.db import models

class AdminReminder(models.Model):
    customer = models.ForeignKey(
        'user.User',
        on_delete=models.CASCADE,
        related_name='admin_reminders'
    )
    reminder_dates = models.JSONField()
    triggered_dates = models.JSONField(default=list)
    message = models.TextField()
    is_active = models.BooleanField(default=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Admin reminder for {self.customer}"
