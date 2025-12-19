import 'package:get/get.dart';

import '../../data/providers/feedback_provider.dart';
import '../../data/repositories/feedback_repository.dart';
import 'feedback_controller.dart';

class FeedbackBinding extends Bindings {
  @override
  void dependencies() {
    /// Provider
    Get.lazyPut<FeedbackProvider>(
      () => FeedbackProvider(),
      fenix: true,
    );

    /// Repository
    Get.lazyPut<FeedbackRepository>(
      () => FeedbackRepository(Get.find<FeedbackProvider>()),
      fenix: true,
    );

    /// Controller
    Get.lazyPut<FeedbackController>(
      () => FeedbackController(
        feedbackRepository: Get.find<FeedbackRepository>(),
      ),
    );
  }
}
