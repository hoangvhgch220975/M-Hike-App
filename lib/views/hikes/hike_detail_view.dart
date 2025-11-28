import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/hike.dart';
import '../../viewmodels/hike_viewmodel.dart';
import 'hike_form_view.dart';

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
    final vm = Provider.of<HikeViewModel>(context, listen: false);
    final h = await vm.getHikeById(widget.hikeId);
    setState(() {
      _hike = h;
      _isLoading = false;
    });
  }

  Future<void> _markComplete() async {
    if (_hike == null || _hike!.id == null) return;
    final vm = Provider.of<HikeViewModel>(context, listen: false);
    await vm.markHikeAsCompleted(_hike!.id!);
    await _loadHike();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hike marked as completed')));
    }
  }

  Future<void> _deleteHike() async {
    if (_hike == null || _hike!.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete hike?'),
        content: Text('Are you sure you want to delete "${_hike!.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    final vm = Provider.of<HikeViewModel>(context, listen: false);
    final success = await vm.deleteHike(_hike!.id!);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Hike deleted' : 'Failed to delete hike')));
      if (success) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Colors adapted from original palette but using theme where appropriate
    final primary = cs.primary;
    final accent = cs.secondary;
    final secondaryText = isDark ? Colors.grey.shade300 : const Color(0xFF8B4513);
    final danger = Colors.red;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: cs.onBackground),
        actions: [
          // Popup menu for Edit/Delete
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
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
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
                          backgroundColor: cs.background,
                          flexibleSpace: FlexibleSpaceBar(
                            background: Stack(
                              children: [
                                // Placeholder hero area - use a subtle gradient
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          cs.surface,
                                          cs.background.withOpacity(0.9),
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(Icons.park, size: 84, color: cs.primary),
                                    ),
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
                                        colors: [cs.surface, cs.surface.withOpacity(0.66), Colors.transparent],
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
                                Text(
                                  _hike!.name,
                                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.onBackground),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.location_on, size: 20, color: cs.onBackground.withOpacity(0.6)),
                                    const SizedBox(width: 6),
                                    Text(
                                      _hike!.location,
                                      style: theme.textTheme.bodyMedium?.copyWith(color: cs.onBackground.withOpacity(0.7), fontWeight: FontWeight.w500),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 20),

                                _infoGrid(
                                  primary,
                                  date: _hike!.date,
                                  length: "${_hike!.length.toStringAsFixed(1)} km",
                                  difficulty: _hike!.difficulty,
                                  parking: 'N/A',
                                ),

                                const SizedBox(height: 20),
                                Text(
                                  'Description',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: secondaryText),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _hike!.description ?? 'No description provided.',
                                  style: theme.textTheme.bodyMedium?.copyWith(color: cs.onBackground.withOpacity(0.75), height: 1.5),
                                ),

                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    _pill(primary, Icons.check_circle, 'Complete', active: _hike!.isComplete),
                                    const SizedBox(width: 12),
                                    _pill(cs.secondary, Icons.star, 'Remarkable', active: _hike!.isRemarkable),
                                  ],
                                ),

                                const SizedBox(height: 24),
                                Text(
                                  'Observations',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: secondaryText),
                                ),
                                const SizedBox(height: 12),

                                // Observations list - use hike.observations if available
                                if (_hike!.observations.isEmpty) ...[
                                  Text('No observations yet.', style: theme.textTheme.bodyMedium),
                                ] else ...[
                                  _observationList(_hike!.observations),
                                ],

                                const SizedBox(height: 120),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Bottom area: show mark complete button only when it's a planned hike
                    if (!_hike!.isComplete)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          color: cs.surface.withOpacity(0.98),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _markComplete,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: cs.primary,
                                    foregroundColor: cs.onPrimary,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Mark as complete', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                  ],
                )),
    );
  }

  Widget _infoGrid(Color primary,
      {required String date, required String length, required String difficulty, required String parking}) {
    Widget tile(IconData icon, String label, String value) {
      return Container(
        padding: const EdgeInsets.all(16),
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
            Icon(icon, color: primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor)),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            )
          ],
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.15) : color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ))
        ],
      ),
    );
  }

  Widget _observationList(List observations) {
    Widget card(String imgUrl, String text, String time) {
      return Container(
        width: 260,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              blurRadius: 8,
              offset: Offset(0, 3),
              color: Color(0x11000000),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(imgUrl, height: 70, width: 70, fit: BoxFit.cover),
            ),
            const SizedBox(height: 12),
            Text(
              text,
              style: TextStyle(fontSize: 14, color: Theme.of(context).hintColor, height: 1.4),
            ),
            const SizedBox(height: 6),
            Text(
              time,
              style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor.withOpacity(0.8)),
            )
          ],
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: observations.map<Widget>((obs) {
          // Each observation should carry image/time/text — if not available, show a simple tile
          final img = (obs is Map && obs['img'] != null) ? obs['img'] as String : null;
          final text = (obs is Map && obs['text'] != null) ? obs['text'] as String : (obs?.caption ?? 'Observation');
          final time = (obs is Map && obs['time'] != null) ? obs['time'] as String : (obs?.time ?? '');

          return img != null ? card(img, text, time) : Container(
            width: 260,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: TextStyle(color: Theme.of(context).hintColor)),
                const SizedBox(height: 6),
                Text(time, style: TextStyle(color: Theme.of(context).hintColor.withOpacity(0.8), fontSize: 11)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
