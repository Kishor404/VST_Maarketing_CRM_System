import 'package:get/get.dart';

import '../../data/providers/auth_provider.dart';
import '../../data/repositories/auth_repository.dart';
import 'profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    /// Provider
    Get.lazyPut<AuthProvider>(
      () => AuthProvider(),
      fenix: true,
    );

    /// Repository
    Get.lazyPut<AuthRepository>(
      () => AuthRepository(Get.find<AuthProvider>()),
      fenix: true,
    );

    /// Controller
    Get.lazyPut<ProfileController>(
      () => ProfileController(
        authRepository: Get.find<AuthRepository>(),
      ),
    );
  }
}
