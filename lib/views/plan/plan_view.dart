// lib/views/plan/plan_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/hike_viewmodel.dart';
import 'empty_plan_view.dart';
import 'widgets/plan_card.dart';

class PlanView extends StatefulWidget {
  const PlanView({super.key});

  @override
  State<PlanView> createState() => _PlanViewState();
}

class _PlanViewState extends State<PlanView> {
  @override
  void initState() {
    super.initState();
    // Load planned hikes when view initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<HikeViewModel>(context, listen: false);
      viewModel.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = _PlanColors();

    return Consumer<HikeViewModel>(
      builder: (context, viewModel, child) {
        // Show empty view if no planned hikes exist
        if (viewModel.plan.isEmpty && !viewModel.isLoading) {
          return const EmptyPlanView();
        }

        return Scaffold(
          backgroundColor: colors.lightGrey,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
            title: const Text(
              "Plan",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1E),
              ),
            ),
          ),
          body: viewModel.plan.isEmpty && !viewModel.isLoading
              ? _buildEmptyState(colors)
              : RefreshIndicator(
                  color: const Color(0xFF2E7D32),
                  onRefresh: () async {
                    await viewModel.initialize();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: viewModel.plan.length + (viewModel.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                    if (index == viewModel.plan.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: SizedBox(
                            height: 32,
                            width: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Color(0xFF13ec37),
                            ),
                          ),
                        ),
                      );
                    }

                    final hike = viewModel.plan[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: PlanCard(
                        hike: hike,
                        onCompleted: () async {
                          // Mark hike as completed
                          await viewModel.markHikeAsCompleted(hike.id!);

                          if (context.mounted) {
                            // Show success notification
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.white),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '✓ Hike "${hike.name}" marked as completed!',
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF2E7D32),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.all(16),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFF13ec37),
            shape: const CircleBorder(),
            child: const Icon(Icons.add, color: Colors.black, size: 32),
            onPressed: () {
              // TODO: Navigate to create hike
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(_PlanColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hiking_outlined, size: 64, color: colors.darkGrey),
          const SizedBox(height: 16),
          Text(
            'No planned hikes yet',
            style: TextStyle(
              fontSize: 16,
              color: colors.darkGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


// COLOR PALETTE
class _PlanColors {
  final Color greenAccent = const Color(0xFF13ec37);
  final Color lightGrey = const Color(0xFFF6F8F6);
  final Color darkGrey = const Color(0xFF6B7280);
  final Color darkText = const Color(0xFF1F2937);
}

