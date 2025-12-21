import pandas as pd
import re
from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils.timezone import make_aware

from user.models import User
from crm.models import Card


class Command(BaseCommand):
    help = "Import customers and cards from Excel file"

    def add_arguments(self, parser):
        parser.add_argument("file", type=str, help="Path to Excel file")

    # -----------------------------
    # Helpers
    # -----------------------------
    def clean(self, val):
        """Handle NaN / None safely"""
        if pd.isna(val):
            return ""
        return str(val).strip()

    def normalize_phone(self, phone):
        """
        Normalize Indian phone numbers:
        - Remove spaces, symbols
        - Ensure 10 digits
        - Convert to +91XXXXXXXXXX
        """
        phone = self.clean(phone)

        # Remove all non-digits
        phone = re.sub(r"\D", "", phone)

        # Remove leading country code if exists
        if phone.startswith("91") and len(phone) > 10:
            phone = phone[-10:]

        if len(phone) != 10:
            raise ValueError(f"Invalid phone number: {phone}")

        return "+91" + phone

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
                with transaction.atomic():  # ✅ PER-ROW TRANSACTION

                    phone = self.normalize_phone(row["phone"])
                    name = self.clean(row["name"])
                    address = self.clean(row["address"])
                    city = self.clean(row["city"])
                    postal_code = self.clean(row["postal_code"])
                    region = self.clean(row["region"])
                    password = self.clean(row["password"])

                    # 1️⃣ GET OR CREATE CUSTOMER
                    user, created = User.objects.get_or_create(
                        phone=phone,
                        defaults={
                            "name": name,
                            "address": address,
                            "city": city,
                            "postal_code": postal_code,
                            "region": region,
                            "role": "customer",
                        }
                    )

                    if created:
                        user.set_password(password or "abc12345")
                        user.save(update_fields=["password"])
                        created_users += 1
                    else:
                        existing_users += 1

                    # 2️⃣ CREATE CARD
                    Card.objects.create(
                        model=self.clean(row["model"]),
                        customer=user,
                        customer_name=self.clean(row["customer_name"]),
                        card_type=self.clean(row["card_type"]) or "normal",
                        address=address,
                        city=city,
                        postal_code=postal_code,
                        region=region,
                        date_of_installation=row["date_of_installation"],
                        warranty_start_date=row["warranty_start_date"],
                        warranty_end_date=row["warranty_end_date"],
                    )

                    created_cards += 1

            except Exception as e:
                self.stderr.write(
                    f"❌ Row {idx + 1} failed: {e}"
                )
                continue

        self.stdout.write(self.style.SUCCESS("🎉 Import completed"))
        self.stdout.write(f"✔ Customers created: {created_users}")
        self.stdout.write(f"✔ Existing customers reused: {existing_users}")
        self.stdout.write(f"✔ Cards created: {created_cards}")
