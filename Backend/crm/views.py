# crm/views.py
from datetime import datetime
import csv
from io import StringIO

from django.conf import settings
from django.db.models import Value
from django.db.models.functions import Coalesce
from django.http import HttpResponse
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework.exceptions import PermissionDenied

from rest_framework import viewsets, status, generics
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db import models

from user.models import User  # your custom user model

from .models import Card, Service, ServiceEntry, Feedback, Attendance, JobCard, IndustrialAMC
from .serializers import (
    CardSerializer,
    CardCreateSerializer,
    ServiceSerializer,
    ServiceCreateSerializer,
    ServiceAdminCreateSerializer,
    ServiceEntrySerializer,
    FeedbackSerializer,
    AttendanceSerializer,
    JobCardSerializer,
    IndustrialAMCSerializer,
    # assume User serializer exists if needed (e.g., UserSerializer)
)
from .permissions import IsAdmin, IsStaff, IsCustomer
from .utils import generate_otp, hash_otp, otp_expiry_time, verify_otp_hash, parse_iso_datetime

# ---------- Cards ----------
from django.db.models import Q
from rest_framework import viewsets, filters
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend

from .models import Card
from .serializers import CardSerializer, CardCreateSerializer


class CardViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    queryset = Card.objects.select_related("customer").all()

    # 🔍 filtering / searching / sorting
    filter_backends = [
        DjangoFilterBackend,
        filters.SearchFilter,
        filters.OrderingFilter,
    ]

    # allow ?customer=123
    filterset_fields = ["customer"]

    # allow ?search=
    search_fields = [
        "customer__name",
        "customer__phone",
        "model",
    ]

    # allow ?ordering=
    ordering_fields = [
        "id",
        "date_of_installation",
        "warranty_start_date",
        "warranty_end_date",
        "amc_start_date",
        "amc_end_date",
    ]

    ordering = ["-id"]  # default latest first

    def get_serializer_class(self):
        if self.action == "create":
            return CardCreateSerializer
        return CardSerializer

    def get_queryset(self):
        user = self.request.user
        qs = super().get_queryset()

        # 👤 CUSTOMER → only own cards
        if user.role == "customer":
            return qs.filter(customer=user)

        # 👷 STAFF / WORKER → region OR assigned services
        if user.role in ("worker", "staff"):
            return qs.filter(
                Q(region=user.region) |
                Q(services__assigned_to=user)
            ).distinct()

        # 👑 ADMIN → full access + optional filters
        if user.role == "admin":
            phone = self.request.query_params.get("phone")
            if phone:
                qs = qs.filter(customer__phone__icontains=phone)

            customer_id = self.request.query_params.get("customer")
            if customer_id:
                qs = qs.filter(customer_id=customer_id)

            return qs

        return qs.none()


    def perform_create(self, serializer):
        user = self.request.user
        allow_customer_create = getattr(settings, "CRM_ALLOW_CUSTOMER_CARD_CREATE", False)

        # Admins can create any card
        if user.role == "admin":
            serializer.save()
            return

        # If customers can create their own card, ensure they are creating for themselves
        if allow_customer_create and user.role == "customer":
            # Force customer field to the current user (ignore any client-submitted customer id)
            serializer.save(customer=user, customer_name=serializer.validated_data.get("customer_name", user.name))
            return

        # otherwise not allowed
        raise PermissionDenied("Only admin can create cards.")
    
    @action(
        detail=True,
        methods=["delete"],
        permission_classes=[IsAuthenticated, IsAdmin],
        url_path="admin-delete"
    )
    def admin_delete(self, request, pk=None):
        """
        Admin-only: Delete a card.
        Prevent deletion if active services exist.
        """
        card = self.get_object()

        # 🚫 Check for active services
        active_services = Service.objects.filter(
            card=card,
            status__in=["pending", "assigned", "scheduled", "awaiting_otp"]
        ).exists()

        if active_services:
            return Response(
                {
                    "detail": "Card cannot be deleted. Active services exist."
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # ✅ Safe to delete
        card.delete()

        return Response(
            {
                "detail": "Card deleted successfully",
                "card_id": pk
            },
            status=status.HTTP_200_OK
        )


# crm/views.py — updated ServiceViewSet (replace existing ServiceViewSet class)

from datetime import datetime as _dt
from django.utils import timezone as _tz
from django.db.models import DateTimeField, Value
from django.utils.dateparse import parse_date

from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.shortcuts import get_object_or_404

from .models import Service, ServiceEntry
from .serializers import ServiceSerializer, ServiceCreateSerializer, ServiceEntrySerializer
from user.models import User
from .utils import parse_iso_datetime, generate_otp, hash_otp, otp_expiry_time, verify_otp_hash
from django.db.models.functions import Coalesce
from rest_framework.exceptions import PermissionDenied

# NEW imports for safe null-last ordering
from django.db.models import Case, When, IntegerField, F
from django.db import transaction
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.shortcuts import get_object_or_404



class ServiceViewSet(viewsets.ModelViewSet):
    queryset = Service.objects.select_related("card", "assigned_to").all()
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self):
        if self.action == "create":
            return ServiceCreateSerializer
        if self.action == "admin_create":
            return ServiceAdminCreateSerializer
        # use ServiceSerializer for list/retrieve/update/partial_update
        return ServiceSerializer

    def get_queryset(self):
        qs = super().get_queryset()
        user = self.request.user

        if user.role == "customer":
            qs = qs.filter(card__customer=user)
        elif user.role in ("worker", "staff"):
            qs = qs.filter(assigned_to=user)
            

        # ordering: scheduled_at asc (NULLs last), then created_at
        try:
            # Annotate an integer flag: 0 for non-null scheduled_at, 1 for null.
            # Order by that flag first (so non-null come first), then by scheduled_at asc, then created_at.
            qs = qs.annotate(
                scheduled_is_null=Case(
                    When(scheduled_at__isnull=True, then=Value(1)),
                    default=Value(0),
                    output_field=IntegerField(),
                )
            ).order_by("scheduled_is_null", F("scheduled_at").asc(nulls_last=True), "created_at")
        except Exception:
            # Fallback: if DB/backend doesn't support nulls_last in F.ordering, fall back to simpler ordering.
            try:
                qs = qs.annotate(
                    scheduled_is_null=Case(
                        When(scheduled_at__isnull=True, then=Value(1)),
                        default=Value(0),
                        output_field=IntegerField(),
                    )
                ).order_by("scheduled_is_null", "scheduled_at", "created_at")
            except Exception:
                qs = qs.order_by("created_at")

        # allow filtering via query params
        status_q = self.request.query_params.get("status")
        card_q = self.request.query_params.get("card")
        assigned_q = self.request.query_params.get("assigned_to")
        if status_q:
            qs = qs.filter(status=status_q)
        if card_q:
            qs = qs.filter(card_id=card_q)
        if assigned_q:
            qs = qs.filter(assigned_to_id=assigned_q)
        return qs

    def perform_create(self, serializer):
        """
        Let serializer.create() use request from context to set requested_by/created_by.
        Avoid passing extra kwargs here (serializer handles request via context).
        """
        # ensure request is in serializer context (DRF normally does this)
        serializer.context.setdefault("request", self.request)
        service = serializer.save()
        message="A New Service Was Booked By Customer."
        phone = getattr(settings, "ADMIN_PHONE")
        Send_SMS(phone, message)
        return service
    
    @action(
        detail=False,
        methods=["post"],
        permission_classes=[IsAuthenticated, IsAdmin],
        url_path="admin_create",
    )
    def admin_create(self, request):
        """
        Admin creates a service.
        Status is FORCED to 'assigned' by serializer.
        """
        serializer = ServiceAdminCreateSerializer(
            data=request.data,
            context={"request": request}
        )

        serializer.is_valid(raise_exception=True)
        service = serializer.save()

        return Response(
            {
                "detail": "service created and assigned",
                "service_id": service.id,
                "status": service.status,
            },
            status=status.HTTP_201_CREATED,
        )


    @action(detail=True, methods=["post"], permission_classes=[IsAuthenticated])
    def assign(self, request, pk=None):
        """
        Admin assigns a staff and optional scheduled_at (DATE).
        """
        if request.user.role != "admin":
            return Response({"detail": "only admin"}, status=status.HTTP_403_FORBIDDEN)

        service = self.get_object()

        assigned_to_id = request.data.get("assigned_to")
        scheduled_at = request.data.get("scheduled_at")

        if not assigned_to_id:
            return Response({"detail": "assigned_to required"}, status=status.HTTP_400_BAD_REQUEST)

        staff = get_object_or_404(User, pk=assigned_to_id)

        # 🔒 ATOMIC + UPDATE_FIELDS (THIS IS THE FIX)
        with transaction.atomic():
            service.assigned_to = staff
            service.status = "assigned"

            if scheduled_at:
                try:
                    service.scheduled_at = parse_iso_datetime(scheduled_at)
                except Exception:
                    return Response(
                        {"detail": "invalid scheduled_at format (YYYY-MM-DD)"},
                        status=status.HTTP_400_BAD_REQUEST
                    )

            service.save(update_fields=["assigned_to", "scheduled_at", "status"])

        # 🔁 reload from DB to confirm
        service.refresh_from_db(fields=["status"])

        return Response(
            {
                "detail": "assigned",
                "status": service.status
            },
            status=status.HTTP_200_OK
        )


    @action(detail=True, methods=["post"], permission_classes=[IsAuthenticated])
    def reschedule(self, request, pk=None):
        """
        Customer (owner) or admin can reschedule. Accepts ISO datetime string for scheduled_at.
        """
        service = self.get_object()
        user = request.user
        if not (user.role == "admin" or service.card.customer_id == user.id):
            return Response({"detail": "not allowed"}, status=status.HTTP_403_FORBIDDEN)

        scheduled_at = request.data.get("scheduled_at")
        if not scheduled_at:
            return Response({"detail": "scheduled_at required"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            service.scheduled_at = parse_iso_datetime(scheduled_at)
        except Exception:
            return Response({"detail": "invalid datetime format"}, status=status.HTTP_400_BAD_REQUEST)

        service.status = "scheduled"
        service.save()
        # TODO: notify assigned staff & customer
        return Response({"detail": "rescheduled"}, status=status.HTTP_200_OK)

    @action(detail=True, methods=["post"], permission_classes=[IsAuthenticated])
    def cancel(self, request, pk=None):
        """
        Cancel booking. Owner customer or admin only.
        """
        service = self.get_object()
        user = request.user
        if not (user.role == "admin" or service.card.customer_id == user.id):
            return Response({"detail": "not allowed"}, status=status.HTTP_403_FORBIDDEN)

        service.status = "cancelled"
        service.save()
        # TODO: notify assigned staff & customer
        return Response({"detail": "cancelled"}, status=status.HTTP_200_OK)

    @action(detail=True, methods=["post"], permission_classes=[IsAuthenticated])
    def request_otp(self, request, pk=None):
        """
        Staff requests OTP: generate, store hash & expiry, send SMS (stub).
        """
        service = self.get_object()
        user = request.user
        # allow only assigned staff or admin to request
        if user.role not in ("worker", "staff", "admin") and service.assigned_to_id != user.id:
            return Response({"detail": "not allowed"}, status=status.HTTP_403_FORBIDDEN)
        
        phone = request.data.get("phone")

        if not phone:
            return Response(
                {"detail": "phone is required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        otp = generate_otp(4)
        service.otp_hash = hash_otp(otp)
        service.otp_expires_at = otp_expiry_time()
        service.otp_phone=phone
        service.status = "awaiting_otp"
        service.save()

        message = str(otp)+" is your OTP for verfiy the service "+str(service.id)+" for "+service.description+". Thanks For Choosing VST Maarketing."
        Send_SMS(phone, message)
        
        if getattr(settings, "CRM_DEV_RETURN_OTP", False):
            return Response({"detail": "otp-generated", "otp": otp})
        
        return Response({"detail": "otp-sent"}, status=status.HTTP_200_OK)
    
    @action(detail=True, methods=["post"], permission_classes=[IsAuthenticated])
    def reinstall(self, request, pk=None):

        service = self.get_object()
        user = request.user

        if service.status != "job_card_pending":
            return Response({"detail": "Service has no pending job cards"}, status=400)

        otp = request.data.get("otp")
        job_card_ids = request.data.get("job_cards", [])

        if not otp:
            return Response({"detail": "otp required"}, status=400)

        if not job_card_ids:
            return Response({"detail": "job_cards list required"}, status=400)

        # OTP expiry check
        if not service.otp_hash or not service.otp_expires_at or timezone.now() > service.otp_expires_at:
            return Response({"detail": "otp expired"}, status=400)

        if not verify_otp_hash(otp, service.otp_hash):
            return Response({"detail": "invalid otp"}, status=400)

        # Fetch job cards
        job_cards = JobCard.objects.filter(
            id__in=job_card_ids,
            service=service,
            reinstall_staff=request.user
        )


        if not job_cards.exists():
            return Response({"detail": "Invalid job cards"}, status=400)

        # Permission check
        if user.role != "admin":

            not_allowed = job_cards.exclude(reinstall_staff=user).exists()

            if not_allowed:
                return Response({"detail": "You are not reinstall staff for some job cards"}, status=403)

        # Ensure repaired first
        if job_cards.exclude(status="repair_completed").exists():
            return Response({"detail": "Some job cards are not repaired"}, status=400)

        # Mark selected job cards reinstalled
        job_cards.update(
            status="reinstalled",
            reinstalled_at=timezone.now()
        )

        # Check if ALL job cards done → complete service
        if not JobCard.objects.filter(service=service).exclude(status="reinstalled").exists():

            service.status = "completed"
            service.otp_hash = None
            service.otp_expires_at = None
            service.save()

        return Response({"detail": "Selected parts reinstalled"})


    @action(detail=True, methods=["post"], permission_classes=[IsAuthenticated])
    def verify_otp(self, request, pk=None):
        """
        Staff submits OTP + work details -> validate, create ServiceEntry, mark completed.
        """
        service = self.get_object()
        user = request.user

        if user.role not in ("worker", "staff", "admin") and service.assigned_to_id != user.id:
            return Response({"detail": "not allowed"}, status=status.HTTP_403_FORBIDDEN)

        otp = request.data.get("otp")
        if not otp:
            return Response({"detail": "otp is required"}, status=status.HTTP_400_BAD_REQUEST)

        if not service.otp_hash or not service.otp_expires_at or timezone.now() > service.otp_expires_at:
            return Response({"detail": "otp expired or not requested"}, status=status.HTTP_400_BAD_REQUEST)

        if not verify_otp_hash(otp, service.otp_hash):
            return Response({"detail": "invalid otp"}, status=status.HTTP_400_BAD_REQUEST)

        work_detail = request.data.get("work_detail", "")
        parts_replaced = request.data.get("parts_replaced")
        amount_charged = request.data.get("amount_charged")
        next_service_date = request.data.get("next_service_date")

        parsed_next_date = None
        if next_service_date:
            parsed_next_date = parse_date(next_service_date)

        # 🔒 ATOMIC BLOCK
        job_cards_data = []

        index = 0
        while True:
            part_name = request.data.get(f"job_cards[{index}][part_name]")
            details = request.data.get(f"job_cards[{index}][details]")
            image = request.FILES.get(f"job_cards[{index}][image]")

            if part_name is None and details is None and image is None:
                break

            job_cards_data.append({
                "part_name": part_name,
                "details": details,
                "image": image,
            })

            index += 1


        with transaction.atomic():

            se = ServiceEntry.objects.create(
                service=service,
                performed_by=user,
                actual_complaint=service.description,
                visit_type=service.visit_type,
                work_detail=work_detail,
                parts_replaced=parts_replaced,
                amount_charged=amount_charged,
            )

            # If job cards exist → create them
            if job_cards_data:

                for jc in job_cards_data:
                    JobCard.objects.create(
                        service=service,
                        service_entry=se,
                        staff=user,
                        reinstall_staff=user, 
                        customer=service.card.customer,
                        part_name=jc.get("part_name"),
                        details=jc.get("details"),
                        image=jc.get("image"),
                    )

                # DO NOT COMPLETE SERVICE
                Service.objects.filter(pk=service.pk).update(
                    status="job_card_pending",
                    otp_hash=None,
                    otp_expires_at=None,
                )

            else:
                # Normal completion
                Service.objects.filter(pk=service.pk).update(
                    status="completed",
                    otp_hash=None,
                    otp_expires_at=None,
                    next_service_date=parsed_next_date,
                )


        final_status = "job_card_pending" if job_cards_data else "completed"

        return Response(
            {
                "detail": "service processed",
                "service_entry_id": se.id,
                "status": final_status,
            },
            status=status.HTTP_200_OK,
        )

# ---------- ServiceEntry ----------
class ServiceEntryViewSet(viewsets.ModelViewSet):
    queryset = ServiceEntry.objects.select_related("service", "performed_by").all()
    serializer_class = ServiceEntrySerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs = super().get_queryset()
        user = self.request.user
        if user.role == "customer":
            return qs.filter(service__card__customer=user)
        if user.role in ("worker", "staff"):
            return qs.filter(performed_by=user)
        return qs


# ---------- Feedback ----------

class FeedbackViewSet(viewsets.ModelViewSet):
    queryset = Feedback.objects.select_related("service", "customer").all()
    serializer_class = FeedbackSerializer
    permission_classes = [IsAuthenticated]

    def perform_create(self, serializer):
        # ensure request is present in context (DRF usually does this)
        serializer.context.setdefault("request", self.request)
        # create() in serializer will set customer from request
        serializer.save()



# ---------- Attendance ----------
# crm/views.py (AttendanceViewSet)
from django.utils import timezone
from django.shortcuts import get_object_or_404
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Attendance
from .serializers import AttendanceSerializer
from user.models import User
from .permissions import IsAdmin  # your existing admin permission class
from .utils import parse_iso_date  # helper that parses "YYYY-MM-DD" -> date

class AttendanceViewSet(viewsets.ModelViewSet):
    """
    Admin-controlled attendance API. Staff can view their own attendance via `me`.
    Admin calls mark_present/mark_absent/bulk to set attendance and user.is_available.
    """
    queryset = Attendance.objects.select_related("user", "marked_by").all()
    serializer_class = AttendanceSerializer
    permission_classes = [IsAuthenticated]  # further checks per-action

    def get_permissions(self):
        # Admin-only for modifying actions
        if self.action in ("mark_present", "mark_absent", "bulk", "create", "update", "partial_update", "destroy"):
            return [IsAuthenticated(), IsAdmin()]
        # all authenticated users can view list/retrieve; staff can use "me"
        return [IsAuthenticated()]

    def get_queryset(self):
        user = self.request.user
        if user.role in ("worker", "staff"):
            # staff only see their own attendance
            return Attendance.objects.filter(user=user)
        if user.role == "customer":
            return Attendance.objects.none()
        # admin sees all
        return super().get_queryset()

    @action(detail=False, methods=["post"], permission_classes=[IsAuthenticated, IsAdmin])
    def mark_present(self, request):
        user_id = request.data.get("user")
        date_str = request.data.get("date")

        if not user_id:
            return Response({"detail": "user is required"}, status=status.HTTP_400_BAD_REQUEST)

        staff = get_object_or_404(User, pk=user_id)

        try:
            d = parse_iso_date(date_str) if date_str else timezone.localdate()
        except ValueError:
            return Response({"detail": "invalid date, expected YYYY-MM-DD"}, status=status.HTTP_400_BAD_REQUEST)

        # 🚫 only allow TODAY
        if d != timezone.localdate():
            return Response(
                {"detail": "Attendance can only be marked for today"},
                status=status.HTTP_400_BAD_REQUEST
            )

        att, _ = Attendance.objects.update_or_create(
            user=staff,
            date=d,
            defaults={"status": "present", "marked_by": request.user}
        )

        staff.is_available = True
        staff.save(update_fields=["is_available"])

        return Response(
            {"detail": "marked present", "attendance_id": att.id},
            status=status.HTTP_200_OK
        )


    @action(detail=False, methods=["post"], permission_classes=[IsAuthenticated, IsAdmin])
    def mark_absent(self, request):
        user_id = request.data.get("user")
        date_str = request.data.get("date")

        if not user_id:
            return Response({"detail": "user is required"}, status=status.HTTP_400_BAD_REQUEST)

        staff = get_object_or_404(User, pk=user_id)

        try:
            d = parse_iso_date(date_str) if date_str else timezone.localdate()
        except ValueError:
            return Response({"detail": "invalid date, expected YYYY-MM-DD"}, status=status.HTTP_400_BAD_REQUEST)

        # 🚫 only allow TODAY
        if d != timezone.localdate():
            return Response(
                {"detail": "Attendance can only be marked for today"},
                status=status.HTTP_400_BAD_REQUEST
            )

        att, _ = Attendance.objects.update_or_create(
            user=staff,
            date=d,
            defaults={"status": "absent", "marked_by": request.user}
        )

        staff.is_available = False
        staff.save(update_fields=["is_available"])

        return Response(
            {"detail": "marked absent", "attendance_id": att.id},
            status=status.HTTP_200_OK
        )


    @action(detail=False, methods=["post"], permission_classes=[IsAuthenticated, IsAdmin])
    def bulk(self, request):
        date_str = request.data.get("date")

        try:
            d = parse_iso_date(date_str) if date_str else timezone.localdate()
        except ValueError:
            return Response({"detail": "invalid date, expected YYYY-MM-DD"}, status=status.HTTP_400_BAD_REQUEST)

        # 🚫 only allow TODAY
        if d != timezone.localdate():
            return Response(
                {"detail": "Bulk attendance allowed only for today"},
                status=status.HTTP_400_BAD_REQUEST
            )

        present_ids = request.data.get("present", [])
        absent_ids = request.data.get("absent", [])

        for uid in present_ids:
            staff = get_object_or_404(User, pk=uid)
            Attendance.objects.update_or_create(
                user=staff, date=d,
                defaults={"status": "present", "marked_by": request.user}
            )
            staff.is_available = True
            staff.save(update_fields=["is_available"])

        for uid in absent_ids:
            staff = get_object_or_404(User, pk=uid)
            Attendance.objects.update_or_create(
                user=staff, date=d,
                defaults={"status": "absent", "marked_by": request.user}
            )
            staff.is_available = False
            staff.save(update_fields=["is_available"])

        return Response(
            {"detail": "bulk attendance updated for today"},
            status=status.HTTP_200_OK
        )
    
    @action(detail=False, methods=["get"], permission_classes=[IsAuthenticated, IsAdmin])
    def by_date(self, request):
        """
        GET /api/crm/attendance/by_date/?date=YYYY-MM-DD
        Admin-only: fetch attendance for a specific date
        """
        date_str = request.query_params.get("date")

        try:
            d = parse_iso_date(date_str) if date_str else timezone.localdate()
        except ValueError:
            return Response(
                {"detail": "invalid date format, expected YYYY-MM-DD"},
                status=status.HTTP_400_BAD_REQUEST
            )

        qs = Attendance.objects.filter(date=d).select_related("user", "marked_by")

        data = []
        for att in qs:
            data.append({
                "id": att.id,
                "user_id": att.user.id,
                "user_name": att.user.name,
                "role": att.user.role,
                "status": att.status,
                "date": att.date.isoformat(),
                "marked_by": att.marked_by.id if att.marked_by else None,
            })

        return Response(
            {
                "date": d.isoformat(),
                "total": len(data),
                "records": data
            },
            status=status.HTTP_200_OK
        )



    @action(detail=False, methods=["get"], permission_classes=[IsAuthenticated])
    def me(self, request):
        """
        GET /api/crm/attendance/me/  — staff can view today's attendance (or last attendance).
        """
        user = request.user
        d = timezone.localdate()
        try:
            att = Attendance.objects.filter(user=user, date=d).order_by("-created_at").first()
        except Exception:
            att = None
        if not att:
            return Response({"date": d.isoformat(), "status": None})
        serializer = self.get_serializer(att)
        return Response(serializer.data)


# ---------- Reports & admin utilities ----------
from datetime import datetime, timedelta
from calendar import monthrange
from dateutil.relativedelta import relativedelta

from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response

class WarrantyReportView(APIView):
    permission_classes = [IsAuthenticated, IsAdmin]

    def get(self, request):
        month = request.query_params.get("month")
        if not month:
            today = timezone.localdate()
            month = f"{today.year}-{today.month:02d}"

        year, mon = map(int, month.split("-"))

        first_day = datetime(year, mon, 1).date()
        last_day = datetime(year, mon, monthrange(year, mon)[1]).date()

        results = []

        # ----------------------------------
        # 1. Fetch cards
        # ----------------------------------
        cards = Card.objects.select_related("customer").filter(
            warranty_start_date__isnull=False,
            warranty_end_date__isnull=False,
        )

        # ----------------------------------
        # 2. Fetch ALL free services once
        # ----------------------------------
        free_services = (
            Service.objects
            .filter(service_type="free")
            .values("card_id", "scheduled_at", "assigned_to_id", "assigned_to__name")
        )

        # Group services by card_id
        services_by_card = {}
        for s in free_services:
            services_by_card.setdefault(s["card_id"], []).append({
                "date": s["scheduled_at"],
                "staff_id": s["assigned_to_id"],
                "staff_name": s["assigned_to__name"]
            })

        # ----------------------------------
        # 3. Process milestones
        # ----------------------------------
        for c in cards:
            if c.card_type == "om":
                continue

            if c.warranty_start_date > last_day or c.warranty_end_date < first_day:
                continue

            milestones = []
            current_milestone = c.warranty_start_date + relativedelta(months=3)

            while current_milestone < c.warranty_end_date:
                milestones.append(current_milestone)
                current_milestone += relativedelta(months=3)

            if c.warranty_end_date not in milestones:
                milestones.append(c.warranty_end_date)

            card_services = services_by_card.get(c.id, [])

            for m in milestones:
                if not (first_day <= m <= last_day):
                    continue

                start_window = m - timedelta(days=30)
                end_window = m + timedelta(days=30)

                status = "notdone"
                done_staff = None
                scheduled_date = None

                for svc in card_services:
                    svc_date = svc["date"]

                    if svc_date and start_window <= svc_date <= end_window:
                        status = "done"
                        scheduled_date = svc_date.isoformat() if svc_date else None
                        done_staff = {
                            "staff_id": svc["staff_id"],
                            "staff_name": svc["staff_name"],
                        }
                        break

                results.append({
                    "card_id": c.id,
                    "card_model": c.model,
                    "customer_id": c.customer.id,
                    "customer_name": c.customer.name,
                    "customer_phone": c.customer.phone,
                    "address": c.address,
                    "city": c.city,
                    "milestone": m.isoformat(),
                    "status": status,
                    "staff": done_staff,
                    "scheduled_date": scheduled_date,  # ✅ NEW
                    "allmilestones": [m.isoformat() for m in milestones],
                })

        return Response(results)

    
class WarrantyReportByCardView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        card_id = request.query_params.get("card_id")
        user = request.user

        
        if not card_id:
            return Response(
                {"detail": "card_id is required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        month = request.query_params.get("month")
        if month:
            try:
                year, mon = map(int, month.split("-"))
                first_day = datetime(year, mon, 1).date()
                last_day = datetime(year, mon, monthrange(year, mon)[1]).date()
            except Exception:
                return Response(
                    {"detail": "invalid month format, expected YYYY-MM"},
                    status=status.HTTP_400_BAD_REQUEST
                )
        else:
            # if month not given → full warranty period
            first_day = None
            last_day = None

        card = get_object_or_404(
            Card.objects.select_related("customer"),
            pk=card_id
        )

        if user.role in ("worker", "staff"):
            raise PermissionDenied("Workers are not allowed")

        if user.role == "customer" and card.customer_id != user.id:
            raise PermissionDenied("You do not have permission to view this card JJ")
        

        if not card.warranty_start_date or not card.warranty_end_date:
            return Response(
                {"detail": "Card has no warranty dates"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # ------------------------------
        # Fetch free services for card
        # ------------------------------
        free_services = (
            Service.objects
            .filter(card=card, service_type="free")
            .values_list("preferred_date", flat=True)
        )

        milestones = []

        current = card.warranty_start_date + relativedelta(months=3)

        while current < card.warranty_end_date:
            milestones.append(current)
            current += relativedelta(months=3)
        
        if card.warranty_end_date not in milestones:
            milestones.append(card.warranty_end_date)

        results = []

        for m in milestones:
            if first_day and last_day:
                if not (first_day <= m <= last_day):
                    continue

            start_window = m - timedelta(days=30)
            end_window = m + timedelta(days=30)

            status_flag = "notdone"
            for svc_date in free_services:
                if svc_date and start_window <= svc_date <= end_window:
                    status_flag = "done"
                    break

            results.append({
                "milestone": m.isoformat(),
                "status": status_flag,
            })
        if(card.card_type=="om"):
            results=[]

        return Response(
            {
                "card_id": card.id,
                "card_model": card.model,
                "customer_id": card.customer.id,
                "customer_name": card.customer.name,
                "customer_phone": card.customer.phone,
                "address": card.address,
                "city": card.city,
                "warranty_start": card.warranty_start_date,
                "warranty_end": card.warranty_end_date,
                "milestones": results,
            },
            status=status.HTTP_200_OK
        )
    
    
class AMCReportView(APIView):
    permission_classes = [IsAuthenticated, IsAdmin]

    def get(self, request):
        month = request.query_params.get("month")
        if not month:
            today = timezone.localdate()
            month = f"{today.year}-{today.month:02d}"

        year, mon = map(int, month.split("-"))

        first_day = datetime(year, mon, 1).date()
        last_day = datetime(year, mon, monthrange(year, mon)[1]).date()

        results = []

        # ----------------------------------
        # 1. Fetch cards
        # ----------------------------------
        cards = Card.objects.select_related("customer").filter(
            amc_start_date__isnull=False,
            amc_end_date__isnull=False,
        )

        # ----------------------------------
        # 2. Fetch ALL free services + staff
        # ----------------------------------
        free_services = (
            Service.objects
            .filter(service_type="free")
            .values(
                "card_id",
                "scheduled_at",
                "assigned_to_id",
                "assigned_to__name",
            )
        )

        # Group services by card_id
        services_by_card = {}

        for s in free_services:
            services_by_card.setdefault(s["card_id"], []).append({
                "date": s["scheduled_at"],
                "staff_id": s["assigned_to_id"],
                "staff_name": s["assigned_to__name"],
            })

        # ----------------------------------
        # 3. Process milestones
        # ----------------------------------
        for c in cards:
            if c.card_type == "om":
                continue

            if c.amc_start_date > last_day or c.amc_end_date < first_day:
                continue

            milestones = []
            current_milestone = c.amc_start_date + relativedelta(months=3)

            while current_milestone < c.amc_end_date:
                milestones.append(current_milestone)
                current_milestone += relativedelta(months=3)

            if c.amc_end_date not in milestones:
                milestones.append(c.amc_end_date)

            card_services = services_by_card.get(c.id, [])

            for m in milestones:
                if not (first_day <= m <= last_day):
                    continue

                start_window = m - timedelta(days=30)
                end_window = m + timedelta(days=30)

                status = "notdone"
                done_staff = None
                scheduled_date = None

                for svc in card_services:
                    svc_date = svc["date"]

                    if svc_date and start_window <= svc_date <= end_window:
                        status = "done"
                        scheduled_date = svc_date.isoformat() if svc_date else None
                        done_staff = {
                            "staff_id": svc["staff_id"],
                            "staff_name": svc["staff_name"],
                        }
                        break

                results.append({
                    "card_id": c.id,
                    "card_model": c.model,
                    "customer_id": c.customer.id,
                    "customer_name": c.customer.name,
                    "customer_phone": c.customer.phone,
                    "address": c.address,
                    "city": c.city,
                    "milestone": m.isoformat(),
                    "status": status,
                    "staff": done_staff,
                    "scheduled_date": scheduled_date,
                    "allmilestones": [m.isoformat() for m in milestones],
                })

        return Response(results)

    
class AMCReportByCardView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        card_id = request.query_params.get("card_id")
        user = request.user

        
        if not card_id:
            return Response(
                {"detail": "card_id is required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        month = request.query_params.get("month")
        if month:
            try:
                year, mon = map(int, month.split("-"))
                first_day = datetime(year, mon, 1).date()
                last_day = datetime(year, mon, monthrange(year, mon)[1]).date()
            except Exception:
                return Response(
                    {"detail": "invalid month format, expected YYYY-MM"},
                    status=status.HTTP_400_BAD_REQUEST
                )
        else:
            # if month not given → full warranty period
            first_day = None
            last_day = None

        card = get_object_or_404(
            Card.objects.select_related("customer"),
            pk=card_id
        )

        if user.role in ("worker", "staff"):
            raise PermissionDenied("Workers are not allowed")

        if user.role == "customer" and card.customer_id != user.id:
            raise PermissionDenied("You do not have permission to view this card JJ")
        

        if not card.amc_start_date or not card.amc_end_date:
            return Response(
                {"detail": "Card has no amc dates"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # ------------------------------
        # Fetch free services for card
        # ------------------------------
        free_services = (
            Service.objects
            .filter(card=card, service_type="free")
            .values_list("preferred_date", flat=True)
        )

        milestones = []

        current = card.amc_start_date + relativedelta(months=3)

        while current <= card.amc_end_date:
            milestones.append(current)
            current += relativedelta(months=3)

        if card.amc_end_date not in milestones:
            milestones.append(card.amc_end_date)
            
        results = []

        for m in milestones:
            if first_day and last_day:
                if not (first_day <= m <= last_day):
                    continue

            start_window = m - timedelta(days=30)
            end_window = m + timedelta(days=30)

            status_flag = "notdone"
            for svc_date in free_services:
                if svc_date and start_window <= svc_date <= end_window:
                    status_flag = "done"
                    break

            results.append({
                "milestone": m.isoformat(),
                "status": status_flag,
            })
        if(card.card_type=="om"):
            results=[]

        return Response(
            {
                "card_id": card.id,
                "card_model": card.model,
                "customer_id": card.customer.id,
                "customer_name": card.customer.name,
                "customer_phone": card.customer.phone,
                "address": card.address,
                "city": card.city,
                "amc_start": card.amc_start_date,
                "amc_end": card.amc_end_date,
                "milestones": results,
            },
            status=status.HTTP_200_OK
        )



class UpcomingServicesReportView(APIView):
    permission_classes = [IsAuthenticated, IsAdmin]

    def get(self, request):
        from_date = request.query_params.get("from")
        to_date = request.query_params.get("to")
        qs = Service.objects.filter(status__in=("scheduled", "assigned", "pending"))
        if from_date:
            try:
                dt_from = parse_iso_datetime(from_date)
                qs = qs.filter(scheduled_at__gte=dt_from)
            except Exception:
                pass
        if to_date:
            try:
                dt_to = parse_iso_datetime(to_date)
                qs = qs.filter(scheduled_at__lte=dt_to)
            except Exception:
                pass

        data = []
        for s in qs.order_by("scheduled_at")[:1000]:
            data.append({
                "id": s.id,
                "card_id": s.card_id,
                "scheduled_at": s.scheduled_at,
                "assigned_to": s.assigned_to_id,
                "status": s.status
            })
        return Response(data)


class AutoAssignRunView(APIView):
    permission_classes = [IsAuthenticated, IsAdmin]

    def post(self, request):
        # Trigger auto-assign algorithm (synchronous stub or enqueue Celery)
        # TODO: implement logic considering attendance, region, availability, and conflicts.
        # For now return not implemented.
        return Response({"detail": "auto-assign triggered (stub) - implement Celery task"}, status=status.HTTP_200_OK)


class ExportServicesCSVView(APIView):
    permission_classes = [IsAuthenticated, IsAdmin]

    def get(self, request):
        """Export services as CSV for given date range"""
        from_date = request.query_params.get("from")
        to_date = request.query_params.get("to")
        qs = Service.objects.all()
        if from_date:
            qs = qs.filter(created_at__gte=from_date)
        if to_date:
            qs = qs.filter(created_at__lte=to_date)
        qs = qs.order_by("created_at")

        buf = StringIO()
        writer = csv.writer(buf)
        writer.writerow(["id", "card_id", "customer", "service_type", "status", "scheduled_at", "assigned_to", "amount_charged", "created_at"])
        for s in qs:
            writer.writerow([
                s.id,
                s.card_id,
                s.card.customer_id if s.card else "",
                s.service_type,
                s.status,
                s.scheduled_at.isoformat() if s.scheduled_at else "",
                s.assigned_to_id if s.assigned_to else "",
                s.amount_charged if s.amount_charged else "",
                s.created_at.isoformat()
            ])
        resp = HttpResponse(buf.getvalue(), content_type="text/csv")
        resp["Content-Disposition"] = "attachment; filename=services_export.csv"
        return resp


# ---------- Dev test endpoint to send OTP (dev-only) ----------
class DevSendOtpView(APIView):
    """
    Development only: triggers OTP generation and returns otp (do NOT enable in production).
    """
    permission_classes = [IsAuthenticated, IsAdmin]

    def post(self, request):
        service_id = request.data.get("service_id")
        service = get_object_or_404(Service, pk=service_id)
        otp = generate_otp(4)
        service.otp_hash = hash_otp(otp)
        service.otp_expires_at = otp_expiry_time()
        service.save()
        return Response({"otp": otp, "detail": "dev otp generated"}, status=status.HTTP_200_OK)


def Send_SMS(phone, message):
    print("SMS Send !")
    if getattr(settings, "CRM_DEV_SMS_TEST", False):
        print("-----------------------")
        print("To : "+phone)
        print("Message : "+message)
        print("-----------------------")


from django.utils import timezone
from django.db.models import Q
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import JobCard, Service
from .serializers import JobCardSerializer
from .utils import verify_otp_hash


class JobCardViewSet(viewsets.ModelViewSet):
    serializer_class = JobCardSerializer
    permission_classes = [IsAuthenticated]

    # ======================================================
    # 1️⃣ GET JOB CARDS (ADMIN / STAFF / REINSTALL STAFF)
    # ======================================================
    def get_queryset(self):

        user = self.request.user

        qs = JobCard.objects.select_related(
            "service",
            "staff",
            "reinstall_staff",
            "customer"
        ).order_by("-created_at")

        # 👑 ADMIN
        if user.role == "admin":
            return qs

        mine = self.request.query_params.get("mine") == "true"
        reinstall = self.request.query_params.get("reinstall") == "true"

        # LIST FILTERS
        if self.action == "list":
            if mine:
                return qs.filter(staff=user)

            if reinstall:
                return qs.filter(
                    reinstall_staff=user,
                    status="repair_completed"
                )

            return qs.none()

        # ⭐ DETAIL ACCESS (VERY IMPORTANT)
        return qs.filter(
            Q(staff=user) |
            Q(reinstall_staff=user)
        )



    # ======================================================
    # 4️⃣ ADMIN UPDATE STATUS + ASSIGN REINSTALL STAFF
    # ======================================================
    def partial_update(self, request, *args, **kwargs):
        user = request.user

        if user.role != "admin":
            return Response(
                {"detail": "Only admin can update job cards"},
                status=status.HTTP_403_FORBIDDEN
            )

        job_card = self.get_object()

        status_val = request.data.get("status")
        reinstall_staff_id = request.data.get("reinstall_staff")

        allowed_status = [
            "get_from_customer",
            "received_office",
            "repair_completed",
            "reinstalled",
        ]

        if status_val and status_val not in allowed_status:
            return Response({"detail": "Invalid status"}, status=400)

        # ---- STATUS TIMESTAMPS ----
        if status_val == "received_office":
            job_card.received_office_at = timezone.now()

        elif status_val == "repair_completed":
            job_card.repair_completed_at = timezone.now()

        elif status_val == "reinstalled":
            job_card.reinstalled_at = timezone.now()

        if reinstall_staff_id:
            job_card.reinstall_staff_id = reinstall_staff_id

        if status_val:
            job_card.status = status_val

        job_card.save()

        return Response(
            self.get_serializer(job_card, context={"request": request}).data
        )
    
    @action(
        detail=True,
        methods=["post"],
        permission_classes=[IsAuthenticated],
        url_path="verify_reinstall_otp"
    )
    def verify_reinstall_otp(self, request, pk=None):

        job_card = self.get_object()
        user = request.user
        service = job_card.service

        # 🔐 Permission
        if job_card.reinstall_staff_id != user.id and user.role != "admin":
            return Response(
                {"detail": "Not assigned reinstall staff"},
                status=403
            )

        otp = request.data.get("otp")

        if not otp:
            return Response({"detail": "OTP required"}, status=400)

        # 🔍 OTP Validation
        if not service.otp_hash or not service.otp_expires_at:
            return Response({"detail": "OTP not requested"}, status=400)

        if timezone.now() > service.otp_expires_at:
            return Response({"detail": "OTP expired"}, status=400)

        if not verify_otp_hash(otp, service.otp_hash):
            return Response({"detail": "Invalid OTP"}, status=400)

        # ✅ Mark JobCard Reinstalled
        job_card.status = "reinstalled"
        job_card.reinstalled_at = timezone.now()
        job_card.save()

        # ✅ If All JobCards Done → Complete Service
        pending = JobCard.objects.filter(
            service=service
        ).exclude(status="reinstalled").exists()

        if not pending:
            service.status = "completed"
            service.otp_hash = None
            service.otp_expires_at = None
            service.save()

        return Response({
            "detail": "Reinstallation completed"
        })

    
    @action(
        detail=True,
        methods=["post"],
        permission_classes=[IsAuthenticated],
        url_path="request_reinstall_otp"
    )
    def request_reinstall_otp(self, request, pk=None):

        job_card = self.get_object()
        user = request.user

        # 🔐 Permission
        if job_card.reinstall_staff_id != user.id and user.role != "admin":
            return Response(
                {"detail": "Not assigned reinstall staff"},
                status=403
            )

        service = job_card.service

        phone = request.data.get("phone") or service.otp_phone

        if not phone:
            return Response(
                {"detail": "phone required"},
                status=400
            )

        # ✅ Generate OTP
        otp = generate_otp(4)

        service.otp_hash = hash_otp(otp)
        service.otp_expires_at = otp_expiry_time()
        service.otp_phone = phone
        service.save()

        # ✅ Send SMS
        message = (
            f"{otp} is your OTP for reinstall verification "
            f"Service {service.id}"
        )

        Send_SMS(phone, message)

        # ⭐ DEV MODE RETURN OTP
        if getattr(settings, "CRM_DEV_RETURN_OTP", False):
            return Response({
                "detail": "otp-generated",
                "otp": otp
            })

        return Response({"detail": "otp-sent"})


    # ======================================================
    # 6️⃣ REINSTALL COMPLETE (STAFF + OTP)
    # ======================================================
    @action(
        detail=True,
        methods=["post"],
        permission_classes=[IsAuthenticated],
        url_path="complete-reinstall"
    )
    def complete_reinstall(self, request, pk=None):
        job_card = self.get_object()
        user = request.user

        # 🔐 Permission
        if job_card.reinstall_staff_id != user.id:
            return Response(
                {"detail": "You are not assigned to reinstall this part"},
                status=403
            )

        service = job_card.service
        otp = request.data.get("otp")

        if not otp:
            return Response({"detail": "OTP required"}, status=400)

        # OTP validation
        if not service.otp_hash or not service.otp_expires_at:
            return Response({"detail": "OTP not requested"}, status=400)

        if timezone.now() > service.otp_expires_at:
            return Response({"detail": "OTP expired"}, status=400)

        if not verify_otp_hash(otp, service.otp_hash):
            return Response({"detail": "Invalid OTP"}, status=400)

        # ✅ Mark job card reinstalled
        job_card.status = "reinstalled"
        job_card.reinstalled_at = timezone.now()
        job_card.save()

        # ✅ Check if all job cards are reinstalled
        pending = JobCard.objects.filter(
            service=service
        ).exclude(status="reinstalled").exists()

        if not pending:
            service.status = "completed"
            service.otp_hash = None
            service.otp_expires_at = None
            service.save()

        return Response({"detail": "Reinstallation completed"})



from dateutil.relativedelta import relativedelta

def generate_industrial_milestones(amc):

    milestones = []
    current = amc.start_date + relativedelta(months=amc.interval_months)

    while current <= amc.end_date:
        milestones.append(current)
        current += relativedelta(months=amc.interval_months)

    return milestones


class IndustrialAMCViewSet(viewsets.ModelViewSet):

    queryset = IndustrialAMC.objects.select_related("card", "card__customer")
    serializer_class = IndustrialAMCSerializer
    permission_classes = [IsAuthenticated, IsAdmin]

class IndustrialAMCReportView(APIView):

    permission_classes = [IsAuthenticated, IsAdmin]

    def get(self, request):

        month = request.query_params.get("month")

        if not month:
            today = timezone.localdate()
            month = f"{today.year}-{today.month:02d}"

        # ✅ Validate month input
        try:
            year, mon = map(int, month.split("-"))
        except Exception:
            return Response(
                {"error": "Invalid month format. Use YYYY-MM"},
                status=400
            )

        first_day = datetime(year, mon, 1).date()
        last_day = datetime(year, mon, monthrange(year, mon)[1]).date()

        results = []

        # ✅ Fetch all AMCs
        amcs = IndustrialAMC.objects.select_related(
            "card",
            "card__customer"
        )

        # ✅ Fetch all services ONCE
        all_services = Service.objects.filter(
            service_type="free"
        ).values(
            "card_id",
            "scheduled_at",
            "assigned_to_id",
            "assigned_to__name"
        )

        # ✅ Build service map
        service_map = {}

        for svc in all_services:
            service_map.setdefault(svc["card_id"], []).append(svc)

        # =========================
        # Main AMC Loop
        # =========================
        for amc in amcs:

            # Skip invalid interval
            if not amc.interval_days:
                continue

            milestones = []

            current = amc.start_date + timedelta(days=amc.interval_days)

            while current <= amc.end_date:
                milestones.append(current)
                current += timedelta(days=amc.interval_days)

            services = service_map.get(amc.card.id, [])

            # =====================
            # Milestone Loop
            # =====================
            for m in milestones:

                if not (first_day <= m <= last_day):
                    continue

                start_window = m - timedelta(days=30)
                end_window = m + timedelta(days=30)

                status = "notdone"
                done_staff = None
                scheduled_date = None

                # =====================
                # Service Matching
                # =====================
                for svc in services:

                    svc_date = svc["scheduled_at"]

                    # Normalize datetime → date
                    if svc_date:
                        svc_date = (
                            svc_date.date()
                            if hasattr(svc_date, "date")
                            else svc_date
                        )

                    if svc_date and start_window <= svc_date <= end_window:

                        status = "done"
                        scheduled_date = svc_date.isoformat()

                        done_staff = {
                            "staff_id": svc["assigned_to_id"],
                            "staff_name": svc["assigned_to__name"],
                        }

                        break

                results.append({

                    "card_id": amc.card.id,
                    "card_model": amc.card.model,

                    "customer_id": amc.card.customer.id,
                    "customer_name": amc.card.customer.name,
                    "customer_phone": amc.card.customer.phone,

                    "address": amc.card.address,
                    "city": amc.card.city,

                    "interval_days": amc.interval_days,

                    "milestone": m.isoformat(),
                    "status": status,
                    "staff": done_staff,
                    "scheduled_date": scheduled_date,

                    "allmilestones": [d.isoformat() for d in milestones]
                })

        return Response(results)


from django.db.models import Max, F, ExpressionWrapper, DurationField
from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .serializers import FollowUpCardSerializer
from datetime import timedelta

class FollowUpCardsView(APIView):

    permission_classes = [IsAuthenticated, IsAdmin]

    def get(self, request):

        try:
            n_days = int(request.query_params.get("days", 30))
        except ValueError:
            return Response({"detail": "Invalid days parameter"}, status=400)

        today = timezone.localdate()

        cards = (
            Card.objects
            .annotate(
                last_service_date=Max(
                    "services__scheduled_at",
                    filter=models.Q(services__status="completed")
                )
            )
            .filter(last_service_date__isnull=False)
        )

        results = []

        for card in cards:
            days_since = (today - card.last_service_date).days

            if days_since > n_days:
                card.days_since_service = days_since
                results.append(card)

        serializer = FollowUpCardSerializer(results, many=True)
        return Response(serializer.data)
