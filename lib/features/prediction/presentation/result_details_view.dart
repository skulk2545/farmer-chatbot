import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jowar_disease_detection/core/constants/colors.dart';
import 'package:jowar_disease_detection/core/constants/styles.dart';
import 'package:jowar_disease_detection/core/services/tts_service.dart';
import 'package:jowar_disease_detection/features/prediction/data/models/prediction_model.dart';

class ResultDetailsView extends StatelessWidget {
  final PredictionModel result;

  const ResultDetailsView({super.key, required this.result});

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

  String _getReadAloudText() {
    return "Diagnosed Condition: ${result.disease}. "
        "Confidence: ${result.confidence} percent. "
        "Description: ${result.description} "
        "Symptoms: ${result.symptoms} "
        "Organic Treatment: ${result.organicTreatment} "
        "Chemical Treatment: ${result.chemicalTreatment}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final severityColor = _getSeverityColor(result.severity);
    final tts = Provider.of<TtsService>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppStyles.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Diagnosis Header Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
              border: Border.all(color: severityColor, width: 3),
              boxShadow: AppStyles.cardShadow(context),
            ),
            padding: const EdgeInsets.all(AppStyles.md),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      result.crop,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: severityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Severity: ${result.severity}",
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: severityColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppStyles.sm),
                Text(
                  result.disease,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppStyles.xs),
                Text(
                  "Confidence: ${result.confidence}%",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Divider(height: AppStyles.lg),
                // Audio Read Aloud Control
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      icon: Icon(tts.isPlaying ? Icons.stop_rounded : Icons.volume_up_rounded),
                      iconSize: 28,
                      onPressed: () {
                        if (tts.isPlaying) {
                          tts.stop();
                        } else {
                          tts.speak(_getReadAloudText());
                        }
                      },
                      tooltip: tts.isPlaying ? "Stop reading" : "Read diagnosis details aloud",
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tts.isPlaying ? "Stop Reading" : "Read Advice Aloud",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppStyles.lg),

          // 2. Info Cards List
          _buildInfoCard(
            context: context,
            title: "Description",
            content: result.description,
            icon: Icons.info_outline_rounded,
          ),
          _buildInfoCard(
            context: context,
            title: "Symptoms",
            content: result.symptoms,
            icon: Icons.visibility_outlined,
          ),
          _buildInfoCard(
            context: context,
            title: "Causes",
            content: result.causes,
            icon: Icons.help_outline_rounded,
          ),
          _buildInfoCard(
            context: context,
            title: "Organic Treatment",
            content: result.organicTreatment,
            icon: Icons.eco_outlined,
            iconColor: AppColors.severityHealthy,
          ),
          _buildInfoCard(
            context: context,
            title: "Chemical Treatment",
            content: result.chemicalTreatment,
            icon: Icons.science_outlined,
            iconColor: AppColors.severityHigh,
          ),
          _buildInfoCard(
            context: context,
            title: "Prevention",
            content: result.prevention,
            icon: Icons.shield_outlined,
          ),
          _buildInfoCard(
            context: context,
            title: "References",
            content: result.reference,
            icon: Icons.menu_book_outlined,
          ),
          
          const SizedBox(height: AppStyles.xl),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required String content,
    required IconData icon,
    Color? iconColor,
  }) {
    if (content.isEmpty) return const SizedBox.shrink();
    
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppStyles.md),
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.md),
        child: CrossFade<String>(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: iconColor ?? theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: AppStyles.sm),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppStyles.sm),
            Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple Helper for layout formatting
class CrossFade<T> extends StatelessWidget {
  final CrossAxisAlignment crossAxisAlignment;
  final List<Widget> children;

  const CrossFade({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: children,
    );
  }
}
