// lib/views/feed/widgets/feed_card.dart

import 'package:flutter/material.dart';
import '../../../models/hike.dart';

class FeedCard extends StatelessWidget {
  final Hike hike;

  const FeedCard({super.key, required this.hike});

  @override
  Widget build(BuildContext context) {
    final c = _FeedColors();

    // Generate tags based on hike properties
    final tags = _generateTags();

    return Container(
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
          // IMAGE - Show default hike image
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

          // CONTENT
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hike.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 6),

                _iconText(Icons.location_on, hike.location),
                const SizedBox(height: 4),
                _iconText(Icons.calendar_today, hike.date),
                const SizedBox(height: 4),
                _iconText(Icons.straighten, '${hike.length.toStringAsFixed(1)} km'),

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
    );
  }

  List<FeedTag> _generateTags() {
    List<FeedTag> tags = [];

    // Difficulty tag
    Color difficultyColor;
    IconData difficultyIcon;
    switch (hike.difficulty) {
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
    tags.add(FeedTag(hike.difficulty, difficultyColor, difficultyIcon));

    // Completed tag
    if (hike.isComplete) {
      tags.add(const FeedTag("Completed", Color(0xFF225749)));
    }

    // Remarkable tag
    if (hike.isRemarkable) {
      tags.add(const FeedTag("Remarkable 🌟", Colors.amber));
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

