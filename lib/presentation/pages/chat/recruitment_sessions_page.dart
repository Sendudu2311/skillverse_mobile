import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/recruitment_chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/recruitment_chat_models.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../widgets/empty_state_widget.dart';
import '../../themes/app_theme.dart';

/// Page showing the list of recruitment chat sessions for the Learner.
class RecruitmentSessionsPage extends StatefulWidget {
  const RecruitmentSessionsPage({super.key});

  @override
  State<RecruitmentSessionsPage> createState() =>
      _RecruitmentSessionsPageState();
}

class _RecruitmentSessionsPageState extends State<RecruitmentSessionsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAndLoad();
    });
  }

  void _initAndLoad() {
    final auth = context.read<AuthProvider>();
    final provider = context.read<RecruitmentChatProvider>();
    if (auth.user != null) {
      provider.setCurrentUserId(auth.user!.id);
      provider.loadMySessions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const SkillVerseAppBar(
        title: 'Chat Tuyển Dụng',
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Consumer<RecruitmentChatProvider>(
          builder: (context, provider, _) {
            if (provider.isLoadingSessions) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 5,
                itemBuilder: (_, __) => const _SessionCardSkeleton(),
              );
            }
  
            if (provider.sessions.isEmpty) {
              return Center(
                child: EmptyStateWidget(
                  icon: Icons.work_outline,
                  title: 'Chưa có cuộc trò chuyện tuyển dụng',
                  subtitle:
                      'Khi nhà tuyển dụng liên hệ bạn, cuộc trò chuyện sẽ xuất hiện tại đây',
                  iconGradient: AppTheme.blueGradient,
                ),
              );
            }
  
            return RefreshIndicator(
              onRefresh: () => provider.loadMySessions(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.sessions.length,
                itemBuilder: (context, index) {
                  final session = provider.sessions[index];
                  return _SessionCard(session: session, isDark: isDark);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Session Card
// ════════════════════════════════════════════════════════════════════════════

class _SessionCard extends StatelessWidget {
  final RecruitmentSessionResponse session;
  final bool isDark;
  const _SessionCard({required this.session, required this.isDark});

  Color _statusColor(RecruitmentSessionStatus status) {
    switch (status) {
      case RecruitmentSessionStatus.CONTACTED:
        return const Color(0xFF6B7280);
      case RecruitmentSessionStatus.INTERESTED:
        return const Color(0xFF10B981);
      case RecruitmentSessionStatus.INVITED:
        return const Color(0xFF22D3EE);
      case RecruitmentSessionStatus.APPLICATION_RECEIVED:
        return const Color(0xFF8B5CF6);
      case RecruitmentSessionStatus.SCREENING:
        return const Color(0xFFF59E0B);
      case RecruitmentSessionStatus.OFFER_SENT:
        return const Color(0xFFEC4899);
      case RecruitmentSessionStatus.HIRED:
        return const Color(0xFF22C55E);
      case RecruitmentSessionStatus.NOT_INTERESTED:
        return const Color(0xFFEF4444);
      case RecruitmentSessionStatus.ARCHIVED:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = (session.unreadCount ?? 0) > 0;
    final chatDisabled = session.isChatAvailable == false;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => context.push('/recruitment-chat/${session.id}'),
      child: Opacity(
        opacity: chatDisabled ? 0.6 : 1.0,
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor:
                      AppTheme.primaryBlueDark.withValues(alpha: 0.15),
                  backgroundImage: session.recruiterAvatar != null
                      ? NetworkImage(session.recruiterAvatar!)
                      : null,
                  child: session.recruiterAvatar == null
                      ? Icon(
                          Icons.business,
                          color: AppTheme.primaryBlueDark,
                          size: 24,
                        )
                      : null,
                ),
                if (hasUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? AppTheme.darkCardBackground
                              : Colors.white,
                          width: 2,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '${session.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recruiter name + status badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          session.recruiterName ?? 'Nhà tuyển dụng',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                hasUnread ? FontWeight.w700 : FontWeight.w600,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(session.status).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          session.status.label,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: _statusColor(session.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Job title + company
                  if (session.jobTitle != null || session.recruiterCompany != null)
                    Row(
                      children: [
                        Icon(
                          Icons.work_outline,
                          size: 12,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            [
                              if (session.jobTitle != null) session.jobTitle,
                              if (session.recruiterCompany != null)
                                session.recruiterCompany,
                            ].join(' • '),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryBlueDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),

                  // Last message preview
                  if (session.lastMessagePreview != null)
                    Text(
                      session.lastMessagePreview!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            hasUnread ? FontWeight.w600 : FontWeight.normal,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                  // Chat disabled warning
                  if (chatDisabled)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock,
                            size: 11,
                            color: AppTheme.errorColor,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Job đã đóng',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.errorColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Trailing arrow
            Icon(
              Icons.chevron_right,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Skeleton Loader
// ════════════════════════════════════════════════════════════════════════════

class _SessionCardSkeleton extends StatelessWidget {
  const _SessionCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmer = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.grey.shade200;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkCardBackground
            : AppTheme.lightCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 26, backgroundColor: shimmer),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 140,
                  decoration: BoxDecoration(
                    color: shimmer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: 200,
                  decoration: BoxDecoration(
                    color: shimmer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 10,
                  width: 100,
                  decoration: BoxDecoration(
                    color: shimmer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
