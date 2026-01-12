# reminders/views.py

from rest_framework import generics
from .models import AdminReminder
from .serializers import AdminReminderSerializer


class AdminReminderListCreateView(generics.ListCreateAPIView):
    queryset = AdminReminder.objects.select_related('customer')
    serializer_class = AdminReminderSerializer


class AdminReminderDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = AdminReminder.objects.select_related('customer')
    serializer_class = AdminReminderSerializer
