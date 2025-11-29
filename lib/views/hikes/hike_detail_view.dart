import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../models/hike.dart';
import '../../db/app_db.dart';
import '../../viewmodels/hike_viewmodel.dart';
import 'hike_form_view.dart';
import '../observations/no_observation_card.dart';
import '../observations/observation_item.dart';
import '../observations/observation_list_view.dart';
import '../observations/observation_form_view.dart';

class HikeDetailView extends StatefulWidget {
  final int hikeId;

  const HikeDetailView({super.key, required this.hikeId});

  @override
  State<HikeDetailView> createState() => _HikeDetailViewState();
}

class _HikeDetailViewState extends State<HikeDetailView> {
  Hike? _hike;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHike();
  }

  Future<void> _loadHike() async {
    setState(() => _isLoading = true);

    // Use getHikeDetailData to fetch the hike together with all observations and media
    Hike? h;
    try {
      h = await AppDatabase.instance.getHikeDetailData(widget.hikeId);
    } catch (e) {
      h = null;
    }

    if (!mounted) return;
    setState(() {
      _hike = h;
      _isLoading = false;
    });
  }

  // Choose the best image to show in the banner:
  // 1) First image-type MediaItem from observations (most recent observations are first)
  // 2) Fallback to placeholder asset
  Widget _buildBannerImage() {
    // Find first image path
    String? path;
    if (_hike != null && _hike!.observations.isNotEmpty) {
      for (final obs in _hike!.observations) {
        if (obs.media.isNotEmpty) {
          // Find first media item whose type equals 'image' (case-insensitive)
          dynamic found;
          for (final m in obs.media) {
            try {
              if ((m.type).toLowerCase() == 'image') {
                found = m;
                break;
              }
            } catch (_) {
              // ignore malformed media entries
            }
          }
          if (found != null && (found.path as String).isNotEmpty) {
            path = found.path as String;
            break;
          }
        }
      }
    }

    // If we found a local file path and not running on web, show it
    if (path != null && path.isNotEmpty) {
      try {
        if (!kIsWeb) {
          final file = File(path);
          if (file.existsSync()) {
            return Image.file(file, fit: BoxFit.cover);
          }
        }

        // If path looks like a network URL, try Image.network
        if (path.startsWith('http://') || path.startsWith('https://')) {
          return Image.network(path, fit: BoxFit.cover);
        }
      } catch (_) {
        // ignore and fallthrough to placeholder
      }
    }

    // Default placeholder
    return Image.asset('lib/assets/images/imageholder.png', fit: BoxFit.cover);
  }

  Future<void> _markComplete() async {
    // intentionally empty
  }

  Future<void> _deleteHike() async {
    if (_hike == null || _hike!.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete hike?'),
        content: Text('Are you sure you want to delete "${_hike!.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final vm = Provider.of<HikeViewModel>(context, listen: false);
    final success = await vm.deleteHike(_hike!.id!);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Hike deleted' : 'Failed to delete hike')),
      );
      if (success) Navigator.of(context).pop(true);
    }
  }

  void _onAddObservation() async {
    if (!mounted) return;
    final result = await Navigator.of(context).push<bool?>(
      MaterialPageRoute(builder: (_) => ObservationFormView(hikeId: _hike?.id)),
    );

    if (result == true) {
      await _loadHike();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Observation added')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final primary = cs.primary;
    final secondaryText = isDark ? Colors.grey.shade300 : const Color(0xFF8B4513);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // Show the floating add button only when the hike is complete AND
      // there is at least one observation (per requested behavior). When
      // there are no observations, the NoObservationCard will render its
      // own Add button and the FAB is hidden to avoid duplicate controls.
      floatingActionButton: (!_isLoading && _hike != null && _hike!.isComplete && _hike!.observations.isNotEmpty)
          ? FloatingActionButton.extended(
        onPressed: _onAddObservation,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Add observation'),
      )
          : null,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: cs.onBackground),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                if (_hike != null) {
                  final result = await Navigator.of(context).push<bool?>(
                    MaterialPageRoute(builder: (_) => HikeFormView(hike: _hike)),
                  );
                  if (result == true) await _loadHike();
                }
              } else if (value == 'delete') {
                await _deleteHike();
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
            icon: Icon(Icons.more_vert, color: cs.onBackground),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_hike == null
          ? Center(child: Text('Hike not found', style: theme.textTheme.bodyLarge))
          : Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 300,
                automaticallyImplyLeading: false,
                backgroundColor: cs.background,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      Positioned.fill(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // show hike/observation image when available, otherwise placeholder
                            _buildBannerImage(),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    cs.surface.withOpacity(0.1),
                                    cs.background.withOpacity(0.05),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                cs.surface,
                                cs.surface.withOpacity(0.66),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_hike!.isComplete)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: cs.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Completed',
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.cardColor.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Planned',
                            style: TextStyle(
                              color: theme.hintColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      Text(
                        _hike!.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onBackground,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Icon(Icons.location_on, size: 20, color: cs.onBackground.withOpacity(0.6)),
                          const SizedBox(width: 6),
                          Text(
                            _hike!.location,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onBackground.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        ],
                      ),

                      const SizedBox(height: 20),

                      _infoGrid(
                        primary,
                        date: _hike!.date,
                        length: "${_hike!.length.toStringAsFixed(1)} km",
                        difficulty: _hike!.difficulty,
                        parking: _hike!.hasParking ? 'Yes' : 'No',
                      ),

                      const SizedBox(height: 20),

                      Text(
                        'Description',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: secondaryText,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        _hike!.description ?? 'No description provided.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onBackground.withOpacity(0.75),
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          _pill(primary, Icons.check_circle, 'Complete', active: _hike!.isComplete),
                          const SizedBox(width: 12),
                          _pill(const Color(0xFFFFD700), Icons.star, 'Remarkable', active: _hike!.isRemarkable),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Text(
                        'Observations',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: secondaryText,
                        ),
                      ),

                      const SizedBox(height: 12),

                      if (!_hike!.isComplete)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 6,
                                offset: Offset(0, 2),
                                color: Color(0x11000000),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: cs.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.info_outline, color: cs.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hike is planned',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Observations can only be added after the hike has been completed.',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_hike!.observations.isEmpty)
                        NoObservationCard(onAdd: _onAddObservation)
                      else ...[
                          ObservationListForHike(
                            hikeId: _hike!.id!,
                            limit: 5,
                            onChanged: () async {
                              // reload full hike data when inline list reports changes
                              await _loadHike();
                            },
                          ),

                          // If there are more than 5 observations, show a button to view them all
                          if (_hike!.observations.length > 5) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () async {
                                  final result = await Navigator.of(context).push<bool?>(
                                    MaterialPageRoute(builder: (_) => ObservationListView(hikeId: _hike!.id!)),
                                  );
                                  // If any deletion happened in the full list, reload hike
                                  if (result == true) await _loadHike();
                                },
                                child: const Text('View all observations'),
                              ),
                            ),
                          ],

                          const SizedBox(height: 120),
                        ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      )),
    );
  }

  Widget _infoGrid(
      Color primary, {
        required String date,
        required String length,
        required String difficulty,
        required String parking,
      }) {
    Widget tile(IconData icon, String label, String value) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              blurRadius: 8,
              offset: Offset(0, 3),
              color: Color(0x11000000),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.0,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        tile(Icons.calendar_month, "Date", date),
        tile(Icons.straighten, "Length", length),
        tile(Icons.trending_up, "Difficulty", difficulty),
        tile(Icons.local_parking, "Parking", parking),
      ],
    );
  }

  Widget _pill(Color color, IconData icon, String label, {bool active = false}) {
    final bool isStar = icon == Icons.star || icon == Icons.star_border;

    const Color amberMain = Color(0xFFFFC107);
    const Color amberBgActive = Color(0xFFFFF8E1);

    if (isStar) {
      final theme = Theme.of(context);
      final Color textColor = active ? amberMain : theme.hintColor;
      final Color bgColor = active ? amberBgActive : theme.cardColor.withOpacity(0.06);
      final IconData displayIcon = active ? Icons.star : Icons.star_border;
      final FontWeight fw = active ? FontWeight.w700 : FontWeight.w600;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(40)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(displayIcon, size: 16, color: textColor),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: textColor, fontWeight: fw, fontSize: 13)),
          ],
        ),
      );
    }

    final IconData displayIcon =
    (!active && icon == Icons.check_circle) ? Icons.check_circle_outline : icon;

    final Color textColor = active ? color : Theme.of(context).hintColor;
    final Color bgColor = active ? color.withOpacity(0.12) : Theme.of(context).cardColor.withOpacity(0.06);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(40)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(displayIcon, size: 16, color: textColor),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
