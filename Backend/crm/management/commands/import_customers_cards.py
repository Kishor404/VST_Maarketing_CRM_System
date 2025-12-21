# crm/management/commands/import_customers_cards.py

import pandas as pd
from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils.text import slugify

from user.models import User
from crm.models import Card


class Command(BaseCommand):
    help = "Import customers and cards from Excel file"

    def add_arguments(self, parser):
        parser.add_argument("file", type=str, help="Path to Excel file")

    def normalize_phone(self, phone):
        phone = str(phone).strip()
        phone = phone.replace(" ", "").replace("-", "")
        phone = phone.lstrip("0")

        if not phone.startswith("+"):
            phone = "+91" + phone
        return phone

    @transaction.atomic
    def handle(self, *args, **kwargs):
        file_path = kwargs["file"]

        df = pd.read_excel(file_path)

        created_users = 0
        existing_users = 0
        created_cards = 0

        for idx, row in df.iterrows():
            try:
                phone = self.normalize_phone(row["phone"])
                name = str(row["name"]).strip()
                address = str(row["address"]).strip()
                city = str(row["city"]).strip()
                postal_code = str(row["postal_code"]).strip()
                region = str(row["region"]).strip()
                password = str(row["password"]).strip()

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
                    user.set_password(password)
                    user.save()
                    created_users += 1
                else:
                    existing_users += 1

                # 2️⃣ CREATE CARD
                Card.objects.create(
                    model=str(row["model"]).strip(),
                    customer=user,
                    customer_name=str(row["customer_name"]).strip(),
                    card_type=str(row["card_type"]).strip(),
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

        self.stdout.write(self.style.SUCCESS("🎉 Import completed"))
        self.stdout.write(f"✔ Customers created: {created_users}")
        self.stdout.write(f"✔ Existing customers reused: {existing_users}")
        self.stdout.write(f"✔ Cards created: {created_cards}")
