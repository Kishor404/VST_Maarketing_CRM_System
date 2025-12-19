import 'package:get/get.dart';

import '../../data/providers/service_provider.dart';
import '../../data/repositories/service_repository.dart';
import 'service_detail_controller.dart';

class ServiceDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ServiceProvider>(() => ServiceProvider());

    Get.lazyPut<ServiceRepository>(
      () => ServiceRepository(Get.find<ServiceProvider>()),
    );

    Get.lazyPut<ServiceDetailController>(
      () => ServiceDetailController(
        serviceRepository: Get.find<ServiceRepository>(),
      ),
    );
  }
}
