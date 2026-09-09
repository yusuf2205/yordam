import 'package:flutter/material.dart';
import '../services/api_client.dart';

class ChatBubble {
  final String text;
  final bool isUser;
  ChatBubble(this.text, this.isUser);
}

/// The core AI interaction screen. This is where a message like
/// "Завтра в 10 утра позвонить поставщику" turns into an actual task via the
/// backend's create_task tool (see backend/src/ai).
class AiChatScreen extends StatefulWidget {
  final ApiClient apiClient;
  const AiChatScreen({super.key, required this.apiClient});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _inputController = TextEditingController();
  final _messages = <ChatBubble>[];
  String? _conversationId;
  bool _isSending = false;

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() {
      _messages.add(ChatBubble(text, true));
      _inputController.clear();
      _isSending = true;
    });
    try {
      final result = await widget.apiClient.sendChatMessage(text, conversationId: _conversationId);
      setState(() {
        _conversationId = result.conversationId;
        var reply = result.reply;
        if (result.toolCalls.isNotEmpty) {
          reply += '\n\n✅ Создано задач: ${result.toolCalls.length}';
        }
        _messages.add(ChatBubble(reply, false));
      });
    } catch (e) {
      setState(() => _messages.add(ChatBubble('Ошибка: $e', false)));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI-помощник')),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Напишите, что нужно сделать — например:\n'
                        '«Завтра в 10 утра позвонить поставщику»',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final bubble = _messages[index];
                      return Align(
                        alignment: bubble.isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: bubble.isUser
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(bubble.text),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(
                        hintText: 'Напишите или скажите...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isSending ? null : _send,
                    icon: _isSending
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
