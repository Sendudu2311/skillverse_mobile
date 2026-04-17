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
      'INTERVIEW_SCHEDULED' => ('Lịch phỏng vấn', Color(0xFF00C8E8)),
      'INTERVIEWED' => ('Đã phỏng vấn', AppTheme.themePurpleStart),
      'OFFER_SENT' => ('Đã gửi đề nghị', Color(0xFFAA55FF)),
      'OFFER_ACCEPTED' => ('Nhận đề nghị', AppTheme.themeGreenStart),
      'OFFER_REJECTED' => ('Từ chối đề nghị', Colors.red),
      'CONTRACT_SIGNED' => ('Đã ký HĐ', AppTheme.themePurpleStart),
      'ACCEPTED' || 'APPROVED' => ('Đã chấp nhận', AppTheme.themeGreenStart),
      'REJECTED' => ('Bị từ chối', Colors.red),
      'IN_PROGRESS' => ('Đang làm', AppTheme.themeBlueStart),
      'WORKING' => ('Đang làm việc', AppTheme.themeBlueStart),
      'UNDER_REVIEW' => ('Đang xét duyệt', AppTheme.themePurpleStart),
      'REVISION_REQUIRED' => ('Cần sửa lại', AppTheme.themeOrangeStart),
      'SUBMITTED' => ('Đã nộp bài', AppTheme.themePurpleStart),
      'SUBMITTED_OVERDUE' => ('Nộp trễ', Colors.red),
      'CANCELLATION_REQUESTED' => ('Yêu cầu hủy', Colors.red),
      'AUTO_CANCELLED' => ('Tự động hủy', Colors.red),
      'REVISION_RESPONSE_OVERDUE' => (
        'Quá hạn phản hồi sửa',
        AppTheme.errorColor,
      ),
      'DISPUTE_OPENED' => ('Đang tranh chấp', AppTheme.warningColor),
      'COMPLETED' => ('Hoàn thành', AppTheme.themeGreenStart),
      'PAID' => ('Đã thanh toán', AppTheme.themeGreenEnd),
      'WITHDRAWN' => ('Đã rút đơn', Colors.blueGrey),
      'CANCELLED' => ('Đã hủy', Colors.grey),

      // Booking statuses
      'CONFIRMED' => ('Đã xác nhận', AppTheme.successColor),
      'ONGOING' => ('Đang diễn ra', AppTheme.infoColor),
      'PENDING_COMPLETION' ||
      'PENDINGCOMPLETION' => ('Chờ xác nhận hoàn thành', AppTheme.warningColor),
      'DISPUTED' => ('Tranh chấp', AppTheme.errorColor),
      'REFUNDED' => ('Đã hoàn tiền', AppTheme.warningColor),

      // Payment statuses
      'PROCESSING' => ('Đang xử lý', AppTheme.themeBlueStart),
      'FAILED' => ('Thất bại', AppTheme.errorColor),

      // Journey statuses
      'NOT_STARTED' => ('Chưa bắt đầu', Colors.grey),
      'ASSESSMENT_PENDING' => ('Đang tạo test', Colors.orange),
      'TEST_IN_PROGRESS' => ('Đang làm bài', Colors.blue),
      'EVALUATION_PENDING' => ('Đang đánh giá', Colors.purple),
      'ROADMAP_GENERATED' => ('Có lộ trình', Colors.teal),
      'STUDY_PLAN_IN_PROGRESS' => ('Đang học', Colors.indigo),
      'ACTIVE' => ('Đang hoạt động', Colors.green),
      'PAUSED' => ('Tạm dừng', Colors.amber),
      'DELETED' => ('Đã xoá', Colors.grey),
      'LOCKED' => ('Đã khoá', Colors.grey),
      'AVAILABLE' => ('Sẵn sàng', Colors.teal),

      // Contract statuses
      'DRAFT' => ('Bản nháp', Colors.grey),
      'PENDING_SIGNER' => ('Chờ ứng viên ký', AppTheme.themeBlueStart),
      'PENDING_EMPLOYER' => ('Chờ NTD ký', AppTheme.themeOrangeStart),
      'SIGNED' => ('Đã ký', AppTheme.themeGreenStart),

      // Assignment submission statuses
      'LATE_PENDING' => ('Nộp muộn - Đang chờ', Colors.orange),
      'GRADED' => ('Đã chấm', AppTheme.successColor),
      'LATE_GRADED' => ('Nộp muộn - Đã chấm', AppTheme.successColor),

      _ => (status, Colors.grey),
    };
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: Container(
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
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
