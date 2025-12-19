import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';

class FeedbackProvider {
  final ApiClient _apiClient = ApiClient();

  /// -----------------------------
  /// POST /api/crm/feedbacks/
  /// -----------------------------
  Future<void> submitFeedback({
    required int serviceId,
    required int rating,
    required String comments,
  }) async {
    await _apiClient.post(
      ApiEndpoints.feedback,
      data: {
        'service': serviceId,
        'rating': rating,
        'comments': comments,
      },
    );
  }
}
