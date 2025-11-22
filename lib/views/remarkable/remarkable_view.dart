// lib/views/remarkable/remarkable_view.dart

import 'package:flutter/material.dart';

class RemarkableView extends StatelessWidget {
  const RemarkableView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'This is Remarkable View',
          style: TextStyle(fontSize: 24, color: Colors.black),
        ),
      ),
    );
  }
}

