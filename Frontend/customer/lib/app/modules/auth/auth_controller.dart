import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../data/repositories/auth_repository.dart';
import '../../routes/app_routes.dart';
import '../../core/utils/app_snackbar.dart';

class AuthController extends GetxController {
  final AuthRepository authRepository;
  final GetStorage _storage = GetStorage();

  AuthController({required this.authRepository});

  final loading = false.obs;

  /// Login with phone & password
  Future<void> login({
    required String phone,
    required String password,
  }) async {
    try {
      loading.value = true;

      final response = await authRepository.login(
        phone: phone,
        password: password,
      );

      // Store tokens
      _storage.write('access', response['access']);
      _storage.write('refresh', response['refresh']);

      // Navigate to home
      Get.offAllNamed(AppRoutes.HOME);
    } catch (e) {
      AppSnackbar.error(
        'Login Failed',
        'Invalid phone number or password',
      );
    } finally {
      loading.value = false;
    }
  }

  Future<void> register({
    required String name,
    required String phone,
    required String password,
    required String address,
    required String city,
    required String postalCode,
    required String region,
  }) async {
    if (password.length < 8 || RegExp(r'^\d+$').hasMatch(password)) {
      AppSnackbar.error(
        'Invalid Password',
        'Password must be at least 8 characters and not numeric',
      );
      return;
    }

    try {
      loading.value = true;

      await authRepository.register(
        name: name,
        phone: phone,
        password: password,
        address: address,
        city: city,
        postalCode: postalCode,
        region: region,
      );

      AppSnackbar.success(
        'Success',
        'Registration successful. Please login.',
      );

      Get.offAllNamed(AppRoutes.LOGIN);
    } catch (e) {
      AppSnackbar.error(
        'Registration Failed',
        'Phone number already exists or invalid data',
      );
    } finally {
      loading.value = false;
    }
  }

  /// Logout
  void logout() {
    _storage.erase();
    Get.offAllNamed(AppRoutes.LOGIN);
  }
}
