import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../routes/app_routes.dart';
import '../../data/repositories/auth_repository.dart';

class SplashController extends GetxController {
  final AuthRepository authRepository;
  final _storage = GetStorage();

  SplashController({required this.authRepository});

  @override
  void onInit() {
    super.onInit();

    // ⏳ Allow splash UI to render first
    Future.delayed(const Duration(milliseconds: 300), _bootstrap);
  }

  Future<void> _bootstrap() async {
    // ⏳ Keep splash visible (UX)
    await Future.delayed(const Duration(seconds: 1));

    final access = _storage.read('access');

    if (access == null) {
      Get.offAllNamed(AppRoutes.LOGIN);
      return;
    }

    try {
      await authRepository.getProfile();
      Get.offAllNamed(AppRoutes.HOME);
    } catch (_) {
      _storage.erase();
      Get.offAllNamed(AppRoutes.LOGIN);
    }
  }
}
