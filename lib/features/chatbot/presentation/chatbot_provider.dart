import 'package:flutter/material.dart';
import 'package:jowar_disease_detection/core/services/logging_service.dart';
import 'package:jowar_disease_detection/features/chatbot/data/models/chat_message.dart';
import 'package:jowar_disease_detection/features/chatbot/data/repositories/chatbot_repository.dart';

class ChatbotProvider extends ChangeNotifier {
  final ChatbotRepository _repository = ChatbotRepository();
  
  List<ChatMessage> _messages = [];
  final List<String> _pendingOfflineQuestions = []; // Tracks unsent questions
  bool _isLoading = false;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get hasPendingOffline => _pendingOfflineQuestions.isNotEmpty;

  void loadHistory() {
    try {
      _messages = _repository.getLocalMessages();
      notifyListeners();
    } catch (e) {
      LoggingService.error("Failed to load local chat history", tag: "ChatbotProvider", error: e);
    }
  }

  Future<void> sendUserQuery(String text, {required bool isOnline}) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messages.add(userMessage);
    await _repository.cacheMessage(userMessage);
    notifyListeners();

    if (isOnline) {
      _isLoading = true;
      notifyListeners();

      try {
        final botReply = await _repository.sendMessage(text);
        _messages.add(botReply);
      } catch (e) {
        final errorReply = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: "Error getting response from chatbot: ${e.toString()}",
          isUser: false,
          timestamp: DateTime.now(),
        );
        _messages.add(errorReply);
        await _repository.cacheMessage(errorReply);
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    } else {
      // Offline mode: cache query for sync later, add automatic helper message
      _pendingOfflineQuestions.add(text);
      
      final offlineReply = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: "You are currently offline. Your question has been saved and will be sent automatically when internet connectivity is restored.",
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(offlineReply);
      await _repository.cacheMessage(offlineReply);
      notifyListeners();
    }
  }

  /// Automatically synchronizes pending offline messages when connection is restored.
  Future<void> syncOfflineMessages() async {
    if (_pendingOfflineQuestions.isEmpty) return;

    LoggingService.info("Syncing offline queries: ${_pendingOfflineQuestions.length}", tag: "ChatbotProvider");
    _isLoading = true;
    notifyListeners();

    final List<String> queriesToSync = List.from(_pendingOfflineQuestions);
    _pendingOfflineQuestions.clear();

    for (final String question in queriesToSync) {
      try {
        final botReply = await _repository.sendMessage(question);
        _messages.add(botReply);
      } catch (e) {
        // Re-queue on failure
        _pendingOfflineQuestions.add(question);
        LoggingService.error("Failed to sync offline query", tag: "ChatbotProvider", error: e);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> clearChatHistory() async {
    await _repository.clearHistory();
    _messages.clear();
    _pendingOfflineQuestions.clear();
    notifyListeners();
  }
}
