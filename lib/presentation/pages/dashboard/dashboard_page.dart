import 'dart:async';

import 'package:flutter/material.dart';
import '../../widgets/common_loading.dart';
import '../../widgets/skeleton_loaders.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/skin_provider.dart';
import '../../themes/app_theme.dart';
// OnboardingPrompt disabled — redirect handled by LoginPage._navigateAfterAuth()
import '../../widgets/glass_card.dart';
import '../../widgets/error_state_widget.dart';
import '../../../core/utils/error_handler.dart';
import '../../../data/models/enrollment_models.dart';
import '../../../data/models/dashboard_models.dart';
import '../../../core/services/firebase_push_notification_service.dart';
import 'dashboard_widgets.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  StreamSubscription? _fcmForegroundSub;
  StreamSubscription? _fcmTapSub;

  NotificationProvider? _notificationProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Capture the provider reference while the widget is still in the tree
    _notificationProvider = context.read<NotificationProvider>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only fetch from API if provider has no cached data yet
      final dashProvider = context.read<DashboardProvider>();
      if (!dashProvider.hasData) {
        final userId = context.read<AuthProvider>().user?.id;
        dashProvider.loadDashboard(userId: userId);
      }
      final skinProvider = context.read<SkinProvider>();
      if (skinProvider.allSkins.isEmpty) {
        skinProvider.loadAllSkins();
      }
      context.read<NotificationProvider>().startPolling();
      _checkAndShowOnboarding();
      _subscribeFcmStreams();
    });
  }

  void _subscribeFcmStreams() {
    final fcm = FirebasePushNotificationService.instance;

    // Foreground: increment badge + show snackbar
    _fcmForegroundSub = fcm.onForegroundMessage.listen((payload) {
      if (!mounted) return;
      context.read<NotificationProvider>().fetchUnreadCount();
      ErrorHandler.showSuccessSnackBar(context, payload.title ?? 'Thông báo mới');
    });

    // Tap from OS tray: navigate by type
    _fcmTapSub = fcm.onNotificationTap.listen((payload) {
      if (!mounted) return;
      final type = payload.data['type'] as String?;
      final relatedId = payload.data['relatedId'] as String?;
      final route = _routeForPushType(type, relatedId);
      if (route != null) context.push(route);
    });
  }

  String? _routeForPushType(String? type, String? relatedId) {
    switch (type) {
      case 'LIKE':
      case 'COMMENT':
        return relatedId != null ? '/community/$relatedId' : '/community';
      case 'BOOKING_CREATED':
      case 'BOOKING_CONFIRMED':
      case 'BOOKING_REJECTED':
      case 'BOOKING_REMINDER':
      case 'BOOKING_COMPLETED':
      case 'BOOKING_CANCELLED':
      case 'BOOKING_REFUND':
      case 'BOOKING_STARTED':
      case 'BOOKING_MENTOR_COMPLETED':
        return '/my-bookings';
      case 'PREMIUM_PURCHASE':
      case 'PREMIUM_EXPIRATION':
      case 'PREMIUM_CANCEL':
        return '/premium';
      case 'WALLET_DEPOSIT':
      case 'COIN_PURCHASE':
      case 'WITHDRAWAL_APPROVED':
      case 'WITHDRAWAL_REJECTED':
      case 'ESCROW_FUNDED':
      case 'ESCROW_RELEASED':
      case 'ESCROW_REFUNDED':
        return '/wallet';
      case 'SHORT_TERM_APPLICATION_SUBMITTED':
      case 'SHORT_TERM_APPLICATION_ACCEPTED':
      case 'SHORT_TERM_APPLICATION_REJECTED':
      case 'SHORT_TERM_WORK_SUBMITTED':
      case 'SHORT_TERM_WORK_APPROVED':
      case 'FULLTIME_APPLICATION_REVIEWED':
      case 'FULLTIME_APPLICATION_ACCEPTED':
      case 'FULLTIME_APPLICATION_REJECTED':
      case 'WORKER_CANCELLATION_REQUESTED':
      case 'WORKER_AUTO_CANCELLED':
        return '/my-applications';
      case 'TASK_DEADLINE':
      case 'TASK_OVERDUE':
      case 'TASK_REVIEW':
        return '/task-board';
      case 'PRECHAT_MESSAGE':
      case 'RECRUITMENT_MESSAGE':
        return '/chat';
      default:
        return '/notifications';
    }
  }

  @override
  void dispose() {
    _fcmForegroundSub?.cancel();
    _fcmTapSub?.cancel();
    _notificationProvider?.stopPolling();
    super.dispose();
  }

  Future<void> _checkAndShowOnboarding() async {
    // Disabled: New user onboarding is now handled by LoginPage._navigateAfterAuth()
    // which redirects users with 0 journeys directly to /journey/create.
    // Keeping method stub for potential future use.
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
                HeroCardSkeleton(),
                SizedBox(height: 16),
                ContinueLearningSkeleton(),
                SizedBox(height: 16),
                ActiveRoadmapSkeleton(),
                SizedBox(height: 16),
                QuickActionsSkeleton(),
                SizedBox(height: 16),
                StatsGridSkeleton(),
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

                // 4. Quick Actions (2×4 grid)
                DashboardQuickActionsWidget(isDark: isDark),
                const SizedBox(height: 16),

                // 5. Stats Grid (2×2)
                DashboardStatsGrid(
                  enrolledCoursesCount: dashboardProvider.enrolledCoursesCount,
                  certificatesCount: dashboardProvider.certificatesCount,
                  totalHoursStudied: dashboardProvider.totalHoursStudied,
                  completedProjectsCount:
                      dashboardProvider.completedProjectsCount,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // 6. Wallet (compact)
                DashboardWalletCard(
                  cashBalance: dashboardProvider.cashBalance.toDouble(),
                  coinBalance: dashboardProvider.coinBalance,
                  isDark: isDark,
                ),

                // 7. Premium (compact, conditional)
                if (dashboardProvider.hasPremium) ...[
                  const SizedBox(height: 16),
                  DashboardPremiumCard(
                    premiumPlanName: dashboardProvider.premiumPlanName,
                    premiumDaysRemaining:
                        dashboardProvider.premiumDaysRemaining,
                    isDark: isDark,
                  ),
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
    final result = await provider.checkIn();
    if (!mounted) return;
    
    if (result == null) {
      ErrorHandler.showErrorSnackBar(context, 'Điểm danh thất bại, thử lại sau');
      return;
    }
    if (result.alreadyCheckedIn) {
      ErrorHandler.showWarningSnackBar(context, 'Bạn đã điểm danh hôm nay rồi!');
    } else {
      ErrorHandler.showSuccessSnackBar(
        context, 
        'Điểm danh thành công! +${result.coinsAwarded} SC 🔥 Streak: ${result.currentStreak} ngày'
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
        padding: const EdgeInsets.fromLTRB(20, 8, 8, 20),
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
            // Top bar: notification bell (compact)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [_buildNotificationBell(context)],
            ),
            const SizedBox(height: 4),
            Row(
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
                          fontSize: 13,
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
                            fontSize: 27,
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
                                  size: 15,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$streak ngày',
                                  style: TextStyle(
                                    fontSize: 12,
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
                                  width: 10,
                                  height: 10,
                                  margin: const EdgeInsets.only(right: 5),
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
                          width: 92,
                          height: 92,
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
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationBell(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (_, provider, __) {
        final count = provider.unreadCount;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 22),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
              onPressed: () => context.push('/notifications'),
            ),
            if (count > 0)
              Positioned(
                top: 6,
                right: 6,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    decoration: const BoxDecoration(
                      color: AppTheme.errorColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
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
          disabledForegroundColor: checkedIn ? AppTheme.themeGreenStart : null,
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
                child: CommonLoading.small(color: Colors.white),
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
      width: 92,
      height: 92,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlueDark, AppTheme.secondaryPurple],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.waving_hand, color: Colors.white, size: 36),
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
        gradientColors: AppTheme.blueGradient.colors,
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
}
