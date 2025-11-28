import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/hike_viewmodel.dart';
import '../../models/hike.dart';
import 'empty_feed_view.dart';
import 'widgets/feed_card.dart';
import '../search/search_view.dart';
import '../hikes/hike_detail_view.dart';

class FeedView extends StatefulWidget {
  const FeedView({super.key});

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  String _selectedFilter = 'All';

  // Pagination
  final ScrollController _controller = ScrollController();
  List<Hike> _allHikes = [];
  List<Hike> _displayed = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _initialized = false;
  final int _pageSize = 4;

  // AppBar animation
  bool _showGreenHeader = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = Provider.of<HikeViewModel>(context, listen: false);
      vm.initialize();
      vm.loadFeed();
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
    if (!_controller.hasClients) return;

    final offset = _controller.offset;
    final shouldShowGreen = offset > 0;

    if (shouldShowGreen != _showGreenHeader) {
      setState(() {
        _showGreenHeader = shouldShowGreen;
      });
    }

    if (_isLoadingMore || !_hasMore) return;

    final threshold = 120;
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

    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    final shown = _displayed.length;
    final remaining = _allHikes.length - shown;

    if (remaining <= 0) {
      setState(() {
        _hasMore = false;
        _isLoadingMore = false;
      });
      return;
    }

    final nextCount = remaining > _pageSize ? _pageSize : remaining;
    final nextItems = _allHikes.skip(shown).take(nextCount).toList();

    setState(() {
      _displayed.addAll(nextItems);
      _hasMore = _displayed.length < _allHikes.length;
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<HikeViewModel>(
      builder: (context, vm, child) {
        List<Hike> filtered = _getFilteredHikes(vm);

        if (!_initialized || filtered.length != _allHikes.length) {
          _resetPagination(filtered);
        }

        if (filtered.isEmpty && !vm.isLoading) {
          return const EmptyFeedView();
        }

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: _showGreenHeader
                ? colorScheme.primary.withOpacity(0.12)
                : Colors.transparent,
            elevation: _showGreenHeader ? 2 : 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
            title: Text(
              'Hike Feed',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(12),
              child: Image.asset(
                'lib/assets/images/hike_logo.png',
                width: 28,
                height: 28,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SearchView()),
                  );
                },
                icon: Icon(Icons.search, size: 28, color: theme.iconTheme.color),
              )
            ],
          ),
          body: SafeArea(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  children: [
                    const SizedBox(height: 14), // more space from AppBar
                    _buildFilters(theme),
                    const SizedBox(height: 16), // more space to content below
                    Expanded(
                      child: _displayed.isEmpty && vm.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : RefreshIndicator(
                        color: colorScheme.primary,
                        onRefresh: () async {
                          await vm.loadFeed();
                          await vm.loadRemarkable();
                        },
                        child: ListView.builder(
                          controller: _controller,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _displayed.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _displayed.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: _isLoadingMore
                                      ? const SizedBox(
                                    height: 32,
                                    width: 32,
                                    child: CircularProgressIndicator(strokeWidth: 3),
                                  )
                                      : const SizedBox.shrink(),
                                ),
                              );
                            }

                            final hike = _displayed[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: FeedCard(
                                hike: hike,
                                onRemarkableChanged: () {
                                  final vm = Provider.of<HikeViewModel>(
                                      context,
                                      listen: false);
                                  vm.loadFeed();
                                  vm.loadRemarkable();
                                },
                                onTap: () async {
                                  if (hike.id == null) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Cannot open this hike (missing id)')),
                                      );
                                    }
                                    return;
                                  }

                                  final result = await Navigator.of(context).push<bool?>(
                                    MaterialPageRoute(builder: (ctx) => HikeDetailView(hikeId: hike.id!)),
                                  );

                                  if (result == true) {
                                    // refresh lists
                                    final vm = Provider.of<HikeViewModel>(context, listen: false);
                                    vm.loadFeed();
                                    vm.loadRemarkable();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hike updated')));
                                    }
                                  }
                                },
                              ),
                            );
                          },
                        ),
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

  List<Hike> _getFilteredHikes(HikeViewModel vm) {
    switch (_selectedFilter) {
      case 'Remarkable 🌟':
        return vm.remarkable;
      case 'Recent':
        return vm.feed.take(10).toList();
      case 'Easy':
        return vm.feed.where((h) => h.difficulty == 'Easy').toList();
      case 'Moderate':
        return vm.feed.where((h) => h.difficulty == 'Moderate').toList();
      case 'Hard':
        return vm.feed.where((h) => h.difficulty == 'Hard').toList();
      default:
        return vm.feed;
    }
  }

  Widget _buildFilters(ThemeData theme) {
    return SizedBox(
      height: 56, // taller filter bar for more vertical breathing room
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
        children: [
          _filter("All", theme),
          _filter("Remarkable 🌟", theme),
          _filter("Recent", theme),
          _filter("Easy", theme),
          _filter("Moderate", theme),
          _filter("Hard", theme),
        ],
      ),
    );
  }

  Widget _filter(String label, ThemeData theme) {
    final active = _selectedFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
          _initialized = false;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: active ? theme.colorScheme.primary : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: active
              ? null
              : [
            BoxShadow(
              color: theme.dividerColor.withOpacity(0.6),
              blurRadius: 4,
            )
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : theme.textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
