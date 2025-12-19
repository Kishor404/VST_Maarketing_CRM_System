import 'package:get/get.dart';

import 'main_controller.dart';
import '../home/home_controller.dart';
import '../work/work_controller.dart';
import '../feedback/feedback_controller.dart';
import '../profile/profile_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    // Main shell
    Get.put(MainController());

    // Child pages controllers
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<WorkController>(() => WorkController());
    Get.lazyPut<FeedbackController>(() => FeedbackController());
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}
