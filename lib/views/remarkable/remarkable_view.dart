import 'package:flutter/material.dart';

import '../../db/app_db.dart';
import '../../models/hike.dart';
import 'empty_remarkable_view.dart';
import 'widgets/remarkable_card.dart';

class RemarkableView extends StatelessWidget {
  const RemarkableView({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Hike>>(
      future: AppDatabase.instance.getRemarkableHikes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF5F5F5),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            body: Center(child: Text('Error loading remarkable hikes: ${snapshot.error}')),
          );
        }

        final hikes = snapshot.data ?? [];

        // If no remarkable hikes, show empty view (keeps its own scaffold)
        if (hikes.isEmpty) return const EmptyRemarkableView();

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),

          // AppBar preserves previous look but allows back button if pushed
          appBar: AppBar(
            backgroundColor: Colors.white.withOpacity(0.8),
            elevation: 0,
            automaticallyImplyLeading: true,
            centerTitle: true,
            title: const Text(
              'Remarkable Hikes',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
          ),

          body: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: hikes.length + 1,
            itemBuilder: (context, index) {
              if (index == hikes.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Color(0xFF2E7D32),
                            strokeWidth: 3,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text("Loading more...", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }

              final hike = hikes[index];

              return RemarkableCard(
                hike: hike,
                onTap: () {
                  // TODO: navigate to hike detail when implemented
                },
              );
            },
          ),
        );
      },
    );
  }
}
