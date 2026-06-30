import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:jowar_disease_detection/core/constants/colors.dart';
import 'package:jowar_disease_detection/core/constants/styles.dart';
import 'package:jowar_disease_detection/features/splash/presentation/splash_provider.dart';
import 'package:jowar_disease_detection/features/home/presentation/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runHealthCheck();
    });
  }

  Future<void> _runHealthCheck() async {
    final provider = Provider.of<SplashProvider>(context, listen: false);
    final isHealthy = await provider.checkBackendHealth();
    if (isHealthy && mounted) {
      // Navigate to Home Screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  void _showConfigureUrlDialog() {
    final provider = Provider.of<SplashProvider>(context, listen: false);
    final controller = TextEditingController(text: provider.currentBackendUrl);
    bool testing = false;
    String? testResult;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Configure Backend URL"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Specify the API Server address. Physical Android devices must use host machine IP (e.g. http://192.168.x.x:8000)."),
                  const SizedBox(height: AppStyles.md),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: "Backend Base URL",
                      border: AppStyles.inputBorder(Theme.of(context).colorScheme.outline),
                      hintText: "http://10.0.2.2:8000",
                    ),
                  ),
                  if (testResult != null) ...[
                    const SizedBox(height: AppStyles.sm),
                    Text(
                      testResult!,
                      style: TextStyle(
                        color: testResult!.startsWith("Success") 
                            ? AppColors.severityHealthy 
                            : AppColors.severityHigh,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: testing 
                      ? null 
                      : () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: testing
                      ? null
                      : () async {
                          setDialogState(() {
                            testing = true;
                            testResult = "Testing connection...";
                          });
                          
                          // Save temporarily to test
                          final previousUrl = provider.currentBackendUrl;
                          await provider.updateBackendUrl(controller.text.trim());
                          final ok = await provider.checkBackendHealth();
                          
                          setDialogState(() {
                            testing = false;
                            if (ok) {
                              testResult = "Success: Connected!";
                            } else {
                              testResult = "Failed: Unable to connect.";
                              // Revert
                              provider.updateBackendUrl(previousUrl);
                            }
                          });
                        },
                  child: testing 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Test"),
                ),
                FilledButton(
                  onPressed: testing
                      ? null
                      : () async {
                          await provider.updateBackendUrl(controller.text.trim());
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            _runHealthCheck();
                          }
                        },
                  child: const Text("Save & Connect"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primaryContainer.withValues(alpha: 0.8),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: Consumer<SplashProvider>(
          builder: (context, splash, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                // App Logo Icon
                Container(
                  padding: const EdgeInsets.all(AppStyles.xl),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.agriculture_rounded,
                    size: 100,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppStyles.lg),
                Text(
                  "Jowar Crop Assistant",
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  "Sorghum Health Diagnosis & Support",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(flex: 1),
                
                if (splash.status == SplashStatus.loading) ...[
                  SpinKitThreeBounce(
                    color: theme.colorScheme.primary,
                    size: 40,
                  ),
                  const SizedBox(height: AppStyles.md),
                  const Text("Checking server connection..."),
                ] else if (splash.status == SplashStatus.error) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppStyles.lg),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          color: theme.colorScheme.error,
                          size: 48,
                        ),
                        const SizedBox(height: AppStyles.sm),
                        Text(
                          "Failed to connect to backend",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppStyles.xs),
                        Text(
                          splash.errorMessage,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppStyles.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _showConfigureUrlDialog,
                              icon: const Icon(Icons.settings),
                              label: const Text("Configure"),
                            ),
                            const SizedBox(width: AppStyles.md),
                            FilledButton.icon(
                              onPressed: _runHealthCheck,
                              icon: const Icon(Icons.refresh),
                              label: const Text("Retry"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(flex: 2),
              ],
            );
          },
        ),
      ),
    );
  }
}
