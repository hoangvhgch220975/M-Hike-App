// lib/views/feed/feed_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/hike_viewmodel.dart';
import '../../models/hike.dart';
import 'empty_feed_view.dart';
import 'widgets/feed_card.dart';
import '../search/search_view.dart';

class FeedView extends StatefulWidget {
  const FeedView({super.key});

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  String _selectedFilter = 'All';

  // Pagination fields
  final ScrollController _controller = ScrollController();
  List<Hike> _allHikes = [];
  List<Hike> _displayed = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _initialized = false;
  final int _pageSize = 4;

  @override
  void initState() {
    super.initState();
    // Load completed hikes when view initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<HikeViewModel>(context, listen: false);
      viewModel.initialize();
    });
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients || _isLoadingMore || !_hasMore) return;
    final threshold = 120.0; // px from bottom to trigger
    if (_controller.position.maxScrollExtent - _controller.position.pixels <= threshold) {
      _loadMore();
    }
  }

  void _resetPagination(List<Hike> source) {
    _allHikes = List.of(source);
    final first = _allHikes.length > _pageSize ? _pageSize : _allHikes.length;
    _displayed = _allHikes.take(first).toList();
    _hasMore = _displayed.length < _allHikes.length;
    _isLoadingMore = false;
    _initialized = true;
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
    });

    // Simulate searching/fetching for up to 1.2 seconds
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    final currentlyShown = _displayed.length;
    final remaining = _allHikes.length - currentlyShown;
    if (remaining <= 0) {
      setState(() {
        _hasMore = false;
        _isLoadingMore = false;
      });
      return;
    }

    final nextCount = remaining > _pageSize ? _pageSize : remaining;
    final nextItems = _allHikes.skip(currentlyShown).take(nextCount).toList();

    setState(() {
      _displayed.addAll(nextItems);
      _hasMore = _displayed.length < _allHikes.length;
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = _FeedColors();

    return Consumer<HikeViewModel>(
      builder: (context, viewModel, child) {
        // Get filtered hikes based on selected filter
        List<Hike> filtered = _getFilteredHikes(viewModel);

        // If filtered list changed (or first init), reset pagination
        if (!_initialized || filtered.length != _allHikes.length) {
          _resetPagination(filtered);
        }

        // Show empty view if no completed hikes exist (and not loading)
        if (filtered.isEmpty && !viewModel.isLoading) {
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
                      child: _displayed.isEmpty && viewModel.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              controller: _controller,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _displayed.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _displayed.length) {
                                  // footer
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 24),
                                    child: Center(
                                      child: _isLoadingMore
                                          ? const SizedBox(
                                              height: 32,
                                              width: 32,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 3,
                                                color: Color(0xFF225749),
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  );
                                }

                                final hike = _displayed[index];
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
            onPressed: () {
              // Navigate to search view
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const SearchView()),
              );
            },
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
          _initialized = false; // reset pagination when filter changes
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
