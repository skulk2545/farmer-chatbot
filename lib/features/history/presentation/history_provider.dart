import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:jowar_disease_detection/core/services/logging_service.dart';

class HistoryProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _historyItems = [];

  List<Map<String, dynamic>> get historyItems => _historyItems;

  /// Loads history items from Hive and sorts them descending by timestamp.
  void loadHistory() {
    try {
      final box = Hive.box('history');
      final rawItems = box.values.toList();
      
      _historyItems = rawItems
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      
      // Sort by timestamp descending (newest first)
      _historyItems.sort((a, b) {
        final aTime = a['timestamp'] ?? '';
        final bTime = b['timestamp'] ?? '';
        return bTime.compareTo(aTime);
      });
      
      notifyListeners();
    } catch (e) {
      LoggingService.error("Failed to load prediction history", tag: "HistoryProvider", error: e);
    }
  }

  /// Clears all local prediction history.
  Future<void> clearHistory() async {
    try {
      final box = Hive.box('history');
      await box.clear();
      _historyItems.clear();
      notifyListeners();
      LoggingService.info("Local prediction history cleared successfully.", tag: "HistoryProvider");
    } catch (e) {
      LoggingService.error("Failed to clear prediction history", tag: "HistoryProvider", error: e);
    }
  }
}
