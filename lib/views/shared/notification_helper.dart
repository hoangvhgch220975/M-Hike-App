// lib/utils/notification_helper.dart

import 'package:flutter/material.dart';

/// Reusable notification helper for showing snackbars throughout the app
class NotificationHelper {
  /// Show a success notification (green)
  static void showSuccess(BuildContext context, String message) {
    _showNotification(
      context,
      message,
      icon: Icons.check_circle,
      backgroundColor: const Color(0xFF2E7D32),
    );
  }

  /// Show an error notification (red)
  static void showError(BuildContext context, String message) {
    _showNotification(
      context,
      message,
      icon: Icons.error,
      backgroundColor: const Color(0xFFD32F2F),
    );
  }

  /// Show an info notification (blue)
  static void showInfo(BuildContext context, String message) {
    _showNotification(
      context,
      message,
      icon: Icons.info,
      backgroundColor: const Color(0xFF1976D2),
    );
  }

  /// Show a warning notification (orange)
  static void showWarning(BuildContext context, String message) {
    _showNotification(
      context,
      message,
      icon: Icons.warning,
      backgroundColor: const Color(0xFFFF9800),
    );
  }

  /// Show a custom notification
  static void showCustom(
    BuildContext context,
    String message, {
    IconData? icon,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showNotification(
      context,
      message,
      icon: icon ?? Icons.notifications,
      backgroundColor: backgroundColor ?? const Color(0xFF424242),
      duration: duration,
    );
  }

  /// Private method to display the notification
  static void _showNotification(
    BuildContext context,
    String message, {
    required IconData icon,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: duration,
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}

