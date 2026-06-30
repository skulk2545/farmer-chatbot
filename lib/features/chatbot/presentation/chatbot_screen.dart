import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:jowar_disease_detection/core/constants/styles.dart';
import 'package:jowar_disease_detection/core/widgets/offline_banner.dart';
import 'package:jowar_disease_detection/core/services/connectivity_service.dart';
import 'package:jowar_disease_detection/core/services/tts_service.dart';
import 'package:jowar_disease_detection/core/services/stt_service.dart';
import 'package:jowar_disease_detection/features/chatbot/data/models/chat_message.dart';
import 'package:jowar_disease_detection/features/chatbot/presentation/chatbot_provider.dart';
import 'package:intl/intl.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ConnectivityService _connectivityService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatbotProvider>(context, listen: false);
      chatProvider.loadHistory();
      
      // Setup auto sync on online status
      _connectivityService = Provider.of<ConnectivityService>(context, listen: false);
      _connectivityService.addListener(_handleConnectivityChange);
      
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _connectivityService.removeListener(_handleConnectivityChange);
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleConnectivityChange() {
    if (_connectivityService.isOnline && mounted) {
      Provider.of<ChatbotProvider>(context, listen: false).syncOfflineMessages();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    
    _inputController.clear();
    final isOnline = _connectivityService.isOnline;
    
    Provider.of<ChatbotProvider>(context, listen: false)
        .sendUserQuery(text, isOnline: isOnline)
        .then((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chat = Provider.of<ChatbotProvider>(context);
    final tts = Provider.of<TtsService>(context);
    final stt = Provider.of<SttService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Farmer AI Assistant"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: "Clear chat history",
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Clear History?"),
                  content: const Text("This will permanently delete all messages cached on this device."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Cancel"),
                    ),
                    FilledButton(
                      onPressed: () {
                        chat.clearChatHistory();
                        Navigator.of(context).pop();
                      },
                      child: const Text("Clear"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          
          // Conversation Body
          Expanded(
            child: chat.messages.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppStyles.md),
                    itemCount: chat.messages.length + (chat.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chat.messages.length) {
                        return _buildTypingIndicator(theme);
                      }
                      
                      final message = chat.messages[index];
                      return _buildChatBubble(theme, message, tts);
                    },
                  ),
          ),
          
          // Audio Speech overlay when listening
          if (stt.isListening)
            Container(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.9),
              padding: const EdgeInsets.all(AppStyles.md),
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SpinKitWave(
                    color: Colors.green,
                    size: 24,
                  ),
                  const SizedBox(height: AppStyles.sm),
                  Text(
                    stt.lastWords.isEmpty ? "Listening to your voice..." : stt.lastWords,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppStyles.sm),
                  FilledButton(
                    onPressed: () {
                      stt.stopListening();
                      if (stt.lastWords.isNotEmpty) {
                        _inputController.text = stt.lastWords;
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                    ),
                    child: const Text("Stop Listening"),
                  ),
                ],
              ),
            ),

          // Message Input Field
          _buildInputBar(theme, stt),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 72,
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppStyles.md),
            Text(
              "Ask about Sorghum Diseases",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppStyles.xs),
            Text(
              "Type a farming question or tap the microphone to speak. For example:\n\"How do I cure Charcoal Rot?\"",
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(ThemeData theme, ChatMessage message, TtsService tts) {
    final bool isUser = message.isUser;
    final alignment = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isUser 
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final textColor = isUser
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;
    final formattedTime = DateFormat('hh:mm a').format(message.timestamp);

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Row(
          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                radius: 16,
                child: Icon(Icons.psychology_rounded, size: 18, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(AppStyles.md),
                margin: const EdgeInsets.only(bottom: AppStyles.xs, top: AppStyles.xs),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(AppStyles.radiusMedium),
                    topRight: const Radius.circular(AppStyles.radiusMedium),
                    bottomLeft: isUser ? const Radius.circular(AppStyles.radiusMedium) : Radius.zero,
                    bottomRight: isUser ? Radius.zero : const Radius.circular(AppStyles.radiusMedium),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: TextStyle(color: textColor, height: 1.3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 9,
                        color: textColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!isUser) ...[
              // Audio TTS read button for chatbot answers
              IconButton(
                icon: const Icon(Icons.volume_up_rounded, size: 18),
                onPressed: () {
                  tts.speak(message.text);
                },
                tooltip: "Listen to response",
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppStyles.sm),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            radius: 16,
            child: Icon(Icons.psychology_rounded, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppStyles.md, vertical: AppStyles.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
            ),
            child: const SpinKitThreeBounce(
              color: Colors.green,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(ThemeData theme, SttService stt) {
    return Container(
      padding: const EdgeInsets.all(AppStyles.sm),
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Row(
          children: [
            // Voice Microphone Button
            Semantics(
              label: "Speak question",
              button: true,
              child: IconButton(
                icon: Icon(
                  stt.isListening ? Icons.mic_off_rounded : Icons.mic_rounded,
                  color: stt.isListening ? Colors.red : theme.colorScheme.primary,
                ),
                onPressed: () async {
                  if (stt.isListening) {
                    stt.stopListening();
                  } else {
                    await stt.startListening((words) {
                      _inputController.text = words;
                    });
                  }
                },
              ),
            ),
            
            // Input Text Field
            Expanded(
              child: TextField(
                controller: _inputController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: "Ask about diseases...",
                  border: AppStyles.inputBorder(Colors.transparent, radius: AppStyles.radiusLarge),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppStyles.md, vertical: 8),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 4),
            
            // Send Button
            IconButton(
              icon: Icon(Icons.send_rounded, color: theme.colorScheme.primary),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
