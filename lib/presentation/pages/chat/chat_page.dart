import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/providers/chat_provider.dart';
import '../../../data/models/chat_models.dart';
import '../../../core/utils/meowl_guard.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();

  // Data for expandable prompt categories

  @override
  void initState() {
    super.initState();
    // Initialize chat provider with a welcome message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  /// Sends the message from the text field to the provider.
  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();

    // 🛡️ Guard check before sending
    final guard = guardUserInput(message);
    if (!guard.allow && guard.reason != null) {
      // Show fallback message instead of sending to API
      final fallbackMessage = pickFallback(guard.reason!, 'vi'); // Default to Vietnamese
      _showFallbackMessage(message, fallbackMessage);
      return;
    }

    context.read<ChatProvider>().sendMessage(message);
  }

  /// Shows a fallback message when guard blocks the user input
  void _showFallbackMessage(String userMessage, String fallbackContent) {
    final chatProvider = context.read<ChatProvider>();

    // Add user message and fallback response directly
    final userMsg = UIMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: userMessage,
      timestamp: DateTime.now(),
    );

    final fallbackMsg = UIMessage(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      role: 'assistant',
      content: fallbackContent,
      timestamp: DateTime.now(),
    );

    chatProvider.addMessagesDirectly([userMsg, fallbackMsg]);
  }

  /// Sends a predefined message from a quick prompt to the provider.
  void _sendQuickMessage(String message) {
    context.read<ChatProvider>().sendMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        return Column(
          children: [
            // ## Chat Header ##
            _buildChatHeader(),

            // ## Messages List ##
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: chatProvider.messages.length,
                itemBuilder: (context, index) {
                  final message = chatProvider.messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),

            // ## Quick Prompts and Categories ##
            _buildQuickPromptsRow(),

            // ## Input Section ##
            _buildInputArea(chatProvider),
          ],
        );
      },
    );
  }

  /// Builds the header with the AI assistant's avatar and name.
  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: ClipOval(
              child: Align(
                alignment: const Alignment(
                  0.0,
                  0.3,
                ), // Adjust the Y-value to move up/down
                child: Image.asset(
                  'assets/meowl_bg_clear.png', // Make sure this asset exists
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text('🐱', style: TextStyle(fontSize: 20)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meowl Chat',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'AI Assistant',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the horizontal row of quick action chips.
  Widget _buildQuickPromptsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _QuickChip(
              label: 'Khóa học Flutter',
              onTap: () => _sendQuickMessage(
                'Tôi muốn học Flutter, bạn có thể tư vấn không?',
              ),
            ),
            const SizedBox(width: 8),
            _QuickChip(
              label: 'Lộ trình Python',
              onTap: () => _sendQuickMessage(
                'Lộ trình học Python từ cơ bản đến nâng cao',
              ),
            ),
            const SizedBox(width: 8),
            _QuickChip(
              label: 'Tư vấn nghề nghiệp',
              onTap: () =>
                  _sendQuickMessage('Tôi nên chọn ngành gì trong lập trình?'),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the text input field and send button area.
  Widget _buildInputArea(ChatProvider chatProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Nhập tin nhắn...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            onPressed: chatProvider.isLoading ? null : _sendMessage,
            child: chatProvider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  /// Builds a single message bubble for either the user or the assistant.
  Widget _buildMessageBubble(UIMessage message) {
    bool isUser = message.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          // Assistant Avatar
          if (!isUser) ...[
            const CircleAvatar(
              radius: 16,
              child: Text('🐱', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isUser
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          // User Avatar
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: const Icon(Icons.person, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}

/// A simple helper widget for the tappable suggestion chips.
class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
    );
  }
}
