import 'package:get/get.dart';
import '../../core/utils/app_snackbar.dart';
import '../../routes/app_routes.dart';
import '../../data/repositories/feedback_repository.dart';

class FeedbackController extends GetxController {
  final FeedbackRepository feedbackRepository;

  FeedbackController({required this.feedbackRepository});

  final loading = false.obs;

  /// Submit feedback for a completed service
  Future<void> submitFeedback({
    required int serviceId,
    required int rating,
    required String comments,
  }) async {
    try {
      loading.value = true;

      await feedbackRepository.submitFeedback(
        serviceId: serviceId,
        rating: rating,
        comments: comments,
      );

      AppSnackbar.success(
        'Thank you',
        'Your feedback has been submitted',
      );

      /// 🔑 VERY IMPORTANT
      Get.offAllNamed(AppRoutes.HOME);
    } catch (e) {
      AppSnackbar.error(
        'Error',
        'Unable to submit feedback',
      );
    } finally {
      loading.value = false;
    }
  }
}
