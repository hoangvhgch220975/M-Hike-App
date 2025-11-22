// lib/views/plan/plan_view.dart

import 'package:flutter/material.dart';

class PlanView extends StatelessWidget {
  const PlanView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'This is Plan View',
          style: TextStyle(fontSize: 24, color: Colors.black),
        ),
      ),
    );
  }
}

