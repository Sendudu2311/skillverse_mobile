import 'package:flutter/material.dart';
import '../../widgets/skeleton_loaders.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/skin_provider.dart';
import '../../themes/app_theme.dart';
import '../../../core/utils/storage_helper.dart';
import '../../../core/utils/number_formatter.dart';
import '../../widgets/onboarding_prompt.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/error_state_widget.dart';
import '../../../data/models/enrollment_models.dart';
import '../../../data/models/dashboard_models.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _showAllActions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id;
      context.read<DashboardProvider>().loadDashboard(userId: userId);
      context.read<SkinProvider>().loadAllSkins();
      _checkAndShowOnboarding();
    });
  }

  Future<void> _checkAndShowOnboarding() async {
    final shouldShow =
        StorageHelper.instance.readBool(StorageKey.showOnboardingPrompt) ??
        false;
    if (shouldShow && mounted) {
      OnboardingPrompt.show(
        context,
        onDismiss: () {
          StorageHelper.instance.writeBool(
            StorageKey.showOnboardingPrompt,
            false,
          );
        },
      );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng,';
    if (hour < 18) return 'Chào buổi chiều,';
    return 'Chào buổi tối,';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer2<AuthProvider, DashboardProvider>(
      builder: (context, authProvider, dashboardProvider, child) {
        final user = authProvider.user;

        if (dashboardProvider.isLoading && !dashboardProvider.hasData) {
          return const SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                CardSkeleton(imageHeight: 120),
                SizedBox(height: 16),
                ListItemSkeleton(),
                ListItemSkeleton(),
                ListItemSkeleton(),
              ],
            ),
          );
        }

        if (dashboardProvider.errorMessage != null &&
            !dashboardProvider.hasData) {
          return ErrorStateWidget(
            message: dashboardProvider.errorMessage!,
            onRetry: () {
              final userId = authProvider.user?.id;
              dashboardProvider.loadDashboard(userId: userId);
            },
          );
        }

        return RefreshIndicator(
          onRefresh: () {
            final userId = authProvider.user?.id;
            return dashboardProvider.refreshDashboard(userId: userId);
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero: greeting + streak + weekly dots + Meowl
                _buildHeroCard(
                  context,
                  user?.fullName ?? 'Pilot',
                  dashboardProvider,
                  isDark,
                ),
                const SizedBox(height: 16),

                // 2. Continue Learning
                _buildContinueLearning(
                  context,
                  dashboardProvider.continueCourse,
                  isDark,
                ),
                const SizedBox(height: 16),

                // 3. Active Roadmap (compact, conditional)
                if (dashboardProvider.activeRoadmap != null) ...[
                  _buildActiveRoadmap(
                    context,
                    dashboardProvider.activeRoadmap!,
                    isDark,
                  ),
                  const SizedBox(height: 16),
                ],

                // 4. Quick Actions (4-col, expandable)
                _buildQuickActions(context, isDark),
                const SizedBox(height: 16),

                // 5. Stats Grid (2×2)
                _buildStatsGrid(context, dashboardProvider, isDark),
                const SizedBox(height: 16),

                // 6. Wallet (compact)
                _buildWalletCompact(context, dashboardProvider, isDark),

                // 7. Premium (compact, conditional)
                if (dashboardProvider.hasPremium) ...[
                  const SizedBox(height: 16),
                  _buildPremiumCompact(context, dashboardProvider, isDark),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── 1. Hero Card ────────────────────────────────────────────────────────────

  Future<void> _handleCheckIn(BuildContext context) async {
    final provider = context.read<DashboardProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await provider.checkIn();
    if (!mounted) return;
    if (result == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Điểm danh thất bại, thử lại sau')),
      );
      return;
    }
    if (result.alreadyCheckedIn) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Bạn đã điểm danh hôm nay rồi!')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Điểm danh thành công! +${result.coinsAwarded} SC 🔥 Streak: ${result.currentStreak} ngày',
          ),
          backgroundColor: AppTheme.themeOrangeStart,
        ),
      );
    }
  }

  Widget _buildHeroCard(
    BuildContext context,
    String userName,
    DashboardProvider provider,
    bool isDark,
  ) {
    final weeklyActivity = provider.weeklyActivity;
    final streak = provider.currentStreak;
    final daysOfWeek = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Semantics(
      label: 'welcome_header',
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.darkCardBackground
              : AppTheme.lightCardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppTheme.darkBorderColor
                : AppTheme.lightBorderColor,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: greeting + name + streak row
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: AppTheme.accentCyan,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Gradient name text
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        AppTheme.accentCyan,
                        isDark ? Colors.white : AppTheme.lightTextPrimary,
                        AppTheme.accentCyan,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ).createShader(bounds),
                    child: Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Streak badge + weekly dots
                  Row(
                    children: [
                      // Streak badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.themeOrangeStart.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.themeOrangeStart.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              color: AppTheme.themeOrangeStart,
                              size: 13,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '$streak ngày',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.themeOrangeStart,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Weekly dots
                      Row(
                        children: List.generate(7, (i) {
                          final isActive = weeklyActivity.length > i
                              ? weeklyActivity[i]
                              : false;
                          return Tooltip(
                            message: daysOfWeek[i],
                            child: Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppTheme.themeOrangeStart
                                    : (isDark
                                          ? AppTheme.darkBorderColor
                                          : AppTheme.lightBorderColor),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Check-in button
                  _buildCheckInButton(context, provider),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Right: Meowl avatar
            Consumer<SkinProvider>(
              builder: (context, skinProvider, _) {
                final skin = skinProvider.selectedSkin;
                if (skin != null && skin.imageUrl != null) {
                  return Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondaryPurple.withValues(
                            alpha: 0.4,
                          ),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Image.network(
                      skin.imageUrl!,
                      width: 72,
                      height: 72,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                    ),
                  );
                }
                return _buildDefaultAvatar();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInButton(BuildContext context, DashboardProvider provider) {
    final checkedIn = provider.isCheckedInToday;
    final loading = provider.isCheckingIn;

    return SizedBox(
      height: 30,
      child: ElevatedButton.icon(
        onPressed: (checkedIn || loading)
            ? null
            : () => _handleCheckIn(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: checkedIn
              ? AppTheme.themeGreenStart.withValues(alpha: 0.2)
              : AppTheme.themeOrangeStart,
          foregroundColor: checkedIn ? AppTheme.themeGreenStart : Colors.white,
          disabledBackgroundColor: checkedIn
              ? AppTheme.themeGreenStart.withValues(alpha: 0.15)
              : null,
          disabledForegroundColor:
              checkedIn ? AppTheme.themeGreenStart : null,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: checkedIn
                  ? AppTheme.themeGreenStart.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          elevation: 0,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: loading
            ? SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                checkedIn ? Icons.check_circle_outline : Icons.today_outlined,
                size: 14,
              ),
        label: Text(
          checkedIn ? 'Đã điểm danh' : 'Điểm danh',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlueDark, AppTheme.secondaryPurple],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.waving_hand, color: Colors.white, size: 24),
    );
  }

  // ─── 2. Continue Learning ────────────────────────────────────────────────────

  Widget _buildContinueLearning(
    BuildContext context,
    EnrollmentDetailDto? course,
    bool isDark,
  ) {
    if (course != null) {
      final progress = course.progressPercent / 100.0;
      return GradientGlassCard(
        gradientColors: [
          AppTheme.primaryBlueDark.withValues(alpha: 0.9),
          AppTheme.secondaryPurple.withValues(alpha: 0.9),
        ],
        borderRadius: 14,
        padding: const EdgeInsets.all(16),
        onTap: () => context.push('/courses/${course.courseId}'),
        child: Row(
          children: [
            // Icon block
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.school_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Course info + progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TIẾP TỤC HỌC',
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: AppTheme.accentCyan,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    course.courseTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${course.progressPercent}%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white, size: 20),
          ],
        ),
      );
    }

    // Placeholder — no active enrollment
    return GlassCard(
      onTap: () => context.push('/courses'),
      padding: const EdgeInsets.all(16),
      borderRadius: 14,
      borderColor: AppTheme.primaryBlueDark.withValues(alpha: 0.4),
      child: Row(
        children: [
          Icon(
            Icons.add_circle_outline,
            color: AppTheme.primaryBlueDark,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bắt đầu khóa học mới',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }

  // ─── 3. Active Roadmap (compact) ─────────────────────────────────────────────

  Widget _buildActiveRoadmap(
    BuildContext context,
    RoadmapSession roadmap,
    bool isDark,
  ) {
    final progress = roadmap.progressPercentage / 100.0;

    return GestureDetector(
      onTap: () => context.push('/roadmap'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.darkCardBackground
              : AppTheme.lightCardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.primaryBlueDark.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route, color: AppTheme.primaryBlueDark, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    roadmap.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${roadmap.progressPercentage}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: AppTheme.primaryBlueDark,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: isDark
                    ? AppTheme.darkBackgroundSecondary
                    : AppTheme.lightBackgroundSecondary,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryBlueDark,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${roadmap.completedQuests}/${roadmap.totalQuests} quests',
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 4. Quick Actions ────────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    final actions = [
      {
        'icon': Icons.map_outlined,
        'label': 'AI Roadmap',
        'color': AppTheme.themePurpleStart,
        'route': '/roadmap',
      },
      {
        'icon': Icons.explore_outlined,
        'label': 'Hành trình',
        'color': AppTheme.accentCyan,
        'route': '/journey',
      },
      {
        'icon': Icons.school_outlined,
        'label': 'Khóa học',
        'color': AppTheme.themeBlueStart,
        'route': '/courses',
      },
      {
        'icon': Icons.chat_bubble_outline,
        'label': 'AI Chat',
        'color': AppTheme.themeGreenStart,
        'route': '/chat',
      },
      {
        'icon': Icons.dashboard_customize_outlined,
        'label': 'Task Board',
        'color': AppTheme.accentCyan,
        'route': '/task-board',
      },
      {
        'icon': Icons.psychology_outlined,
        'label': 'Expert Chat',
        'color': const Color(0xFFE040FB),
        'route': '/expert-chat',
      },
      {
        'icon': Icons.people_outline,
        'label': 'Cộng đồng',
        'color': AppTheme.themeOrangeStart,
        'route': '/community',
      },
      {
        'icon': Icons.person_outline,
        'label': 'Mentor 1:1',
        'color': AppTheme.primaryBlueDark,
        'route': '/mentors',
      },
      {
        'icon': Icons.work_outline,
        'label': 'Portfolio',
        'color': AppTheme.accentPink,
        'route': '/portfolio',
      },
      {
        'icon': Icons.storefront_outlined,
        'label': 'Skin Shop',
        'color': AppTheme.accentGold,
        'route': '/skins',
      },
      {
        'icon': Icons.work_history_outlined,
        'label': 'Việc làm',
        'color': const Color(0xFF26A69A),
        'route': '/jobs',
      },
    ];

    final visible = _showAllActions ? actions : actions.sublist(0, 8);
    final remaining = actions.length - 8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Truy cập nhanh',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemCount: visible.length,
          itemBuilder: (context, index) {
            final action = visible[index];
            return _buildQuickActionCell(
              context,
              icon: action['icon'] as IconData,
              label: action['label'] as String,
              color: action['color'] as Color,
              onTap: () => context.push(action['route'] as String),
              isDark: isDark,
            );
          },
        ),
        if (!_showAllActions) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _showAllActions = true),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.expand_more,
                    size: 16,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Xem thêm ($remaining)',
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
          ),
        ],
      ],
    );
  }

  Widget _buildQuickActionCell(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Semantics(
      label: 'quick_action_$label',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.darkCardBackground
                : AppTheme.lightCardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 5. Stats Grid (2×2) ─────────────────────────────────────────────────────

  Widget _buildStatsGrid(
    BuildContext context,
    DashboardProvider provider,
    bool isDark,
  ) {
    final stats = [
      {
        'icon': Icons.school_outlined,
        'value': provider.enrolledCoursesCount,
        'label': 'Khóa học đang học',
        'color': AppTheme.primaryBlueDark,
      },
      {
        'icon': Icons.emoji_events_outlined,
        'value': provider.certificatesCount,
        'label': 'Chứng chỉ đạt được',
        'color': AppTheme.themePurpleStart,
      },
      {
        'icon': Icons.access_time_outlined,
        'value': provider.totalHoursStudied,
        'label': 'Giờ học tích lũy',
        'color': AppTheme.themeOrangeStart,
      },
      {
        'icon': Icons.work_outline,
        'value': provider.completedProjectsCount,
        'label': 'Dự án hoàn thành',
        'color': AppTheme.themeGreenStart,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final s = stats[index];
        return _buildStatCard(
          icon: s['icon'] as IconData,
          value: s['value'] as int,
          label: s['label'] as String,
          color: s['color'] as Color,
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required int value,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkCardBackground
            : AppTheme.lightCardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: color,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 6. Wallet (compact) ─────────────────────────────────────────────────────

  Widget _buildWalletCompact(
    BuildContext context,
    DashboardProvider provider,
    bool isDark,
  ) {
    return Semantics(
      label: 'wallet_card',
      child: GlassCard(
        onTap: () => context.push('/wallet'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderColor: AppTheme.primaryBlueDark.withValues(alpha: 0.3),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlueDark.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppTheme.primaryBlueDark,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ví vũ trụ',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        NumberFormatter.formatCurrency(
                          provider.cashBalance.toDouble(),
                          currency: 'đ',
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: AppTheme.themeGreenStart,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 1,
                        height: 12,
                        color: isDark
                            ? AppTheme.darkBorderColor
                            : AppTheme.lightBorderColor,
                      ),
                      Text(
                        '${NumberFormatter.formatNumber(provider.coinBalance)} SC',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: AppTheme.accentGold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ─── 7. Premium (compact, conditional) ───────────────────────────────────────

  Widget _buildPremiumCompact(
    BuildContext context,
    DashboardProvider provider,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.accentGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.workspace_premium,
            color: AppTheme.accentGold,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${provider.premiumPlanName} • Còn ${provider.premiumDaysRemaining} ngày',
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.push('/premium'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Gia hạn',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.accentGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
