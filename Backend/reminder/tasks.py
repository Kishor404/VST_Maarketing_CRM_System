from celery import shared_task
from django.utils import timezone
from django.utils.dateparse import parse_datetime
from reminder.models import AdminReminder
from reminder.services import notify_admin
import logging
from django.conf import settings

logger = logging.getLogger(__name__)

@shared_task(bind=True, autoretry_for=(Exception,), retry_backoff=30, retry_kwargs={"max_retries": 5})
def process_admin_reminders(self):
    now = timezone.now()  # UTC
    logger.info(f"NOW (UTC): {now}")

    reminders = AdminReminder.objects.filter(is_active=True)

    for reminder in reminders:
        for date_str in reminder.reminder_dates:
            reminder_time = parse_datetime(date_str)

            if not reminder_time:
                continue

            # 🔥 FORCE timezone awareness
            if timezone.is_naive(reminder_time):
                reminder_time = timezone.make_aware(
                    reminder_time,
                    timezone.get_default_timezone()
                )

            # 🔥 CONVERT TO UTC
            reminder_time = reminder_time.astimezone(timezone.utc)

            logger.info(f"CHECKING: {reminder_time} <= {now}")

            if reminder_time <= now and date_str not in reminder.triggered_dates:
                notify_admin(reminder, reminder_time)
                logger.info("🔥 REMINDER TRIGGERED 🔥")

                logger.info(settings.CHATINFY_LICENSE_NUMBER)
                logger.info(settings.CHATINFY_API_KEY)

                reminder.triggered_dates.append(date_str)
                reminder.save(update_fields=["triggered_dates"])
