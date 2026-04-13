import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../providers/notification_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/selectable_chip_row.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../widgets/common_loading.dart';
import '../../widgets/skeleton_loaders.dart';
import '../../widgets/animated_list_item.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_state_widget.dart';
import '../../../data/models/notification_models.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<NotificationProvider>().loadNextPage();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SkillVerseAppBar(
        title: 'Thông báo',
        actions: [
          Consumer<NotificationProvider>(
            builder: (_, provider, __) {
              if (provider.unreadCount == 0) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: provider.markAllAsRead,
                icon: const Icon(Icons.done_all, size: 16),
                label: const Text('Đọc tất cả', style: TextStyle(fontSize: 12)),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Consumer<NotificationProvider>(
            builder: (_, provider, __) {
              final selected = NotificationFilter.values.indexOf(
                provider.filter,
              );
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SelectableChipRow(
                  labels: const ['Tất cả', 'Chưa đọc', 'Đã đọc'],
                  selectedIndex: selected,
                  onSelected: (i) {
                    final filter = NotificationFilter.values[i];
                    if (provider.filter != filter) {
                      provider.loadNotifications(filter: filter);
                    }
                  },
                ),
              );
            },
          ),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: 8,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (_, __) => const NotificationSkeleton(),
          );
        }

        if (provider.hasError) {
          return ErrorStateWidget(
            message: provider.errorMessage ?? 'Có lỗi xảy ra',
            onRetry: () => provider.loadNotifications(),
          );
        }

        if (provider.notifications.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.notifications_none_outlined,
            title: 'Không có thông báo',
            subtitle: 'Thông báo mới sẽ xuất hiện ở đây',
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadNotifications(),
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 24),
            itemCount:
                provider.notifications.length +
                (provider.hasMore && provider.isLoadingMore ? 1 : 0),
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              if (index >= provider.notifications.length) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: CommonLoading.center(),
                );
              }
              final notification = provider.notifications[index];
              return AnimatedListItem(
                index: index,
                child: _NotificationTile(
                  notification: notification,
                  onTap: () => _handleTap(provider, notification),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _handleTap(NotificationProvider provider, AppNotification notification) {
    if (!notification.isRead) {
      provider.markAsRead(notification.id);
    }
    final route = _routeForType(notification);
    if (route != null) context.push(route);
  }

  // ── Routing by notification type ──────────────────────────────────────────

  String? _routeForType(AppNotification n) {
    switch (n.type) {
      case NotificationType.like:
      case NotificationType.comment:
        if (n.relatedId != null) return '/community/${n.relatedId}';
        return '/community';

      case NotificationType.bookingCreated:
      case NotificationType.bookingConfirmed:
      case NotificationType.bookingRejected:
      case NotificationType.bookingReminder:
      case NotificationType.bookingCompleted:
      case NotificationType.bookingCancelled:
      case NotificationType.bookingRefund:
        return '/my-bookings';

      case NotificationType.premiumPurchase:
      case NotificationType.premiumExpiration:
      case NotificationType.premiumCancel:
        return '/premium';

      case NotificationType.walletDeposit:
      case NotificationType.coinPurchase:
      case NotificationType.withdrawalApproved:
      case NotificationType.withdrawalRejected:
      case NotificationType.escrowFunded:
      case NotificationType.escrowReleased:
      case NotificationType.escrowRefunded:
        return '/wallet';

      case NotificationType.taskDeadline:
      case NotificationType.taskOverdue:
      case NotificationType.taskReview:
        return '/task-board';

      case NotificationType.jobApproved:
      case NotificationType.jobRejected:
      case NotificationType.jobDeleted:
      case NotificationType.jobBanned:
      case NotificationType.jobUnbanned:
        return '/jobs';

      case NotificationType.mentorReviewReceived:
      case NotificationType.mentorLevelUp:
      case NotificationType.mentorBadgeAwarded:
        return '/mentors';

      case NotificationType.prechatMessage:
      case NotificationType.recruitmentMessage:
        return '/chat';

      default:
        return null; // stay on notification page
    }
  }
}

// ── Notification Tile ─────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: unread
            ? AppTheme.primaryBlueDark.withValues(alpha: isDark ? 0.12 : 0.05)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar / Icon
            _buildAvatar(isDark),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: unread ? FontWeight.bold : FontWeight.normal,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(notification.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          (isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary)
                              .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Unread dot
            if (unread) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryBlueDark,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isDark) {
    // If sender has an avatar, show it
    if (notification.senderAvatar != null &&
        notification.senderAvatar!.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: _typeColor().withValues(alpha: 0.15),
        backgroundImage: NetworkImage(notification.senderAvatar!),
        onBackgroundImageError: (_, __) {},
      );
    }

    // Otherwise show type icon
    return CircleAvatar(
      radius: 22,
      backgroundColor: _typeColor().withValues(alpha: 0.15),
      child: Icon(_typeIcon(), size: 20, color: _typeColor()),
    );
  }

  IconData _typeIcon() {
    switch (notification.type) {
      case NotificationType.like:
        return Icons.favorite;
      case NotificationType.comment:
        return Icons.chat_bubble_outline;
      case NotificationType.premiumPurchase:
      case NotificationType.premiumExpiration:
      case NotificationType.premiumCancel:
        return Icons.star_outline;
      case NotificationType.walletDeposit:
      case NotificationType.coinPurchase:
      case NotificationType.withdrawalApproved:
      case NotificationType.withdrawalRejected:
      case NotificationType.escrowFunded:
      case NotificationType.escrowReleased:
      case NotificationType.escrowRefunded:
        return Icons.account_balance_wallet_outlined;
      case NotificationType.bookingCreated:
      case NotificationType.bookingConfirmed:
      case NotificationType.bookingRejected:
      case NotificationType.bookingReminder:
      case NotificationType.bookingCompleted:
      case NotificationType.bookingCancelled:
      case NotificationType.bookingRefund:
        return Icons.calendar_today_outlined;
      case NotificationType.taskDeadline:
      case NotificationType.taskOverdue:
      case NotificationType.taskReview:
      case NotificationType.assignmentSubmitted:
      case NotificationType.assignmentGraded:
      case NotificationType.assignmentLate:
        return Icons.task_alt;
      case NotificationType.jobApproved:
      case NotificationType.jobRejected:
      case NotificationType.jobDeleted:
      case NotificationType.jobBanned:
      case NotificationType.jobUnbanned:
        return Icons.work_outline;
      case NotificationType.mentorReviewReceived:
      case NotificationType.mentorLevelUp:
      case NotificationType.mentorBadgeAwarded:
        return Icons.emoji_events_outlined;
      case NotificationType.prechatMessage:
      case NotificationType.recruitmentMessage:
        return Icons.message_outlined;
      case NotificationType.welcome:
        return Icons.waving_hand_outlined;
      case NotificationType.warning:
      case NotificationType.violationReport:
        return Icons.warning_amber_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _typeColor() {
    switch (notification.type) {
      case NotificationType.like:
        return Colors.red;
      case NotificationType.comment:
      case NotificationType.prechatMessage:
      case NotificationType.recruitmentMessage:
        return Colors.blue;
      case NotificationType.premiumPurchase:
      case NotificationType.premiumExpiration:
      case NotificationType.premiumCancel:
      case NotificationType.mentorLevelUp:
      case NotificationType.mentorBadgeAwarded:
        return Colors.amber;
      case NotificationType.walletDeposit:
      case NotificationType.coinPurchase:
      case NotificationType.withdrawalApproved:
      case NotificationType.escrowReleased:
      case NotificationType.jobApproved:
      case NotificationType.bookingConfirmed:
      case NotificationType.bookingCompleted:
        return Colors.green;
      case NotificationType.withdrawalRejected:
      case NotificationType.jobRejected:
      case NotificationType.jobBanned:
      case NotificationType.bookingRejected:
      case NotificationType.bookingCancelled:
      case NotificationType.taskOverdue:
      case NotificationType.assignmentLate:
      case NotificationType.warning:
      case NotificationType.violationReport:
        return Colors.red;
      case NotificationType.taskDeadline:
      case NotificationType.bookingReminder:
      case NotificationType.reviewWindowExpiring:
        return Colors.orange;
      default:
        return AppTheme.primaryBlueDark;
    }
  }

  String _formatTime(DateTime dt) {
    return DateTimeHelper.formatSmart(dt);
  }
}
