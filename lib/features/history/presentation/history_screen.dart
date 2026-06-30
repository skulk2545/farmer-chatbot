import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jowar_disease_detection/core/constants/styles.dart';
import 'package:jowar_disease_detection/core/constants/colors.dart';
import 'package:jowar_disease_detection/features/history/presentation/history_provider.dart';
import 'package:jowar_disease_detection/features/prediction/presentation/prediction_screen.dart';
import 'package:jowar_disease_detection/features/prediction/presentation/result_details_view.dart';
import 'package:jowar_disease_detection/features/prediction/data/models/prediction_model.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HistoryProvider>(context, listen: false).loadHistory();
    });
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case "NONE":
        return AppColors.severityHealthy;
      case "MEDIUM":
        return AppColors.severityMedium;
      case "HIGH":
      case "CRITICAL":
        return AppColors.severityHigh;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final history = Provider.of<HistoryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan History"),
        actions: [
          if (history.historyItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: "Clear all history",
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Delete All Scans?"),
                    content: const Text("This will permanently clear all historical diagnostic scans on this device."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("Cancel"),
                      ),
                      FilledButton(
                        onPressed: () {
                          history.clearHistory();
                          Navigator.of(context).pop();
                        },
                        child: const Text("Delete All"),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: history.historyItems.isEmpty
          ? _buildEmptyState(theme)
          : ListView.builder(
              padding: const EdgeInsets.all(AppStyles.md),
              itemCount: history.historyItems.length,
              itemBuilder: (context, index) {
                final item = history.historyItems[index];
                
                // Parse date
                String formattedDate = "Unknown Date";
                if (item['timestamp'] != null) {
                  try {
                    final date = DateTime.parse(item['timestamp']);
                    formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);
                  } catch (_) {}
                }

                final PredictionModel model = PredictionModel.fromJson(
                  Map<String, dynamic>.from(item['details'] ?? {}),
                );
                final Color severityColor = _getSeverityColor(model.severity);

                return Card(
                  margin: const EdgeInsets.only(bottom: AppStyles.md),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            appBar: AppBar(
                              title: const Text("Diagnosis Details"),
                            ),
                            body: Column(
                              children: [
                                Expanded(child: ResultDetailsView(result: model)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image Thumbnail with Fallback
                        Container(
                          width: 100,
                          height: 100,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: _buildThumbnailImage(item['image_path']),
                        ),
                        
                        // Text Details
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(AppStyles.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      model.crop,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: severityColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  model.disease,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppStyles.xs),
                                Text(
                                  "Confidence: ${model.confidence}%",
                                  style: theme.textTheme.bodySmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  formattedDate,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildThumbnailImage(dynamic imagePath) {
    if (imagePath != null && imagePath is String && imagePath.isNotEmpty) {
      if (kIsWeb) {
        return Image.network(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
        );
      } else {
        final file = File(imagePath);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
          );
        }
      }
    }
    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    return const Center(
      child: Icon(
        Icons.spa_rounded,
        size: 36,
        color: Colors.green,
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
              Icons.camera_enhance_outlined,
              size: 72,
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppStyles.md),
            Text(
              "No Diagnosis History",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppStyles.xs),
            Text(
              "You have not made any crop leaf diagnostic scans yet. Take a picture of your sorghum crop leaf to perform a diagnosis.",
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
              label: const Text("Scan Your Crop Now"),
            ),
          ],
        ),
      ),
    );
  }
}
