import 'package:get/get.dart';

import '../../data/providers/service_provider.dart';
import '../../data/providers/feedback_provider.dart';
import '../../data/providers/attendance_provider.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/service_model.dart';
import '../../data/models/feedback_model.dart';
import '../../core/api/api_client.dart';
import '../../core/utils/snackbar.dart';

class HomeController extends GetxController {
  final ServiceProvider _serviceProvider =
      ServiceProvider(ApiClient());
  final FeedbackProvider _feedbackProvider =
      FeedbackProvider(ApiClient());
  final AttendanceProvider _attendanceProvider =
      AttendanceProvider(ApiClient());

  /// Dashboard stats
  final totalCompleted = 0.obs;
  final awaitingOtp = 0.obs;
  final averageRating = 0.0.obs;
  final attendanceStatus = 'Not taken'.obs;

  final loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
  }

  /// ============================
  /// Load Dashboard
  /// ============================
  Future<void> loadDashboard() async {
    try {
      loading.value = true;
      
      final results = await Future.wait([
        _serviceProvider.getAssignedServices(),
        _serviceProvider.getCompletedServices(),
        _feedbackProvider.getMyFeedbacks(),
        _attendanceProvider.getTodayAttendance(),
      ]);
      
      final List<ServiceModel> assignedServices =
          results[0] as List<ServiceModel>;

      final List<ServiceModel> completedServices =
          results[1] as List<ServiceModel>;

      final List<FeedbackModel> feedbacks =
          results[2] as List<FeedbackModel>;

      final AttendanceModel attendance =
          results[3] as AttendanceModel;

      /// Completed count
      totalCompleted.value = completedServices.length;

      /// Awaiting OTP count
      awaitingOtp.value = assignedServices
          .where((s) => s.awaitingOtp)
          .length;

      /// Average rating
      if (feedbacks.isNotEmpty) {
        final sum = feedbacks
            .map((f) => f.rating)
            .reduce((a, b) => a + b);

        averageRating.value =
            double.parse((sum / feedbacks.length)
                .toStringAsFixed(1));
      } else {
        averageRating.value = 0.0;
      }

      /// Attendance
      attendanceStatus.value =
          attendance.status ?? 'Not taken';
    } catch (e) {
      print(e);
      AppSnackbar.error(
        title: 'Dashboard Error',
        message: e.toString(),
      );
    } finally {
      loading.value = false;
    }
  }
}
