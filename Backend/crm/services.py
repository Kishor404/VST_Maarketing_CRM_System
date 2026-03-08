import logging
import requests
from datetime import timezone, timedelta
from django.conf import settings


logger = logging.getLogger(__name__)

IST = timezone(timedelta(hours=5, minutes=30))

def notify_admin(msg, staff_phone):

    print("✨ MESSAGE SENT", msg)

    url = "https://web.chatinfy.in/api/sendmediamessage.php"


    params = {
        "LicenseNumber": settings.CHATINFY_LICENSE_NUMBER,
        "APIKey": settings.CHATINFY_API_KEY,
        "Contact": staff_phone,
        "Message": msg,
        "Type": "text",
        "HeaderType": "text",
        "HeaderText": "Reminder Alert",
        "HeaderURL": "",
    }

    try:
        response = requests.get(url, params=params, timeout=10)
        response.raise_for_status()

        logger.info("Reminder notification sent successfully")

    except requests.exceptions.RequestException as e:
        logger.error("Failed to send reminder notification: %s", e)