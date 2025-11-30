import 'dart:io';
import 'package:flutter/material.dart';
import '../../db/app_db.dart';
import '../../models/observation.dart';
import '../../models/media_item.dart';
import 'observation_detail_view.dart';
import 'video_handler/video_player_view.dart';

class ObservationItem extends StatelessWidget {
  final Observation observation;
  final VoidCallback? onTap;

  const ObservationItem({
    super.key,
    required this.observation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey.shade700;
    final footerColor = isDark ? Colors.grey[500] : Colors.grey.shade500;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        width: MediaQuery.of(context).size.width * 0.85,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              offset: const Offset(0, 4),
              color: isDark
                ? const Color.fromARGB(40, 0, 0, 0)
                : const Color.fromARGB(20, 0, 0, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: caption and metadata
            Text(
              observation.caption.isNotEmpty ? observation.caption : 'Observation',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // Full Content
            Text(
              observation.content,
              style: TextStyle(fontSize: 14, color: subtextColor, height: 1.4),
            ),

            const SizedBox(height: 12),

            // Thumbnails row (if any)
            if (observation.media.isNotEmpty) ...[
              SizedBox(
                height: 72,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: observation.media.length,
                  itemBuilder: (context, index) {
                    final m = observation.media[index];
                    final isVideo = (m.type ?? '').toLowerCase() == 'video';

                    if (!isVideo) {
                      final provider = _providerForPath(m.path);
                      return GestureDetector(
                        onTap: () => _showMediaGallery(context, observation.media, index),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(image: provider, fit: BoxFit.cover),
                          ),
                        ),
                      );
                    } else {
                      // Video tile: show a thumbnail if possible (FileImage) with a play overlay
                      Widget thumb;
                      try {
                        final provider = _providerForPath(m.path);
                        thumb = Image(image: provider, width: 72, height: 72, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.black));
                      } catch (_) {
                        thumb = Container(color: Colors.black, width: 72, height: 72);
                      }

                      return GestureDetector(
                        onTap: () => _showMediaGallery(context, observation.media, index),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(margin: const EdgeInsets.only(right: 8), width: 72, height: 72, child: ClipRRect(borderRadius: BorderRadius.circular(12), child: thumb)),
                            const Icon(Icons.play_circle_outline, color: Colors.white, size: 32),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 12),

            // Footer: timestamp and media count (IDs removed)
            Row(
              children: [
                Text(observation.time, style: TextStyle(fontSize: 12, color: footerColor)),
                const Spacer(),
                Text('${observation.media.length} media', style: TextStyle(fontSize: 12, color: footerColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Loads observations for a given hikeId from the database and renders a
/// horizontal list of [ObservationItem].
class ObservationListForHike extends StatefulWidget {
  final int hikeId;
  final int? limit; // optional: show only most recent N observations
  final void Function(Observation obs)? onObservationTap;
  // optional async callback fired when the inline list reports changes
  // (e.g. detail view deleted or edited an observation). Typed as
  // Future<void> Function()? so callers can pass async handlers.
  final Future<void> Function()? onChanged;

  const ObservationListForHike({
    super.key,
    required this.hikeId,
    this.onObservationTap,
    this.limit,
    this.onChanged,
  });

  @override
  State<ObservationListForHike> createState() => _ObservationListForHikeState();
}

class _ObservationListForHikeState extends State<ObservationListForHike> {
  bool _isLoading = true;
  List<Observation> _observations = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadObservations();
  }

  Future<void> _loadObservations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rows = await AppDatabase.instance.getObservationsByHike(widget.hikeId);
      if (!mounted) return;
      setState(() {
        _observations = rows;
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

  // Make this async so we can await navigation results and notify the
  // optional [onChanged] callback if the detail view signals changes.
  Future<void> _handleTapObservation(Observation obs) async {
    if (widget.onObservationTap != null) {
      widget.onObservationTap!(obs);
      return;
    }

    // Default: navigate to the ObservationDetailView (guard against missing id)
    if (obs.id == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Observation id missing')));
      }
      return;
    }

    final result = await Navigator.of(context).push<bool?>(
      MaterialPageRoute(builder: (_) => ObservationDetailView(observationId: obs.id!)),
    );

    // If the detail screen returned true (indicating something changed, e.g. deletion),
    // notify the parent via onChanged if provided.
    if (result == true && widget.onChanged != null) {
      await widget.onChanged!();
      // Also refresh our local list in case the DB changed
      await _loadObservations();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    if (_error != null) return SizedBox(
      height: 200,
      child: Center(
        child: Text(
          'Failed to load observations',
          style: theme.textTheme.bodyLarge,
        ),
      ),
    );
    if (_observations.isEmpty) return SizedBox(
      height: 200,
      child: Center(
        child: Text(
          'No observations',
          style: theme.textTheme.bodyLarge,
        ),
      ),
    );

    final display = widget.limit != null ? _observations.take(widget.limit!).toList() : _observations;

    return SizedBox(
      height: 300,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: display.map<Widget>((obs) {
          return ObservationItem(observation: obs, onTap: () { _handleTapObservation(obs); });
        }).toList(),
      ),
    );
  }
}

// Helper: choose an ImageProvider for a given path string.
ImageProvider _providerForPath(String path) {
  if (path.startsWith('http') || path.startsWith('https')) return NetworkImage(path);
  if (path.startsWith('file://')) return FileImage(File(path.replaceFirst('file://', '')));
  if (path.startsWith('/') || (Platform.isWindows && RegExp(r'^[a-zA-Z]:\\').hasMatch(path))) return FileImage(File(path));
  return AssetImage(path) as ImageProvider;
}

void _showFullImage(BuildContext context, String path) {
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

/// Show swipeable media gallery starting from a specific index
void _showMediaGallery(BuildContext context, List<MediaItem> mediaList, int initialIndex) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => _MediaGalleryView(
        mediaList: mediaList,
        initialIndex: initialIndex,
      ),
    ),
  );
}

/// Full-screen swipeable media gallery
class _MediaGalleryView extends StatefulWidget {
  final List<MediaItem> mediaList;
  final int initialIndex;

  const _MediaGalleryView({
    required this.mediaList,
    required this.initialIndex,
  });

  @override
  State<_MediaGalleryView> createState() => _MediaGalleryViewState();
}

class _MediaGalleryViewState extends State<_MediaGalleryView> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Swipeable media
          PageView.builder(
            controller: _pageController,
            itemCount: widget.mediaList.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final mediaItem = widget.mediaList[index];
              final isVideo = (mediaItem.type ?? '').toLowerCase() == 'video';

              if (isVideo) {
                // Video with play button
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
                      Center(
                        child: Image(
                          image: _providerForPath(mediaItem.path),
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, st) => Container(
                            color: Colors.black,
                            child: const Center(
                              child: Icon(
                                Icons.videocam,
                                size: 64,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            size: 56,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                // Image with zoom
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image(
                      image: _providerForPath(mediaItem.path),
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, st) => const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 64,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                );
              }
            },
          ),

          // Top bar with close button and counter
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    // Close button
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Counter
                    if (widget.mediaList.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${widget.mediaList.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Page dots indicator
          if (widget.mediaList.length > 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      widget.mediaList.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentIndex == index ? 8 : 6,
                        height: _currentIndex == index ? 8 : 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentIndex == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Helper: extract basename from a path or URL
String _basename(String path) {
  if (path.startsWith('http') || path.startsWith('https')) {
    try {
      final uri = Uri.parse(path);
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : path;
    } catch (_) {
      return path;
    }
  }

  var p = path;
  if (p.startsWith('file://')) p = p.replaceFirst('file://', '');
  // Normalize separators
  p = p.replaceAll('\\', '/');
  final parts = p.split('/');
  return parts.isNotEmpty ? parts.last : p;
}
