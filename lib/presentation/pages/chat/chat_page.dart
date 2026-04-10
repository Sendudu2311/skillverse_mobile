import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../presentation/providers/chat_provider.dart';
import '../../../data/models/chat_models.dart';
import '../../../core/utils/meowl_guard.dart';
import '../../widgets/common_loading.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Data for expandable prompt categories

  @override
  void initState() {
    super.initState();
    // Lazy init: only add welcome message if chat is empty.
    // Messages are preserved in memory across tab switches.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<ChatProvider>();
      if (chatProvider.messages.isEmpty) {
        chatProvider.initialize();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
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
        // Auto-scroll when loading changes
        if (chatProvider.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }

        return Column(
          children: [
            // ## Chat Header ##
            _buildChatHeader(),

            // ## Messages List ##
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: chatProvider.messages.length +
                    (chatProvider.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  // Show thinking indicator as the last item while loading
                  if (index >= chatProvider.messages.length) {
                    return _buildThinkingBubble();
                  }
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
    final chatProvider = context.read<ChatProvider>();

    // Use dynamic quick actions from onboarding context (G2), fallback to defaults
    final quickActions = chatProvider.quickActions.isNotEmpty
        ? chatProvider.quickActions
        : [
            MeowlQuickAction(
              id: 'default-1',
              label: 'Khóa học Flutter',
              description: '',
              actionType: 'PROMPT',
              actionValue: 'Tôi muốn học Flutter, bạn có thể tư vấn không?',
            ),
            MeowlQuickAction(
              id: 'default-2',
              label: 'Lộ trình Python',
              description: '',
              actionType: 'PROMPT',
              actionValue: 'Lộ trình học Python từ cơ bản đến nâng cao',
            ),
            MeowlQuickAction(
              id: 'default-3',
              label: 'Tư vấn nghề nghiệp',
              description: '',
              actionType: 'PROMPT',
              actionValue: 'Tôi nên chọn ngành gì trong lập trình?',
            ),
          ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: quickActions.map((action) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _QuickChip(
                label: action.label,
                onTap: () {
                  if (action.actionType == 'NAVIGATE') {
                    context.push(action.actionValue);
                  } else {
                    _sendQuickMessage(action.actionValue);
                  }
                },
              ),
            );
          }).toList(),
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
                ? CommonLoading.small()
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  /// Builds a single message bubble for either the user or the assistant.
  Widget _buildMessageBubble(UIMessage message) {
    bool isUser = message.role == 'user';
    final hasReminders =
        !isUser && message.reminders != null && message.reminders!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
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

          // G4: Reminder cards (shown below assistant messages)
          if (hasReminders) ...[
            const SizedBox(height: 8),
            ...message.reminders!.map(
              (reminder) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _ReminderCard(reminder: reminder),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds a thinking bubble indicator shown while waiting for AI response.
  Widget _buildThinkingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 16,
            child: Text('🐱', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const _ThinkingDots(),
          ),
        ],
      ),
    );
  }
}

/// Animated thinking dots indicator
class _ThinkingDots extends StatefulWidget {
  const _ThinkingDots();

  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = (_controller.value + delay) % 1.0;
            final opacity = (1 - (value * 2 - 1).abs()).clamp(0.3, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

/// G4: Reminder card displayed below AI response
class _ReminderCard extends StatelessWidget {
  final ChatReminder reminder;
  const _ReminderCard({required this.reminder});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(reminder.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (reminder.description.isNotEmpty)
                  Text(
                    reminder.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => context.push(reminder.actionUrl),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Hành động',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
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
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}
