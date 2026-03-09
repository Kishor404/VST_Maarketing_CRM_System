import pandas as pd
import re
from django.core.management.base import BaseCommand
from django.db import transaction

from user.models import User
from crm.models import Card


class Command(BaseCommand):
    help = "Import customers and cards from cleaned Excel file"

    def add_arguments(self, parser):
        parser.add_argument("file", type=str, help="Path to clean Excel file")

    # -----------------------------
    # Helpers
    # -----------------------------
    def clean(self, val):
        if pd.isna(val):
            return ""
        return str(val).strip()

    def normalize_phone(self, phone):
        phone = self.clean(phone)

        phone = re.sub(r"\D", "", phone)

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
                with transaction.atomic():

                    phone = self.normalize_phone(row["phone"])

                    name = self.clean(row["name"])
                    address = self.clean(row["address"])
                    city = self.clean(row["city"])
                    model = self.clean(row["model"])

                    warranty_start = pd.to_datetime(
                        row["warranty_from"], errors="coerce"
                    )

                    warranty_end = pd.to_datetime(
                        row["warranty_to"], errors="coerce"
                    )

                    warranty_start = (
                        warranty_start.date() if not pd.isna(warranty_start) else None
                    )

                    warranty_end = (
                        warranty_end.date() if not pd.isna(warranty_end) else None
                    )

                    installation = warranty_start

                    # -----------------------------
                    # USER
                    # -----------------------------
                    user, created = User.objects.get_or_create(
                        phone=phone,
                        defaults={
                            "name": name,
                            "address": address,
                            "city": city,
                            "postal_code": "626102",
                            "region": "rajapalayam",
                            "role": "customer",
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
                        address=address,
                        city=city,
                        postal_code="626102",
                        region="rajapalayam",
                        date_of_installation=installation,
                        warranty_start_date=warranty_start,
                        warranty_end_date=warranty_end,
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