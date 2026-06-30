import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:jowar_disease_detection/core/services/logging_service.dart';

class TtsService extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;

  TtsService() {
    _initTts();
  }

  bool get isPlaying => _isPlaying;

  void _initTts() {
    _flutterTts.setStartHandler(() {
      _isPlaying = true;
      notifyListeners();
    });

    _flutterTts.setCompletionHandler(() {
      _isPlaying = false;
      notifyListeners();
    });

    _flutterTts.setCancelHandler(() {
      _isPlaying = false;
      notifyListeners();
    });

    _flutterTts.setErrorHandler((msg) {
      _isPlaying = false;
      notifyListeners();
      LoggingService.error("TTS engine error: $msg", tag: "TtsService");
    });
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      
      // Stop current reading before starting new one
      if (_isPlaying) {
        await stop();
      }
      
      await _flutterTts.speak(text);
    } catch (e) {
      LoggingService.error("TTS speak failed", tag: "TtsService", error: e);
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isPlaying = false;
      notifyListeners();
    } catch (e) {
      LoggingService.error("TTS stop failed", tag: "TtsService", error: e);
    }
  }
}
