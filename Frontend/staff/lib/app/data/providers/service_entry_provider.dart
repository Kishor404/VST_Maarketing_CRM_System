import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/api/api_exceptions.dart';
import '../models/service_entry_model.dart';

class ServiceEntryProvider {
  final ApiClient _apiClient;

  ServiceEntryProvider(this._apiClient);

  /// ============================
  /// Get entries for a service
  /// ============================
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

      final List data = response.data is List
          ? response.data
          : response.data['results'];

      return data
          .map((e) => ServiceEntryModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// ============================
  /// Create Service Entry
  /// ============================
  Future<ServiceEntryModel> createServiceEntry({
    required int serviceId,
    required String workDetail,
    required String visitType,
    String? actualComplaint,
    List<PartReplacedModel>? partsReplaced,
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
          "parts_replaced":
              partsReplaced?.map((p) => p.toJson()).toList() ?? [],
          "amount_charged": amountCharged,
          "next_service_date": nextServiceDate,
        },
      );
      debugPrint(response.data);
      return ServiceEntryModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}