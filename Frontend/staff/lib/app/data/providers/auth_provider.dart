import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/api/api_exceptions.dart';

class AuthProvider {
  final ApiClient _apiClient;

  AuthProvider(this._apiClient);

  /// ============================
  /// Login
  /// ============================
  ///
  /// POST /api/auth/login/
  /// Body: { phone, password }
  ///
  /// Returns:
  /// { access, refresh }
  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final result = await _apiClient.post(
      ApiEndpoints.login,
      data: {
        "phone": phone,
        "password": password,
      },
    );

    if (result is! Map<String, dynamic>) {
      throw ApiException('Invalid login response format');
    }

    if (!result.containsKey('access') ||
        !result.containsKey('refresh')) {
      throw ApiException('Token missing in response');
    }

    return result;
  }

  /// ============================
  /// Refresh Token
  /// ============================
  ///
  /// POST /api/auth/refresh/
  Future<String> refreshToken({
    required String refreshToken,
  }) async {
    final result = await _apiClient.post(
      ApiEndpoints.refreshToken,
      data: {
        "refresh": refreshToken,
      },
    );

    if (result is! Map<String, dynamic> ||
        !result.containsKey('access')) {
      throw ApiException('Invalid refresh token response');
    }

    return result['access'] as String;
  }

  /// ============================
  /// Get My Profile
  /// ============================
  ///
  /// GET /api/auth/me/
  Future<Map<String, dynamic>> getMyProfile() async {
    final result =
        await _apiClient.get(ApiEndpoints.myProfile);

    if (result is! Map<String, dynamic>) {
      throw ApiException('Invalid profile response format');
    }

    return result;
  }
}
