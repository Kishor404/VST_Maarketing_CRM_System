import 'package:get/get.dart';

import '../../data/providers/card_provider.dart';
import '../../data/providers/service_provider.dart';
import '../../data/repositories/card_repository.dart';
import '../../data/repositories/service_repository.dart';
import 'card_controller.dart';

class CardBinding extends Bindings {
  @override
  void dependencies() {
    // Providers
    Get.lazyPut<CardProvider>(() => CardProvider(), fenix: true);
    Get.lazyPut<ServiceProvider>(() => ServiceProvider(), fenix: true);

    // Repositories
    Get.lazyPut<CardRepository>(
      () => CardRepository(Get.find<CardProvider>()),
      fenix: true,
    );

    Get.lazyPut<ServiceRepository>(
      () => ServiceRepository(Get.find<ServiceProvider>()),
      fenix: true,
    );

    // Controller ✅ FIXED
    Get.lazyPut<CardController>(
      () => CardController(
        cardRepository: Get.find<CardRepository>(),
        serviceRepository: Get.find<ServiceRepository>(),
      ),
    );
  }
}
