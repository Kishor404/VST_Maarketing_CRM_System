# crm/admin.py
from django.contrib import admin
from django.http import HttpResponse
from django.utils import timezone
from django.utils.html import format_html
from django.urls import reverse

import csv
import io

from django.conf import settings

from .models import Card, Service, ServiceEntry, Feedback, Attendance, AuditLog, JobCard
from .utils import generate_otp, hash_otp, otp_expiry_time


admin.site.register(Card)
admin.site.register(JobCard)
admin.site.register(Service)
admin.site.register(ServiceEntry)
admin.site.register(Feedback)
admin.site.register(Attendance)
admin.site.register(AuditLog)