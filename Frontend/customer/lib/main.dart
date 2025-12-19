import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';


import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local storage
  await GetStorage.init();
  debugPrint('🚀 App started');

  runApp(const VSTCustomerApp());
}

class VSTCustomerApp extends StatelessWidget {
  const VSTCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'VST Maarketing',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.lightTheme,

      // Routing
      initialRoute: AppRoutes.SPLASH,
      getPages: AppPages.routes,

      // Default transitions
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),

      // Unknown route safety
      unknownRoute: GetPage(
        name: '/not-found',
        page: () => const Scaffold(
          body: Center(
            child: Text(
              'Page Not Found',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}
