import logging
import requests
from datetime import timezone, timedelta
from django.conf import settings


logger = logging.getLogger(__name__)

IST = timezone(timedelta(hours=5, minutes=30))

def notify_admin(reminder, trigger_time):

    if trigger_time.tzinfo is None:
        trigger_time = trigger_time.replace(tzinfo=timezone.utc)

    trigger_time_ist = trigger_time.astimezone(IST)

    formatted_time = trigger_time_ist.strftime("%d-%m-%Y %I:%M %p")

    print("✨ REMINDER", reminder.message, trigger_time)

    url = "https://web.chatinfy.in/api/sendmediamessage.php"
    msg = f"{reminder.message} for {reminder.customer.name} ( {reminder.customer_id} )."
    params = {
        "LicenseNumber": settings.CHATINFY_LICENSE_NUMBER,
        "APIKey": settings.CHATINFY_API_KEY,
        "Contact": settings.CHATINFY_CONTACT,
        "Message": msg,
        "Type": "text",
        "HeaderType": "text",
        "HeaderText": "Reminder Alert",
        "HeaderURL": "",
        "FooterText": f"Trigger Time (IST): {formatted_time}",
    }

    try:
        response = requests.get(url, params=params, timeout=10)
        response.raise_for_status()

        logger.info("Reminder notification sent successfully")
        logger.debug("API Response: %s", response.text)

    except requests.exceptions.RequestException as e:
        logger.error("Failed to send reminder notification: %s", e)
