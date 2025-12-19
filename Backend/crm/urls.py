# crm/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .views import (
    CardViewSet, ServiceViewSet, ServiceEntryViewSet,
    FeedbackViewSet, AttendanceViewSet,
    WarrantyReportView, UpcomingServicesReportView,
    AutoAssignRunView, ExportServicesCSVView, DevSendOtpView, WarrantyReportByCardView
)

router = DefaultRouter()
router.register(r"cards", CardViewSet, basename="card")
router.register(r"services", ServiceViewSet, basename="service")
router.register(r"service-entries", ServiceEntryViewSet, basename="service-entry")
router.register(r"feedbacks", FeedbackViewSet, basename="feedback")
router.register(r"attendance", AttendanceViewSet, basename="attendance")

urlpatterns = [
    path("", include(router.urls)),

    # Admin reports & utilities
    path("reports/warranty/", WarrantyReportView.as_view(), name="report-warranty"),
    path("reports/upcoming-services/", UpcomingServicesReportView.as_view(), name="report-upcoming-services"),
    path("reports/warranty-report/by_card/",WarrantyReportByCardView.as_view(),name="warranty-report-by-card"),
    path("autoassign/run/", AutoAssignRunView.as_view(), name="autoassign-run"),
    path("admin/export/services/", ExportServicesCSVView.as_view(), name="export-services"),

    # Dev only
    path("test/send-otp/", DevSendOtpView.as_view(), name="dev-send-otp"),
]
