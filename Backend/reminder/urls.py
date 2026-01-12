from django.urls import path
from .views import (
    AdminReminderListCreateView,
    AdminReminderDetailView,
)

urlpatterns = [
    path('admin-reminders/', AdminReminderListCreateView.as_view(), name='admin-reminder-list-create'),
    path('admin-reminders/<int:pk>/', AdminReminderDetailView.as_view(), name='admin-reminder-detail'),
]
