import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

// Services
import 'package:jowar_disease_detection/core/services/connectivity_service.dart';
import 'package:jowar_disease_detection/core/services/tts_service.dart';
import 'package:jowar_disease_detection/core/services/stt_service.dart';

// Themes
import 'package:jowar_disease_detection/core/theme/app_theme.dart';

// Providers
import 'package:jowar_disease_detection/features/splash/presentation/splash_provider.dart';
import 'package:jowar_disease_detection/features/prediction/presentation/prediction_provider.dart';
import 'package:jowar_disease_detection/features/chatbot/presentation/chatbot_provider.dart';
import 'package:jowar_disease_detection/features/history/presentation/history_provider.dart';
import 'package:jowar_disease_detection/features/statistics/presentation/statistics_provider.dart';
import 'package:jowar_disease_detection/features/settings/presentation/settings_provider.dart';

// Screen
import 'package:jowar_disease_detection/features/splash/presentation/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local Hive database and caching boxes
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('history');
  await Hive.openBox('chat_history');
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        ChangeNotifierProvider(create: (_) => TtsService()),
        ChangeNotifierProvider(create: (_) => SttService()..initSpeech()),
        ChangeNotifierProvider(create: (_) => SplashProvider()),
        ChangeNotifierProvider(create: (_) => PredictionProvider()),
        ChangeNotifierProvider(create: (_) => ChatbotProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Dynamic theme mapping from SettingsProvider
    final settings = Provider.of<SettingsProvider>(context);

    return MaterialApp(
      title: 'Jowar Crop Assistant',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
