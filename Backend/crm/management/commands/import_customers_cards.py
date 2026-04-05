import pandas as pd
import re
from django.core.management.base import BaseCommand
from django.db import transaction

from user.models import User
from crm.models import Card
from datetime import date

class Command(BaseCommand):
    help = "Import industrial customers and cards from Excel"

    def add_arguments(self, parser):
        parser.add_argument("file", type=str, help="Path to Excel file")

    # -----------------------------
    # Helpers
    # -----------------------------
    def clean(self, val):
        if pd.isna(val):
            return ""
        return str(val).strip()

    def normalize_phone(self, phone):
        phone = self.clean(phone)

        if not phone:
            return None  # ✅ phone optional

        phone = re.sub(r"\D", "", phone)

        if phone.startswith("91") and len(phone) > 10:
            phone = phone[-10:]

        if len(phone) != 10:
            return None  # ✅ ignore invalid instead of crash

        return "+91" + phone

    def parse_date(self, date_val):
        if pd.isna(date_val):
            return date.today()  # ✅ fallback

        parsed = pd.to_datetime(date_val, dayfirst=True, errors="coerce")

        if pd.isna(parsed):
            return date.today()  # ✅ fallback

        return parsed.date()

    # -----------------------------
    # Main
    # -----------------------------
    def handle(self, *args, **kwargs):

        file_path = kwargs["file"]
        df = pd.read_excel(file_path)

        created_users = 0
        existing_users = 0
        created_cards = 0

        for idx, row in df.iterrows():

            try:
                with transaction.atomic():

                    # -----------------------------
                    # COLUMN MAPPING
                    # -----------------------------
                    name = self.clean(row.get("CUSTOMER NAME"))
                    city = self.clean(row.get("PLACE"))
                    model = self.clean(row.get("MODEL"))
                    phone_raw = row.get("CONTACT NO")
                    installation = self.parse_date(row.get("DATE OF INSTALLATION"))

                    # warranty same as installation
                    warranty_start = installation
                    warranty_end = installation

                    phone = self.normalize_phone(phone_raw)

                    # -----------------------------
                    # USER
                    # -----------------------------
                    user_filter = {"phone": phone} if phone else {"name": name}

                    user, created = User.objects.get_or_create(
                        **user_filter,
                        defaults={
                            "name": name,
                            "address": city,
                            "city": city,
                            "postal_code": "626102",
                            "region": "rajapalayam",
                            "role": "customer",
                            "is_industrial": True, 
                        },
                    )

                    if created:
                        user.set_password("abc12345")
                        user.save(update_fields=["password"])
                        created_users += 1
                    else:
                        existing_users += 1

                    # -----------------------------
                    # DUPLICATE CHECK
                    # -----------------------------
                    if Card.objects.filter(
                        customer=user,
                        model=model,
                        warranty_start_date=warranty_start,
                    ).exists():

                        self.stderr.write(
                            f"⚠️ Row {idx + 1} skipped (duplicate card)"
                        )
                        continue

                    # -----------------------------
                    # CREATE CARD
                    # -----------------------------
                    Card.objects.create(
                        model=model,
                        customer=user,
                        customer_name=name,
                        card_type="normal",
                        address=city,
                        city=city,
                        postal_code="626102",
                        region="rajapalayam",
                        date_of_installation=installation,
                        warranty_start_date=warranty_start,
                        warranty_end_date=warranty_end,
                    )

                    created_cards += 1

            except Exception as e:
                self.stderr.write(f"❌ Row {idx + 1} failed: {e}")
                continue

        self.stdout.write(self.style.SUCCESS("🎉 Import completed"))
        self.stdout.write(f"✔ Customers created: {created_users}")
        self.stdout.write(f"✔ Existing customers reused: {existing_users}")
        self.stdout.write(f"✔ Cards created: {created_cards}")
