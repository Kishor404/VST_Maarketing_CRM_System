import 'package:dio/dio.dart' as dio;

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';

class ServiceProvider {
  final ApiClient _apiClient = ApiClient();

  /// -----------------------------
  /// GET /api/crm/services/
  /// -----------------------------
  Future<List<dynamic>> fetchServices({
    Map<String, dynamic>? query,
  }) async {
    final dio.Response response = await _apiClient.get(
      ApiEndpoints.services,
      queryParameters: query,
    );
    return response.data as List<dynamic>;
  }

  /// -----------------------------
  /// GET /api/crm/services/{id}/
  /// -----------------------------
  Future<Map<String, dynamic>> fetchServiceDetail(int serviceId) async {
    final dio.Response response = await _apiClient.get(
      '${ApiEndpoints.services}$serviceId/',
    );
    return response.data as Map<String, dynamic>;
  }

  /// -----------------------------
  /// POST /api/crm/services/
  /// -----------------------------
  Future<void> bookService({
    required int cardId,
    required String description,
    required DateTime preferredDate,
  }) async {
    await _apiClient.post(
      ApiEndpoints.services,
      data: {
        'card': cardId,
        'description': description,
        'preferred_date':
            preferredDate.toIso8601String().split('T').first,

        /// backend enum: normal | free
        'service_type': 'normal',
        'visit_type':'C'
      },
    );
  }
}
