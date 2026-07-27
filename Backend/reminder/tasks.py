from celery import shared_task
from django.utils import timezone
from django.utils.dateparse import parse_datetime

from reminder.models import AdminReminder
from utils.msg91 import send_reminder

import logging

logger = logging.getLogger(__name__)


@shared_task(
    bind=True,
    autoretry_for=(Exception,),
    retry_backoff=30,
    retry_kwargs={"max_retries": 5},
)
def process_admin_reminders(self):

    now = timezone.now()

    logger.info(f"NOW (UTC): {now}")

    reminders = AdminReminder.objects.filter(is_active=True)

    for reminder in reminders:

        phone = None
        customer_name = ""

        if reminder.customer:
            phone = reminder.customer.phone
            customer_name = reminder.customer.name
        else:
            phone = reminder.phone
            customer_name = reminder.name

        if not phone:
            logger.warning(
                f"Reminder {reminder.id} skipped. No phone number."
            )
            continue

        for date_str in reminder.reminder_dates:

            reminder_time = parse_datetime(date_str)

            if not reminder_time:
                continue

            if timezone.is_naive(reminder_time):
                reminder_time = timezone.make_aware(
                    reminder_time,
                    timezone.get_default_timezone()
                )

            if reminder_time <= now and date_str not in reminder.triggered_dates:

                try:

                    send_reminder(
                        phone=phone,
                        message=reminder.message,
                    )

                    logger.info(
                        f"Reminder sent to {phone}"
                    )

                    reminder.triggered_dates.append(date_str)
                    reminder.save(update_fields=["triggered_dates"])

                except Exception as e:

                    logger.exception(
                        f"Failed to send reminder {reminder.id}: {e}"
                    )
                    raise