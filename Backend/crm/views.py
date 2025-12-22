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

from user.models import User  # your custom user model

from .models import Card, Service, ServiceEntry, Feedback, Attendance
from .serializers import (
    CardSerializer,
    CardCreateSerializer,
    ServiceSerializer,
    ServiceCreateSerializer,
    ServiceAdminCreateSerializer,
    ServiceEntrySerializer,
    FeedbackSerializer,
    AttendanceSerializer,
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
        with transaction.atomic():
            # 1️⃣ Create service entry
            se = ServiceEntry.objects.create(
                service=service,
                performed_by=user if user.role in ("worker", "staff") else None,
                actual_complaint=service.description,
                visit_type=service.visit_type,
                work_detail=work_detail,
                parts_replaced=parts_replaced,
                amount_charged=amount_charged,
            )

            # 2️⃣ FORCE DB UPDATE (NO SAVE())
            Service.objects.filter(pk=service.pk).update(
                status="completed",
                otp_hash=None,
                otp_expires_at=None,
                next_service_date=parsed_next_date,
            )

        return Response(
            {
                "detail": "service completed",
                "service_entry_id": se.id,
                "status": "completed",
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
            .values("card_id", "scheduled_at")
        )

        # Group services by card_id
        services_by_card = {}
        for s in free_services:
            services_by_card.setdefault(s["card_id"], []).append(
                s["scheduled_at"]
            )

        # ----------------------------------
        # 3. Process milestones
        # ----------------------------------
        for c in cards:
            if(c.card_type=="om"):
                continue
            if c.warranty_start_date > last_day or c.warranty_end_date < first_day:
                continue

            milestones = [
                c.warranty_start_date + relativedelta(months=3),
                c.warranty_start_date + relativedelta(months=6),
                c.warranty_start_date + relativedelta(months=9),
            ]

            card_services = services_by_card.get(c.id, [])

            for m in milestones:
                if not (first_day <= m <= last_day):
                    continue

                # ±30 day window
                start_window = m - timedelta(days=30)
                end_window = m + timedelta(days=30)

                print(start_window, end_window)

                status = "notdone"

                for svc_date in card_services:
                    print(svc_date)
                    if svc_date and start_window <= svc_date <= end_window:
                        status = "done"
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
                    "status": status,   # ✅ done / notdone
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

        milestones = [
            card.warranty_start_date + relativedelta(months=3),
            card.warranty_start_date + relativedelta(months=6),
            card.warranty_start_date + relativedelta(months=9),
        ]

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