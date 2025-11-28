// filepath: c:\Users\Admin\OneDrive\Desktop\COMP1786\CW1786\Cross\m_hike_hybrid_app\lib\views\settings\statistics.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../db/app_db.dart';

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
  int easyHikes = 0;
  int moderateHikes = 0;
  int hardHikes = 0;

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
    final allHikes = await AppDatabase.instance.getAllHikes();

    // Calculate total distance from completed hikes
    double distance = 0.0;
    for (var hike in completed) {
      distance += hike.length;
    }

    // Count difficulty from ALL hikes in database
    int easy = 0;
    int moderate = 0;
    int hard = 0;

    for (var hike in allHikes) {
      // Count by difficulty
      if (hike.difficulty.toLowerCase() == 'easy') {
        easy++;
      } else if (hike.difficulty.toLowerCase() == 'moderate') {
        moderate++;
      } else if (hike.difficulty.toLowerCase() == 'hard') {
        hard++;
      }
    }

    setState(() {
      totalHikes = total;
      completedHikes = completed.length;
      plannedHikes = planned.length;
      remarkableHikes = remarkable.length;
      totalDistance = distance;
      averageDistance = completed.isNotEmpty ? distance / completed.length : 0.0;
      easyHikes = easy;
      moderateHikes = moderate;
      hardHikes = hard;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Statistics',
          style: theme.textTheme.titleLarge?.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Section
            Text('Overview', style: theme.textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.bold)),
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
                    iconColor: colorScheme.primary,
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
            Text('Distance', style: theme.textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildDistanceCard(
              icon: Icons.straighten,
              iconColor: colorScheme.primary,
              label: 'Total Distance',
              value: '${totalDistance.toStringAsFixed(1)} km',
            ),
            const SizedBox(height: 12),
            _buildDistanceCard(
              icon: Icons.show_chart,
              iconColor: colorScheme.primary,
              label: 'Average Distance',
              value: '${averageDistance.toStringAsFixed(1)} km',
            ),

            const SizedBox(height: 32),

            // Hike Status Chart
            Text('Hike Status', style: theme.textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildPieChart(),

            const SizedBox(height: 32),

            // Difficulty Distribution Chart
            Text('Difficulty Distribution', style: theme.textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildBarChart(),
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
          Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, color: theme.hintColor)),
                const SizedBox(height: 4),
                Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    final theme = Theme.of(context);
    // If no hikes, show empty state
    if (totalHikes == 0) {
      return Container(
        height: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text('No hikes yet', style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor, fontSize: 16)),
        ),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    color: const Color(0xFF0288D1),
                    value: completedHikes.toDouble(),
                    title: '$completedHikes',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: const Color(0xFFFF9800),
                    value: plannedHikes.toDouble(),
                    title: '$plannedHikes',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendItem(
                color: const Color(0xFF0288D1),
                label: 'Completed',
                value: '$completedHikes',
              ),
              const SizedBox(height: 12),
              _buildLegendItem(
                color: const Color(0xFFFF9800),
                label: 'Planned',
                value: '$plannedHikes',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // If no hikes, show empty state
    if (totalHikes == 0) {
      return Container(
        height: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: Text('No hikes yet', style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor, fontSize: 16))),
      );
    }

    final maxValue = [easyHikes, moderateHikes, hardHikes].reduce((a, b) => a > b ? a : b).toDouble();

    return Container(
      height: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue + 1,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => theme.colorScheme.onSurface,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      String difficulty;
                      switch (group.x.toInt()) {
                        case 0:
                          difficulty = 'Easy';
                          break;
                        case 1:
                          difficulty = 'Moderate';
                          break;
                        case 2:
                          difficulty = 'Hard';
                          break;
                        default:
                          difficulty = '';
                      }
                      return BarTooltipItem(
                        '$difficulty\n${rod.toY.toInt()} hikes',
                        theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 12) ?? const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        final style = theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 13) ?? const TextStyle(fontWeight: FontWeight.w600, fontSize: 13);
                        switch (value.toInt()) {
                          case 0:
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text('Easy', style: style),
                            );
                          case 1:
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text('Moderate', style: style),
                            );
                          case 2:
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text('Hard', style: style),
                            );
                          default:
                            return const Text('');
                        }
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max || value == meta.min) {
                          return const SizedBox();
                        }
                        return Text(value.toInt().toString(), style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, fontSize: 11, fontWeight: FontWeight.w500));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: theme.dividerColor, strokeWidth: 1);
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: easyHikes > 0 ? easyHikes.toDouble() : 0.1,
                        gradient: LinearGradient(
                          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.85)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 50,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        backDrawRodData: BackgroundBarChartRodData(show: true, toY: maxValue + 1, color: theme.dividerColor),
                      ),
                    ],
                    showingTooltipIndicators: [],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: moderateHikes > 0 ? moderateHikes.toDouble() : 0.1,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 50,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        backDrawRodData: BackgroundBarChartRodData(show: true, toY: maxValue + 1, color: theme.dividerColor),
                      ),
                    ],
                    showingTooltipIndicators: [],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: hardHikes > 0 ? hardHikes.toDouble() : 0.1,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF44336), Color(0xFFEF5350)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 50,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        backDrawRodData: BackgroundBarChartRodData(show: true, toY: maxValue + 1, color: theme.dividerColor),
                      ),
                    ],
                    showingTooltipIndicators: [],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBarLegend(
                color: const Color(0xFF4CAF50),
                count: easyHikes,
              ),
              _buildBarLegend(
                color: const Color(0xFFFF9800),
                count: moderateHikes,
              ),
              _buildBarLegend(
                color: const Color(0xFFF44336),
                count: hardHikes,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarLegend({
    required Color color,
    required int count,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text('$count', style: theme.textTheme.bodyMedium?.copyWith(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
        const SizedBox(width: 8),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
