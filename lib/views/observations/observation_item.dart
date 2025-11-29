import 'dart:io';
import 'package:flutter/material.dart';
import '../../db/app_db.dart';
import '../../models/observation.dart';
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        width: MediaQuery.of(context).size.width * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              blurRadius: 12,
              offset: Offset(0, 4),
              color: Color.fromARGB(20, 0, 0, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: caption and metadata
            Text(
              observation.caption.isNotEmpty ? observation.caption : 'Observation',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.titleMedium?.color),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // Full Content
            Text(
              observation.content,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
            ),

            const SizedBox(height: 12),

            // Thumbnails row (if any)
            if (observation.media.isNotEmpty) ...[
              SizedBox(
                height: 72,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: observation.media.map((m) {
                    final isVideo = (m.type ?? '').toLowerCase() == 'video';
                    if (!isVideo) {
                      final provider = _providerForPath(m.path);
                      return GestureDetector(
                        onTap: () => _showFullImage(context, m.path),
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
                        onTap: () {
                          // open full-screen video player
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => VideoPlayerView(path: m.path)));
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(margin: const EdgeInsets.only(right: 8), width: 72, height: 72, child: ClipRRect(borderRadius: BorderRadius.circular(12), child: thumb)),
                            const Icon(Icons.play_circle_outline, color: Colors.white, size: 32),
                          ],
                        ),
                      );
                    }
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 12),

            // Footer: timestamp and media count (IDs removed)
            Row(
              children: [
                Text(observation.time, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const Spacer(),
                Text('${observation.media.length} media', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
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
    if (_isLoading) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    if (_error != null) return SizedBox(height: 200, child: Center(child: Text('Failed to load observations')));
    if (_observations.isEmpty) return const SizedBox(height: 200, child: Center(child: Text('No observations')));

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
