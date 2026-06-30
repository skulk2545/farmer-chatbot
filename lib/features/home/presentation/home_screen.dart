import 'package:flutter/material.dart';
import 'package:jowar_disease_detection/core/constants/styles.dart';
import 'package:jowar_disease_detection/core/widgets/offline_banner.dart';
import 'package:jowar_disease_detection/features/prediction/presentation/prediction_screen.dart';
import 'package:jowar_disease_detection/features/chatbot/presentation/chatbot_screen.dart';
import 'package:jowar_disease_detection/features/history/presentation/history_screen.dart';
import 'package:jowar_disease_detection/features/statistics/presentation/statistics_screen.dart';
import 'package:jowar_disease_detection/features/settings/presentation/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Grid items configuration
    final List<Map<String, dynamic>> menuItems = [
      {
        "title": "Diagnose Disease",
        "subtitle": "Scan leaf/panicle for diseases",
        "icon": Icons.camera_enhance_rounded,
        "color": theme.colorScheme.primary,
        "route": const PredictionScreen(),
        "semanticLabel": "Diagnose crop disease by scanning leaf or panicle images",
      },
      {
        "title": "Farmer Chatbot",
        "subtitle": "Consult our offline AI assistant",
        "icon": Icons.chat_rounded,
        "color": theme.colorScheme.secondary,
        "route": const ChatbotScreen(),
        "semanticLabel": "Chat with the AI farmer assistant bot",
      },
      {
        "title": "Prediction History",
        "subtitle": "View previous scans & details",
        "icon": Icons.history_rounded,
        "color": theme.colorScheme.tertiary,
        "route": const HistoryScreen(),
        "semanticLabel": "View all historical scans and crop diagnoses",
      },
      {
        "title": "Analytics Stats",
        "subtitle": "View disease & trend charts",
        "icon": Icons.bar_chart_rounded,
        "color": theme.colorScheme.primary,
        "route": const StatisticsScreen(),
        "semanticLabel": "Open analysis dashboard and disease charts",
      },
      {
        "title": "App Settings",
        "subtitle": "Manage theme & server URL",
        "icon": Icons.settings_rounded,
        "color": theme.colorScheme.outline,
        "route": const SettingsScreen(),
        "semanticLabel": "Configure server base URL and application theme",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.agriculture_rounded),
            SizedBox(width: AppStyles.sm),
            Text(
              "Jowar Crop Assistant",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: "Jowar Crop Assistant",
                applicationVersion: "1.0.0",
                applicationIcon: Icon(
                  Icons.agriculture_rounded,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                children: const [
                  Text("A production-grade mobile application for diagnosing Sorghum leaf and panicle diseases in real-time, utilizing custom local neural network inference and semantic chatbots."),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Real-time connectivity monitor banner
          const OfflineBanner(),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppStyles.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting & Header Card
                  Card(
                    color: theme.colorScheme.primaryContainer,
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: AppStyles.lg),
                    child: Padding(
                      padding: const EdgeInsets.all(AppStyles.md),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Welcome, Farmer!",
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(height: AppStyles.xs),
                                Text(
                                  "Let's check and protect your sorghum crops from pests and diseases today.",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppStyles.md),
                          Icon(
                            Icons.wb_sunny_rounded,
                            size: 48,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),

                  Text(
                    "Services Menu",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppStyles.sm),
                  
                  // Grid Menu List
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: AppStyles.md,
                      mainAxisSpacing: AppStyles.md,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: menuItems.length,
                    itemBuilder: (context, index) {
                      final item = menuItems[index];
                      return Semantics(
                        label: item["semanticLabel"],
                        button: true,
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => item["route"]),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(AppStyles.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(AppStyles.sm),
                                    decoration: BoxDecoration(
                                      color: (item["color"] as Color).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                                    ),
                                    child: Icon(
                                      item["icon"],
                                      color: item["color"],
                                      size: 28,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    item["title"],
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: AppStyles.xs),
                                  Text(
                                    item["subtitle"],
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
