import 'package:get/get.dart';
import 'job_card_controller.dart';

class JobCardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<JobCardController>(
      () => JobCardController(),
    );
  }
}