// lib/views/plan/widgets/plan_card.dart

import 'package:flutter/material.dart';
import '../../../models/hike.dart';

class PlanCard extends StatelessWidget {
  final Hike hike;
  final VoidCallback? onCompleted;

  const PlanCard({
    super.key,
    required this.hike,
    this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    // Determine difficulty color
    Color difficultyColor;
    switch (hike.difficulty) {
      case 'Easy':
        difficultyColor = Colors.green;
        break;
      case 'Moderate':
        difficultyColor = Colors.orange;
        break;
      case 'Hard':
        difficultyColor = Colors.red;
        break;
      default:
        difficultyColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(20, 0, 0, 0),
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
                    Text(
                      hike.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          hike.location,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "•",
                          style: TextStyle(color: Color(0xFF9CA3AF)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          hike.date,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Tick button to mark as completed
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onCompleted,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF2E7D32).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 20,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Description
          Text(
            hike.description ?? 'No description available',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
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
                  style: TextStyle(
                    color: difficultyColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                "${hike.length.toStringAsFixed(1)} km",
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1C1C1E),
                  fontWeight: FontWeight.w600,
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}

