import requests
from django.conf import settings


def send_otp(phone: str, otp: str):
    url = "https://control.msg91.com/api/v5/flow/"

    payload = {
        "template_id": settings.MSG91_TEMPLATE_ID,
        "short_url": "0",
        "recipients": [
            {
                "mobiles": f"91{phone}",
                "number": str(otp)
            }
        ]
    }

    headers = {
        "authkey": settings.MSG91_AUTH_KEY,
        "Content-Type": "application/json"
    }

    response = requests.post(
        url,
        json=payload,
        headers=headers,
        timeout=15
    )

    response.raise_for_status()

    return response.json()


import requests
from django.conf import settings


def send_reminder(phone, message):
    url = "https://control.msg91.com/api/v5/flow/"

    payload = {
        "template_id": settings.MSG91_REMINDER_TEMPLATE_ID,
        "short_url": "0",
        "recipients": [
            {
                "mobiles": f"91{phone}",
                "var1": message
            }
        ]
    }

    headers = {
        "authkey": settings.MSG91_AUTH_KEY,
        "Content-Type": "application/json",
    }

    response = requests.post(
        url,
        json=payload,
        headers=headers,
        timeout=15
    )

    print("Status:", response.status_code)
    print("Response:", response.text)

    response.raise_for_status()
    return response.json()