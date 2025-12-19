# user/models.py
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models
from django.utils import timezone

class UserManager(BaseUserManager):
    def normalize_phone(self, phone: str) -> str:
        p = str(phone).strip()
        p = p.lstrip("0")
        if not p.startswith("+"):
            p = "+91" + p  # adjust default country if needed
        return p

    def create_user(self, phone, password=None, **extra_fields):
        if not phone:
            raise ValueError("The phone number must be set")
        phone = self.normalize_phone(phone)
        user = self.model(phone=phone, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, phone, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        return self.create_user(phone, password, **extra_fields)

class User(AbstractBaseUser, PermissionsMixin):
    ROLE_CHOICES = [
        ("customer", "Customer"),
        ("worker", "Worker"),
        ("admin", "Admin"),
    ]
    REGION_CHOICES = [
        ("rajapalayam", "Rajapalayam"),
        ("ambasamuthiram", "Ambasamuthiram"),
        ("sankarankovil", "Sankarankovil"),
        ("tenkasi", "Tenkasi"),
        ("tirunelveli", "Tirunelveli"),
        ("chennai", "Chennai"),
    ]

    name = models.CharField(max_length=150)
    phone = models.CharField(max_length=20, unique=True)
    address = models.TextField(blank=True, null=True)
    city = models.CharField(max_length=120, blank=True, null=True)
    postal_code = models.CharField(max_length=20, blank=True, null=True)
    region = models.CharField(max_length=50, choices=REGION_CHOICES, default="rajapalayam")
    role = models.CharField(max_length=10, choices=ROLE_CHOICES, default="customer")
    fcm_token = models.CharField(max_length=255, blank=True, null=True)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    is_available = models.BooleanField(default=True)  # worker availability
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    USERNAME_FIELD = "phone"
    REQUIRED_FIELDS = ["name"]

    objects = UserManager()

    def __str__(self):
        return f"{self.name} ({self.role})"
