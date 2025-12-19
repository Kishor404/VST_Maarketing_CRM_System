import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../routes/app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  final GetStorage _storage = GetStorage();

  @override
  RouteSettings? redirect(String? route) {
    final String? accessToken = _storage.read('access');

    // If token does not exist → redirect to login
    if (accessToken == null || accessToken.isEmpty) {
      return const RouteSettings(name: AppRoutes.LOGIN);
    }

    // Token exists → allow navigation
    return null;
  }
}
