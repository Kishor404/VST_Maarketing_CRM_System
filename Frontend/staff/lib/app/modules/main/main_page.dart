import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'main_controller.dart';
import '../work/work_controller.dart';

class MainPage extends GetView<MainController> {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    /// 🔗 Inject WorkController
    final workController = Get.find<WorkController>();

    return Obx(
      () => Scaffold(
        /// ============================
        /// App Bar (LOGO ONLY)
        /// ============================
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Image.asset(
            'assets/logo/logoindex.jpg',
            height: 45,
            fit: BoxFit.contain,
          ),
          iconTheme: IconThemeData(color: primary),
        ),

        /// ============================
        /// Body
        /// ============================
        body: controller.pages[controller.currentIndex.value],

        /// ============================
        /// Bottom Navigation
        /// ============================
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: controller.currentIndex.value,
          onTap: controller.changeTab,
          type: BottomNavigationBarType.fixed,
          backgroundColor: primary,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),

            /// 🔴 WORK with BADGE
            BottomNavigationBarItem(
              icon: Obx(() => badgeIcon(
                    icon: Icons.work,
                    count: workController.assignedCount,
                  )),
              label: 'Work',
            ),

            const BottomNavigationBarItem(
              icon: Icon(Icons.star),
              label: 'Feedback',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  /// ============================
  /// Badge Icon
  /// ============================
  Widget badgeIcon({
    required IconData icon,
    required int count,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                count > 9 ? '9+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
