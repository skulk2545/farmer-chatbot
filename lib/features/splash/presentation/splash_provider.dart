import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:jowar_disease_detection/core/api/api_service.dart';
import 'package:jowar_disease_detection/core/api/endpoints.dart';
import 'package:jowar_disease_detection/core/services/logging_service.dart';

enum SplashStatus { idle, loading, success, error }

class SplashProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  SplashStatus _status = SplashStatus.idle;
  String _errorMessage = "";

  SplashStatus get status => _status;
  String get errorMessage => _errorMessage;

  Future<bool> checkBackendHealth() async {
    _status = SplashStatus.loading;
    _errorMessage = "";
    notifyListeners();

    try {
      LoggingService.info("Checking backend connection health...", tag: "SplashProvider");
      final response = await _apiService.get(Endpoints.health);
      
      if (response.statusCode == 200) {
        _status = SplashStatus.success;
        notifyListeners();
        return true;
      } else {
        throw ServerException("Unexpected response code: ${response.statusCode}");
      }
    } catch (e) {
      _status = SplashStatus.error;
      _errorMessage = e.toString();
      LoggingService.error("Health check failed", tag: "SplashProvider", error: e);
      notifyListeners();
      return false;
    }
  }

  Future<void> updateBackendUrl(String newUrl) async {
    final box = Hive.box('settings');
    await box.put('backend_url', newUrl);
    LoggingService.info("Backend URL updated to: $newUrl", tag: "SplashProvider");
    notifyListeners();
  }

  String get currentBackendUrl {
    final box = Hive.box('settings');
    return box.get('backend_url', defaultValue: Endpoints.baseDefaultUrl);
  }
}
