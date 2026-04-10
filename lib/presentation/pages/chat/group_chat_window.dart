import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/group_chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/group_chat_models.dart';
import '../../widgets/skeleton_loaders.dart';
import '../../widgets/common_loading.dart';
import '../../themes/app_theme.dart';

/// Full-screen group chat window with real-time messaging.
class GroupChatWindow extends StatefulWidget {
  final int groupId;
  const GroupChatWindow({super.key, required this.groupId});

  @override
  State<GroupChatWindow> createState() => _GroupChatWindowState();
}

class _GroupChatWindowState extends State<GroupChatWindow> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showScrollDown = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAndEnter();
    });
  }

  void _initAndEnter() {
    final auth = context.read<AuthProvider>();
    final provider = context.read<GroupChatProvider>();
    if (auth.user != null) {
      provider.setCurrentUser(
        userId: auth.user!.id,
        userName: auth.user!.fullName ?? auth.user!.email,
      );
      provider.enterGroup(widget.groupId);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    // Leave group when navigating away
    context.read<GroupChatProvider>().leaveCurrentGroup();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final atBottom = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100;
    if (atBottom != !_showScrollDown) {
      setState(() => _showScrollDown = !atBottom);
    }
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    if (animated) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    _messageController.clear();
    context.read<GroupChatProvider>().sendMessage(content);
    Future.delayed(const Duration(milliseconds: 100), () => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = context.read<AuthProvider>().user?.id ?? 0;

    return Scaffold(
      body: Consumer<GroupChatProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // ── Header ──────────────────────────────────────────────
              _buildHeader(context, isDark, provider),

              // ── Messages ────────────────────────────────────────────
              Expanded(
                child: Stack(
                  children: [
                    _buildMessageList(
                        context, isDark, provider, currentUserId),

                    // Scroll to bottom button
                    if (_showScrollDown)
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: FloatingActionButton.small(
                          onPressed: () => _scrollToBottom(),
                          backgroundColor: AppTheme.primaryBlueDark,
                          child: const Icon(Icons.keyboard_arrow_down,
                              color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Input ───────────────────────────────────────────────
              _buildInputArea(context, isDark, provider),
            ],
          );
        },
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────
  Widget _buildHeader(
      BuildContext context, bool isDark, GroupChatProvider provider) {
    final group = provider.currentGroup;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
        left: 8,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : AppTheme.lightCardBackground,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),

          // Group avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primaryBlueDark.withOpacity(0.2),
            backgroundImage: group?.avatarUrl != null
                ? NetworkImage(group!.avatarUrl!)
                : null,
            child: group?.avatarUrl == null
                ? const Icon(Icons.groups, color: AppTheme.primaryBlueDark, size: 22)
                : null,
          ),
          const SizedBox(width: 12),

          // Group name + member count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group?.name ?? 'Đang tải...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (group != null)
                  Text(
                    '${group.memberCount} thành viên${group.mentorName != null ? ' • ${group.mentorName}' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Message list ──────────────────────────────────────────────────────
  Widget _buildMessageList(BuildContext context, bool isDark,
      GroupChatProvider provider, int currentUserId) {
    if (provider.isLoadingMessages) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => const CommentSkeleton(),
      );
    }

    if (provider.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Chào mừng đến với nhóm!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy bắt đầu cuộc trò chuyện',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Auto-scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final isAtBottom = _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 150;
        if (isAtBottom) {
          _scrollToBottom(animated: false);
        }
      }
    });

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: provider.messages.length,
      itemBuilder: (context, index) {
        final message = provider.messages[index];
        final isMe = message.isMine(currentUserId);

        // Show sender name when it changes
        final showName = !isMe &&
            (index == 0 ||
                provider.messages[index - 1].senderId != message.senderId);

        return _GroupMessageBubble(
          message: message,
          isMe: isMe,
          showSenderName: showName,
          isDark: isDark,
        );
      },
    );
  }

  // ── Input area ────────────────────────────────────────────────────────
  Widget _buildInputArea(
      BuildContext context, bool isDark, GroupChatProvider provider) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : AppTheme.lightCardBackground,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Text input
            Expanded(
              child: TextField(
                controller: _messageController,
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppTheme.darkBackgroundSecondary
                      : AppTheme.lightBackgroundSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppTheme.darkBorderColor
                          : AppTheme.lightBorderColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppTheme.darkBorderColor
                          : AppTheme.lightBorderColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        const BorderSide(color: AppTheme.primaryBlueDark),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),

            // Send button
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primaryBlueDark,
              child: IconButton(
                onPressed: provider.isSending ? null : _sendMessage,
                icon: provider.isSending
                    ? CommonLoading.small()
                    : const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Message Bubble Widget
// ════════════════════════════════════════════════════════════════════════════

class _GroupMessageBubble extends StatelessWidget {
  final GroupChatMessageDTO message;
  final bool isMe;
  final bool showSenderName;
  final bool isDark;

  const _GroupMessageBubble({
    required this.message,
    required this.isMe,
    required this.showSenderName,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender name (for other's messages)
          if (showSenderName)
            Padding(
              padding: const EdgeInsets.only(left: 44, bottom: 4),
              child: Text(
                message.senderName ?? 'Unknown',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlueDark,
                ),
              ),
            ),

          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Other's avatar
              if (!isMe) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      AppTheme.primaryBlueDark.withOpacity(0.2),
                  backgroundImage: message.senderAvatarUrl != null
                      ? NetworkImage(message.senderAvatarUrl!)
                      : null,
                  child: message.senderAvatarUrl == null
                      ? Text(
                          (message.senderName ?? '?')[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlueDark,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
              ],

              // Bubble
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppTheme.primaryBlueDark
                        : (isDark
                            ? AppTheme.darkCardBackground
                            : AppTheme.lightCardBackground),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isMe
                          ? const Radius.circular(16)
                          : const Radius.circular(4),
                      bottomRight: isMe
                          ? const Radius.circular(4)
                          : const Radius.circular(16),
                    ),
                    border: isMe
                        ? null
                        : Border.all(
                            color: isDark
                                ? AppTheme.darkBorderColor
                                : AppTheme.lightBorderColor,
                          ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Message content
                      _buildContent(),
                      const SizedBox(height: 4),
                      // Timestamp
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe
                              ? Colors.white.withOpacity(0.7)
                              : (isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (isMe) const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (message.messageType) {
      case 'GIF':
        if (message.gifUrl != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              message.gifUrl!,
              width: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Text(
                '[GIF] ${message.content}',
                style: TextStyle(
                  color: isMe ? Colors.white : null,
                ),
              ),
            ),
          );
        }
        return Text(
          message.content,
          style: TextStyle(color: isMe ? Colors.white : null),
        );
      case 'IMAGE':
        if (message.imageUrl != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              message.imageUrl!,
              width: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Text(
                '[Image]',
                style: TextStyle(color: isMe ? Colors.white : null),
              ),
            ),
          );
        }
        return Text(
          message.content,
          style: TextStyle(color: isMe ? Colors.white : null),
        );
      case 'EMOJI':
        return Text(
          message.emojiCode ?? message.content,
          style: const TextStyle(fontSize: 32),
        );
      default: // TEXT
        return Text(
          message.content,
          style: TextStyle(
            color: isMe
                ? Colors.white
                : (isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary),
          ),
        );
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Vừa xong';
      if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
      if (diff.inDays < 1) {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
      return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
