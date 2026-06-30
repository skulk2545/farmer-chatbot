import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:jowar_disease_detection/core/services/logging_service.dart';

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<dynamic> _subscription;
  bool _isOnline = true;

  ConnectivityService() {
    _initConnectivity();
    // Listen to changes (handles both List<ConnectivityResult> for newer versions and single result)
    _subscription = _connectivity.onConnectivityChanged.listen((event) {
      _updateConnectionStatus(event);
    });
  }

  bool get isOnline => _isOnline;

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      LoggingService.error("Failed to check initial connectivity", tag: "ConnectivityService", error: e);
    }
  }

  void _updateConnectionStatus(dynamic result) {
    final bool prevStatus = _isOnline;
    
    if (result is List) {
      // Handles List<ConnectivityResult> in connectivity_plus v5+
      _isOnline = result.isNotEmpty && !result.contains(ConnectivityResult.none);
    } else if (result is ConnectivityResult) {
      // Handles legacy single ConnectivityResult
      _isOnline = result != ConnectivityResult.none;
    } else {
      _isOnline = true;
    }
    
    if (prevStatus != _isOnline) {
      LoggingService.info("Connectivity changed. Online: $_isOnline", tag: "ConnectivityService");
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
