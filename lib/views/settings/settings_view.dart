// lib/views/settings/settings_view.dart

import 'package:flutter/material.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'This is Settings View',
          style: TextStyle(fontSize: 24, color: Colors.black),
        ),
      ),
    );
  }
}

