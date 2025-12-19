import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppSnackbar {
  AppSnackbar._(); // no instance

  static void success(
    String title,
    String message,
  ) {
    _show(
      title,
      message,
      background: Colors.green,
      icon: Icons.check_circle_outline,
    );
  }

  static void error(
    String title,
    String message,
  ) {
    _show(
      title,
      message,
      background: Colors.red,
      icon: Icons.error_outline,
    );
  }

  static void warning(
    String title,
    String message,
  ) {
    _show(
      title,
      message,
      background: Colors.orange,
      icon: Icons.warning_amber_outlined,
    );
  }

  static void info(
    String title,
    String message,
  ) {
    _show(
      title,
      message,
      background: Colors.blue,
      icon: Icons.info_outline,
    );
  }

  /// Core snackbar style
  static void _show(
    String title,
    String message, {
    required Color background,
    required IconData icon,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 16,
      backgroundColor: background.withOpacity(0.95),
      colorText: Colors.white,
      icon: Icon(icon, color: Colors.white),
      shouldIconPulse: false,
      duration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 400),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
    );
  }
}
