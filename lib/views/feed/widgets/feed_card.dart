// lib/views/feed/widgets/feed_card.dart

import 'package:flutter/material.dart';
import '../../../models/hike.dart';
import '../../../db/app_db.dart';
import '../../shared/notification_helper.dart';

class FeedCard extends StatefulWidget {
  final Hike hike;
  final VoidCallback? onRemarkableChanged;
  final VoidCallback? onTap;

  const FeedCard({
    super.key,
    required this.hike,
    this.onRemarkableChanged,
    this.onTap,
  });

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> {
  late bool _isRemarkable;

  @override
  void initState() {
    super.initState();
    _isRemarkable = widget.hike.isRemarkable;
  }

  Future<void> _toggleRemarkable() async {
    final newValue = !_isRemarkable;

    // Update in database
    final updatedHike = Hike(
      id: widget.hike.id,
      name: widget.hike.name,
      location: widget.hike.location,
      date: widget.hike.date,
      length: widget.hike.length,
      difficulty: widget.hike.difficulty,
      description: widget.hike.description,
      isComplete: widget.hike.isComplete,
      isRemarkable: newValue,
      hasParking: widget.hike.hasParking,
    );

    try {
      await AppDatabase.instance.updateHike(updatedHike);

      setState(() {
        _isRemarkable = newValue;
      });

      // Show notification
      if (newValue) {
        if (mounted) {
          NotificationHelper.showSuccess(
            context,
            '⭐ "${widget.hike.name}" marked as remarkable!',
          );
        }
      } else {
        if (mounted) {
          NotificationHelper.showInfo(
            context,
            'Removed remarkable status from "${widget.hike.name}"',
          );
        }
      }

      // Notify parent to refresh
      widget.onRemarkableChanged?.call();
    } catch (e) {
      if (mounted) {
        NotificationHelper.showError(
          context,
          'Failed to update remarkable status',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _FeedColors();

    // Generate tags based on hike properties
    final tags = _generateTags();

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE - Show default hike image with remarkable button
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.asset(
                      'lib/assets/images/imageholder.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Remarkable button overlay
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: _toggleRemarkable,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isRemarkable
                            ? const Color(0xFFFFD700)
                            : Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRemarkable ? Icons.star : Icons.star_border,
                        color: _isRemarkable
                            ? Colors.white
                            : const Color(0xFF6B7280),
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // CONTENT
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.hike.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 6),

                  _iconText(Icons.location_on, widget.hike.location),
                  const SizedBox(height: 4),
                  _iconText(Icons.calendar_today, widget.hike.date),
                  const SizedBox(height: 4),
                  _iconText(Icons.straighten, '${widget.hike.length.toStringAsFixed(1)} km'),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tags.map((t) => _tagChip(t)).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FeedTag> _generateTags() {
    List<FeedTag> tags = [];

    // Difficulty tag
    Color difficultyColor;
    IconData difficultyIcon;
    switch (widget.hike.difficulty) {
      case 'Easy':
        difficultyColor = Colors.green;
        difficultyIcon = Icons.directions_walk;
        break;
      case 'Moderate':
        difficultyColor = Colors.lightBlue;
        difficultyIcon = Icons.hiking;
        break;
      case 'Hard':
        difficultyColor = Colors.indigo;
        difficultyIcon = Icons.landscape;
        break;
      default:
        difficultyColor = Colors.grey;
        difficultyIcon = Icons.help_outline;
    }
    tags.add(FeedTag(widget.hike.difficulty, difficultyColor, difficultyIcon));

    // Completed tag
    if (widget.hike.isComplete) {
      tags.add(const FeedTag("Completed", Color(0xFF225749)));
    }

    // Remarkable tag (use state variable for real-time updates)
    if (_isRemarkable) {
      tags.add(const FeedTag("Remarkable 🌟", Color(0xFFFFD700)));
    }

    return tags;
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _tagChip(FeedTag tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tag.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tag.icon != null) ...[
            Icon(tag.icon, size: 14, color: tag.color),
            const SizedBox(width: 4),
          ],
          Text(
            tag.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: tag.color,
            ),
          ),
        ],
      ),
    );
  }
}

// TAG MODEL
class FeedTag {
  final String label;
  final Color color;
  final IconData? icon;

  const FeedTag(this.label, this.color, [this.icon]);
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
