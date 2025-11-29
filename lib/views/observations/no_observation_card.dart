import 'package:flutter/material.dart';

/// A small reusable card shown when a hike has no observations yet.
///
/// Provides an optional `onAdd` callback so callers can wire up navigation
/// to the Add Observation flow. Uses the project's image placeholder asset
/// `lib/assets/images/imageholder.png`.
class NoObservationCard extends StatelessWidget {
  final VoidCallback? onAdd;
  final String message;

  const NoObservationCard({Key? key, this.onAdd, this.message = 'No observations yet.'}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(blurRadius: 8, offset: Offset(0, 3), color: Color(0x11000000))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Replace the placeholder image with a representative icon that
          // adapts to the app's color scheme. This avoids relying on an
          // external asset and provides a clean, modern look.
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Tooltip(
                message: 'No observations yet',
                child: Semantics(
                  label: 'No observations image',
                  child: Icon(
                    Icons.photo_camera_outlined,
                    size: 56,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Add observations to capture photos, notes and media for this hike.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            textAlign: TextAlign.center,
          ),
          if (onAdd != null) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Add observation'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
            ),
          ]
        ],
      ),
    );
  }
}
