# reminders/views.py

from rest_framework import generics
from .models import AdminReminder
from .serializers import AdminReminderSerializer

from user.permissions import IsAdmin
from rest_framework.permissions import IsAuthenticated

class AdminReminderListCreateView(
    generics.ListCreateAPIView
):
    serializer_class = AdminReminderSerializer
    permission_classes = [IsAuthenticated, IsAdmin]

    def get_queryset(self):
        return AdminReminder.objects.select_related(
            "customer"
        ).filter(
            region=self.request.user.region
        )

    def perform_create(self, serializer):
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