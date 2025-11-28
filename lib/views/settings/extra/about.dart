// lib/views/settings/about.dart

import 'package:flutter/material.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'About',
          style: theme.textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // App Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'lib/assets/images/hike_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // App Name
            Text('M-Hike', style: theme.textTheme.headlineSmall?.copyWith(fontSize: 32, fontWeight: FontWeight.bold)),

            const SizedBox(height: 8),

            // App Version
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Version 1.0.0',
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.primary),
              ),
            ),

            const SizedBox(height: 32),

            // Description
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'M-Hike is your ultimate companion for planning and tracking hiking adventures. '
                'Record your journeys, capture memorable moments, and discover new trails. '
                'Whether you\'re a casual walker or an experienced mountaineer, M-Hike helps you '
                'make every hike unforgettable.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
            ),

            const SizedBox(height: 32),

            // Features Section
            _buildSectionTitle('Features', theme),
            const SizedBox(height: 16),

            _buildFeatureItem(
              context,
              icon: Icons.map,
              title: 'Plan Your Hikes',
              description: 'Create and organize your hiking plans with detailed information',
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              context,
              icon: Icons.camera_alt,
              title: 'Capture Moments',
              description: 'Record observations and photos during your adventures',
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              context,
              icon: Icons.terrain,
              title: 'Track Progress',
              description: 'Monitor your hiking history and achievements',
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              context,
              icon: Icons.star,
              title: 'Mark Remarkable',
              description: 'Highlight your most memorable hiking experiences',
            ),

            const SizedBox(height: 32),

            // Developer Info
            _buildSectionTitle('Developer', theme),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.transparent,
                    child: ClipOval(
                      child: Image.asset(
                        'lib/assets/images/avatar.jpg',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Vu Hong Hoang',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'University of Greenwich',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Copyright
            Text(
              '© 2024 M-Hike. All rights reserved.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Made with ❤️ for hikers',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildFeatureItem(BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
