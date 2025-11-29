import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../db/app_db.dart';
import '../../models/hike.dart';
import '../../viewmodels/hike_viewmodel.dart';
import 'empty_remarkable_view.dart';
import 'widgets/remarkable_card.dart';
import '../hikes/hike_detail_view.dart';

class RemarkableView extends StatefulWidget {
  const RemarkableView({super.key});

  @override
  State<RemarkableView> createState() => _RemarkableViewState();
}

class _RemarkableViewState extends State<RemarkableView> {
  final ScrollController _controller = ScrollController();
  List<Hike> _allHikes = [];
  List<Hike> _displayed = [];
  bool _initialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  bool _showGreenAppBar = false; // AppBar color animation
  bool _isBottomRefreshing = false;

  final int _pageSize = 3; // items per "page" when loading more

  @override
  void initState() {
    super.initState();
    _loadAllRemarkable();
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

    // Change AppBar color when scrolled
    final offset = _controller.offset;
    final shouldShowGreen = offset > 0; // Show green after any scroll to match Feed/Plan

    if (shouldShowGreen != _showGreenAppBar) {
      setState(() {
        _showGreenAppBar = shouldShowGreen;
      });
    }

    // Load more logic
    if (_isLoadingMore || !_hasMore) return;
    final threshold = 120.0; // px from bottom to trigger
    if (_controller.position.maxScrollExtent - _controller.position.pixels <= threshold) {
      _loadMore();
    }
  }

  void _triggerBottomRefresh() async {
    if (_isBottomRefreshing) return;
    setState(() {
      _isBottomRefreshing = true;
    });

    await Future.delayed(const Duration(milliseconds: 1200));
    await _loadAllRemarkable();

    if (mounted) {
      final vm = Provider.of<HikeViewModel>(context, listen: false);
      vm.loadFeed();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Remarkable updated')));
    }

    setState(() {
      _isBottomRefreshing = false;
    });
  }

  Future<void> _loadAllRemarkable() async {
    setState(() {
      _initialLoading = true;
      _error = null;
    });

    try {
      final hikes = await AppDatabase.instance.getRemarkableHikes();
      if (!mounted) return;
      _allHikes = hikes;
      if (_allHikes.isEmpty) {
        // nothing to display; EmptyRemarkableView will be returned from build
        setState(() {
          _initialLoading = false;
          _hasMore = false;
          _displayed = [];
        });
        return;
      }

      final firstCount = _allHikes.length > _pageSize ? _pageSize : _allHikes.length;
      setState(() {
        _displayed = _allHikes.take(firstCount).toList();
        _hasMore = _displayed.length < _allHikes.length;
        _initialLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _initialLoading = false;
      });
    }
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_initialLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: colorScheme.primary)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(child: Text('Error loading remarkable hikes: $_error', style: theme.textTheme.bodyMedium)),
      );
    }

    if (_allHikes.isEmpty) {
      return const EmptyRemarkableView();
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: _showGreenAppBar ? colorScheme.primary.withOpacity(0.12) : theme.cardColor.withOpacity(0.9),
        elevation: _showGreenAppBar ? 2 : 0,
        automaticallyImplyLeading: true,
        centerTitle: true,
        title: Text('Remarkable Hikes', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        color: colorScheme.primary,
        onRefresh: _loadAllRemarkable,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification || notification is OverscrollNotification) {
              final metrics = notification.metrics;
              if (metrics.pixels > metrics.maxScrollExtent &&
                  metrics.pixels - metrics.maxScrollExtent > 80) {
                _triggerBottomRefresh();
              }
            }
            return false;
          },
          child: ListView.builder(
            controller: _controller,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: _displayed.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _displayed.length) {
                // footer: show loading spinner while searching for more; if none, footer will be hidden
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: _isLoadingMore
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: colorScheme.secondary,
                                  strokeWidth: 3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('Searching for more...', style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                );
              }

              final hike = _displayed[index];
              return RemarkableCard(
                hike: hike,
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
                    // Reload the remarkable hikes list
                    await _loadAllRemarkable();
                    // Refresh the feed as well
                    final vm = Provider.of<HikeViewModel>(context, listen: false);
                    vm.loadFeed();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hike updated')));
                    }
                  }
                },
                onRemarkableChanged: () {
                  // Reload the remarkable hikes list
                  _loadAllRemarkable();
                  // Refresh the feed as well
                  final vm = Provider.of<HikeViewModel>(context, listen: false);
                  vm.loadFeed();
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
