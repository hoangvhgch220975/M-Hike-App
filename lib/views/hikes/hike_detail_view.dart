import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/hike.dart';
import '../../db/app_db.dart';
import '../../viewmodels/hike_viewmodel.dart';
import 'hike_form_view.dart';
import '../observations/no_observation_card.dart';

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

    // Read the hike directly from the database to ensure fields like
    // isComplete/isRemarkable are authoritative and up-to-date.
    Hike? h;
    try {
      h = await AppDatabase.instance.getHikeById(widget.hikeId);
    } catch (e) {
      h = null;
    }

    // Load observations for this hike from DB
    List observations = [];
    try {
      observations = await AppDatabase.instance.getObservationsByHike(widget.hikeId);
    } catch (e) {
      observations = [];
    }

    if (!mounted) return;
    setState(() {
      if (h != null) {
        h.observations = List.from(observations);
      }
      _hike = h;
      _isLoading = false;
    });
  }

  Future<void> _markComplete() async {
    // Removed: status is display-only in this view; no action performed.
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

  void _onAddObservation() async {
    // Centralized add-observation handler. Replace navigation to a real
    // AddObservationView if you have one; currently shows a placeholder.
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add observation flow not implemented')));
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
      // Show a floating action button to add more observations when the hike
      // is completed and already contains at least one observation. When the
      // hike has no observations we keep the Add button inside the empty-state
      // `NoObservationCard` so the FAB is not shown in that case.
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
                          automaticallyImplyLeading: false,
                          backgroundColor: cs.background,
                          flexibleSpace: FlexibleSpaceBar(
                            background: Stack(
                              children: [
                                // Placeholder hero area - use a subtle gradient
                                Positioned.fill(
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      // Banner image (uses the placeholder asset when no banner image provided)
                                      Image.asset('lib/assets/images/imageholder.png', fit: BoxFit.cover),
                                      // Gradient overlay to keep legibility on top of the image
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              cs.surface.withOpacity(0.28),
                                              cs.background.withOpacity(0.88),
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
                                // Status tag: Completed or Planned
                                if (_hike!.isComplete)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: cs.primary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text('Completed', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text('Planned', style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w700, fontSize: 12)),
                                  ),
                                const SizedBox(height: 12),
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
                                  parking: _hike!.hasParking ? 'Yes' : 'No',
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
                                    // Use a consistent yellow for Remarkable
                                    _pill(const Color(0xFFFFD700), Icons.star, 'Remarkable', active: _hike!.isRemarkable),
                                  ],
                                ),

                                const SizedBox(height: 24),
                                Text(
                                  'Observations',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: secondaryText),
                                ),
                                const SizedBox(height: 12),

                                // Observations are only allowed for completed hikes.
                                // If the hike is planned, show an informational card stating
                                // observations cannot be added until the hike is completed.
                                if (!_hike!.isComplete) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: const [BoxShadow(blurRadius: 6, offset: Offset(0, 2), color: Color(0x11000000))],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(color: cs.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                                          child: Icon(Icons.info_outline, color: cs.primary),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Hike is planned', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                                              const SizedBox(height: 6),
                                              Text('Observations can only be added after the hike has been completed.', style: theme.textTheme.bodySmall),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  // Hike is complete: show observations if present, or the addable empty state.
                                  if (_hike!.observations.isEmpty) ...[
                                    NoObservationCard(
                                      onAdd: _onAddObservation,
                                    ),
                                  ] else ...[
                                    _observationList(_hike!.observations),
                                  ],
                                ],

                                const SizedBox(height: 120),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Removed bottom action area — detail view is read-only now.
                  ],
                )),
    );
  }

  Widget _infoGrid(Color primary,
      {required String date, required String length, required String difficulty, required String parking}) {
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
            // Make text wrap/ellipsis safely to prevent overflow
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
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

    // Stronger amber for Remarkable so it looks clearly yellow on light backgrounds
    const Color amberMain = Color(0xFFFFC107); // amber 500
    const Color amberBgActive = Color(0xFFFFF8E1); // amber 50
    const Color amberBgInactive = Color(0xFFFFF9E6);

    if (isStar) {
      // For the star (Remarkable) pill we'll show a clearly amber style when active,
      // and a muted/disabled appearance when inactive (bordered star, hintColor text, subdued bg).
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
        )
      );

    }

    // Non-star pills: show outlined variant when inactive, colored when active
    IconData displayIcon = icon;
    if (!active && icon == Icons.check_circle) displayIcon = Icons.check_circle_outline;

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
      )
    );
  }

  Widget _observationList(List observations) {
    Widget card(String? imgUrl, String text, String time) {
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
              child: imgUrl != null && imgUrl.isNotEmpty
                  ? Image.network(
                      imgUrl,
                      height: 70,
                      width: 70,
                      fit: BoxFit.cover,
                      // Show a small progress indicator while loading
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 70,
                          width: 70,
                          color: Theme.of(context).cardColor,
                          child: const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
                        );
                      },
                      // Fall back to the local placeholder if the network image fails
                      errorBuilder: (context, error, stackTrace) => Image.asset('lib/assets/images/imageholder.png', height: 70, width: 70, fit: BoxFit.cover),
                    )
                  : Image.asset('lib/assets/images/imageholder.png', height: 70, width: 70, fit: BoxFit.cover),
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
          // Each observation should carry image/time/text — if not available, show placeholder image
          final img = (obs is Map && obs['img'] != null) ? obs['img'] as String : null;
          final text = (obs is Map && obs['text'] != null) ? obs['text'] as String : (obs?.caption ?? 'Observation');
          final time = (obs is Map && obs['time'] != null) ? obs['time'] as String : (obs?.time ?? '');

          return card(img, text, time);
        }).toList(),
      ),
    );
  }
}
