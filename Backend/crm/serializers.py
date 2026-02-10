# crm/serializers.py
from rest_framework import serializers
from django.utils import timezone
from django.conf import settings
from .models import Card, Service, ServiceEntry, Feedback, Attendance, JobCard, IndustrialAMC
from user.models import User  # your User model
from .utils import generate_otp, hash_otp, otp_expiry_time,booking_is_eligible_for_free
from datetime import timedelta

BOOKING_WINDOW_DAYS = getattr(settings, "CRM_BOOKING_WINDOW_DAYS", 30)
    
class CardSerializer(serializers.ModelSerializer):
    # expose customer-related fields (READ ONLY)
    customer_id = serializers.IntegerField(source="customer.id", read_only=True)
    customer_name = serializers.CharField(source="customer.name", read_only=True)
    customer_phone = serializers.CharField(source="customer.phone", read_only=True)

    class Meta:
        model = Card
        fields = "__all__"
        read_only_fields = (
            "id",
            "created_at",
            "updated_at",
            "customer",          # still protected
            "customer_id",
            "customer_name",
            "customer_phone",
        )

class CardCreateSerializer(serializers.ModelSerializer):
    # Accept a customer id on create and validate it belongs to a customer
    customer = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.filter(role="customer"),
        required=True
    )

    class Meta:
        model = Card
        # explicitly include the fields you want writable on create
        fields = [
            "id", "model", "customer", "customer_name", "card_type",
            "region", "address", "city", "postal_code",
            "date_of_installation", "warranty_start_date", "warranty_end_date", "amc_start_date", "amc_end_date",
            "created_at", "updated_at"
        ]
        read_only_fields = ("id", "created_at", "updated_at")

    def validate(self, attrs):
        ws = attrs.get("warranty_start_date")
        we = attrs.get("warranty_end_date")
        if ws and we and we < ws:
            raise serializers.ValidationError("warranty_end_date must be after warranty_start_date.")
        return attrs

    def create(self, validated_data):
        # If customer_name is not provided, default to customer's name
        customer = validated_data.get("customer")
        if not validated_data.get("customer_name") and customer:
            validated_data["customer_name"] = customer.name
        return super().create(validated_data)
    

class JobCardSerializer(serializers.ModelSerializer):
    service_id = serializers.IntegerField(source="service.id", read_only=True)
    service_status = serializers.CharField(source="service.status", read_only=True)
    staff_name = serializers.CharField(source="staff.name", read_only=True)
    reinstall_staff_name = serializers.CharField(
        source="reinstall_staff.name",
        read_only=True
    )
    image_url = serializers.SerializerMethodField()

    class Meta:
        model = JobCard
        fields = "__all__"

        read_only_fields = (
            "id",
            "staff",
            "customer",
            "service",
            "service_entry",
            "created_at",
            "get_from_customer_at",
            "received_office_at",
            "repair_completed_at",
            "reinstalled_at",
        )

    def get_image_url(self, obj):
        request = self.context.get("request")
        if obj.image and request:
            return request.build_absolute_uri(obj.image.url)
        return None






class ServiceEntrySerializer(serializers.ModelSerializer):
    performed_by = serializers.PrimaryKeyRelatedField(read_only=True)
    job_cards = JobCardSerializer(many=True, read_only=True)

    class Meta:
        model = ServiceEntry
        fields = "__all__"
        read_only_fields = ("id", "performed_by", "created_at")


# crm/serializers.py — replace FeedbackSerializer with this

from rest_framework import serializers
from .models import Feedback, Service
from django.utils import timezone

class FeedbackSerializer(serializers.ModelSerializer):
    service = serializers.PrimaryKeyRelatedField(queryset=Service.objects.all(), required=True)
    rating = serializers.IntegerField(min_value=1, max_value=5)
    comments = serializers.CharField(required=False, allow_blank=True, allow_null=True)

    class Meta:
        model = Feedback
        # include card and customer as read-only in response, but don't accept them in input
        fields = ("id", "service", "card", "rating", "comments", "created_at", "customer")
        read_only_fields = ("id", "created_at", "customer", "card")

    def validate_service(self, value: Service):
        """
        Ensure the request user is allowed to give feedback for this service.
        Optionally enforce that service.status == 'completed'.
        """
        request = self.context.get("request")
        if request and getattr(request, "user", None):
            user = request.user
            # If user is a customer, ensure they own the service's card
            if user.role == "customer":
                if value.card.customer_id != user.id:
                    raise serializers.ValidationError("You cannot give feedback for a service that is not yours.")
            # Optionally: require completed services only
            if getattr(value, "status", "").lower() != "completed":
                raise serializers.ValidationError("Feedback can only be given for completed services.")
        return value

    def create(self, validated_data):
        """
        Create Feedback and ensure required FK fields (card, customer, service) are set.
        """
        request = self.context.get("request", None)
        user = request.user if request else None

        service = validated_data.pop("service")
        rating = validated_data.get("rating")
        comments = validated_data.get("comments", "") or ""

        # service.card must exist; set card from service
        card = getattr(service, "card", None)
        if card is None:
            raise serializers.ValidationError("Associated service has no card; cannot create feedback.")

        feedback = Feedback.objects.create(
            service=service,
            card=card,
            customer=user,
            rating=rating,
            comments=comments
        )
        return feedback

class AttendanceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Attendance
        fields = "__all__"
        read_only_fields = ("id",)


# ============ SERVICE ===========

from rest_framework import serializers
from django.utils import timezone
from django.conf import settings
from datetime import date as _date

from .models import Service, ServiceEntry
from user.models import User

BOOKING_WINDOW_DAYS = getattr(settings, "CRM_BOOKING_WINDOW_DAYS", 30)


# helper to add months to a date (avoids needing python-dateutil)
def add_months(d: _date, months: int) -> _date:
    year = d.year + (d.month + months - 1) // 12
    month = (d.month + months - 1) % 12 + 1
    mdays = [31, 29 if (year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)) else 28,
             31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    day = min(d.day, mdays[month - 1])
    return _date(year, month, day)


class ServiceSerializer(serializers.ModelSerializer):
    entries = ServiceEntrySerializer(many=True, read_only=True)
    assigned_to_detail = serializers.SerializerMethodField()
    customer_data = serializers.SerializerMethodField()
    feedback = serializers.SerializerMethodField()
    card_data= serializers.SerializerMethodField()

    # expose preferred_date (date only)
    preferred_date = serializers.DateField(read_only=True, allow_null=True)
    scheduled_at = serializers.DateField(allow_null=True)

    class Meta:
        model = Service
        fields = [
            "id", "card", "card_data","requested_by", "customer_data", "service_type", "status", "description",
            "preferred_date", "scheduled_at", "assigned_to", "assigned_to_detail",
            "is_paid", "amount_charged", "visit_type", "next_service_date",
            "entries", "feedback", "otp_phone", "created_at",
        ]
        read_only_fields = ("id", "requested_by", "created_at")
    
    def get_feedback(self, obj):
        """
        Return latest feedback for the service (if any)
        """
        feedback = obj.feedbacks.order_by("-created_at").first()
        if not feedback:
            return None

        return {
            "id": feedback.id,
            "rating": feedback.rating,
            "comments": feedback.comments,
            "customer": feedback.customer_id,
            "created_at": feedback.created_at.isoformat(),
        }
    def get_customer_data(self, obj):
        """
        Return latest feedback for the service (if any)
        """
        if obj.requested_by:
            return {"id": obj.requested_by.id, "name": getattr(obj.requested_by, "name", obj.requested_by.phone), "phone":obj.requested_by.phone}
        return None
    
    def get_card_data(self, obj):
        """
        Return latest feedback for the service (if any)
        """
        if obj.requested_by:
            return {"id": obj.card.id, "address":obj.card.address, "city":obj.card.city, "model":obj.card.model, "card_type":obj.card.card_type}
        return None

    def get_assigned_to_detail(self, obj):
        if obj.assigned_to:
            return {"id": obj.assigned_to.id, "name": getattr(obj.assigned_to, "name", obj.assigned_to.phone), "phone":obj.assigned_to.phone}
        return None

    def to_representation(self, instance):
        """
        Ensure preferred_date is represented (ISO date string). Fallbacks handled gracefully.
        """
        ret = super().to_representation(instance)
        try:
            val = getattr(instance, "preferred_date", None)
            if val is not None:
                # date -> ISO
                ret["preferred_date"] = val.isoformat()
        except Exception:
            pass
        return ret


class ServiceCreateSerializer(serializers.ModelSerializer):
    """
    Create serializer that accepts only preferred_date (date-only).
    If preferred_date is omitted or null, we default to today's date.
    """
    service_type = serializers.CharField(required=False, allow_null=True)
    preferred_date = serializers.DateField(required=False, allow_null=True)

    class Meta:
        model = Service
        fields = [
            "card", "description", "service_type",
            "preferred_date",
            "visit_type",
        ]

    def validate_card(self, card):
        # ensure card belongs to the user when booking by customer
        request = self.context.get("request")
        if request and getattr(request, "user", None):
            user = request.user
            if user.role == "customer" and card.customer_id != user.id:
                raise serializers.ValidationError("Card does not belong to the authenticated customer.")
        return card

    def validate(self, data):
        """
        - Normalize preferred_date (if None => use today)
        - Validate not in past and within booking window
        - Decide service_type (free/normal) using last-free-service logic:
        a free service is allowed only if the card is under warranty AND
        there was no completed free service in the previous 3 months.
        """
        preferred_date = data.get("preferred_date", None)

        # default to today if omitted or null
        if preferred_date is None:
            booking_date = timezone.localdate()
        else:
            booking_date = preferred_date

        # validate not in past
        today = timezone.localdate()
        if booking_date < today:
            raise serializers.ValidationError("Preferred date cannot be in the past.")

        # validate within booking window
        max_allowed = today + timezone.timedelta(days=BOOKING_WINDOW_DAYS)
        if booking_date > max_allowed:
            raise serializers.ValidationError(f"Preferred date must be within next {BOOKING_WINDOW_DAYS} days.")

        # decide service_type if missing or 'auto'
        svc_type = (data.get("service_type") or "").strip().lower()
        if not svc_type or svc_type == "auto":
            svc_type = "normal"
            card = data.get("card")
            # Use the last-free-service rule instead of fixed milestones
            if card and getattr(card, "warranty_start_date", None) and getattr(card, "warranty_end_date", None):
                try:
                    is_free_allowed = booking_is_eligible_for_free(card, booking_date)
                    svc_type = "free" if is_free_allowed else "normal"
                except Exception:
                    # on any error, fall back to normal (safe default)
                    svc_type = "normal"
            else:
                svc_type = "normal"
            data["service_type"] = svc_type

        # ensure we store the final preferred_date (never leave None)
        data["preferred_date"] = booking_date

        return data


    def create(self, validated_data):
        request = self.context.get("request", None)
        user = request.user if request else None

        service = Service.objects.create(
            card=validated_data["card"],
            requested_by=user,
            service_type=validated_data.get("service_type", "normal"),
            description=validated_data.get("description", "") or "",
            preferred_date=validated_data.get("preferred_date", timezone.localdate()),
            visit_type=validated_data.get("visit_type", "onsite"),
            created_by=user if user is not None else None,
        )
        return service
    
    
from django.utils import timezone
from rest_framework import serializers

class ServiceAdminCreateSerializer(serializers.ModelSerializer):
    """
    Admin creates service:
    - status is ALWAYS set to 'assigned'
    - status is NOT accepted from request payload
    """

    requested_by = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.filter(role="customer"),
        required=True
    )

    assigned_to = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.filter(role="worker"),
        required=True
    )

    preferred_date = serializers.DateField(required=False, allow_null=True)
    scheduled_at = serializers.DateField(required=False, allow_null=True)  # ✅ DATE ONLY

    class Meta:
        model = Service
        fields = [
            "card",
            "description",
            "service_type",
            "preferred_date",
            "scheduled_at",   # ✅ added
            "visit_type",
            "requested_by",
            "assigned_to",
        ]

    def validate(self, data):
        today = timezone.localdate()

        # Default preferred_date → today
        if not data.get("preferred_date"):
            data["preferred_date"] = today

        # Prevent past preferred_date
        if data["preferred_date"] < today:
            raise serializers.ValidationError(
                {"preferred_date": "Preferred date cannot be in the past."}
            )

        # Default scheduled_at → preferred_date
        if not data.get("scheduled_at"):
            data["scheduled_at"] = data["preferred_date"]

        # Prevent past scheduled_at
        if data["scheduled_at"] < today:
            raise serializers.ValidationError(
                {"scheduled_at": "Scheduled date cannot be in the past."}
            )

        return data

    def create(self, validated_data):
        request = self.context.get("request")
        admin_user = request.user if request else None

        service = Service.objects.create(
            card=validated_data["card"],
            requested_by=validated_data["requested_by"],
            assigned_to=validated_data["assigned_to"],
            service_type=validated_data.get("service_type", "normal"),
            description=validated_data.get("description", "") or "",
            preferred_date=validated_data["preferred_date"],
            scheduled_at=validated_data["scheduled_at"],  # ✅ DATE
            visit_type=validated_data.get("visit_type", "onsite"),

            # 🔥 FORCE STATUS
            status="assigned",
            created_by=admin_user,
        )

        return service


class IndustrialAMCSerializer(serializers.ModelSerializer):

    class Meta:
        model = IndustrialAMC
        fields = "__all__"
        read_only_fields = ("id", "created_by", "created_at")

    def validate_card(self, card):

        if not card.customer.is_industrial:
            raise serializers.ValidationError(
                "Selected card does not belong to industrial customer"
            )

        return card

    def create(self, validated_data):

        request = self.context.get("request")
        admin = request.user if request else None

        return IndustrialAMC.objects.create(
            created_by=admin,
            **validated_data
        )
