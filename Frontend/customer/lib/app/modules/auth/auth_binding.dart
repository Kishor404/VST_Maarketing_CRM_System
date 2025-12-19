import 'package:get/get.dart';

import '../../data/providers/auth_provider.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthProvider>(() => AuthProvider(), fenix: true);
    Get.lazyPut<AuthRepository>(
      () => AuthRepository(Get.find<AuthProvider>()),
      fenix: true,
    );
    Get.lazyPut<AuthController>(
      () => AuthController(
        authRepository: Get.find<AuthRepository>(),
      ),
    );
  }
}
