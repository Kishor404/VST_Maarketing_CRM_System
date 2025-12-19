import 'package:get/get.dart';

import '../modules/splash/splash_page.dart';
import '../modules/auth/login_page.dart';
import '../modules/main/main_page.dart';
import '../modules/work/work_completion_page.dart';

import '../modules/splash/splash_binding.dart';
import '../modules/auth/auth_binding.dart';
import '../modules/main/main_binding.dart';
import '../modules/work/work_binding.dart';

import 'app_routes.dart';

class AppPages {
  static final pages = [
    /// Splash
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
      binding: SplashBinding(),
    ),

    /// Login
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: AuthBinding(),
    ),

    /// Main (Bottom Navigation Shell)
    GetPage(
      name: AppRoutes.main,
      page: () => const MainPage(),
      binding: MainBinding(),
    ),

    GetPage(
      name: AppRoutes.workComplete,
      page: () => const WorkCompletionPage(),
      binding: WorkBinding(), // ✅ IMPORTANT
    ),
  ];
}
