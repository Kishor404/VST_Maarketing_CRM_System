from rest_framework import generics
from rest_framework.permissions import IsAuthenticated

from .models import AdminReminder
from .serializers import AdminReminderSerializer

from user.permissions import IsAdmin


class AdminReminderListCreateView(generics.ListCreateAPIView):

    serializer_class = AdminReminderSerializer
    permission_classes = [IsAuthenticated, IsAdmin]

    def get_queryset(self):
        return AdminReminder.objects.select_related(
            "customer"
        ).filter(
            region=self.request.user.region
        )

    def perform_create(self, serializer):

        customer = serializer.validated_data.get("customer")

        # ==========================================
        # MODE 1: EXISTING CUSTOMER
        # ==========================================
        if customer:
            serializer.save(
                region=customer.region
            )
            return

        # ==========================================
        # MODE 2: NEW / EXTERNAL CONTACT
        # ==========================================
        serializer.save(
            region=self.request.user.region
        )


class AdminReminderDetailView(
    generics.RetrieveUpdateDestroyAPIView
):

    serializer_class = AdminReminderSerializer
    permission_classes = [IsAuthenticated, IsAdmin]

    def get_queryset(self):
        return AdminReminder.objects.select_related(
            "customer"
        ).filter(
            region=self.request.user.region
        )

    def perform_update(self, serializer):

        customer = serializer.validated_data.get("customer")

        # Existing customer reminder
        if customer:
            serializer.save(
                region=customer.region
            )
            return

        # External/new customer reminder
        serializer.save(
            region=self.request.user.region
        )