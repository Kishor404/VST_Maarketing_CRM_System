import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/api/api_exceptions.dart';
import '../models/feedback_model.dart';

class FeedbackProvider {
  final ApiClient _apiClient;

  FeedbackProvider(this._apiClient);

  /// ============================
  /// List Feedbacks (Staff)
  /// ============================

  /// Get feedbacks related to services handled by logged-in staff
  /// GET /api/crm/feedbacks/
  Future<List<FeedbackModel>> getMyFeedbacks() async {
    
    final data =
        await _apiClient.get(ApiEndpoints.feedbacks);

    if (data is! List) {
      throw Exception('Invalid feedback response');
    }

    return data
        .map((e) => FeedbackModel.fromJson(e))
        .toList();
  }

  /// ============================
  /// Feedback by Service (Optional)
  /// ============================

  /// If backend supports filtering
  /// GET /api/crm/feedbacks/?service=<service_id>
  Future<List<FeedbackModel>> getFeedbacksByService(
    int serviceId,
  ) async {
    try {
      final Response response = await _apiClient.get(
        ApiEndpoints.feedbacks,
        queryParameters: {
          "service": serviceId,
        },
      );

      final List data = response.data as List;
      return data.map((e) => FeedbackModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
