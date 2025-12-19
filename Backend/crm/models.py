# crm/models.py
from django.db import models
from django.utils import timezone
from django.core.validators import MinValueValidator
from django.conf import settings

try:
    from django.db.models import JSONField
except ImportError:
    from django.contrib.postgres.fields import JSONField

User = settings.AUTH_USER_MODEL  # "user.User"

REGION_CHOICES = (
    ("rajapalayam", "Rajapalayam"),
    ("ambasamuthiram", "Ambasamuthiram"),
    ("sankarankovil", "Sankarankovil"),
    ("tenkasi", "Tenkasi"),
    ("tirunelveli", "Tirunelveli"),
    ("chennai", "Chennai"),
)

CARD_TYPE = (
    ("normal", "Normal"),
    ("om", "Other Machine"),
)

SERVICE_TYPE = (
    ("normal", "Normal"),
    ("free", "Free"),
)

SERVICE_STATUS = (
    ("pending", "Pending"),
    ("scheduled", "Scheduled"),
    ("assigned", "Assigned"),
    ("in_progress", "In Progress"),
    ("awaiting_otp", "Awaiting OTP"),
    ("completed", "Completed"),
    ("cancelled", "Cancelled"),
)

VISIT_TYPE = (
    ("I","Installation"),
    ("C","Complaint"),
    ("MS","Mandatory Service"),
    ("CS","Contract Service"),
    ("CC","Curtacy Call"),
)


class Card(models.Model):
    REGION_CHOICES = [
        ("rajapalayam", "Rajapalayam"),
        ("ambasamuthiram", "Ambasamuthiram"),
        ("sankarankovil", "Sankarankovil"),
        ("tenkasi", "Tenkasi"),
        ("tirunelveli", "Tirunelveli"),
        ("chennai", "Chennai"),
    ]
    model = models.CharField(max_length=150)
    customer = models.ForeignKey(User, on_delete=models.CASCADE, related_name="cards")
    customer_name = models.CharField(max_length=255)
    card_type = models.CharField(max_length=20, choices=CARD_TYPE, default="normal", db_index=True)
    region = models.CharField(max_length=50, choices=REGION_CHOICES, default="rajapalayam")
    address = models.TextField(blank=True)
    city = models.CharField(max_length=100, blank=True)
    postal_code = models.CharField(max_length=20, blank=True)

    date_of_installation = models.DateField(null=True, blank=True)
    warranty_start_date = models.DateField(null=True, blank=True, db_index=True)
    warranty_end_date = models.DateField(null=True, blank=True, db_index=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Card {self.id} - {self.model} ({self.customer_name})"


class Service(models.Model):
    card = models.ForeignKey(Card, on_delete=models.CASCADE, related_name="services")
    requested_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name="requested_services")
    service_type = models.CharField(max_length=20, choices=SERVICE_TYPE, default="normal", db_index=True)
    status = models.CharField(max_length=20, choices=SERVICE_STATUS, default="pending", db_index=True)
    description = models.TextField(blank=True)

    preferred_date = models.DateField(null=True, blank=True)
    scheduled_at = models.DateField(null=True, blank=True, db_index=True)
    assigned_to = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name="assigned_services")

    is_paid = models.BooleanField(default=False)
    amount_charged = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True, validators=[MinValueValidator(0)])

    otp_hash = models.CharField(max_length=128, blank=True, null=True)
    otp_phone = models.CharField(max_length=128, blank=True, null=True)
    otp_expires_at = models.DateTimeField(null=True, blank=True)

    visit_type = models.CharField(max_length=20, choices=VISIT_TYPE, default="C")
    next_service_date = models.DateField(null=True, blank=True)

    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name="created_services")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["scheduled_at", "created_at"]
        indexes = [
            models.Index(fields=["assigned_to", "status"]),
            models.Index(fields=["card", "status"]),
            models.Index(fields=["scheduled_at"]),
        ]

    def __str__(self):
        return f"Service {self.id} - {self.service_type} - Card {self.card.id}"


class ServiceEntry(models.Model):
    service = models.ForeignKey(Service, on_delete=models.CASCADE, related_name="entries")
    performed_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name="performed_entries")
    actual_complaint = models.TextField(blank=True)
    visit_type = models.CharField(max_length=20, choices=VISIT_TYPE, default="C")
    work_detail = models.TextField()
    parts_replaced = JSONField(blank=True, null=True)
    amount_charged = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Entry {self.id} for Service {self.service.id}"


class Feedback(models.Model):
    service = models.ForeignKey(Service, on_delete=models.CASCADE, related_name="feedbacks")
    card = models.ForeignKey(Card, on_delete=models.CASCADE, related_name="feedbacks")
    customer = models.ForeignKey(User, on_delete=models.CASCADE, related_name="feedbacks")
    rating = models.PositiveSmallIntegerField(default=5)
    comments = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)


class Attendance(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    date = models.DateField()
    status = models.CharField(max_length=20, choices=[("present","Present"),("absent","Absent")], default="present")
    marked_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="attendance_marked_by")
    created_at = models.DateTimeField(auto_now_add=True)
    # unique together user+date
    class Meta:
        unique_together = ("user", "date")




class AuditLog(models.Model):
    from django.conf import settings as _settings  # avoid linter complaining

    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name="audit_logs")
    action = models.CharField(max_length=100)
    object_type = models.CharField(max_length=100)
    object_id = models.CharField(max_length=100)
    payload = JSONField(blank=True, null=True)
    timestamp = models.DateTimeField(auto_now_add=True)
