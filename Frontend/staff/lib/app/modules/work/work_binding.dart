import 'package:get/get.dart';

import 'work_controller.dart';

class WorkBinding extends Bindings {
  @override
  void dependencies() {
    // Use lazyPut so controller is created only when needed
    Get.lazyPut<WorkController>(
      () => WorkController(),
      fenix: true, // 🔥 keeps controller alive across navigation
    );
  }
}
