import 'package:get/get.dart';

import '../../data/providers/auth_provider.dart';
import '../../data/providers/card_provider.dart';
import '../../data/providers/service_provider.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/card_repository.dart';
import '../../data/repositories/service_repository.dart';

import '../cards/card_controller.dart';
import 'home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Providers
    Get.lazyPut<AuthProvider>(() => AuthProvider(), fenix: true);
    Get.lazyPut<CardProvider>(() => CardProvider(), fenix: true);
    Get.lazyPut<ServiceProvider>(() => ServiceProvider(), fenix: true);

    // Repositories
    Get.lazyPut<AuthRepository>(
      () => AuthRepository(Get.find<AuthProvider>()),
      fenix: true,
    );

    Get.lazyPut<CardRepository>(
      () => CardRepository(Get.find<CardProvider>()),
      fenix: true,
    );

    Get.lazyPut<ServiceRepository>(
      () => ServiceRepository(Get.find<ServiceProvider>()),
      fenix: true,
    );

    // CardController ✅ REQUIRED
    Get.lazyPut<CardController>(
      () => CardController(
        cardRepository: Get.find<CardRepository>(),
        serviceRepository: Get.find<ServiceRepository>(),
      ),
      fenix: true,
    );

    // HomeController
    Get.lazyPut<HomeController>(
      () => HomeController(
        authRepository: Get.find<AuthRepository>(),
        cardRepository: Get.find<CardRepository>(),
        serviceRepository: Get.find<ServiceRepository>(),
      ),
    );
  }
}
