import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:jowar_disease_detection/core/services/logging_service.dart';

class SttService extends ChangeNotifier {
  final SpeechToText _speech = SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;
  String _lastWords = "";

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  String get lastWords => _lastWords;

  Future<void> initSpeech() async {
    try {
      _isAvailable = await _speech.initialize(
        onStatus: (status) {
          LoggingService.info("Speech status: $status", tag: "SttService");
          _isListening = _speech.isListening;
          notifyListeners();
        },
        onError: (error) {
          LoggingService.error("Speech error: ${error.errorMsg}", tag: "SttService");
          _isListening = false;
          notifyListeners();
        },
      );
      notifyListeners();
    } catch (e) {
      LoggingService.error("Speech init failed", tag: "SttService", error: e);
    }
  }

  Future<void> startListening(Function(String words) onResult) async {
    if (!_isAvailable) {
      await initSpeech();
    }
    if (_isAvailable && !_isListening) {
      _lastWords = "";
      _isListening = true;
      notifyListeners();
      
      await _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          onResult(_lastWords);
          notifyListeners();
        },
      );
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      notifyListeners();
    }
  }
}
