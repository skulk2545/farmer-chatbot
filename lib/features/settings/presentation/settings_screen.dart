// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jowar_disease_detection/core/constants/styles.dart';
import 'package:jowar_disease_detection/core/constants/colors.dart';
import 'package:jowar_disease_detection/core/widgets/offline_banner.dart';
import 'package:jowar_disease_detection/features/settings/presentation/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showConfigureUrlDialog(BuildContext context, SettingsProvider provider) {
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
              title: const Text("Configure API Server"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Specify backend FastAPI address. Physical devices should use the host computer's local IP (e.g. http://192.168.x.x:8000)."),
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
                          
                          final ok = await provider.updateBackendUrl(controller.text.trim());
                          
                          setDialogState(() {
                            testing = false;
                            if (ok) {
                              testResult = "Success: Connected!";
                            } else {
                              testResult = "Failed: Unable to connect.";
                            }
                          });
                        },
                  child: testing 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Test Connection"),
                ),
                FilledButton(
                  onPressed: testing
                      ? null
                      : () async {
                          await provider.updateBackendUrl(controller.text.trim());
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showThemeSelectorDialog(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select App Theme"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text("System Default"),
                value: ThemeMode.system,
                groupValue: provider.themeMode,
                onChanged: (mode) {
                  if (mode != null) provider.updateThemeMode(mode);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text("Light Mode"),
                value: ThemeMode.light,
                groupValue: provider.themeMode,
                onChanged: (mode) {
                  if (mode != null) provider.updateThemeMode(mode);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text("Dark Mode"),
                value: ThemeMode.dark,
                groupValue: provider.themeMode,
                onChanged: (mode) {
                  if (mode != null) provider.updateThemeMode(mode);
                  Navigator.of(context).pop();
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
    final provider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("App Settings"),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppStyles.md),
              children: [
                // Section: Preferences
                _buildSectionHeader(theme, "Preferences"),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.palette_rounded),
                        title: const Text("Theme Mode"),
                        subtitle: Text(_getThemeName(provider.themeMode)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showThemeSelectorDialog(context, provider),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.dns_rounded),
                        title: const Text("Backend URL"),
                        subtitle: Text(provider.currentBackendUrl),
                        trailing: const Icon(Icons.edit_rounded),
                        onTap: () => _showConfigureUrlDialog(context, provider),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppStyles.lg),

                // Section: API Status & Cache
                _buildSectionHeader(theme, "Diagnostics & Cache"),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.api_rounded),
                        title: const Text("API Service Status"),
                        subtitle: Text(
                          provider.checkingStatus
                              ? "Checking..."
                              : provider.isApiOnline
                                  ? "Online (Connected)"
                                  : "Offline (Unreachable)",
                        ),
                        trailing: provider.checkingStatus
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: () => provider.checkApiStatus(),
                              ),
                        leadingAndTrailingTextStyle: theme.textTheme.bodyMedium,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        title: const Text("Clear Local Caches", style: TextStyle(color: Colors.red)),
                        subtitle: const Text("Wipes offline prediction history & chat logs"),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Clear Cache?"),
                              content: const Text("This action will erase all scanned records and chatbot conversations. The app configurations will remain intact."),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text("Cancel"),
                                ),
                                FilledButton(
                                  onPressed: () async {
                                    await provider.clearAllCache();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Application caches successfully cleared.")),
                                      );
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  child: const Text("Clear Cache"),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppStyles.lg),

                // Section: About
                _buildSectionHeader(theme, "About"),
                Card(
                  child: Column(
                    children: [
                      const ListTile(
                        leading: Icon(Icons.info_outline_rounded),
                        title: Text("App Version"),
                        trailing: Text("1.0.0 (Release)"),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.verified_user_outlined),
                        title: const Text("Technical Architecture"),
                        subtitle: const Text("Flutter 3.x, Clean Architecture, Repository Pattern, Dio Client, Hive Cache"),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("System Architecture"),
                              content: const Text("This crop disease assistant is built with high-performance mobile coding patterns. It utilizes a three-tier Clean Architecture (Data, Domain, Presentation) to enforce strict separation of concerns, providing high offline testability, backoff retries, and high M3 accessibility themes."),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text("OK"),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: AppStyles.xs, bottom: AppStyles.sm),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return "Light Mode";
      case ThemeMode.dark:
        return "Dark Mode";
      default:
        return "System Default";
    }
  }
}
