import 'package:get/get.dart';

import '../../data/models/feedback_model.dart';
import '../../data/providers/feedback_provider.dart';
import '../../core/api/api_client.dart';
import '../../core/utils/snackbar.dart';

class FeedbackController extends GetxController {
  final FeedbackProvider _provider = FeedbackProvider(ApiClient());

  final feedbacks = <FeedbackModel>[].obs;
  final loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchFeedbacks();
  }

  Future<void> fetchFeedbacks() async {
    try {
      loading.value = true;
      feedbacks.value = await _provider.getMyFeedbacks();
    } catch (e) {
      AppSnackbar.error(
        title: 'Error',
        message: e.toString(),
      );
    } finally {
      loading.value = false;
    }
  }
}
