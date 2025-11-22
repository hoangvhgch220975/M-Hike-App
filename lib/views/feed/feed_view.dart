// lib/views/feed/feed_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/hike_viewmodel.dart';
import '../../models/hike.dart';
import 'empty_feed_view.dart';
import 'widgets/feed_card.dart';

class FeedView extends StatefulWidget {
  const FeedView({super.key});

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    // Load completed hikes when view initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<HikeViewModel>(context, listen: false);
      viewModel.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = _FeedColors();

    return Consumer<HikeViewModel>(
      builder: (context, viewModel, child) {
        // Get filtered hikes based on selected filter
        List<Hike> displayHikes = _getFilteredHikes(viewModel);

        // Show empty view if no completed hikes exist
        if (viewModel.feed.isEmpty && !viewModel.isLoading) {
          return const EmptyFeedView();
        }

        return Scaffold(
          backgroundColor: colors.lightGrey,
          body: SafeArea(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  children: [
                    _buildHeader(colors),
                    const SizedBox(height: 4),
                    _buildFilters(colors, viewModel),
                    const SizedBox(height: 8),
                    Expanded(
                      child: displayHikes.isEmpty && !viewModel.isLoading
                          ? _buildEmptyState(colors)
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: displayHikes.length + (viewModel.isLoading ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == displayHikes.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 32),
                                    child: Center(
                                      child: SizedBox(
                                        height: 32,
                                        width: 32,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: Color(0xFF225749),
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                final hike = displayHikes[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 24),
                                    child: FeedCard(hike: hike),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Hike> _getFilteredHikes(HikeViewModel viewModel) {
    switch (_selectedFilter) {
      case 'Remarkable 🌟':
        return viewModel.remarkable;
      case 'Recent':
        return viewModel.feed.take(10).toList();
      case 'Easy':
        return viewModel.feed.where((h) => h.difficulty == 'Easy').toList();
      case 'Moderate':
        return viewModel.feed.where((h) => h.difficulty == 'Moderate').toList();
      case 'Hard':
        return viewModel.feed.where((h) => h.difficulty == 'Hard').toList();
      default:
        return viewModel.feed;
    }
  }

  Widget _buildEmptyState(_FeedColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_list_off, size: 64, color: colors.darkGrey),
          const SizedBox(height: 16),
          Text(
            'No hikes match this filter',
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

  // HEADER
  Widget _buildHeader(_FeedColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: colors.lightGrey.withOpacity(0.9),
      child: Row(
        children: [
          Image.asset(
            'lib/assets/images/hike_logo.png',
            width: 32,
            height: 32,
            fit: BoxFit.contain,
          ),
          const Spacer(),
          const Text(
            "Hike Feed",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, size: 28, color: Color(0xFF1F2937)),
          ),
        ],
      ),
    );
  }

  // FILTER TAGS
  Widget _buildFilters(_FeedColors colors, HikeViewModel viewModel) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        children: [
          _filter("All", _selectedFilter == 'All', colors),
          _filter("Remarkable 🌟", _selectedFilter == 'Remarkable 🌟', colors),
          _filter("Recent", _selectedFilter == 'Recent', colors),
          _filter("Easy", _selectedFilter == 'Easy', colors),
          _filter("Moderate", _selectedFilter == 'Moderate', colors),
          _filter("Hard", _selectedFilter == 'Hard', colors),
        ],
      ),
    );
  }

  Widget _filter(String label, bool active, _FeedColors c) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: active ? c.forestGreen : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: active ? null : [const BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : c.darkText,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}


// COLOR PALETTE
class _FeedColors {
  final Color forestGreen = const Color(0xFF225749);
  final Color skyBlue = const Color(0xFF89CFF0);
  final Color earthBrown = const Color(0xFFA1887F);
  final Color lightGrey = const Color(0xFFF5F5F5);
  final Color darkGrey = const Color(0xFF6B7280);
  final Color darkText = const Color(0xFF1F2937);
}
