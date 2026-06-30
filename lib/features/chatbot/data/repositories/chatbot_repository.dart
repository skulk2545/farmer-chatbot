import 'package:hive/hive.dart';
import 'package:jowar_disease_detection/core/api/api_service.dart';
import 'package:jowar_disease_detection/core/api/endpoints.dart';
import 'package:jowar_disease_detection/core/services/logging_service.dart';
import 'package:jowar_disease_detection/features/chatbot/data/models/chat_message.dart';

class ChatbotRepository {
  final ApiService _apiService = ApiService();

  /// Sends a question to the backend chat API.
  /// On success, stores the chatbot's response locally.
  Future<ChatMessage> sendMessage(String text) async {
    LoggingService.info("Sending chat query: $text", tag: "ChatbotRepository");
    
    try {
      final response = await _apiService.post(
        Endpoints.chat,
        data: {"question": text},
      );

      if (response.statusCode == 200 && response.data != null) {
        final String replyText = response.data['response'] ?? "I couldn't process that question.";
        
        final ChatMessage botMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: replyText,
          isUser: false,
          timestamp: DateTime.now(),
        );

        // Cache bot message
        await cacheMessage(botMessage);
        
        return botMessage;
      } else {
        throw ServerException("Chat API failed with status: ${response.statusCode}");
      }
    } catch (e) {
      LoggingService.error("Chat query execution failed", tag: "ChatbotRepository", error: e);
      rethrow;
    }
  }

  /// Caches a chat message in the local Hive box.
  Future<void> cacheMessage(ChatMessage message) async {
    try {
      final box = Hive.box('chat_history');
      await box.add(message.toJson());
    } catch (e) {
      LoggingService.error("Failed to cache message locally", tag: "ChatbotRepository", error: e);
    }
  }

  /// Retrieves the cached chatbot history.
  List<ChatMessage> getLocalMessages() {
    try {
      final box = Hive.box('chat_history');
      return box.values
          .map((item) => ChatMessage.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      LoggingService.error("Failed to read local chat history", tag: "ChatbotRepository", error: e);
      return [];
    }
  }

  /// Clears the local chat history.
  Future<void> clearHistory() async {
    try {
      final box = Hive.box('chat_history');
      await box.clear();
      LoggingService.info("Local chat history cleared successfully.", tag: "ChatbotRepository");
    } catch (e) {
      LoggingService.error("Failed to clear local chat history", tag: "ChatbotRepository", error: e);
    }
  }
}
