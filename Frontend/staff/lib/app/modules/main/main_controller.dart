import 'package:get/get.dart';

import '../home/home_page.dart';
import '../work/work_list_page.dart';
import '../feedback/feedback_page.dart';
import '../profile/profile_page.dart';

class MainController extends GetxController {
  final currentIndex = 0.obs;

  final pages = const [
    HomePage(),
    WorkPage(),
    FeedbackPage(),
    ProfilePage(),
  ];

  void changeTab(int index) {
    currentIndex.value = index;
  }
}
