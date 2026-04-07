import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../themes/app_theme.dart';
import '../../providers/task_board_provider.dart';
import '../../../core/utils/number_formatter.dart';
import '../../widgets/glass_card.dart';

// =============================================================================
// QUICK ACTIONS GRID
// =============================================================================

class DashboardQuickActionsWidget extends StatelessWidget {
  final bool showAllActions;
  final VoidCallback onToggleShowAll;
  final bool isDark;

  const DashboardQuickActionsWidget({
    super.key,
    required this.showAllActions,
    required this.onToggleShowAll,
    required this.isDark,
  });

  static const _actions = [
    {'icon': Icons.map_outlined, 'label': 'AI Roadmap', 'color': AppTheme.themePurpleStart, 'route': '/roadmap'},
    {'icon': Icons.explore_outlined, 'label': 'Hành trình', 'color': AppTheme.accentCyan, 'route': '/journey'},
    {'icon': Icons.school_outlined, 'label': 'Khóa học', 'color': AppTheme.themeBlueStart, 'route': '/courses'},
    {'icon': Icons.chat_bubble_outline, 'label': 'AI Chat', 'color': AppTheme.themeGreenStart, 'route': '/chat'},
    {'icon': Icons.dashboard_customize_outlined, 'label': 'Task Board', 'color': AppTheme.accentCyan, 'route': '/task-board', 'hasBadge': true},
    {'icon': Icons.psychology_outlined, 'label': 'Expert Chat', 'color': Color(0xFFE040FB), 'route': '/expert-chat'},
    {'icon': Icons.people_outline, 'label': 'Cộng đồng', 'color': AppTheme.themeOrangeStart, 'route': '/community'},
    {'icon': Icons.person_outline, 'label': 'Mentor 1:1', 'color': AppTheme.primaryBlueDark, 'route': '/mentors'},
    {'icon': Icons.work_outline, 'label': 'Portfolio', 'color': AppTheme.accentPink, 'route': '/portfolio'},
    {'icon': Icons.storefront_outlined, 'label': 'Skin Shop', 'color': AppTheme.accentGold, 'route': '/skins'},
    {'icon': Icons.work_history_outlined, 'label': 'Việc làm', 'color': Color(0xFF26A69A), 'route': '/jobs'},
  ];

  @override
  Widget build(BuildContext context) {
    final overdueCount = context.watch<TaskBoardProvider>().overdueCount;
    final visible = showAllActions ? _actions : _actions.sublist(0, 8);
    final remaining = _actions.length - 8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Truy cập nhanh',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
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
            final hasBadge = action['hasBadge'] == true;
            return _QuickActionCell(
              icon: action['icon'] as IconData,
              label: action['label'] as String,
              color: action['color'] as Color,
              onTap: () => context.push(action['route'] as String),
              isDark: isDark,
              badge: hasBadge ? overdueCount : null,
            );
          },
        ),
        if (!showAllActions) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onToggleShowAll,
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
}

class _QuickActionCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;
  final int? badge;

  const _QuickActionCell({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.isDark,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
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
              Stack(
                clipBehavior: Clip.none,
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
                  if (badge != null && badge! > 0)
                    Positioned(
                      top: -4,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? AppTheme.darkCardBackground
                                : AppTheme.lightCardBackground,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          badge! > 99 ? '99+' : '$badge',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
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
}

// =============================================================================
// STATS GRID (2×2)
// =============================================================================

class DashboardStatsGrid extends StatelessWidget {
  final int enrolledCoursesCount;
  final int certificatesCount;
  final int totalHoursStudied;
  final int completedProjectsCount;
  final bool isDark;

  const DashboardStatsGrid({
    super.key,
    required this.enrolledCoursesCount,
    required this.certificatesCount,
    required this.totalHoursStudied,
    required this.completedProjectsCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      {'icon': Icons.school_outlined, 'value': enrolledCoursesCount, 'label': 'Khóa học đang học', 'color': AppTheme.primaryBlueDark},
      {'icon': Icons.emoji_events_outlined, 'value': certificatesCount, 'label': 'Chứng chỉ đạt được', 'color': AppTheme.themePurpleStart},
      {'icon': Icons.access_time_outlined, 'value': totalHoursStudied, 'label': 'Giờ học tích lũy', 'color': AppTheme.themeOrangeStart},
      {'icon': Icons.work_outline, 'value': completedProjectsCount, 'label': 'Dự án hoàn thành', 'color': AppTheme.themeGreenStart},
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
        return _StatCard(
          icon: s['icon'] as IconData,
          value: s['value'] as int,
          label: s['label'] as String,
          color: s['color'] as Color,
          isDark: isDark,
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : AppTheme.lightCardBackground,
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
}

// =============================================================================
// WALLET COMPACT CARD
// =============================================================================

class DashboardWalletCard extends StatelessWidget {
  final double cashBalance;
  final int coinBalance;
  final bool isDark;

  const DashboardWalletCard({
    super.key,
    required this.cashBalance,
    required this.coinBalance,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
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
                        NumberFormatter.formatCurrency(cashBalance, currency: 'đ'),
                        style: const TextStyle(
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
                        '${NumberFormatter.formatNumber(coinBalance)} SC',
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
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// PREMIUM COMPACT CARD
// =============================================================================

class DashboardPremiumCard extends StatelessWidget {
  final String premiumPlanName;
  final int premiumDaysRemaining;
  final bool isDark;

  const DashboardPremiumCard({
    super.key,
    required this.premiumPlanName,
    required this.premiumDaysRemaining,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.accentGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium, color: AppTheme.accentGold, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$premiumPlanName • Còn $premiumDaysRemaining ngày',
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
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
