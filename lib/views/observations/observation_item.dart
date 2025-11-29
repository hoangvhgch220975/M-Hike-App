import 'package:flutter/material.dart';

class ObservationItem extends StatelessWidget {
  final List<String> imageUrls;
  final String description;
  final String timestamp;

  const ObservationItem({
    super.key,
    required this.imageUrls,
    required this.description,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      width: MediaQuery.of(context).size.width * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 4),
            color: Color.fromARGB(20, 0, 0, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Images row
          Row(
            children: imageUrls.map((url) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(url),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Description
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 8),

          // Timestamp
          Text(
            timestamp,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
