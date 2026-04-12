import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/messaging_models.dart';
import '../../providers/messaging_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_loading.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/animated_list_item.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../../core/utils/date_time_helper.dart';

class MessagingPage extends StatefulWidget {
  const MessagingPage({super.key});

  @override
  State<MessagingPage> createState() => _MessagingPageState();
}

class _MessagingPageState extends State<MessagingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MessagingProvider>();
      provider.connectWebSocket();
      provider.loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SkillVerseAppBar(
        title: 'Tin nhắn',
        onBack: () => context.pop(),
        actions: [
          IconButton(
            onPressed: () => context.push('/recruitment-sessions'),
            icon: Icon(
              Icons.work_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: 'Chat tuyển dụng',
          ),
          IconButton(
            onPressed: () => context.push('/community-groups'),
            icon: Icon(
              Icons.groups,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: 'Chat nhóm cộng đồng',
          ),
        ],
      ),
      body: Consumer<MessagingProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.conversations.isEmpty) {
            return CommonLoading.center();
          }
          if (provider.hasError && provider.conversations.isEmpty) {
            return ErrorStateWidget(
              message: provider.errorMessage ?? 'Không thể tải danh sách tin nhắn',
              onRetry: () => provider.loadConversations(),
            );
          }
          if (provider.conversations.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.chat_bubble_outline,
              title: 'Chưa có cuộc trò chuyện',
              subtitle: 'Bắt đầu trò chuyện với người khác từ trang Community hoặc Mentor',
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.refreshConversations(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: provider.conversations.length,
              itemBuilder: (context, index) {
                final conversation = provider.conversations[index];
                return AnimatedListItem(
                  index: index,
                  child: _ConversationTile(
                    conversation: conversation,
                    onTap: () => _openChat(conversation),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _openChat(MessagingConversation conversation) {
    context.push(
      '/messaging/chat/${conversation.counterpartId}',
      extra: conversation,
    );
  }
}

/// Single conversation tile
class _ConversationTile extends StatelessWidget {
  final MessagingConversation conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Text(
          conversation.counterpartName.isNotEmpty
              ? conversation.counterpartName[0].toUpperCase()
              : '?',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        conversation.counterpartName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        conversation.lastContent,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: conversation.unreadCount > 0
              ? Theme.of(context).colorScheme.onSurface
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          fontWeight: conversation.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            DateTimeHelper.formatSmart(DateTime.parse(conversation.lastTime)),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          if (conversation.unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${conversation.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Chat detail page — message thread with one other user
class MessagingChatPage extends StatefulWidget {
  final int counterpartId;
  final MessagingConversation? conversation;

  const MessagingChatPage({
    super.key,
    required this.counterpartId,
    this.conversation,
  });

  @override
  State<MessagingChatPage> createState() => _MessagingChatPageState();
}

class _MessagingChatPageState extends State<MessagingChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MessagingProvider>();
      if (provider.activeOtherUserId != widget.counterpartId) {
        provider.openChat(widget.counterpartId);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    context.read<MessagingProvider>().sendMessage(text);

    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    final counterpartName = widget.conversation?.counterpartName ?? 'Chat';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                counterpartName.isNotEmpty ? counterpartName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Text(counterpartName),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.read<MessagingProvider>().closeChat();
            context.pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<MessagingProvider>().refreshMessages(),
          ),
        ],
      ),
      body: Consumer<MessagingProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.messages.isEmpty) {
            return CommonLoading.center();
          }

          return Column(
            children: [
              // Messages list
              Expanded(
                child: provider.messages.isEmpty
                    ? Center(
                        child: Text(
                          'Chưa có tin nhắn nào.\nHãy gửi tin nhắn đầu tiên!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.messages.length,
                        itemBuilder: (context, index) {
                          final msg = provider.messages[index];
                          final isMe = msg.senderId == context.read<AuthProvider>().user?.id;
                          return _MessageBubble(
                            message: msg,
                            isMe: isMe,
                            counterpartName: widget.conversation?.counterpartName ?? 'User',
                          );
                        },
                      ),
              ),

              // Input area
              _buildInputArea(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInputArea(MessagingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Nhắn tin...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            onPressed: provider.isSending ? null : _sendMessage,
            child: provider.isSending
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CommonLoading.small(),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}

/// Individual message bubble
class _MessageBubble extends StatelessWidget {
  final MessagingMessage message;
  final bool isMe;
  final String counterpartName;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.counterpartName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: Text(
                counterpartName[0].toUpperCase(),
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GlassCard(
              borderRadius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateTimeHelper.formatSmart(DateTime.parse(message.createdAt)),
                    style: TextStyle(
                      fontSize: 10,
                      color: (isMe ? Colors.white70 : Theme.of(context).colorScheme.onSurface)
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}