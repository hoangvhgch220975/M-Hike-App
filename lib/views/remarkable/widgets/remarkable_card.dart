import 'package:flutter/material.dart';
import '../../../models/hike.dart';

class RemarkableCard extends StatelessWidget {
  final Hike hike;
  final VoidCallback? onTap;

  const RemarkableCard({super.key, required this.hike, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(105, 129, 142, 0.15),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image (use placeholder asset as default)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: Image.asset(
                    'lib/assets/images/imageholder.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, size: 48, color: Colors.grey),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0288D1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Text(
                        'Remarkable 🌟',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0288D1),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hike.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hike.location,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    // optional description
                    if (hike.description != null && hike.description!.isNotEmpty)
                      Text(
                        hike.description!,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF6C757D), height: 1.4),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
