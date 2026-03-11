import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/expert_chat_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/formatted_ai_response.dart';

/// Expert Chat Page with Session History Drawer
/// Chat interface with the selected expert
class ExpertChatPage extends StatefulWidget {
  const ExpertChatPage({super.key});

  @override
  State<ExpertChatPage> createState() => _ExpertChatPageState();
}

class _ExpertChatPageState extends State<ExpertChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpertChatProvider>().loadSessions();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
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

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();
    _focusNode.unfocus();

    await context.read<ExpertChatProvider>().sendMessage(message);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<ExpertChatProvider>(
      builder: (context, provider, _) {
        final expertContext = provider.expertContext;

        if (expertContext == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Expert Chat')),
            body: const Center(child: Text('Vui lòng chọn chuyên gia trước')),
          );
        }

        return Scaffold(
          key: _scaffoldKey,
          drawer: _buildSessionDrawer(context, provider, isDark),
          body: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Compact SliverAppBar
              SliverAppBar(
                pinned: true,
                automaticallyImplyLeading: false,
                expandedHeight: 70,
                collapsedHeight: 60,
                backgroundColor: isDark
                    ? AppTheme.darkBackgroundPrimary
                    : AppTheme.lightBackgroundPrimary,
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryBlueDark,
                        AppTheme.accentCyan,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.menu,
                              color: Colors.white,
                              size: 24,
                            ),
                            onPressed: () =>
                                _scaffoldKey.currentState?.openDrawer(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        // Show session title if available, otherwise job role
                                        (provider.currentSessionTitle ??
                                                expertContext.jobRole)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  expertContext.domain,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white70,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Messages
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final message = provider.messages[index];
                    return _MessageBubble(
                      message: message,
                      expertContext: expertContext,
                      onSuggestionTap: (suggestion) {
                        _messageController.text = suggestion;
                        _sendMessage();
                      },
                    );
                  }, childCount: provider.messages.length),
                ),
              ),

              // Loading indicator
              if (provider.isSending)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryBlueDark.withValues(alpha: 0.3),
                                AppTheme.accentCyan.withValues(alpha: 0.3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _ThinkingIndicator(),
                      ],
                    ),
                  ),
                ),

              // Bottom padding for input
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),

          // Compact Input Area
          bottomSheet: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.darkBackgroundPrimary
                  : AppTheme.lightBackgroundPrimary,
              border: Border(
                top: BorderSide(
                  width: 1,
                  color: isDark
                      ? AppTheme.darkBorderColor
                      : AppTheme.lightBorderColor,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: isDark
                            ? AppTheme.darkCardBackground
                            : AppTheme.lightCardBackground,
                        border: Border.all(
                          color: isDark
                              ? AppTheme.darkBorderColor
                              : AppTheme.lightBorderColor,
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: 'Hỏi chuyên gia...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          border: InputBorder.none,
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        enabled: !provider.isSending,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: provider.isSending ? null : _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: provider.isSending
                            ? null
                            : const LinearGradient(
                                colors: [
                                  AppTheme.primaryBlueDark,
                                  AppTheme.accentCyan,
                                ],
                              ),
                        color: provider.isSending ? Colors.grey : null,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSessionDrawer(
    BuildContext context,
    ExpertChatProvider provider,
    bool isDark,
  ) {
    return Drawer(
      backgroundColor: isDark
          ? AppTheme.darkBackgroundPrimary
          : AppTheme.lightBackgroundPrimary,
      child: SafeArea(
        child: Column(
          children: [
            // Compact Drawer Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlueDark, AppTheme.accentCyan],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  const Text(
                    'LỊCH SỬ TRÒ CHUYỆN',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            // New Chat Button
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/expert-chat/domain');
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  'Trò chuyện mới',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlueDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            // Sessions List
            Expanded(
              child: provider.loadingSessions
                  ? const Center(child: CircularProgressIndicator())
                  : provider.sessions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 40,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Chưa có cuộc trò chuyện',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: provider.sessions.length,
                      itemBuilder: (context, index) {
                        final session = provider.sessions[index];
                        final isActive =
                            provider.sessionId == session.sessionId;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppTheme.primaryBlueDark.withValues(
                                    alpha: 0.15,
                                  )
                                : (isDark
                                      ? AppTheme.darkCardBackground
                                      : AppTheme.lightCardBackground),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isActive
                                  ? AppTheme.primaryBlueDark
                                  : (isDark
                                        ? AppTheme.darkBorderColor
                                        : AppTheme.lightBorderColor),
                              width: isActive ? 1.5 : 1,
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            onTap: () async {
                              Navigator.pop(context);
                              await provider.loadSession(session);
                              _scrollToBottom();
                            },
                            leading: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlueDark.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.auto_awesome,
                                size: 16,
                                color: AppTheme.primaryBlueDark,
                              ),
                            ),
                            title: Text(
                              session.title,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.lightTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${session.messageCount} tin nhắn',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: Colors.red.withValues(alpha: 0.7),
                              ),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Xóa cuộc trò chuyện?'),
                                    content: const Text(
                                      'Bạn có chắc muốn xóa cuộc trò chuyện này?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Hủy'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text(
                                          'Xóa',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await provider.deleteSession(
                                    session.sessionId,
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Exit Button
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppTheme.darkBorderColor
                        : AppTheme.lightBorderColor,
                  ),
                ),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  provider.resetSelection();
                  context.go('/expert-chat');
                },
                icon: const Icon(Icons.exit_to_app, size: 16),
                label: const Text(
                  'Thoát chế độ chuyên gia',
                  style: TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                  side: BorderSide(
                    color: isDark
                        ? AppTheme.darkBorderColor
                        : AppTheme.lightBorderColor,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final dynamic message;
  final dynamic expertContext;
  final Function(String)? onSuggestionTap;

  const _MessageBubble({
    required this.message,
    required this.expertContext,
    this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = message.role == 'user';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          // Avatar (for assistant)
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryBlueDark, AppTheme.accentCyan],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
          ],

          // Message Content
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: isUser
                    ? LinearGradient(
                        colors: [
                          AppTheme.primaryBlueDark.withValues(alpha: 0.15),
                          AppTheme.accentCyan.withValues(alpha: 0.15),
                        ],
                      )
                    : null,
                color: isUser
                    ? null
                    : (isDark
                          ? AppTheme.darkCardBackground
                          : AppTheme.lightCardBackground),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isUser ? 12 : 2),
                  bottomRight: Radius.circular(isUser ? 2 : 12),
                ),
                border: Border.all(
                  color: isUser
                      ? AppTheme.primaryBlueDark.withValues(alpha: 0.3)
                      : (isDark
                            ? AppTheme.darkBorderColor
                            : AppTheme.lightBorderColor),
                ),
              ),
              child: isUser
                  ? SelectableText(
                      message.content,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                        height: 1.4,
                      ),
                    )
                  : FormattedAIResponse(
                      content: message.content,
                      isDark: isDark,
                      onSuggestionTap: onSuggestionTap,
                    ),
            ),
          ),

          // Avatar (for user)
          if (isUser) ...[
            const SizedBox(width: 10),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.themeOrangeStart, AppTheme.themeOrangeEnd],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

class _ThinkingIndicator extends StatefulWidget {
  @override
  State<_ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<_ThinkingIndicator>
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
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = (_controller.value + delay) % 1.0;
            final opacity = (1 - (value * 2 - 1).abs()).clamp(0.3, 1.0);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlueDark.withValues(alpha: opacity),
                    AppTheme.accentCyan.withValues(alpha: opacity),
                  ],
                ),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
