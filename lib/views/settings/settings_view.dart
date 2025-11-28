import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'extra/about.dart';
import 'extra/statistics.dart';
import '../../services/permission_service.dart';
import '../../viewmodels/theme_viewmodel.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool notificationsEnabled = false;
  bool locationEnabled = false;
  bool cameraEnabled = false;
  bool galleryEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPermissionStatuses();
  }

  // Load current permission statuses
  Future<void> _loadPermissionStatuses() async {
    final camera = await PermissionService.isCameraGranted();
    final gallery = await PermissionService.isGalleryGranted();
    final location = await PermissionService.isLocationGranted();
    final notification = await PermissionService.isNotificationGranted();

    setState(() {
      cameraEnabled = camera;
      galleryEnabled = gallery;
      locationEnabled = location;
      notificationsEnabled = notification;
      _isLoading = false;
    });
  }

  // Handle camera permission toggle
  Future<void> _handleCameraPermission(bool value) async {
    if (value) {
      // Request permission
      final granted = await PermissionService.requestCamera();
      setState(() {
        cameraEnabled = granted;
      });

      if (!granted && mounted) {
        PermissionService.showPermissionDeniedDialog(context, 'Camera');
      }
    } else {
      // Show dialog to inform user to disable in settings
      if (mounted) {
        _showDisablePermissionDialog('Camera');
      }
    }
  }

  // Handle gallery permission toggle
  Future<void> _handleGalleryPermission(bool value) async {
    if (value) {
      final granted = await PermissionService.requestGallery();
      setState(() {
        galleryEnabled = granted;
      });

      if (!granted && mounted) {
        PermissionService.showPermissionDeniedDialog(context, 'Gallery');
      }
    } else {
      if (mounted) {
        _showDisablePermissionDialog('Gallery');
      }
    }
  }

  // Handle location permission toggle
  Future<void> _handleLocationPermission(bool value) async {
    if (value) {
      final granted = await PermissionService.requestLocation();
      setState(() {
        locationEnabled = granted;
      });

      if (!granted && mounted) {
        PermissionService.showPermissionDeniedDialog(context, 'Location');
      }
    } else {
      if (mounted) {
        _showDisablePermissionDialog('Location');
      }
    }
  }

  // Handle notification permission toggle
  Future<void> _handleNotificationPermission(bool value) async {
    if (value) {
      final granted = await PermissionService.requestNotification();
      setState(() {
        notificationsEnabled = granted;
      });

      if (!granted && mounted) {
        PermissionService.showPermissionDeniedDialog(context, 'Notification');
      }
    } else {
      if (mounted) {
        _showDisablePermissionDialog('Notification');
      }
    }
  }

  // Show dialog to inform user how to disable permission
  void _showDisablePermissionDialog(String permissionName) {
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
            const Text(
              'Disable Permission',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'To disable $permissionName permission, please go to your device Settings > Apps > M-Hike > Permissions.',
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
              PermissionService.openSettings();
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

  @override
  Widget build(BuildContext context) {
    final themeModel = context.watch<ThemeViewModel>();

    // Use the global app theme (MaterialApp's theme/darkTheme) so toggling
    // ThemeViewModel updates the whole app.
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color ?? Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color ?? Colors.black,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2E7D32),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                children: [
                  _buildToggleItem(
                    context,
                    icon: Icons.light_mode,
                    iconColor: const Color(0xFF2E7D32),
                    title: 'Dark/Light Mode',
                    value: themeModel.isDarkMode,
                    onChanged: (val) {
                      context.read<ThemeViewModel>().setDarkMode(val);
                    },
                  ),
                  const Divider(height: 1),
                  _buildToggleItem(
                    context,
                    icon: Icons.notifications,
                    iconColor: const Color(0xFF2E7D32),
                    title: 'Notification Settings',
                    value: notificationsEnabled,
                    onChanged: _handleNotificationPermission,
                  ),
                  const Divider(height: 1),
                  _buildToggleItem(
                    context,
                    icon: Icons.location_on,
                    iconColor: const Color(0xFF0288D1),
                    title: 'Location Permissions',
                    value: locationEnabled,
                    onChanged: _handleLocationPermission,
                  ),
                  const Divider(height: 1),
                  _buildToggleItem(
                    context,
                    icon: Icons.photo_camera,
                    iconColor: const Color(0xFF0288D1),
                    title: 'Camera Permissions',
                    value: cameraEnabled,
                    onChanged: _handleCameraPermission,
                  ),
                  const Divider(height: 1),
                  _buildToggleItem(
                    context,
                    icon: Icons.photo_library,
                    iconColor: const Color(0xFF0288D1),
                    title: 'Gallery Permissions',
                    value: galleryEnabled,
                    onChanged: _handleGalleryPermission,
                  ),
                  const SizedBox(height: 16),
                  _buildNavigationItem(
                    context,
                    icon: Icons.bar_chart,
                    iconColor: const Color(0xFF2E7D32),
                    title: 'Statistics',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const StatisticsView()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildNavigationItem(
                    context,
                    icon: Icons.info,
                    iconColor: const Color(0xFF5D4037),
                    title: 'About',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AboutView()),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildToggleItem(
    BuildContext ctx, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(ctx);
    return Container(
      color: theme.cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyMedium?.color ?? Colors.black87,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF2E7D32),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem(
    BuildContext ctx, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(ctx);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: theme.cardColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodyMedium?.color ?? Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
