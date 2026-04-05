import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

/// Reusable status badge widget.
///
/// Supports two usage modes:
/// 1. Auto-resolve: `StatusBadge(status: 'PENDING')` — looks up label/color from built-in map.
/// 2. Custom: `StatusBadge.custom(label: '...', color: Colors.red)` — fully manual.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusBadge._({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  /// Custom badge with explicit label, color, and optional icon.
  const StatusBadge.custom({
    Key? key,
    required String label,
    required Color color,
    IconData? icon,
  }) : this._(key: key, label: label, color: color, icon: icon);

  /// Auto-resolve status string to label + color.
  /// Combines mappings from Applications, Bookings, and Journey statuses.
  factory StatusBadge({Key? key, required String status, IconData? icon}) {
    final (label, color) = _resolve(status);
    return StatusBadge._(key: key, label: label, color: color, icon: icon);
  }

  static (String, Color) _resolve(String status) {
    return switch (status.toUpperCase()) {
      // Application / Job statuses
      'PENDING' || 'APPLIED' => ('Đang chờ', AppTheme.themeOrangeStart),
      'REVIEWED' => ('Đã xem', AppTheme.themeBlueStart),
      'ACCEPTED' || 'APPROVED' => ('Đã chấp nhận', AppTheme.themeGreenStart),
      'REJECTED' => ('Bị từ chối', Colors.red),
      'IN_PROGRESS' => ('Đang làm', AppTheme.themeBlueStart),
      'WORKING' => ('Đang làm việc', AppTheme.themeBlueStart),
      'UNDER_REVIEW' => ('Đang xét duyệt', AppTheme.themePurpleStart),
      'REVISION_REQUIRED' => ('Cần sửa lại', AppTheme.themeOrangeStart),
      'SUBMITTED' => ('Đã nộp bài', AppTheme.themePurpleStart),
      'SUBMITTED_OVERDUE' => ('Nộp trễ', Colors.red),
      'CANCELLATION_REQUESTED' => ('Yêu cầu hủy', Colors.red),
      'COMPLETED' => ('Hoàn thành', AppTheme.themeGreenStart),
      'PAID' => ('Đã thanh toán', AppTheme.themeGreenEnd),
      'WITHDRAWN' => ('Đã rút đơn', Colors.blueGrey),
      'CANCELLED' => ('Đã hủy', Colors.grey),

      // Booking statuses
      'CONFIRMED' => ('Đã xác nhận', AppTheme.successColor),
      'ONGOING' => ('Đang diễn ra', AppTheme.infoColor),
      'DISPUTED' => ('Tranh chấp', AppTheme.errorColor),
      'REFUNDED' => ('Đã hoàn tiền', AppTheme.warningColor),

      // Journey statuses
      'NOT_STARTED' => ('Chưa bắt đầu', Colors.grey),
      'ASSESSMENT_PENDING' => ('Đang tạo test', Colors.orange),
      'TEST_IN_PROGRESS' => ('Đang làm bài', Colors.blue),
      'EVALUATION_PENDING' => ('Đang đánh giá', Colors.purple),
      'ROADMAP_GENERATED' => ('Có lộ trình', Colors.teal),
      'STUDY_PLAN_IN_PROGRESS' => ('Đang học', Colors.indigo),
      'ACTIVE' => ('Đang hoạt động', Colors.green),
      'PAUSED' => ('Tạm dừng', Colors.amber),

      _ => (status, Colors.grey),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
