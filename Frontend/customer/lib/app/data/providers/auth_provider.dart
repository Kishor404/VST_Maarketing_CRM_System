import '../../core/api/api_client.dart';

class AuthProvider {
  final ApiClient _apiClient = ApiClient();

  /// -----------------------------
  /// LOGIN
  /// POST /api/auth/login/
  /// -----------------------------
  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/api/auth/login/',
      data: {
        'phone': phone,
        'password': password,
      },
    );

    return response.data as Map<String, dynamic>;
  }

  /// -----------------------------
  /// REGISTER
  /// POST /api/auth/register/
  /// -----------------------------
  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String password,
    required String address,
    required String city,
    required String postalCode,
    required String region,
  }) async {
    final response = await _apiClient.post(
      '/api/auth/register/',
      data: {
        'name': name,
        'phone': phone,
        'password': password,
        'address': address,
        'city': city,
        'postal_code': postalCode,
        'region': region,
      },
    );
    print(response.data);
    return response.data as Map<String, dynamic>;
  }

  /// -----------------------------
  /// PROFILE
  /// GET /api/auth/me/
  /// -----------------------------
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _apiClient.get(
      '/api/auth/me/',
    );

    return response.data as Map<String, dynamic>;
  }
}
