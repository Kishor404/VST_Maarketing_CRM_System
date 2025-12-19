import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/api/api_exceptions.dart';
import '../models/service_entry_model.dart';

class ServiceEntryProvider {
  final ApiClient _apiClient;

  ServiceEntryProvider(this._apiClient);

  /// ============================
  /// List Service Entries
  /// ============================

  /// Get service entries for a given service
  /// GET /api/crm/service-entries/?service=<service_id>
  Future<List<ServiceEntryModel>> getEntriesByService(
    int serviceId,
  ) async {
    try {
      final Response response = await _apiClient.get(
        ApiEndpoints.serviceEntries,
        queryParameters: {
          "service": serviceId,
        },
      );

      final List data = response.data as List;
      return data
          .map((e) => ServiceEntryModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// ============================
  /// Create Service Entry (Optional)
  /// ============================

  /// This is OPTIONAL.
  /// Normally service entry is created during OTP verification.
  /// Use this only if backend allows manual entry creation.
  ///
  /// POST /api/crm/service-entries/
  Future<ServiceEntryModel> createServiceEntry({
    required int serviceId,
    required String workDetail,
    required String visitType,
    String? actualComplaint,
    List<Map<String, dynamic>>? partsReplaced,
    double amountCharged = 0,
    String? nextServiceDate,
  }) async {
    try {
      final Response response = await _apiClient.post(
        ApiEndpoints.serviceEntries,
        data: {
          "service": serviceId,
          "work_detail": workDetail,
          "visit_type": visitType,
          "actual_complaint": actualComplaint,
          "parts_replaced": partsReplaced ?? [],
          "amount_charged": amountCharged,
          "next_service_date": nextServiceDate,
        },
      );

      return ServiceEntryModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
