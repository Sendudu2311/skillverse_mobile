import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/recruitment_chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/recruitment_chat_models.dart';
import '../../widgets/skeleton_loaders.dart';
import '../../widgets/common_loading.dart';
import '../../themes/app_theme.dart';

/// Full-screen recruitment chat window between Learner (candidate) and Recruiter.
class RecruitmentChatWindow extends StatefulWidget {
  final int sessionId;
  const RecruitmentChatWindow({super.key, required this.sessionId});

  @override
  State<RecruitmentChatWindow> createState() => _RecruitmentChatWindowState();
}

class _RecruitmentChatWindowState extends State<RecruitmentChatWindow> {
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
    final provider = context.read<RecruitmentChatProvider>();
    if (auth.user != null) {
      provider.setCurrentUserId(auth.user!.id);
      provider.enterSession(widget.sessionId);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    context.read<RecruitmentChatProvider>().leaveSession();
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
    context.read<RecruitmentChatProvider>().sendMessage(content);
    Future.delayed(
        const Duration(milliseconds: 100), () => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = context.read<AuthProvider>().user?.id ?? 0;

    return Scaffold(
      body: Consumer<RecruitmentChatProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // ── Header ──────────────────────────────────────────────
              _buildHeader(context, isDark, provider),

              // ── Job Context Bar ─────────────────────────────────────
              if (provider.activeSession?.jobTitle != null)
                _buildJobContextBar(isDark, provider.activeSession!),

              // ── Chat disabled banner ────────────────────────────────
              if (provider.activeSession?.isChatAvailable == false)
                _buildDisabledBanner(isDark, provider.activeSession!),

              // ── Messages ────────────────────────────────────────────
              Expanded(
                child: Stack(
                  children: [
                    _buildMessageList(
                        context, isDark, provider, currentUserId),
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
  Widget _buildHeader(BuildContext context, bool isDark,
      RecruitmentChatProvider provider) {
    final session = provider.activeSession;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
        left: 8,
        right: 16,
      ),
      decoration: BoxDecoration(
        color:
            isDark ? AppTheme.darkCardBackground : AppTheme.lightCardBackground,
        border: Border(
          bottom: BorderSide(
            color:
                isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back,
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
          ),

          // Recruiter avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primaryBlueDark.withOpacity(0.2),
            backgroundImage: session?.recruiterAvatar != null
                ? NetworkImage(session!.recruiterAvatar!)
                : null,
            child: session?.recruiterAvatar == null
                ? const Icon(Icons.business,
                    color: AppTheme.primaryBlueDark, size: 22)
                : null,
          ),
          const SizedBox(width: 12),

          // Name + company
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session?.recruiterName ?? 'Đang tải...',
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
                if (session?.recruiterCompany != null)
                  Text(
                    session!.recruiterCompany!,
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

          // Status badge
          if (session != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlueDark.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                session.status.label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryBlueDark,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Job Context Bar ───────────────────────────────────────────────────
  Widget _buildJobContextBar(
      bool isDark, RecruitmentSessionResponse session) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlueDark.withOpacity(isDark ? 0.15 : 0.06),
        border: Border(
          bottom: BorderSide(
            color:
                isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.work_outline,
            size: 14,
            color: AppTheme.primaryBlueDark,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              session.jobTitle!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlueDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (session.isRemote == true)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(left: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Remote',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF22C55E),
                ),
              ),
            ),
          if (session.matchScore != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(left: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${session.matchScore}% match',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF59E0B),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Disabled Banner ───────────────────────────────────────────────────
  Widget _buildDisabledBanner(
      bool isDark, RecruitmentSessionResponse session) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(isDark ? 0.15 : 0.08),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.errorColor.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 16, color: AppTheme.errorColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              session.chatDisabledReason ??
                  'Cuộc trò chuyện này hiện không thể tiếp tục.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.errorColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Message List ──────────────────────────────────────────────────────
  Widget _buildMessageList(BuildContext context, bool isDark,
      RecruitmentChatProvider provider, int currentUserId) {
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
              'Chưa có tin nhắn',
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

    // Auto-scroll when new messages arrive
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
        final showName = !isMe &&
            (index == 0 ||
                provider.messages[index - 1].senderId != message.senderId);

        return _RecruitmentMessageBubble(
          message: message,
          isMe: isMe,
          showSenderName: showName,
          isDark: isDark,
        );
      },
    );
  }

  // ── Input Area ────────────────────────────────────────────────────────
  Widget _buildInputArea(BuildContext context, bool isDark,
      RecruitmentChatProvider provider) {
    final chatDisabled = provider.activeSession?.isChatAvailable == false;

    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color:
            isDark ? AppTheme.darkCardBackground : AppTheme.lightCardBackground,
        border: Border(
          top: BorderSide(
            color:
                isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: chatDisabled
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock, size: 14, color: AppTheme.errorColor),
                      const SizedBox(width: 6),
                      Text(
                        'Job đã đóng — không thể gửi tin nhắn',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.errorColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Row(
                children: [
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
                          borderSide: const BorderSide(
                              color: AppTheme.primaryBlueDark),
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
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primaryBlueDark,
                    child: IconButton(
                      onPressed:
                          provider.isSending ? null : _sendMessage,
                      icon: provider.isSending
                          ? CommonLoading.small()
                          : const Icon(Icons.send,
                              color: Colors.white),
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

class _RecruitmentMessageBubble extends StatelessWidget {
  final RecruitmentMessageResponse message;
  final bool isMe;
  final bool showSenderName;
  final bool isDark;

  const _RecruitmentMessageBubble({
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
          if (showSenderName)
            Padding(
              padding: const EdgeInsets.only(left: 44, bottom: 4),
              child: Text(
                message.senderName ?? 'Unknown',
                style: const TextStyle(
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
                  backgroundImage: message.senderAvatar != null
                      ? NetworkImage(message.senderAvatar!)
                      : null,
                  child: message.senderAvatar == null
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
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isMe
                              ? Colors.white
                              : (isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.lightTextPrimary),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(message.createdAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: isMe
                                  ? Colors.white.withOpacity(0.7)
                                  : (isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary),
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              message.isRead == true
                                  ? Icons.done_all
                                  : Icons.done,
                              size: 13,
                              color: message.isRead == true
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                            ),
                          ],
                        ],
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
