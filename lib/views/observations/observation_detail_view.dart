import 'dart:io';
import 'package:flutter/material.dart';
import '../../db/app_db.dart';
import '../../models/observation.dart';
import '../../models/media_item.dart';
import 'observation_form_view.dart';
import 'video_handler/video_player_view.dart';

class ObservationDetailView extends StatefulWidget {
  final int observationId;
  const ObservationDetailView({super.key, required this.observationId});

  @override
  State<ObservationDetailView> createState() => _ObservationDetailViewState();
}

class _ObservationDetailViewState extends State<ObservationDetailView> {
  bool _isLoading = true;
  Observation? _observation;
  String? _error;
  late PageController _pageController;
  int _currentMediaIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadObservation();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadObservation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final obs = await AppDatabase.instance.getObservationById(widget.observationId);
      if (!mounted) return;
      setState(() {
        _observation = obs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  ImageProvider _providerForPath(String path) {
    if (path.startsWith('http') || path.startsWith('https')) return NetworkImage(path);
    if (path.startsWith('file://')) return FileImage(File(path.replaceFirst('file://', '')));
    if (path.startsWith('/') || (Platform.isWindows && RegExp(r'^[a-zA-Z]:\\').hasMatch(path))) return FileImage(File(path));
    return AssetImage(path) as ImageProvider;
  }

  void _showFullImage(String path) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: InteractiveViewer(
          child: Image(
            image: _providerForPath(path),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(body: const Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(body: Center(child: Text('Failed to load observation')));
    }

    if (_observation == null) {
      return Scaffold(body: Center(child: Text('Observation not found')));
    }

    // Build media list for PageView
    final mediaList = _observation!.media.isNotEmpty
        ? _observation!.media
        : [MediaItem(id: null, observationId: widget.observationId, path: 'lib/assets/images/imageholder.png', type: 'image')];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Swipeable media gallery
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              itemCount: mediaList.length,
              onPageChanged: (index) {
                setState(() {
                  _currentMediaIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final mediaItem = mediaList[index];
                final isVideo = (mediaItem.type ?? '').toLowerCase() == 'video';

                if (isVideo) {
                  // Video thumbnail with play button overlay
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => VideoPlayerView(path: mediaItem.path),
                        ),
                      );
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image(
                          image: _providerForPath(mediaItem.path),
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) => Container(
                            color: Colors.black,
                            child: const Center(
                              child: Icon(Icons.videocam, size: 64, color: Colors.white54),
                            ),
                          ),
                        ),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Image
                  return GestureDetector(
                    onTap: () => _showFullImage(mediaItem.path),
                    child: Image(
                      image: _providerForPath(mediaItem.path),
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => Image.asset(
                        'lib/assets/images/imageholder.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }
              },
            ),
          ),

          // Media count indicator (top center)
          if (mediaList.length > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentMediaIndex + 1} / ${mediaList.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

          // Page dots indicator (below media count)
          if (mediaList.length > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 50,
              left: 0,
              right: 0,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    mediaList.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentMediaIndex == index ? 8 : 6,
                      height: _currentMediaIndex == index ? 8 : 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentMediaIndex == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Top close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.25 : 0.32),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(Icons.close, color: isDark ? Colors.black : Colors.white),
                ),
              ),
            ),
          ),

          // Bottom sheet overlay
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : const Color(0xffF5F5F5),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(blurRadius: 12, offset: const Offset(0, -2), color: Colors.black.withOpacity(isDark ? 0.5 : 0.12)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _observation!.caption.isNotEmpty ? _observation!.caption : 'Observation',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ) ?? const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _observation!.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      height: 1.5,
                    ) ?? const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 16),

                  // Thumbnails: show all media as horizontal list with current selection indicator
                  if (_observation!.media.isNotEmpty) ...[
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _observation!.media.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (ctx, i) {
                          final MediaItem m = _observation!.media[i];
                          final provider = _providerForPath(m.path);
                          final isVideo = (m.type ?? '').toLowerCase() == 'video';
                          final isSelected = i == _currentMediaIndex;

                          return GestureDetector(
                            onTap: () {
                              // Jump to this media in the PageView
                              _pageController.animateToPage(
                                i,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? Border.all(color: theme.primaryColor, width: 3)
                                    : null,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Image(
                                      image: provider,
                                      width: 100,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Container(
                                        color: theme.cardColor,
                                        width: 100,
                                        height: 80,
                                        child: const Icon(Icons.broken_image),
                                      ),
                                    ),
                                    if (isVideo)
                                      const Icon(
                                        Icons.play_circle_outline,
                                        color: Colors.white,
                                        size: 36,
                                      ),
                                    if (!isSelected)
                                      Container(
                                        width: 100,
                                        height: 80,
                                        color: Colors.black.withOpacity(0.3),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Row(
                    children: [
                      // Edit button
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(isDark ? 0.2 : 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextButton.icon(
                            onPressed: () async {
                              if (_observation?.id == null) return;
                              final result = await Navigator.of(context).push<bool?>(
                                MaterialPageRoute(builder: (_) => ObservationFormView(observationId: _observation!.id, hikeId: _observation!.hikeId)),
                              );
                              if (result == true) {
                                // If edited, reload locally then inform upstream callers by popping true
                                await _loadObservation();
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Observation updated')));
                                Navigator.of(context).pop(true);
                              }
                            },
                            icon: Icon(Icons.edit, color: theme.primaryColor),
                            label: Text('Edit', style: TextStyle(color: theme.primaryColor)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Delete button
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(isDark ? 0.12 : 0.06),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextButton.icon(
                            onPressed: () async {
                              if (_observation?.id == null) return;
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete observation?'),
                                  content: const Text('Are you sure you want to delete this observation? This cannot be undone.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                    TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              );
                              if (confirm != true) return;
                              final deleted = await AppDatabase.instance.deleteObservation(_observation!.id!);
                              if (!mounted) return;
                              if (deleted > 0) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Observation deleted')));
                                Navigator.of(context).pop(true);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete observation')));
                                await _loadObservation();
                              }
                            },
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
