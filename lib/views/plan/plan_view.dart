// lib/views/plan/plan_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/hike_viewmodel.dart';
import '../../models/hike.dart';
import 'empty_plan_view.dart';
import 'widgets/plan_card.dart';
import '../hikes/hike_form_view.dart';
import '../hikes/hike_detail_view.dart';

class PlanView extends StatefulWidget {
  const PlanView({super.key});

  @override
  State<PlanView> createState() => _PlanViewState();
}

class _PlanViewState extends State<PlanView> {
  final ScrollController _scrollController = ScrollController();
  bool _showGreenAppBar = false;

  @override
  void initState() {
    super.initState();
    // Load planned hikes when view initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<HikeViewModel>(context, listen: false);
      viewModel.loadPlan(); // Load only planned hikes
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final offset = _scrollController.offset;
    // Match FeedView behavior: show the green app bar as soon as the
    // user scrolls any amount (offset > 0). This keeps PlanView in sync
    // with Feed/Remarkable.
    final shouldShowGreen = offset > 0; // Show green after any scroll

    if (shouldShowGreen != _showGreenAppBar) {
      setState(() {
        _showGreenAppBar = shouldShowGreen;
      });
    }
  }

  Future<void> _openHikeForm({Hike? hike}) async {
    final result = await Navigator.of(context).push<bool?>(
      MaterialPageRoute(builder: (ctx) => HikeFormView(hike: hike)),
    );

    if (result == true) {
      // If the form saved successfully, refresh plan
      final vm = Provider.of<HikeViewModel>(context, listen: false);
      await vm.loadPlan();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<HikeViewModel>(
      builder: (context, viewModel, child) {
        // If there are no planned hikes yet, show the dedicated EmptyPlanView
        if (viewModel.plan.isEmpty && !viewModel.isLoading) {
          return const EmptyPlanView();
        }

        // Otherwise show the plan list and FAB for adding
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: _showGreenAppBar ? colorScheme.primary.withOpacity(0.12) : Colors.transparent,
            elevation: _showGreenAppBar ? 2 : 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Image.asset('lib/assets/images/hike_logo.png', width: 32, height: 32, fit: BoxFit.contain),
            ),
            title: Text('Plan', style: theme.textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          body: RefreshIndicator(
            color: colorScheme.primary,
            onRefresh: () async {
              await viewModel.loadPlan(); // Load only planned hikes
            },
            child: ListView.builder(
              controller: _scrollController, // Add controller
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: viewModel.plan.length + (viewModel.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == viewModel.plan.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: SizedBox(
                        height: 32,
                        width: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: colorScheme.secondary,
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
                    // Provide a darker green specifically for the Plan view complete button
                    completeButtonColor: const Color(0xFF0B3D0B), // darker green
                    onCompleted: () async {
                      // Mark hike as completed
                      await viewModel.markHikeAsCompleted(hike.id!);

                      if (context.mounted) {
                        // Show success notification
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle, color: colorScheme.onPrimary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '✓ Hike "${hike.name}" marked as completed!',
                                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: colorScheme.primary,
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
                    // Single tap: open hike detail
                    onTap: () async {
                      if (hike.id == null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Cannot open hike "${hike.name}" (missing id)')),
                          );
                        }
                        return;
                      }

                      final result = await Navigator.of(context).push<bool?>(
                        MaterialPageRoute(builder: (ctx) => HikeDetailView(hikeId: hike.id!)),
                      );

                      if (result == true) {
                        // Refresh plan list after a change (deleted/updated)
                        await viewModel.loadPlan();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Hike updated')),
                          );
                        }
                      }
                    },
                    // Long-press -> options: Edit / Delete
                    onEdit: () => _openHikeForm(hike: hike),
                    onDelete: () async {
                      final success = await viewModel.deleteHike(hike.id!);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Deleted "${hike.name}"' : 'Failed to delete "${hike.name}"'),
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
            backgroundColor: colorScheme.primary,
            shape: const CircleBorder(),
            child: Icon(Icons.add, color: colorScheme.onPrimary, size: 32),
            onPressed: () {
              _openHikeForm();
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hiking_outlined, size: 64, color: theme.iconTheme.color),
          const SizedBox(height: 16),
          Text('No planned hikes yet', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
