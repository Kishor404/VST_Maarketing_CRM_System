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

  runApp(const VstStaffApp());
}

class VstStaffApp extends StatelessWidget {
  const VstStaffApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'VST Maarketing Staff',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.lightTheme,
      // darkTheme: AppTheme.darkTheme, // enable later if needed
      themeMode: ThemeMode.light,

      // Routing
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,

      // Global config
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
