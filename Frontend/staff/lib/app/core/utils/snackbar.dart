import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppSnackbar {
  AppSnackbar._();

  static void success({
    required String title,
    required String message,
  }) {
    _show(
      title: title,
      message: message,
      backgroundColor: const Color.fromARGB(255, 2, 116, 8),
      icon: Icons.check_circle,
    );
  }

  static void error({
    required String title,
    required String message,
  }) {
    _show(
      title: title,
      message: message,
      backgroundColor: Colors.red.shade600,
      icon: Icons.error,
    );
  }

  static void info({
    required String title,
    required String message,
  }) {
    _show(
      title: title,
      message: message,
      backgroundColor: Colors.blue.shade600,
      icon: Icons.info,
    );
  }

  static void _show({
    required String title,
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP, // ✅ KEY FIX
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      icon: Icon(icon, color: Colors.white),
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutBack,
    );
  }
}
