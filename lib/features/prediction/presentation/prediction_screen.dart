import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:jowar_disease_detection/core/constants/styles.dart';
import 'package:jowar_disease_detection/core/widgets/offline_banner.dart';
import 'package:jowar_disease_detection/core/widgets/error_retry_view.dart';
import 'package:jowar_disease_detection/core/services/tts_service.dart';
import 'package:jowar_disease_detection/features/prediction/presentation/prediction_provider.dart';
import 'package:jowar_disease_detection/features/prediction/presentation/result_details_view.dart';

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  
  @override
  void dispose() {
    // Make sure we stop TTS if navigating away
    if (mounted) {
      Provider.of<TtsService>(context, listen: false).stop();
    }
    super.dispose();
  }

  void _showImageSourceOptions(BuildContext context) {
    final provider = Provider.of<PredictionProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppStyles.radiusMedium)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text("Take Photo (Camera)"),
                onTap: () {
                  Navigator.of(context).pop();
                  provider.pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text("Choose from Gallery"),
                onTap: () {
                  Navigator.of(context).pop();
                  provider.pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<PredictionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Crop Diagnosis"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Stop TTS and reset prediction screen
            Provider.of<TtsService>(context, listen: false).stop();
            provider.reset();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          
          Expanded(
            child: Consumer<PredictionProvider>(
              builder: (context, state, child) {
                if (state.isLoading) {
                  return _buildUploadProgressView(theme, state);
                }

                if (state.predictionResult != null) {
                  return Column(
                    children: [
                      Expanded(
                        child: ResultDetailsView(result: state.predictionResult!),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppStyles.md),
                        child: FilledButton.icon(
                          onPressed: () => state.reset(),
                          icon: const Icon(Icons.add_photo_alternate_rounded),
                          label: const Text("Scan Another Crop"),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                if (state.errorMessage != null) {
                  return ErrorRetryView(
                    errorMessage: state.errorMessage!,
                    onRetry: () {
                      if (state.selectedImage != null) {
                        state.diagnoseCrop();
                      } else {
                        state.reset();
                      }
                    },
                  );
                }

                return _buildImageSelectorView(theme, state);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSelectorView(ThemeData theme, PredictionProvider state) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppStyles.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (state.selectedImage != null) ...[
              // Image Preview
              Container(
                width: double.infinity,
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                  boxShadow: AppStyles.cardShadow(context),
                  image: DecorationImage(
                    image: FileImage(state.selectedImage!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: AppStyles.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showImageSourceOptions(context),
                      icon: const Icon(Icons.refresh),
                      label: const Text("Retake"),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppStyles.md),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => state.diagnoseCrop(),
                      icon: const Icon(Icons.analytics_rounded),
                      label: const Text("Diagnose"),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 50),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Empty State (No image chosen)
              GestureDetector(
                onTap: () => _showImageSourceOptions(context),
                child: Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_rounded,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: AppStyles.md),
                      Text(
                        "Tap to Capture or Pick Leaf Image",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: AppStyles.xs),
                      Text(
                        "Supported: JPG, JPEG, PNG (max 10MB)",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppStyles.xl),
              // Tips Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppStyles.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline_rounded, color: theme.colorScheme.primary),
                          const SizedBox(width: AppStyles.sm),
                          Text(
                            "Tips for accurate diagnosis:",
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppStyles.sm),
                      const Text("• Focus clearly on the affected area of the leaf or panicle."),
                      const Text("• Avoid heavy shadows, background clutter, or overly bright lighting."),
                      const Text("• Center the crop leaf horizontally in the frame."),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUploadProgressView(ThemeData theme, PredictionProvider state) {
    final int percentage = (state.uploadProgress * 100).toInt();
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              value: state.uploadProgress > 0 ? state.uploadProgress : null,
              strokeWidth: 6,
            ),
            const SizedBox(height: AppStyles.lg),
            Text(
              "Analyzing Sorghum Crop...",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppStyles.sm),
            if (percentage > 0) ...[
              Text(
                "Uploading Image: $percentage%",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppStyles.md),
              LinearProgressIndicator(
                value: state.uploadProgress,
                borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
              ),
            ] else ...[
              const Text("Sending payload to server model..."),
            ],
          ],
        ),
      ),
    );
  }
}
