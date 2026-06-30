import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:jowar_disease_detection/core/constants/styles.dart';
import 'package:jowar_disease_detection/core/widgets/offline_banner.dart';
import 'package:jowar_disease_detection/features/statistics/presentation/statistics_provider.dart';
import 'package:jowar_disease_detection/features/prediction/presentation/prediction_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StatisticsProvider>(context, listen: false).compileLocalStats();
    });
  }

  final List<Color> _chartColors = [
    Colors.green,
    Colors.amber,
    Colors.red,
    Colors.blue,
    Colors.orange,
    Colors.purple,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = Provider.of<StatisticsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Analytics Dashboard"),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          
          Expanded(
            child: stats.isLoading
                ? const Center(child: CircularProgressIndicator())
                : stats.totalScans == 0
                    ? _buildEmptyState(theme)
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(AppStyles.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. KPI Summaries Row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildKpiCard(
                                    context: context,
                                    title: "Total Scans",
                                    value: "${stats.totalScans}",
                                    icon: Icons.qr_code_scanner_rounded,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: AppStyles.md),
                                Expanded(
                                  child: _buildKpiCard(
                                    context: context,
                                    title: "Avg Confidence",
                                    value: "${stats.avgConfidence.toStringAsFixed(1)}%",
                                    icon: Icons.offline_bolt_rounded,
                                    color: Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppStyles.lg),

                            // 2. Weekly Scans Line Chart
                            Text(
                              "Weekly Scanning Trend",
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: AppStyles.sm),
                            _buildLineChartCard(theme, stats),
                            const SizedBox(height: AppStyles.lg),

                            // 3. Disease Mix Pie Chart
                            Text(
                              "Disease Distribution",
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: AppStyles.sm),
                            _buildPieChartCard(theme, stats),
                            const SizedBox(height: AppStyles.lg),

                            // 4. Confidence Level Bar Chart
                            Text(
                              "Confidence Levels Mix",
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: AppStyles.sm),
                            _buildBarChartCard(theme, stats),
                            const SizedBox(height: AppStyles.xl),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.md),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: AppStyles.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChartCard(ThemeData theme, StatisticsProvider stats) {
    final entries = stats.weeklyTrends.entries.toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.md),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < entries.length) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                entries[idx].key,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        entries.length,
                        (index) => FlSpot(index.toDouble(), entries[index].value.toDouble()),
                      ),
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 4,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Daily Scans for Past 7 Days",
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartCard(ThemeData theme, StatisticsProvider stats) {
    final entries = stats.diseaseDistribution.entries.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.md),
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: List.generate(
                    entries.length,
                    (index) {
                      final color = _chartColors[index % _chartColors.length];
                      final pct = (entries[index].value / stats.totalScans) * 100;
                      return PieChartSectionData(
                        color: color,
                        value: entries[index].value.toDouble(),
                        title: "${pct.toStringAsFixed(0)}%",
                        radius: 50,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppStyles.md),
            // Legends
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: List.generate(
                entries.length,
                (index) {
                  final color = _chartColors[index % _chartColors.length];
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 12, height: 12, color: color),
                      const SizedBox(width: 4),
                      Text(
                        "${entries[index].key} (${entries[index].value})",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartCard(ThemeData theme, StatisticsProvider stats) {
    final entries = stats.confidenceDistribution.entries.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.md),
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < entries.length) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                entries[idx].key,
                                style: const TextStyle(fontSize: 9),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(
                    entries.length,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: entries[index].value.toDouble(),
                          color: theme.colorScheme.secondary,
                          width: 22,
                          borderRadius: BorderRadius.circular(4),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: stats.totalScans.toDouble(),
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Frequency count across confidence ranges",
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 72,
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppStyles.md),
            Text(
              "No Analytics Compiled",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppStyles.xs),
            Text(
              "Analytics diagrams will display here automatically once crop diagnostic scans are completed.",
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppStyles.lg),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const PredictionScreen()),
                );
              },
              icon: const Icon(Icons.add_a_photo_rounded),
              label: const Text("Scan Your First Crop"),
            ),
          ],
        ),
      ),
    );
  }
}
