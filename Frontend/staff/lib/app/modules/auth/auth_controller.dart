import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/utils/snackbar.dart';
import '../../routes/app_routes.dart';

class AuthController extends GetxController {
  final ApiClient _apiClient = ApiClient();
  final GetStorage _storage = GetStorage();

  final phone = ''.obs;
  final password = ''.obs;

  final loading = false.obs;

  /// ============================
  /// Login
  /// ============================

  Future<void> login() async {
    if (phone.value.isEmpty || password.value.isEmpty) {
      AppSnackbar.error(
        title: 'Invalid Input',
        message: 'Phone and password are required',
      );
      return;
    }

    try {
      loading.value = true;

      /// 🔹 LOGIN
      final loginData = await _apiClient.post(
        ApiEndpoints.login,
        data: {
          "phone": '+91${phone.value}',
          "password": password.value,
        },
      );

      if (loginData is! Map<String, dynamic>) {
        throw Exception('Invalid login response');
      }

      final access = loginData['access'];
      final refresh = loginData['refresh'];

      if (access == null || refresh == null) {
        throw Exception('Token missing in response');
      }

      // Save tokens
      _storage.write(StorageKeys.accessToken, access);
      _storage.write(StorageKeys.refreshToken, refresh);
      _storage.write(StorageKeys.isLoggedIn, true);

      /// 🔹 FETCH PROFILE
      final profileData =
          await _apiClient.get(ApiEndpoints.myProfile);

      if (profileData is! Map<String, dynamic>) {
        throw Exception('Invalid profile response');
      }

      final role = profileData['role'];

      if (role != 'staff' && role != 'worker') {
        _forceLogout();
        AppSnackbar.error(
          title: 'Access Denied',
          message: 'This app is only for staff members',
        );
        return;
      }

      _storage.write(StorageKeys.userProfile, profileData);
      _storage.write(StorageKeys.userRole, role);

      AppSnackbar.success(
        title: 'Login Successful',
        message: 'Welcome to VST Staff App',
      );

      Get.offAllNamed(AppRoutes.main);
    } catch (e) {
      AppSnackbar.error(
        title: 'Login Failed',
        message: e.toString(),
      );
    } finally {
      loading.value = false;
    }
  }

  /// ============================
  /// Logout
  /// ============================

  void logout() {
    _forceLogout();
    Get.offAllNamed(AppRoutes.login);
  }

  void _forceLogout() {
    _storage.erase();
  }
}
