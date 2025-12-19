import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../routes/app_routes.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';

class SplashController extends GetxController {
  final GetStorage _storage = GetStorage();
  final ApiClient _apiClient = ApiClient();

  @override
  void onReady() {
    super.onReady();
    _handleStartup();
  }

  Future<void> _handleStartup() async {
    await Future.delayed(const Duration(seconds: 1));

    final accessToken = _storage.read(StorageKeys.accessToken);
    final refreshToken = _storage.read(StorageKeys.refreshToken);

    if (accessToken == null || refreshToken == null) {
      _goToLogin();
      return;
    }

    try {
      /// ApiClient.get() returns DATA, not Response
      final data = await _apiClient.get(ApiEndpoints.myProfile);
      final role = data['role'];

      /// Staff-only access
      if (role != 'worker' && role != 'staff') {
        _forceLogout();
        return;
      }

      /// Go to main dashboard
      Get.offAllNamed(AppRoutes.main);
    } catch (e) {
      _forceLogout();
    }
  }

  void _goToLogin() {
    Get.offAllNamed(AppRoutes.login);
  }

  void _forceLogout() {
    _storage.erase();
    _goToLogin();
  }
}
