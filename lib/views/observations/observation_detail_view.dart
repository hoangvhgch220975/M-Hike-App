import 'dart:io';
import 'package:flutter/material.dart';
import '../../db/app_db.dart';
import '../../models/observation.dart';
import '../../models/media_item.dart';
import 'observation_form_view.dart';
import 'video_player_view.dart';

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

  @override
  void initState() {
    super.initState();
    _loadObservation();
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

    if (_isLoading) {
      return Scaffold(body: const Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(body: Center(child: Text('Failed to load observation')));
    }

    if (_observation == null) {
      return Scaffold(body: Center(child: Text('Observation not found')));
    }

    // Use the first media item as banner if available
    final bannerPath = _observation!.media.isNotEmpty ? _observation!.media.first.path : 'lib/assets/images/imageholder.png';
    final bannerProvider = _providerForPath(bannerPath);

    return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image(
              image: bannerProvider,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, st) => Image.asset('lib/assets/images/imageholder.png', fit: BoxFit.cover),
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
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.32), shape: BoxShape.circle),
                child: const Center(child: Icon(Icons.close, color: Colors.white)),
              ),
            ),
          ),

          // Bottom sheet overlay
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              decoration: BoxDecoration(
                color: const Color(0xffF5F5F5),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(blurRadius: 12, offset: const Offset(0, -2), color: Colors.black.withOpacity(0.12)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _observation!.caption.isNotEmpty ? _observation!.caption : 'Observation',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xff5C4033)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _observation!.content,
                    style: TextStyle(color: const Color(0xff5C4033).withOpacity(0.85), fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 16),

                  // Thumbnails: show all media as horizontal list
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
                          return GestureDetector(
                            onTap: () {
                              if (isVideo) {
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => VideoPlayerView(path: m.path)));
                              } else {
                                _showFullImage(m.path);
                              }
                            },
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
                                    errorBuilder: (c, e, s) => Container(color: theme.cardColor, width: 100, height: 80, child: const Icon(Icons.broken_image)),
                                  ),
                                  if (isVideo) const Icon(Icons.play_circle_outline, color: Colors.white, size: 36),
                                ],
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
                          decoration: BoxDecoration(color: const Color(0xff2F4F2F).withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
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
                            icon: const Icon(Icons.edit, color: Color(0xff2F4F2F)),
                            label: const Text('Edit', style: TextStyle(color: Color(0xff2F4F2F))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Delete button
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.06), borderRadius: BorderRadius.circular(20)),
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
