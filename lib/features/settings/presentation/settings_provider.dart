import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:jowar_disease_detection/core/api/api_service.dart';
import 'package:jowar_disease_detection/core/api/endpoints.dart';
import 'package:jowar_disease_detection/core/services/logging_service.dart';

class SettingsProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  ThemeMode _themeMode = ThemeMode.system;
  bool _isApiOnline = false;
  bool _checkingStatus = false;

  SettingsProvider() {
    _loadSettings();
    checkApiStatus();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isApiOnline => _isApiOnline;
  bool get checkingStatus => _checkingStatus;

  void _loadSettings() {
    try {
      final box = Hive.box('settings');
      final String savedMode = box.get('theme_mode', defaultValue: 'system');
      
      switch (savedMode) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        default:
          _themeMode = ThemeMode.system;
      }
      notifyListeners();
    } catch (e) {
      LoggingService.error("Failed to load theme mode setting", tag: "SettingsProvider", error: e);
    }
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    try {
      final box = Hive.box('settings');
      String modeString = 'system';
      if (mode == ThemeMode.light) {
        modeString = 'light';
      } else if (mode == ThemeMode.dark) {
        modeString = 'dark';
      }
      await box.put('theme_mode', modeString);
      notifyListeners();
    } catch (e) {
      LoggingService.error("Failed to save theme mode setting", tag: "SettingsProvider", error: e);
    }
  }

  String get currentBackendUrl {
    final box = Hive.box('settings');
    return box.get('backend_url', defaultValue: Endpoints.baseDefaultUrl);
  }

  Future<bool> updateBackendUrl(String newUrl) async {
    try {
      final box = Hive.box('settings');
      await box.put('backend_url', newUrl);
      notifyListeners();
      return await checkApiStatus();
    } catch (e) {
      LoggingService.error("Failed to update backend URL setting", tag: "SettingsProvider", error: e);
      return false;
    }
  }

  Future<bool> checkApiStatus() async {
    _checkingStatus = true;
    notifyListeners();
    
    try {
      final response = await _apiService.get(Endpoints.health);
      _isApiOnline = response.statusCode == 200;
    } catch (e) {
      _isApiOnline = false;
    } finally {
      _checkingStatus = false;
      notifyListeners();
    }
    return _isApiOnline;
  }

  Future<void> clearAllCache() async {
    try {
      final historyBox = Hive.box('history');
      final chatBox = Hive.box('chat_history');
      
      await historyBox.clear();
      await chatBox.clear();
      
      LoggingService.info("Application cache (history, chat logs) cleared.", tag: "SettingsProvider");
      notifyListeners();
    } catch (e) {
      LoggingService.error("Failed to clear cache", tag: "SettingsProvider", error: e);
      rethrow;
    }
  }
}
