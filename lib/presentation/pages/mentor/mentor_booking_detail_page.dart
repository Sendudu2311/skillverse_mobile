import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/mentor_models.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/utils/error_handler.dart';
import '../../providers/mentor_booking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/skeleton_loaders.dart';

class MentorBookingDetailPage extends StatefulWidget {
  final int bookingId;

  const MentorBookingDetailPage({super.key, required this.bookingId});

  @override
  State<MentorBookingDetailPage> createState() =>
      _MentorBookingDetailPageState();
}

class _MentorBookingDetailPageState extends State<MentorBookingDetailPage> {
  MentorBooking? _booking;
  bool _isLoading = true;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    setState(() => _isLoading = true);
    try {
      await context
          .read<MentorBookingProvider>()
          .refreshBookingDetail(widget.bookingId);
      final provider = context.read<MentorBookingProvider>();
      final found = provider.bookings.where((b) => b.id == widget.bookingId);
      if (found.isNotEmpty) {
        _booking = found.first;
      }
    } catch (_) {
      // handled by provider
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _isLearner {
    final userId = context.read<AuthProvider>().user?.id;
    return userId != null && _booking != null && _booking!.learnerId == userId;
  }




  bool get _meetingVisible {
    if (_booking == null || _booking!.meetingLink == null) return false;
    if (_booking!.status == BookingStatus.ongoing) return true;
    if (_booking!.status == BookingStatus.confirmed) {
      final diff =
          _booking!.startTime.difference(DateTime.now()).inMinutes;
      return diff <= 30;
    }
    return false;
  }

  Future<void> _runAction(Future<void> Function() action, String success) async {
    setState(() => _isBusy = true);
    try {
      await action();
      await _loadBooking();
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(context, success);
      }
    } catch (e) {
      if (mounted) {
        final provider = context.read<MentorBookingProvider>();
        ErrorHandler.showErrorSnackBar(
          context,
          provider.errorMessage ?? 'Có lỗi xảy ra',
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _handleStartMeeting() async {
    if (_booking == null) return;
    setState(() => _isBusy = true);
    try {
      final provider = context.read<MentorBookingProvider>();
      final updated = await provider.startMeeting(_booking!.id);
      final link = updated?.meetingLink ?? _booking!.meetingLink;
      if (link != null && link.isNotEmpty) {
        await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
      }
      await _loadBooking();
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, 'Không thể mở phòng học');
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: SkillVerseAppBar(
        title: 'CHI TIẾT LỊCH HẸN',
        icon: Icons.calendar_today_outlined,
        useGradientTitle: true,
        onBack: () => context.pop(),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadBooking,
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: _isLoading
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (_, __) => const ListItemSkeleton(hasTrailing: true),
            )
          : _booking == null
              ? _buildEmptyState(isDark)
              : RefreshIndicator(
                  onRefresh: _loadBooking,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroCard(isDark),
                        const SizedBox(height: 16),
                        _buildSessionInfoCard(isDark),
                        const SizedBox(height: 16),
                        _buildFinanceCard(isDark),
                        const SizedBox(height: 16),
                        _buildTimelineCard(isDark),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: !_isLoading && _booking != null 
          ? _buildActionBar(isDark) 
          : null,
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy thông tin booking',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
          ),
        ],
      ),
    );
  }

  // ─── Hero Card ──────────────────────────────────────────────────────────

  Widget _buildHeroCard(bool isDark) {
    final booking = _booking!;
    final counterpartName =
        _isLearner ? (booking.mentorName ?? 'Mentor') : (booking.learnerName ?? 'Học viên');
    final counterpartAvatar =
        _isLearner ? booking.mentorAvatar : booking.learnerAvatar;
    final roleLabel = _isLearner ? 'Mentor' : 'Học viên';

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 32,
            backgroundColor: AppTheme.primaryBlueDark.withOpacity(0.2),
            backgroundImage: counterpartAvatar != null
                ? NetworkImage(counterpartAvatar)
                : null,
            child: counterpartAvatar == null
                ? Text(
                    counterpartName.isNotEmpty
                        ? counterpartName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlueDark,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roleLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  counterpartName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusBadge(status: booking.status.name),
                    Text(
                      'Booking #${booking.id}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Giá trị',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                booking.priceVnd != null
                    ? NumberFormatter.formatCurrency(booking.priceVnd!)
                    : 'N/A',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.successColor,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Action Bar ─────────────────────────────────────────────────────────

  Widget _buildActionBar(bool isDark) {
    final booking = _booking!;
    final actions = <Widget>[];

    // Meeting button (Join / Start)
    if (_meetingVisible) {
      actions.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isBusy ? null : () {
              if (booking.meetingLink != null) {
                launchUrl(
                  Uri.parse(booking.meetingLink!),
                  mode: LaunchMode.externalApplication,
                );
              } else {
                _handleStartMeeting();
              }
            },
            icon: const Icon(Icons.video_call, size: 18),
            label: Text(booking.meetingLink != null ? 'Vào phòng' : 'Bắt đầu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
            ),
          ),
        ),
      );
      actions.add(const SizedBox(width: 8));
    }

    // Start Meeting for confirmed bookings near start time (but meetingLink is null)
    if (!_meetingVisible &&
        booking.status == BookingStatus.confirmed &&
        booking.meetingLink == null) {
      final minutesToStart =
          booking.startTime.difference(DateTime.now()).inMinutes;
      if (minutesToStart <= 30) {
        actions.add(
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isBusy ? null : _handleStartMeeting,
              icon: const Icon(Icons.video_call, size: 18),
              label: const Text('Bắt đầu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
              ),
            ),
          ),
        );
        actions.add(const SizedBox(width: 8));
      }
    }

    // Cancel
    if (booking.canCancel) {
      actions.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isBusy
                ? null
                : () => _showCancelDialog(),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Hủy'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
              side: const BorderSide(color: AppTheme.errorColor),
            ),
          ),
        ),
      );
      actions.add(const SizedBox(width: 8));
    }

    // Confirm Complete (learner)
    if (booking.canConfirmComplete && _isLearner) {
      actions.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isBusy
                ? null
                : () => _showConfirmCompleteDialog(),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Xác nhận hoàn thành'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
            ),
          ),
        ),
      );
      actions.add(const SizedBox(width: 8));
    }

    // Rate
    if (booking.canRate && _isLearner) {
      actions.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.push(
              '/booking-review/${booking.id}?mentorName=${Uri.encodeComponent(booking.mentorName ?? '')}',
            ),
            icon: const Icon(Icons.star_outline, size: 18),
            label: const Text('Đánh giá'),
          ),
        ),
      );
      actions.add(const SizedBox(width: 8));
    }

    // Chat
    actions.add(
      SizedBox(
        width: 48,
        child: IconButton.outlined(
          onPressed: () {
            // Navigate to messaging with the counterpart
            final counterpartId =
                _isLearner ? booking.mentorId : booking.learnerId;
            context.push('/messaging/chat/$counterpartId');
          },
          icon: const Icon(Icons.chat_outlined, size: 20),
          tooltip: 'Nhắn tin',
        ),
      ),
    );

    if (actions.isEmpty) return const SizedBox.shrink();

    // Remove trailing SizedBox spacer if exists
    if (actions.isNotEmpty && actions.last is SizedBox && (actions.last as SizedBox).width == 8) {
      actions.removeLast();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : AppTheme.lightCardBackground,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(children: actions),
      ),
    );
  }

  // ─── Session Info Card ──────────────────────────────────────────────────

  Widget _buildSessionInfoCard(bool isDark) {
    final booking = _booking!;
    final hasPayment = booking.paymentReference != null ||
        [
          BookingStatus.confirmed,
          BookingStatus.ongoing,
          BookingStatus.pendingCompletion,
          BookingStatus.completed,
        ].contains(booking.status);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Thông tin buổi học',
            icon: Icons.calendar_today,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            isDark,
            icon: Icons.calendar_month,
            label: 'Ngày',
            value: DateTimeHelper.formatDateWithWeekday(booking.startTime),
          ),
          _buildInfoRow(
            isDark,
            icon: Icons.access_time,
            label: 'Giờ bắt đầu',
            value: DateTimeHelper.formatTime(booking.startTime),
          ),
          _buildInfoRow(
            isDark,
            icon: Icons.timelapse,
            label: 'Thời lượng',
            value: '${booking.calculatedDuration} phút',
          ),
          _buildInfoRow(
            isDark,
            icon: Icons.payment,
            label: 'Thanh toán',
            value: hasPayment ? 'Đã thanh toán' : 'Chưa thanh toán',
            valueColor:
                hasPayment ? AppTheme.successColor : AppTheme.warningColor,
          ),
          _buildInfoRow(
            isDark,
            icon: Icons.videocam,
            label: 'Phòng học',
            value: booking.meetingLink != null ? 'Đã tạo' : 'Chưa tạo',
            valueColor: booking.meetingLink != null
                ? AppTheme.accentCyan
                : AppTheme.darkTextSecondary,
          ),
          // Show meeting link if available
          if (booking.meetingLink != null) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => launchUrl(
                Uri.parse(booking.meetingLink!),
                mode: LaunchMode.externalApplication,
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.accentCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.accentCyan.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.link,
                      size: 16,
                      color: AppTheme.accentCyan,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.meetingLink!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.accentCyan,
                          decoration: TextDecoration.underline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    bool isDark, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ??
                    (isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary),
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Finance Card ──────────────────────────────────────────────────────

  Widget _buildFinanceCard(bool isDark) {
    final booking = _booking!;
    final price = booking.priceVnd ?? 0;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Tài chính', icon: Icons.account_balance_wallet),
          const SizedBox(height: 16),
          _buildFinanceRow(
            isDark,
            label: 'Giá trị booking',
            value: NumberFormatter.formatCurrency(price),
            highlight: true,
            color: AppTheme.accentCyan,
          ),
          if (_isLearner) ...[
            _buildFinanceRow(
              isDark,
              label: 'Bạn chi trả',
              value: NumberFormatter.formatCurrency(
                booking.status == BookingStatus.completed ? price : 0,
              ),
            ),
            _buildFinanceRow(
              isDark,
              label: 'Hoàn tiền',
              value: NumberFormatter.formatCurrency(
                [BookingStatus.cancelled, BookingStatus.rejected, BookingStatus.refunded]
                        .contains(booking.status)
                    ? price
                    : 0,
              ),
              color: [BookingStatus.cancelled, BookingStatus.rejected, BookingStatus.refunded]
                      .contains(booking.status)
                  ? AppTheme.warningColor
                  : null,
            ),
          ] else ...[
            _buildFinanceRow(
              isDark,
              label: 'Bạn nhận (80%)',
              value: NumberFormatter.formatCurrency(
                booking.status == BookingStatus.completed ? price * 0.8 : 0,
              ),
              color: AppTheme.successColor,
            ),
            _buildFinanceRow(
              isDark,
              label: 'Phí hệ thống (20%)',
              value: NumberFormatter.formatCurrency(
                booking.status == BookingStatus.completed ? price * 0.2 : 0,
              ),
            ),
          ],
          // Escrow
          if (![
            BookingStatus.completed,
            BookingStatus.cancelled,
            BookingStatus.rejected,
            BookingStatus.refunded,
          ].contains(booking.status))
            _buildFinanceRow(
              isDark,
              label: 'Đang giữ (Escrow)',
              value: NumberFormatter.formatCurrency(price),
              color: AppTheme.warningColor,
            ),
        ],
      ),
    );
  }

  Widget _buildFinanceRow(
    bool isDark, {
    required String label,
    required String value,
    bool highlight = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color ??
                  (isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Timeline Card ─────────────────────────────────────────────────────

  Widget _buildTimelineCard(bool isDark) {
    final booking = _booking!;
    final events = <_TimelineEvent>[];

    if (booking.createdAt != null) {
      events.add(_TimelineEvent(
        label: 'Booking được tạo',
        time: booking.createdAt!,
        color: AppTheme.accentCyan,
      ));
    }

    if (booking.status != BookingStatus.pending &&
        booking.status != BookingStatus.cancelled &&
        booking.status != BookingStatus.rejected) {
      events.add(_TimelineEvent(
        label: 'Đã xác nhận',
        time: booking.createdAt ?? booking.startTime,
        color: AppTheme.successColor,
      ));
    }

    if (booking.mentorCompletedAt != null) {
      events.add(_TimelineEvent(
        label: 'Mentor đánh dấu hoàn tất',
        time: booking.mentorCompletedAt!,
        color: AppTheme.themePurpleStart,
      ));
    }

    if (booking.learnerCompletedAt != null) {
      events.add(_TimelineEvent(
        label: 'Learner xác nhận hoàn tất',
        time: booking.learnerCompletedAt!,
        color: AppTheme.successColor,
      ));
    }

    if (booking.status == BookingStatus.cancelled) {
      events.add(_TimelineEvent(
        label: 'Đã hủy',
        time: booking.createdAt ?? DateTime.now(),
        color: AppTheme.errorColor,
      ));
    }

    if (events.isEmpty) return const SizedBox.shrink();

    // Sort chronologically
    events.sort((a, b) => a.time.compareTo(b.time));

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Lịch sử', icon: Icons.history),
          const SizedBox(height: 16),
          ...events.asMap().entries.map((entry) {
            final isLast = entry.key == events.length - 1;
            final event = entry.value;
            return _buildTimelineItem(isDark, event, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(bool isDark, _TimelineEvent event, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: event.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: event.color.withOpacity(0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isDark
                          ? AppTheme.darkBorderColor
                          : AppTheme.lightBorderColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateTimeHelper.formatSmart(event.time),
                    style: TextStyle(
                      fontSize: 11,
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
      ),
    );
  }

  // ─── Dialogs ───────────────────────────────────────────────────────────

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận hủy'),
        content: const Text(
          'Bạn có chắc chắn muốn hủy lịch hẹn này? Tiền sẽ được hoàn lại vào ví.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _runAction(
                () => context
                    .read<MentorBookingProvider>()
                    .cancelBooking(_booking!.id),
                'Đã hủy lịch hẹn',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Hủy lịch'),
          ),
        ],
      ),
    );
  }

  void _showConfirmCompleteDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận hoàn thành'),
        content: const Text(
          'Bạn xác nhận buổi mentoring đã hoàn thành? Tiền sẽ được chuyển cho mentor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Chưa'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _runAction(
                () => context
                    .read<MentorBookingProvider>()
                    .confirmComplete(_booking!.id),
                'Đã xác nhận hoàn thành!',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}

class _TimelineEvent {
  final String label;
  final DateTime time;
  final Color color;

  const _TimelineEvent({
    required this.label,
    required this.time,
    required this.color,
  });
}
