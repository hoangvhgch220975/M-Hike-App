// lib/views/feed/feed_view.dart

import 'package:flutter/material.dart';

class FeedView extends StatelessWidget {
  const FeedView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'This is Feed View',
          style: TextStyle(fontSize: 24, color: Colors.black),
        ),
      ),
    );
  }
}

