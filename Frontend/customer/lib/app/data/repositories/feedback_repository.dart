import '../providers/feedback_provider.dart';

class FeedbackRepository {
  final FeedbackProvider provider;

  FeedbackRepository(this.provider);

  /// Submit feedback for a completed service
  Future<void> submitFeedback({
    required int serviceId,
    required int rating,
    required String comments,
  }) async {
    await provider.submitFeedback(
      serviceId: serviceId,
      rating: rating,
      comments: comments,
    );
  }
}
