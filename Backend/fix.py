from crm.models import Service
from crm.utils import parse_iso_datetime
from django.db import transaction
from django.core.exceptions import ValidationError

bad = []
for s in Service.objects.all():
    val = s.scheduled_at
    if isinstance(val, str):
        bad.append(s.id)
print("found string scheduled_at for service ids:", bad)

# Fix them (best-effort). This parses ISO strings to aware datetimes.
fixed = 0
with transaction.atomic():
    for sid in bad:
        s = Service.objects.get(id=sid)
        try:
            parsed = parse_iso_datetime(s.scheduled_at)
            s.scheduled_at = parsed
            s.save(update_fields=["scheduled_at"])
            fixed += 1
        except Exception as e:
            print("failed to parse for service", sid, "error:", e)
print("fixed count:", fixed)
