# crm/utils.py
import hashlib
import hmac
import secrets
from datetime import timedelta
from django.utils import timezone
from datetime import datetime
from django.utils.dateparse import parse_datetime as django_parse_datetime

from django.conf import settings

OTP_TTL_SECONDS = getattr(settings, "CRM_OTP_TTL_SECONDS", 10 * 60)  # 10 minutes default
OTP_HASH_SALT = getattr(settings, "CRM_OTP_HASH_SALT", "vst-crm-salt")  # change in prod env

def generate_otp(length: int = 4) -> str:
    # numeric OTP
    range_max = 10 ** length
    n = secrets.randbelow(range_max)
    return str(n).zfill(length)

def hash_otp(otp: str) -> str:
    # HMAC-SHA256 with salt
    return hmac.new(OTP_HASH_SALT.encode(), otp.encode(), hashlib.sha256).hexdigest()

def verify_otp_hash(otp: str, otp_hash: str) -> bool:
    return hmac.compare_digest(hash_otp(otp), otp_hash)

def otp_expiry_time() -> timezone.datetime:
    return timezone.now() + timedelta(seconds=OTP_TTL_SECONDS)

from django.utils.dateparse import parse_date as django_parse_date
from datetime import date

def parse_iso_date(value):
    if value is None:
        return None
    if isinstance(value, date):
        return value
    if isinstance(value, str):
        d = django_parse_date(value)
        if d is None:
            raise ValueError("Invalid date format; expected YYYY-MM-DD")
        return d
    raise ValueError("Unsupported date value")


def parse_iso_datetime(value):
    """
    Accepts a datetime, date, or ISO string and returns an *aware* datetime in current timezone.
    Raises ValueError if it cannot parse.
    """
    if value is None:
        return None

    # if already a datetime
    if isinstance(value, datetime):
        dt = value
    elif isinstance(value, str):
        # try Django's parser which handles many ISO variants
        dt = django_parse_datetime(value)
        if dt is None:
            # try Python 3.11+ fromisoformat fallback (less flexible)
            try:
                dt = datetime.fromisoformat(value)
            except Exception:
                raise ValueError(f"Could not parse datetime from string: {value!r}")
    else:
        raise ValueError(f"Unsupported datetime value: {type(value)}")

    # If date-only (no time) parse_datetime may return date? unlikely — ensure it's datetime
    if not isinstance(dt, datetime):
        raise ValueError("Parsed value is not a datetime")

    # If naive, make aware in current timezone
    if timezone.is_naive(dt):
        dt = timezone.make_aware(dt, timezone.get_current_timezone())

    return dt

# crm/utils.py
from datetime import date
from django.utils import timezone
try:
    from dateutil.relativedelta import relativedelta
except Exception:
    # small fallback (same as earlier)
    def add_months(d, months):
        year = d.year + (d.month + months - 1) // 12
        month = (d.month + months - 1) % 12 + 1
        mdays = [31, 29 if (year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)) else 28,
                 31,30,31,30,31,31,30,31,30,31]
        day = min(d.day, mdays[month - 1])
        return date(year, month, day)
    class relativedelta:
        def __init__(self, months=0): self.months = months
        def __radd__(self, other): return add_months(other, self.months)

def card_last_free_service_date(card):
    """
    Returns a date object of the most recent completed free service for the given card,
    or None if none exists.
    Prefers ServiceEntry.created_at if you store completed entries; fallback to Service.completed_at or Service.updated_at.
    """
    from .models import Service, ServiceEntry
    from django.db.models import Q

    # Try ServiceEntry first (if you create entries on completion)
    se = ServiceEntry.objects.filter(service__card=card, service__service_type="free").order_by("-created_at").first()
    if se:
        return se.created_at.date()

    # Fallback to Service row where status == 'completed' and service_type == 'free'
    svc = Service.objects.filter(card=card, service_type="free", status="completed").order_by("-updated_at", "-created_at").first()
    if svc:
        # prefer an explicit completed_at timestamp if you added one
        if getattr(svc, "completed_at", None):
            return svc.completed_at.date()
        # else use updated_at or created_at
        return (svc.updated_at or svc.created_at).date()
    return None

def booking_is_eligible_for_free(card, booking_date):
    """
    booking_date: datetime.date
    Returns True when the card is under warranty and last free service was at least 3 months ago (or never).
    """
    if not getattr(card, "warranty_start_date", None) or not getattr(card, "warranty_end_date", None):
        return False
    # inside warranty
    if not (card.warranty_start_date <= booking_date <= card.warranty_end_date):
        return False

    last_free = card_last_free_service_date(card)  # returns date or None
    if not last_free:
        # no prior free → allow if booking_date within warranty
        return True

    # require booking_date >= last_free + 3 months (use relativedelta)
    from datetime import date as _date
    try:
        next_allowed = last_free + relativedelta(months=3)
    except Exception:
        # fallback to basic month arithmetic if relativedelta missing
        next_allowed = add_months(last_free, 3)

    return booking_date >= next_allowed
