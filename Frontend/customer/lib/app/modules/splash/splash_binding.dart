import 'package:get/get.dart';
import 'package:flutter/foundation.dart';

import '../../data/providers/auth_provider.dart';
import '../../data/repositories/auth_repository.dart';
import 'splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    debugPrint('🔥 SplashBinding dependencies called');

    Get.put<AuthProvider>(AuthProvider());
    Get.put<AuthRepository>(AuthRepository(Get.find<AuthProvider>()));

    // 🔴 CHANGE HERE
    Get.put<SplashController>(
      SplashController(
        authRepository: Get.find<AuthRepository>(),
      ),
    );
  }
}
