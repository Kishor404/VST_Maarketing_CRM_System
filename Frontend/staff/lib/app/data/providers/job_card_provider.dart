import '../../core/api/api_client.dart';
import '../models/job_card_model.dart';

class JobCardProvider {
  final ApiClient _apiClient = ApiClient();

  /// =====================================================
  /// GET → My Created Job Cards
  /// Backend filter: ?mine=true
  /// =====================================================
  Future<List<JobCardModel>> getMyJobCards() async {
    final data = await _apiClient.get(
      '/api/crm/job-cards/',
      queryParameters: {
        "mine": true,
      },
    );

    if (data is! List) {
      throw Exception("Invalid My JobCards response");
    }

    return data
        .map<JobCardModel>(
          (e) => JobCardModel.fromJson(e),
        )
        .toList();
  }

  /// =====================================================
  /// GET → Reinstall Pending Job Cards
  /// Backend filter: ?reinstall=true
  /// =====================================================
  Future<List<JobCardModel>> getReinstallJobCards() async {
    final data = await _apiClient.get(
      '/api/crm/job-cards/',
      queryParameters: {
        "reinstall": true,
      },
    );

    if (data is! List) {
      throw Exception("Invalid Reinstall JobCards response");
    }

    return data
        .map<JobCardModel>(
          (e) => JobCardModel.fromJson(e),
        )
        .toList();
  }

  /// =====================================================
  /// GET → Single Job Card Detail
  /// =====================================================
  Future<JobCardModel> getJobCardDetail(int jobCardId) async {
    final data = await _apiClient.get(
      '/api/crm/job-cards/$jobCardId/',
    );

    if (data is! Map<String, dynamic>) {
      throw Exception("Invalid JobCard detail response");
    }

    return JobCardModel.fromJson(data);
  }

  /// =====================================================
  /// POST → Reinstall Part
  /// Calls:
  /// /services/{id}/reinstall/
  /// =====================================================
  Future<Map<String, dynamic>> reinstallPart({
    required int serviceId,
    required List<int> jobCardIds,
    required String otp,
  }) async {

    final data = await _apiClient.post(
      '/api/crm/services/$serviceId/reinstall/',
      data: {
        "otp": otp,
        "job_cards": jobCardIds,
      },
    );

    return data ?? {};
  }

  /// -----------------------------
  /// REQUEST REINSTALL OTP
  /// -----------------------------
  Future<String?> requestReinstallOtp(int jobCardId) async {
    final data = await _apiClient.post(
      '/api/crm/job-cards/$jobCardId/request_reinstall_otp/',
    );

    if (data is Map<String, dynamic>) {
      return data['otp']?.toString(); // DEV ONLY
    }
    return null;
  }

  /// -----------------------------
  /// VERIFY REINSTALL OTP
  /// -----------------------------
  Future<void> verifyReinstallOtp({
    required int jobCardId,
    required String otp,
  }) async {
    await _apiClient.post(
      '/api/crm/job-cards/$jobCardId/verify_reinstall_otp/',
      data: {"otp": otp},
    );
  }


}
