import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:jowar_disease_detection/core/services/logging_service.dart';
import 'package:intl/intl.dart';

class StatisticsProvider extends ChangeNotifier {
  bool _isLoading = false;
  int _totalScans = 0;
  double _avgConfidence = 0.0;
  Map<String, int> _diseaseDistribution = {};
  Map<String, int> _confidenceDistribution = {
    "< 50%": 0,
    "50% - 75%": 0,
    "75% - 90%": 0,
    "90% +": 0,
  };
  Map<String, int> _weeklyTrends = {};

  bool get isLoading => _isLoading;
  int get totalScans => _totalScans;
  double get avgConfidence => _avgConfidence;
  Map<String, int> get diseaseDistribution => _diseaseDistribution;
  Map<String, int> get confidenceDistribution => _confidenceDistribution;
  Map<String, int> get weeklyTrends => _weeklyTrends;

  /// Compiles advanced crop health statistics using the local Hive history cache.
  void compileLocalStats() {
    _isLoading = true;
    notifyListeners();

    try {
      final box = Hive.box('history');
      final rawItems = box.values.toList();
      final items = rawItems.map((item) => Map<String, dynamic>.from(item as Map)).toList();

      _totalScans = items.length;

      if (_totalScans == 0) {
        _avgConfidence = 0.0;
        _diseaseDistribution = {};
        _confidenceDistribution = {
          "< 50%": 0,
          "50% - 75%": 0,
          "75% - 90%": 0,
          "90% +": 0,
        };
        _weeklyTrends = {};
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 1. Calculate Average Confidence
      double sumConf = 0.0;
      for (final item in items) {
        final double conf = (item['confidence'] as num?)?.toDouble() ?? 0.0;
        sumConf += conf;
      }
      _avgConfidence = sumConf / _totalScans;

      // 2. Compile Disease Distribution (Pie Chart)
      final Map<String, int> diseaseMap = {};
      for (final item in items) {
        final String disease = item['disease'] ?? 'Unknown';
        diseaseMap[disease] = (diseaseMap[disease] ?? 0) + 1;
      }
      _diseaseDistribution = diseaseMap;

      // 3. Compile Confidence Bands (Bar Chart)
      final Map<String, int> confBands = {
        "< 50%": 0,
        "50% - 75%": 0,
        "75% - 90%": 0,
        "90% +": 0,
      };
      for (final item in items) {
        final double conf = (item['confidence'] as num?)?.toDouble() ?? 0.0;
        if (conf < 50.0) {
          confBands["< 50%"] = (confBands["< 50%"] ?? 0) + 1;
        } else if (conf >= 50.0 && conf < 75.0) {
          confBands["50% - 75%"] = (confBands["50% - 75%"] ?? 0) + 1;
        } else if (conf >= 75.0 && conf < 90.0) {
          confBands["75% - 90%"] = (confBands["75% - 90%"] ?? 0) + 1;
        } else {
          confBands["90% +"] = (confBands["90% +"] ?? 0) + 1;
        }
      }
      _confidenceDistribution = confBands;

      // 4. Compile Weekly Trend Counts (Line Chart)
      final Map<String, int> trends = {};
      final now = DateTime.now();
      
      // Initialize past 7 days with 0 counts
      for (int i = 6; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final String dateKey = DateFormat('E').format(day); // e.g. Mon, Tue
        trends[dateKey] = 0;
      }

      for (final item in items) {
        if (item['timestamp'] != null) {
          try {
            final date = DateTime.parse(item['timestamp']);
            final int differenceInDays = now.difference(date).inDays;
            
            if (differenceInDays >= 0 && differenceInDays < 7) {
              final String dateKey = DateFormat('E').format(date);
              trends[dateKey] = (trends[dateKey] ?? 0) + 1;
            }
          } catch (_) {}
        }
      }
      _weeklyTrends = trends;
      
    } catch (e) {
      LoggingService.error("Failed to compile crop statistics", tag: "StatisticsProvider", error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
