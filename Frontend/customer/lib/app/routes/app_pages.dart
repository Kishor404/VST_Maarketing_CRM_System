import 'package:get/get.dart';

import '../core/middleware/auth_middleware.dart';
import '../modules/splash/splash_page.dart';
import '../modules/splash/splash_binding.dart';
import '../modules/auth/login_page.dart';
import '../modules/auth/register_page.dart';
import '../modules/auth/auth_binding.dart';
import '../modules/home/home_page.dart';
import '../modules/home/home_binding.dart';
import '../modules/cards/card_list_page.dart';
import '../modules/cards/card_detail_page.dart';
import '../modules/cards/card_binding.dart';
import '../modules/services/service_list_page.dart';
import '../modules/services/service_booking_page.dart';
import '../modules/services/service_booking_controller.dart';
import '../modules/services/service_detail_page.dart';
import '../modules/services/service_detail_binding.dart';
import '../modules/services/service_binding.dart';
import '../modules/feedback/feedback_page.dart';
import '../modules/feedback/feedback_binding.dart';
import '../modules/profile/profile_page.dart';
import '../modules/profile/profile_binding.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static final routes = <GetPage>[
    /// Splash
    GetPage(
      name: AppRoutes.SPLASH,
      page: () => const SplashPage(),
      binding: SplashBinding(),
    ),

    /// Login
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => const LoginPage(),
      binding: AuthBinding(),
    ),

    GetPage(
      name: AppRoutes.REGISTER,
      page: () => const RegisterPage(),
      binding: AuthBinding(),
    ),


    /// Home
    GetPage(
      name: AppRoutes.HOME,
      page: () => const HomePage(),
      binding: HomeBinding(),
      middlewares: [AuthMiddleware()],
    ),

    /// Cards
    GetPage(
      name: AppRoutes.CARDS,
      page: () => const CardListPage(),
      binding: CardBinding(),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: AppRoutes.CARD_DETAIL,
      page: () => const CardDetailPage(),
      binding: CardBinding(),
      middlewares: [AuthMiddleware()],
    ),


    /// Services
    GetPage(
      name: AppRoutes.SERVICES,
      page: () => const ServiceListPage(),
      binding: ServiceBinding(),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: AppRoutes.SERVICE_BOOK,
      page: () => const ServiceBookingPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ServiceBookingController(
              cardRepository: Get.find(),
              serviceRepository: Get.find(),
            ));
      }),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: AppRoutes.SERVICE_DETAIL,
      page: () => const ServiceDetailPage(),
      binding: ServiceDetailBinding(),
      middlewares: [AuthMiddleware()],
    ),


    /// Feedback
    GetPage(
      name: AppRoutes.FEEDBACK,
      page: () => const FeedbackPage(),
      binding: FeedbackBinding(),
      middlewares: [AuthMiddleware()],
    ),

    /// Profile
    GetPage(
      name: AppRoutes.PROFILE,
      page: () => const ProfilePage(),
      binding: ProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
