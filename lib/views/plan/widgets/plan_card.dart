// lib/views/plan/widgets/plan_card.dart

import 'package:flutter/material.dart';
import '../../../models/hike.dart';

class PlanCard extends StatelessWidget {
  final Hike hike;
  final VoidCallback? onCompleted;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  // Optional override color for the complete button (if null, uses theme.primary)
  final Color? completeButtonColor;

  const PlanCard({
    super.key,
    required this.hike,
    this.onCompleted,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.completeButtonColor,
  });

  @override
  Widget build(BuildContext context) {
    // Determine difficulty color
    Color difficultyColor;
    switch (hike.difficulty) {
      case 'Easy':
        difficultyColor = const Color(0xFF4CAF50);
        break;
      case 'Moderate':
        difficultyColor = const Color(0xFFFF9800);
        break;
      case 'Hard':
        difficultyColor = const Color(0xFFF44336);
        break;
      default:
        difficultyColor = Colors.grey;
    }

    final theme = Theme.of(context);
    // Use provided completeButtonColor for this card if present, otherwise fall back to theme primary
    final primary = completeButtonColor ?? theme.colorScheme.primary;
    // Determine icon color that contrasts with the chosen primary
    final onPrimary = ThemeData.estimateBrightnessForColor(primary) == Brightness.dark ? Colors.white : Colors.black;

    // Show options when user taps the overflow button
    void _showOptions() async {
      showModalBottomSheet<void>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        builder: (ctx) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    if (onEdit != null) onEdit!();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.of(ctx).pop();

                    // Confirm deletion
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dCtx) {
                        return AlertDialog(
                          title: const Text('Delete hike?'),
                          content: Text('Are you sure you want to delete "${hike.name}"? This action cannot be undone.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(dCtx).pop(false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.of(dCtx).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                          ],
                        );
                      },
                    );

                    if (confirm == true && onDelete != null) {
                      onDelete!();
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.close),
                  title: const Text('Cancel'),
                  onTap: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          );
        },
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        // Outer InkWell handles both tap (open detail) and long-press (open options)
        onTap: onTap,
        onLongPress: _showOptions,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color.fromARGB(30, 0, 0, 0),
                offset: Offset(0, 8),
                blurRadius: 24,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + Location + Date + Complete Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hike.name, style: theme.textTheme.titleMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(hike.location, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w500)),
                            const SizedBox(width: 6),
                            Text('•', style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
                            const SizedBox(width: 6),
                            Text(hike.date, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Tick button to mark as completed (no overflow button; long-press the card for options)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onCompleted,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(Icons.check, size: 20, color: onPrimary),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                hike.description ?? 'No description available',
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, height: 1.5, color: theme.hintColor),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 16),

              // Difficulty + Length
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: difficultyColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: difficultyColor.withOpacity(0.2)),
                    ),
                    child: Text(
                      hike.difficulty,
                      style: theme.textTheme.bodyMedium?.copyWith(color: difficultyColor, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    "${hike.length.toStringAsFixed(1)} km",
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
