// filepath: c:\Users\Admin\OneDrive\Desktop\COMP1786\CW1786\Cross\m_hike_hybrid_app\lib\views\settings\statistics.dart

import 'package:flutter/material.dart';
import '../../db/app_db.dart';

class StatisticsView extends StatefulWidget {
  const StatisticsView({super.key});

  @override
  State<StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<StatisticsView> {
  int totalHikes = 0;
  int completedHikes = 0;
  int plannedHikes = 0;
  int remarkableHikes = 0;
  double totalDistance = 0.0;
  double averageDistance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final total = await AppDatabase.instance.getHikesCount();
    final completed = await AppDatabase.instance.getCompletedHikes();
    final planned = await AppDatabase.instance.getPlannedHikes();
    final remarkable = await AppDatabase.instance.getRemarkableHikes();

    // Calculate total distance
    double distance = 0.0;
    for (var hike in completed) {
      distance += hike.length;
    }

    setState(() {
      totalHikes = total;
      completedHikes = completed.length;
      plannedHikes = planned.length;
      remarkableHikes = remarkable.length;
      totalDistance = distance;
      averageDistance = completed.isNotEmpty ? distance / completed.length : 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Statistics',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Section
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.hiking,
                    iconColor: const Color(0xFF2E7D32),
                    label: 'Total Hikes',
                    value: '$totalHikes',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.check_circle,
                    iconColor: const Color(0xFF0288D1),
                    label: 'Completed',
                    value: '$completedHikes',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.schedule,
                    iconColor: const Color(0xFFFF9800),
                    label: 'Planned',
                    value: '$plannedHikes',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.star,
                    iconColor: const Color(0xFFFFC107),
                    label: 'Remarkable',
                    value: '$remarkableHikes',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Distance Section
            const Text(
              'Distance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 16),
            _buildDistanceCard(
              icon: Icons.straighten,
              iconColor: const Color(0xFF8E24AA),
              label: 'Total Distance',
              value: '${totalDistance.toStringAsFixed(1)} km',
            ),
            const SizedBox(height: 12),
            _buildDistanceCard(
              icon: Icons.show_chart,
              iconColor: const Color(0xFFE91E63),
              label: 'Average Distance',
              value: '${averageDistance.toStringAsFixed(1)} km',
            ),

            const SizedBox(height: 32),

            // Achievements Section
            const Text(
              'Achievements',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 16),
            _buildAchievementCard(
              icon: Icons.emoji_events,
              iconColor: const Color(0xFFFFD700),
              title: 'Explorer',
              description: 'Completed your first hike',
              isUnlocked: completedHikes > 0,
            ),
            const SizedBox(height: 12),
            _buildAchievementCard(
              icon: Icons.local_fire_department,
              iconColor: const Color(0xFFFF5722),
              title: 'On Fire',
              description: 'Completed 10 hikes',
              isUnlocked: completedHikes >= 10,
            ),
            const SizedBox(height: 12),
            _buildAchievementCard(
              icon: Icons.terrain,
              iconColor: const Color(0xFF4CAF50),
              title: 'Mountain Master',
              description: 'Hiked 100km in total',
              isUnlocked: totalDistance >= 100,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: iconColor, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool isUnlocked,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isUnlocked
                  ? iconColor.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: isUnlocked ? iconColor : Colors.grey,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked
                        ? const Color(0xFF1C1C1E)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          if (isUnlocked)
            const Icon(
              Icons.check_circle,
              color: Color(0xFF2E7D32),
              size: 24,
            )
          else
            const Icon(
              Icons.lock,
              color: Color(0xFF9CA3AF),
              size: 24,
            ),
        ],
      ),
    );
  }
}

