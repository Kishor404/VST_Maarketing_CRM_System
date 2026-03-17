import logging
import requests
from django.conf import settings

logger = logging.getLogger(__name__)


def notify_admin(phone, message):
    """Send WhatsApp notification using Chatinfy API"""

    contact_phone = str(phone)

    url = "https://web.chatinfy.in/api/sendmediamessage.php"

    params = {
        "LicenseNumber": settings.CHATINFY_LICENSE_NUMBER,
        "APIKey": settings.CHATINFY_API_KEY,
        "Contact": contact_phone,
        "Message": message,
        "Type": "text",
        "HeaderType": "text",
        "HeaderText": "Reminder Alert",
        "HeaderURL": "",
    }

    try:
        logger.info("Sending notification to %s", contact_phone)

        response = requests.get(url, params=params, timeout=10)

        response.raise_for_status()

        logger.info("Notification sent successfully: %s", response.text)

        return response.json() if response.headers.get("Content-Type") == "application/json" else response.text

    except requests.exceptions.RequestException as e:
        logger.error("Failed to send notification: %s", str(e))
        return None