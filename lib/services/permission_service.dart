// lib/services/permission_service.dart

import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class PermissionService {
  // Check if camera permission is granted
  static Future<bool> isCameraGranted() async {
    try {
      final status = await Permission.camera.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('Error checking camera permission: $e');
      return false;
    }
  }

  // Check if gallery/photos permission is granted
  static Future<bool> isGalleryGranted() async {
    try {
      final status = await Permission.photos.status;
      return status.isGranted || status.isLimited;
    } catch (e) {
      debugPrint('Error checking gallery permission: $e');
      return false;
    }
  }

  // Check if location permission is granted
  static Future<bool> isLocationGranted() async {
    try {
      final status = await Permission.location.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      return false;
    }
  }

  // Check if notification permission is granted
  static Future<bool> isNotificationGranted() async {
    try {
      final status = await Permission.notification.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
      return false;
    }
  }

  // Request camera permission
  static Future<bool> requestCamera() async {
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting camera permission: $e');
      return false;
    }
  }

  // Request gallery permission
  static Future<bool> requestGallery() async {
    try {
      final status = await Permission.photos.request();
      return status.isGranted || status.isLimited;
    } catch (e) {
      debugPrint('Error requesting gallery permission: $e');
      return false;
    }
  }

  // Request location permission
  static Future<bool> requestLocation() async {
    try {
      final status = await Permission.location.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return false;
    }
  }

  // Request notification permission
  static Future<bool> requestNotification() async {
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  // Open app settings
  static Future<void> openSettings() async {
    await openAppSettings();
  }

  // Show permission denied dialog
  static void showPermissionDeniedDialog(
    BuildContext context,
    String permissionName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFFF9800),
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              '$permissionName Permission',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'This app needs $permissionName permission to function properly. Please enable it in app settings.',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Open Settings',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Show permission rationale dialog
  static void showPermissionRationaleDialog(
    BuildContext context,
    String permissionName,
    String reason,
    VoidCallback onAccept,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: Color(0xFF2E7D32),
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              '$permissionName Access',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          reason,
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Not Now',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onAccept();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Allow',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

