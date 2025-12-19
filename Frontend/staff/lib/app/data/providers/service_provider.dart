import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../models/service_model.dart';

class ServiceProvider {
  final ApiClient _apiClient;

  ServiceProvider(this._apiClient);

  /// ============================
  /// Assigned Services
  /// ============================
  /// GET /api/crm/services/?status=assigned
  Future<List<ServiceModel>> getAssignedServices() async {
    final data = await _apiClient.get(
      ApiEndpoints.services,
      queryParameters: {"status": "assigned"},
    );

    if (data is! List) {
      throw Exception('Invalid assigned services response');
    }
    return data
        .map<ServiceModel>(
            (e) => ServiceModel.fromJson(e))
        .toList();
  }

  /// ============================
  /// Completed Services
  /// ============================
  /// GET /api/crm/services/?status=completed
  Future<List<ServiceModel>> getCompletedServices() async {
    final data = await _apiClient.get(
      ApiEndpoints.services,
      queryParameters: {"status": "completed"},
    );

    if (data is! List) {
      throw Exception('Invalid completed services response');
    }

    return data
        .map<ServiceModel>(
            (e) => ServiceModel.fromJson(e))
        .toList(); 
    }

  /// ============================
  /// Service Detail
  /// ============================
  /// GET /api/crm/services/{id}/
  Future<ServiceModel> getServiceDetail(int serviceId) async {
    final data = await _apiClient.get(
      ApiEndpoints.serviceDetail(serviceId),
    );

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid service detail response');
    }

    return ServiceModel.fromJson(data);
  }

  /// ============================
  /// OTP Flow
  /// ============================

  /// POST /api/crm/services/{id}/request_otp/
  Future<void> requestOtp(int serviceId, {required String phone}) async {
    await _apiClient.post(
      ApiEndpoints.requestOtp(serviceId),
      data: {
        "phone": phone,
      },
    );
  }

  /// POST /api/crm/services/{id}/verify_otp/
  Future<void> verifyOtpAndComplete({
    required int serviceId,
    required String otp,
    required Map<String, dynamic> payload,
  }) async {
    await _apiClient.post(
      ApiEndpoints.verifyOtp(serviceId),
      data: {
        "otp": otp,
        ...payload,
      },
    );
  }
}
