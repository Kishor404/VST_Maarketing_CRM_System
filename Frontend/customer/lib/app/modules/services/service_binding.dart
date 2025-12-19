import 'package:get/get.dart';

import '../../data/providers/service_provider.dart';
import '../../data/repositories/service_repository.dart';
import 'service_controller.dart';

class ServiceBinding extends Bindings {
  @override
  void dependencies() {
    /// Provider
    Get.lazyPut<ServiceProvider>(
      () => ServiceProvider(),
      fenix: true,
    );

    /// Repository
    Get.lazyPut<ServiceRepository>(
      () => ServiceRepository(Get.find<ServiceProvider>()),
      fenix: true,
    );

    /// Controller
    Get.lazyPut<ServiceController>(
      () => ServiceController(
        serviceRepository: Get.find<ServiceRepository>(),
      ),
    );
  }
}
