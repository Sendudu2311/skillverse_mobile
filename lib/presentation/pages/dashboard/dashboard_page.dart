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

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboard();
      context.read<SkinProvider>().loadAllSkins();

      // Check if we should show onboarding prompt
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
          // Clear flag so it doesn't show again
          StorageHelper.instance.writeBool(
            StorageKey.showOnboardingPrompt,
            false,
          );
        },
      );
    }
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text('Không thể tải dữ liệu'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => dashboardProvider.loadDashboard(),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => dashboardProvider.refreshDashboard(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Header - Futuristic
                _buildWelcomeHeader(context, user?.fullName ?? 'Pilot', isDark),
                const SizedBox(height: 24),

                // Wallet Card
                _buildWalletCard(context, dashboardProvider, isDark),
                const SizedBox(height: 24),

                // Quick Actions
                _buildQuickActions(context, isDark),
                const SizedBox(height: 24),

                // Streak Tracker
                _buildStreakTracker(context, dashboardProvider, isDark),
                const SizedBox(height: 24),

                // Stats Grid
                _buildStatsGrid(context, dashboardProvider, isDark),
                const SizedBox(height: 24),

                // Analyst Track (Roadmap Progress)
                if (dashboardProvider.activeRoadmap != null) ...[
                  _buildAnalystTrack(context, dashboardProvider, isDark),
                  const SizedBox(height: 24),
                ],

                // System Limits (Subscription Features)
                if (dashboardProvider.hasPremium) ...[
                  _buildSystemLimits(context, dashboardProvider, isDark),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        );
      },
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

  Widget _buildWelcomeHeader(
    BuildContext context,
    String userName,
    bool isDark,
  ) {
    return Semantics(
      label: 'welcome_header',
      child: Container(
        padding: const EdgeInsets.all(24),
        clipBehavior: Clip.none,
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
          children: [
            // Left: Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WELCOME BACK,',
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                      color: AppTheme.accentCyan,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Glow layer
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.transparent,
                          shadows: [
                            Shadow(
                              color: AppTheme.accentCyan.withValues(alpha: 0.7),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Gradient text
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
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
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
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Image.network(
                      skin.imageUrl!,
                      width: 80,
                      height: 80,
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

  Widget _buildWalletCard(
    BuildContext context,
    DashboardProvider provider,
    bool isDark,
  ) {
    return Semantics(
      label: 'wallet_card',
      child: GlassCard(
        onTap: () => context.push('/wallet'),
        padding: const EdgeInsets.all(20),
        borderColor: AppTheme.primaryBlueDark.withValues(alpha: 0.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlueDark.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: AppTheme.primaryBlueDark,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VÍ VŨ TRỤ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quản lý tài sản của bạn',
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
                Icon(
                  Icons.chevron_right,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: 16,
                            color: AppTheme.themeGreenStart,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Tiền Mặt',
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
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          NumberFormatter.formatCurrency(
                            provider.cashBalance.toDouble(),
                            currency: 'đ',
                          ),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: AppTheme.themeGreenStart,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: isDark
                      ? AppTheme.darkBorderColor
                      : AppTheme.lightBorderColor,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.monetization_on,
                            size: 16,
                            color: AppTheme.accentGold,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'SkillCoin',
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
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          NumberFormatter.formatNumber(provider.coinBalance),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: AppTheme.accentGold,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Truy cập nhanh',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildQuickActionCard(
              context,
              icon: action['icon'] as IconData,
              label: action['label'] as String,
              color: action['color'] as Color,
              onTap: () => context.push(action['route'] as String),
              isDark: isDark,
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
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
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakTracker(
    BuildContext context,
    DashboardProvider provider,
    bool isDark,
  ) {
    final daysOfWeek = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Semantics(
      label: 'streak_tracker',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: AppTheme.themeOrangeStart,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'CHUỖI HỌC TẬP',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Current Streak
            Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      AppTheme.themeOrangeStart,
                      AppTheme.themeOrangeEnd,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    '${provider.currentStreak}',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'NGÀY',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'monospace',
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Weekly Activity Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final isActive = provider.weeklyActivity.length > index
                    ? provider.weeklyActivity[index]
                    : false;
                return Column(
                  children: [
                    Text(
                      daysOfWeek[index],
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.themeOrangeStart
                            : (isDark
                                  ? AppTheme.darkBackgroundSecondary
                                  : AppTheme.lightBackgroundSecondary),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isActive
                              ? AppTheme.themeOrangeStart
                              : (isDark
                                    ? AppTheme.darkBorderColor
                                    : AppTheme.lightBorderColor),
                        ),
                      ),
                      child: isActive
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 16),

            // Power Level
            Row(
              children: [
                Text(
                  'POWER LEVEL:',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: provider.currentStreak > 0
                          ? (provider.currentStreak / 30).clamp(0.0, 1.0)
                          : 0.0,
                      minHeight: 8,
                      backgroundColor: isDark
                          ? AppTheme.darkBackgroundSecondary
                          : AppTheme.lightBackgroundSecondary,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.themeOrangeStart,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  provider.currentStreak > 0
                      ? '${(provider.currentStreak / 30 * 100).toInt()}%'
                      : 'N/A',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: AppTheme.themeOrangeStart,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    DashboardProvider provider,
    bool isDark,
  ) {
    final stats = [
      {
        'icon': Icons.school_outlined,
        'label': 'KHÓA HỌC ĐANG HỌC',
        'value': provider.enrolledCoursesCount,
        'change': '+${provider.enrolledCoursesCount} this cycle',
        'color': AppTheme.primaryBlueDark,
      },
      {
        'icon': Icons.work_outline,
        'label': 'DỰ ÁN ĐÃ HOÀN THÀNH',
        'value': provider.completedProjectsCount,
        'change': '+${provider.completedProjectsCount} this cycle',
        'color': AppTheme.themeGreenStart,
      },
      {
        'icon': Icons.emoji_events_outlined,
        'label': 'CHỨNG CHỈ ĐÃ ĐẠT',
        'value': provider.certificatesCount,
        'change': '+${provider.certificatesCount} this cycle',
        'color': AppTheme.themePurpleStart,
      },
      {
        'icon': Icons.access_time,
        'label': 'TỔNG SỐ GIỜ HỌC',
        'value': provider.totalHoursStudied,
        'change': '+${provider.totalHoursStudied} this cycle',
        'color': AppTheme.themeOrangeStart,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return _buildStatCard(
          context,
          icon: stat['icon'] as IconData,
          label: stat['label'] as String,
          value: stat['value'] as int,
          change: stat['change'] as String,
          color: stat['color'] as Color,
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int value,
    required String change,
    required Color color,
    required bool isDark,
  }) {
    return Semantics(
      label: 'stat_card_$label',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.darkCardBackground
              : AppTheme.lightCardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 10,
                        color: AppTheme.successColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '+${value}',
                        style: TextStyle(
                          fontSize: 9,
                          fontFamily: 'monospace',
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
                letterSpacing: 0.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalystTrack(
    BuildContext context,
    DashboardProvider provider,
    bool isDark,
  ) {
    final roadmap = provider.activeRoadmap!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkCardBackground
            : AppTheme.lightCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryBlueDark.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route, color: AppTheme.primaryBlueDark, size: 24),
              const SizedBox(width: 12),
              Text(
                'ANALYST TRACK',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/roadmap'),
                child: const Text(
                  'VIEW ALL',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            roadmap.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlueDark.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  roadmap.difficultyLevel.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: AppTheme.primaryBlueDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${roadmap.completedQuests}/${roadmap.totalQuests} quests',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: roadmap.progressPercentage / 100,
                    minHeight: 12,
                    backgroundColor: isDark
                        ? AppTheme.darkBackgroundSecondary
                        : AppTheme.lightBackgroundSecondary,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryBlueDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${roadmap.progressPercentage}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: AppTheme.primaryBlueDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemLimits(
    BuildContext context,
    DashboardProvider provider,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkCardBackground
            : AppTheme.lightCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium,
                color: AppTheme.accentGold,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'SYSTEM LIMITS & CAPABILITIES',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLimitRow(
            'AI CHATBOT REQUESTS',
            'INF',
            Icons.chat_bubble_outline,
            AppTheme.accentCyan,
            isDark,
          ),
          const SizedBox(height: 12),
          _buildLimitRow(
            'AI ROADMAP GENERATION',
            'INF',
            Icons.map_outlined,
            AppTheme.primaryBlueDark,
            isDark,
          ),
          const SizedBox(height: 12),
          _buildLimitRow(
            'PRIORITY SUPPORT',
            'INF',
            Icons.support_agent,
            AppTheme.themePurpleStart,
            isDark,
          ),
          const SizedBox(height: 12),
          _buildLimitRow(
            'COIN EARNING MULTIPLIER',
            'x2',
            Icons.monetization_on_outlined,
            AppTheme.accentGold,
            isDark,
            isBadge: true,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppTheme.successColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${provider.premiumPlanName} • ${provider.premiumDaysRemaining} days remaining',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitRow(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark, {
    bool isBadge = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isBadge
                ? color.withValues(alpha: 0.2)
                : (isDark
                      ? AppTheme.darkBackgroundSecondary
                      : AppTheme.lightBackgroundSecondary),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
