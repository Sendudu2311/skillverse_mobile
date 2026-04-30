import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'open_dispute_sheet.dart';

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
import '../../../data/models/roadmap_follow_up_models.dart';
import '../../../data/services/roadmap_follow_up_service.dart';
import '../../../core/error/exceptions.dart';

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

  // ── Feature C: Follow-Up Meetings ─────────────────────────────────────────
  final _followUpService = RoadmapFollowUpService();
  List<RoadmapFollowUpMeetingDto> _followUps = [];
  bool _isLoadingFollowUps = false;
  bool _isFollowUpBusy = false;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    setState(() => _isLoading = true);
    try {
      await context.read<MentorBookingProvider>().refreshBookingDetail(
        widget.bookingId,
      );
      if (!mounted) return;
      final provider = context.read<MentorBookingProvider>();
      final found = provider.bookings.where((b) => b.id == widget.bookingId);
      if (found.isNotEmpty) {
        _booking = found.first;
      }
      if (_booking?.status == BookingStatus.mentoringActive) {
        _loadFollowUps();
      }
    } catch (_) {
      // handled by provider
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFollowUps() async {
    if (!mounted) return;
    setState(() => _isLoadingFollowUps = true);
    try {
      final meetings = await _followUpService.getFollowUps(widget.bookingId);
      if (mounted) setState(() => _followUps = meetings);
    } catch (_) {
      // non-critical
    } finally {
      if (mounted) setState(() => _isLoadingFollowUps = false);
    }
  }

  Future<void> _acceptFollowUp(int meetingId) async {
    setState(() => _isFollowUpBusy = true);
    try {
      await _followUpService.acceptFollowUp(widget.bookingId, meetingId);
      await _loadFollowUps();
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(context, 'Đã chấp nhận meeting!');
      }
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isFollowUpBusy = false);
    }
  }

  Future<void> _rejectFollowUp(int meetingId) async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối meeting'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            hintText: 'Lý do từ chối (tuỳ chọn)',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(reasonCtrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
    reasonCtrl.dispose();
    if (reason == null || !mounted) return;

    setState(() => _isFollowUpBusy = true);
    try {
      await _followUpService.rejectFollowUp(
        widget.bookingId,
        meetingId,
        reason: reason.isEmpty ? null : reason,
      );
      await _loadFollowUps();
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(context, 'Đã từ chối meeting.');
      }
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isFollowUpBusy = false);
    }
  }

  /// P2: Student creates a new follow-up meeting proposal.
  Future<void> _showCreateMeetingSheet() async {
    final titleCtrl = TextEditingController();
    final purposeCtrl = TextEditingController();
    DateTime scheduledAt = DateTime.now().add(const Duration(hours: 24));
    int durationMinutes = 45;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkCardBackground
                    : AppTheme.lightCardBackground,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Đề xuất Meeting mới',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: titleCtrl,
                        decoration: InputDecoration(
                          labelText: 'Tiêu đề *',
                          hintText: 'VD: Hỏi đáp Node 3 - React Hooks',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: purposeCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Mục đích *',
                          hintText: 'VD: Cần mentor review bài tập...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Scheduled time picker
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: ctx,
                            initialDate: scheduledAt,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 90),
                            ),
                          );
                          if (date == null) return;
                          if (!ctx.mounted) return;
                          final time = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.fromDateTime(scheduledAt),
                          );
                          if (time == null) return;
                          setSheetState(() {
                            scheduledAt = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade400,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                DateTimeHelper.formatDateTime(scheduledAt),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppTheme.darkTextPrimary
                                      : AppTheme.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Duration dropdown
                      DropdownButtonFormField<int>(
                        value: durationMinutes,
                        decoration: InputDecoration(
                          labelText: 'Thời lượng',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 15, child: Text('15 phút')),
                          DropdownMenuItem(value: 30, child: Text('30 phút')),
                          DropdownMenuItem(value: 45, child: Text('45 phút')),
                          DropdownMenuItem(value: 60, child: Text('60 phút')),
                          DropdownMenuItem(value: 90, child: Text('90 phút')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() => durationMinutes = val);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (titleCtrl.text.trim().isEmpty ||
                                purposeCtrl.text.trim().isEmpty) {
                              ErrorHandler.showErrorSnackBar(
                                ctx,
                                'Vui lòng nhập tiêu đề và mục đích.',
                              );
                              return;
                            }
                            Navigator.of(ctx).pop(true);
                          },
                          icon: const Icon(Icons.send, size: 16),
                          label: const Text('Gửi đề xuất'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentCyan,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
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
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isFollowUpBusy = true);
    try {
      await _followUpService.createFollowUp(
        widget.bookingId,
        title: titleCtrl.text.trim(),
        purpose: purposeCtrl.text.trim(),
        scheduledAt: scheduledAt.toUtc().toIso8601String(),
        durationMinutes: durationMinutes,
      );
      await _loadFollowUps();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi đề xuất meeting. Chờ mentor duyệt.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          e is AppException ? e.message : 'Không thể tạo meeting.',
        );
      }
    } finally {
      if (mounted) setState(() => _isFollowUpBusy = false);
    }
  }

  bool get _isLearner {
    final userId = context.read<AuthProvider>().user?.id;
    return userId != null && _booking != null && _booking!.learnerId == userId;
  }

  bool get _isRoadmapMentoring => _booking?.bookingType == 'ROADMAP_MENTORING';

  bool get _meetingVisible {
    if (_booking == null || _booking!.meetingLink == null) return false;
    if (_isRoadmapMentoring) return false;
    if (_booking!.status == BookingStatus.ongoing) return true;
    if (_booking!.status == BookingStatus.confirmed) {
      final diff = _booking!.startTime.difference(DateTime.now()).inMinutes;
      return diff <= 30;
    }
    return false;
  }

  Future<void> _runAction(
    Future<void> Function() action,
    String success,
  ) async {
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
        try {
          await launchUrl(
            Uri.parse(link),
            mode: LaunchMode.externalApplication,
          );
        } catch (e) {
          if (mounted) {
            ErrorHandler.showErrorSnackBar(
              context,
              'Không thể mở phòng học (Jitsi).',
            );
          }
        }
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
                    if (_booking!.status == BookingStatus.mentoringActive) ...[
                      const SizedBox(height: 16),
                      _buildMentoringActiveBanner(isDark),
                      const SizedBox(height: 16),
                      _buildFollowUpMeetingsSection(isDark),
                    ],
                    if (_isLearner &&
                        _booking!.status == BookingStatus.pendingCompletion &&
                        _booking!.disputeId == null) ...[
                      const SizedBox(height: 16),
                      _buildPendingCompletionBanner(isDark),
                    ],
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

  // ─── Follow-Up Meetings Section ─────────────────────────────────────────

  Widget _buildFollowUpMeetingsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.event_repeat,
              size: 18,
              color: isDark ? AppTheme.primaryBlueDark : AppTheme.primaryBlue,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Lịch Follow-Up',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
            ),
            if (_isLoadingFollowUps) ...[
              const SizedBox(width: 10),
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
            // P2: Button to create new meeting
            IconButton(
              onPressed: _isFollowUpBusy ? null : _showCreateMeetingSheet,
              icon: const Icon(Icons.add_circle_outline, size: 22),
              tooltip: 'Đề xuất meeting mới',
              color: AppTheme.accentCyan,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_followUps.isEmpty && !_isLoadingFollowUps)
          Text(
            'Chưa có lịch follow-up. Nhấn + để đề xuất.',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          )
        else
          ...(_followUps.map((m) => _buildFollowUpCard(isDark, m))),
      ],
    );
  }

  Widget _buildFollowUpCard(bool isDark, RoadmapFollowUpMeetingDto m) {
    final showActions =
        m.isPending && m.createdByRole?.toUpperCase() != 'LEARNER';
    final showJoin =
        (m.canJoin == true) &&
        m.meetingLink != null &&
        m.meetingLink!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    m.title ?? 'Follow-Up Meeting',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                ),
                if (m.status != null) StatusBadge(status: m.status!),
              ],
            ),
            if (m.scheduledAt != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 13,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateTimeHelper.formatDateTime(m.scheduledAt!),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  if (m.durationMinutes != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '· ${m.durationMinutes} phút',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            // P5: Creator role badge
            if (m.createdByRole != null) ...[
              const SizedBox(height: 6),
              Text(
                m.createdByRole?.toUpperCase() == 'LEARNER'
                    ? 'Bạn đề xuất'
                    : 'Mentor đề xuất',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: m.createdByRole?.toUpperCase() == 'LEARNER'
                      ? AppTheme.accentCyan
                      : AppTheme.accentGold,
                ),
              ),
            ],
            if (m.purpose != null) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 12,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      m.purpose!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (m.isRejected && m.rejectReason != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppTheme.errorColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'Lý do từ chối: ${m.rejectReason}',
                  style: TextStyle(fontSize: 12, color: AppTheme.errorColor),
                ),
              ),
            ],
            if (showJoin || showActions) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (showJoin)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isFollowUpBusy
                            ? null
                            : () async {
                                try {
                                  await launchUrl(
                                    Uri.parse(m.meetingLink!),
                                    mode: LaunchMode.externalApplication,
                                  );
                                } catch (_) {
                                  if (mounted) {
                                    ErrorHandler.showErrorSnackBar(
                                      context,
                                      'Không thể mở link meeting.',
                                    );
                                  }
                                }
                              },
                        icon: const Icon(Icons.video_call, size: 16),
                        label: const Text('Tham gia'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  if (showJoin && showActions) const SizedBox(width: 8),
                  if (showActions) ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isFollowUpBusy
                            ? null
                            : () => _acceptFollowUp(m.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Chấp nhận'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isFollowUpBusy
                            ? null
                            : () => _rejectFollowUp(m.id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                          side: BorderSide(
                            color: AppTheme.errorColor.withValues(alpha: 0.6),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Từ chối'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Pending Completion Banner ───────────────────────────────────────────

  Widget _buildPendingCompletionBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: AppTheme.warningColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mentor đã đánh dấu hoàn tất. Bạn có thể:\n'
              '• "Xác nhận hoàn thành" → tiền sẽ được giải phóng cho Mentor.\n'
              '• "Khiếu nại" → chuyển sang Admin xem xét, tiền vẫn được giữ.\n'
              'Nếu không thao tác, hệ thống sẽ tự xác nhận sau 24h.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : AppTheme.lightTextPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Mentoring Active Banner ────────────────────────────────────────────

  Widget _buildMentoringActiveBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.infoColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.infoColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.school_outlined,
            color: AppTheme.infoColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Buổi mentoring roadmap đang diễn ra. Tiền escrow sẽ được giải phóng khi mentor xác nhận hoàn thành hành trình của bạn.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : AppTheme.lightTextPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Hero Card ──────────────────────────────────────────────────────────

  Widget _buildHeroCard(bool isDark) {
    final booking = _booking!;
    final counterpartName = _isLearner
        ? (booking.mentorName ?? 'Mentor')
        : (booking.learnerName ?? 'Học viên');
    final counterpartAvatar = _isLearner
        ? booking.mentorAvatar
        : booking.learnerAvatar;
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
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (booking.hasRoadmapWorkspace) {
      actions.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.push(
              '/roadmap/${booking.roadmapSessionId}/workspace?bookingId=${booking.id}&journeyId=${booking.journeyId}',
            ),
            icon: const Icon(Icons.workspace_premium_outlined, size: 18),
            label: const Text('Không gian Mentor'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      );
      actions.add(const SizedBox(width: 8));
    }

    // Meeting button (Join for learner / Start for mentor)
    if (_meetingVisible) {
      // Learner can only join if meeting link already exists
      // Mentor can start meeting (creates Jitsi room) OR join if already created
      if (booking.meetingLink != null || !_isLearner) {
        actions.add(
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isBusy
                  ? null
                  : () async {
                      if (booking.meetingLink != null) {
                        try {
                          await launchUrl(
                            Uri.parse(booking.meetingLink!),
                            mode: LaunchMode.externalApplication,
                          );
                        } catch (e) {
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(
                              content: Text('Không thể mở phòng học (Jitsi).'),
                              backgroundColor: Color(0xFFDC2626),
                            ),
                          );
                        }
                      } else {
                        _handleStartMeeting();
                      }
                    },
              icon: const Icon(Icons.video_call, size: 18),
              label: Text(
                booking.meetingLink != null ? 'Vào phòng' : 'Bắt đầu',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
              ),
            ),
          ),
        );
        actions.add(const SizedBox(width: 8));
      }
    }

    // Start Meeting for confirmed bookings near start time (but meetingLink is null)
    // Only show for Mentor — Learner cannot create a Jitsi room
    if (!_meetingVisible &&
        !_isRoadmapMentoring &&
        !_isLearner &&
        booking.status == BookingStatus.confirmed &&
        booking.meetingLink == null) {
      final minutesToStart = booking.startTime
          .difference(DateTime.now())
          .inMinutes;
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
            onPressed: _isBusy ? null : () => _showCancelDialog(),
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

    // Confirm Complete (learner) — shown for PENDING_COMPLETION or ONGOING after endTime
    if (booking.canConfirmComplete && _isLearner) {
      final isEarlyConfirm = booking.status == BookingStatus.ongoing;
      actions.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isBusy
                ? null
                : () =>
                      _showConfirmCompleteDialog(earlyConfirm: isEarlyConfirm),
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

    // Open Dispute — Learner only, no existing dispute, session must have ended for ONGOING/CONFIRMED
    if (_isLearner && booking.disputeId == null && booking.canOpenDispute) {
      actions.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isBusy ? null : _showOpenDisputeSheet,
            icon: const Icon(Icons.gavel, size: 18),
            label: const Text('Khiếu nại'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.warningColor,
              side: const BorderSide(color: AppTheme.warningColor),
            ),
          ),
        ),
      );
      actions.add(const SizedBox(width: 8));
    }

    // View existing dispute
    if (booking.disputeId != null) {
      actions.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () =>
                context.push('/booking-dispute/${booking.disputeId}'),
            icon: const Icon(Icons.gavel, size: 18),
            label: const Text('Xem khiếu nại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      );
      actions.add(const SizedBox(width: 8));
    }

    // Chat — only shown when chatAllowed
    if (booking.canChat) {
      actions.add(
        SizedBox(
          width: 48,
          child: IconButton.outlined(
            onPressed: () {
              final counterpartId = _isLearner
                  ? booking.mentorId
                  : booking.learnerId;
              context.push(
                '/messaging/chat/$counterpartId?bookingId=${booking.id}',
              );
            },
            icon: const Icon(Icons.chat_outlined, size: 20),
            tooltip: 'Nhắn tin',
          ),
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    // Remove trailing SizedBox spacer if exists
    if (actions.isNotEmpty &&
        actions.last is SizedBox &&
        (actions.last as SizedBox).width == 8) {
      actions.removeLast();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkCardBackground
            : AppTheme.lightCardBackground,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppTheme.darkBorderColor
                : AppTheme.lightBorderColor,
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
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: actions,
          ),
        ),
      ),
    );
  }

  // ─── Session Info Card ──────────────────────────────────────────────────

  Widget _buildSessionInfoCard(bool isDark) {
    final booking = _booking!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final hasPayment =
        booking.paymentReference != null ||
        [
          BookingStatus.confirmed,
          BookingStatus.ongoing,
          BookingStatus.mentoringActive,
          BookingStatus.pendingCompletion,
          BookingStatus.completed,
        ].contains(booking.status);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: _isRoadmapMentoring
                ? 'Thông tin gói đồng hành'
                : 'Thông tin buổi học',
            icon: _isRoadmapMentoring
                ? Icons.workspace_premium_outlined
                : Icons.calendar_today,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            isDark,
            icon: _isRoadmapMentoring
                ? Icons.flag_outlined
                : Icons.calendar_month,
            label: _isRoadmapMentoring ? 'Loại dịch vụ' : 'Ngày',
            value: _isRoadmapMentoring
                ? 'Mentor đồng hành roadmap'
                : DateTimeHelper.formatDateWithWeekday(booking.startTime),
          ),
          if (!_isRoadmapMentoring)
            _buildInfoRow(
              isDark,
              icon: Icons.access_time,
              label: 'Giờ bắt đầu',
              value: DateTimeHelper.formatTime(booking.startTime),
            ),
          if (_isRoadmapMentoring && booking.journeyId != null)
            _buildInfoRow(
              isDark,
              icon: Icons.route_outlined,
              label: 'Hành trình',
              value: '#${booking.journeyId}',
            ),
          if (!_isRoadmapMentoring)
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
            valueColor: hasPayment
                ? AppTheme.successColor
                : AppTheme.warningColor,
          ),
          if (!_isRoadmapMentoring)
            _buildInfoRow(
              isDark,
              icon: Icons.videocam,
              label: 'Phòng học',
              value: booking.meetingLink != null ? 'Đã tạo' : 'Chưa tạo',
              valueColor: booking.meetingLink != null
                  ? AppTheme.accentCyan
                  : AppTheme.darkTextSecondary,
            ),
          if (_isRoadmapMentoring && booking.hasRoadmapWorkspace)
            _buildInfoRow(
              isDark,
              icon: Icons.workspace_premium_outlined,
              label: 'Workspace',
              value: 'Đã sẵn sàng',
              valueColor: AppTheme.successColor,
            ),
          // Completion deadline (shown when PENDING_COMPLETION)
          if (booking.completionDeadline != null) ...[
            _buildInfoRow(
              isDark,
              icon: Icons.hourglass_bottom,
              label: 'Hạn xác nhận',
              value: DateTimeHelper.formatDateTime(booking.completionDeadline!),
              valueColor: AppTheme.warningColor,
            ),
          ],

          // Show meeting link if available
          if (!_isRoadmapMentoring && booking.meetingLink != null) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                try {
                  await launchUrl(
                    Uri.parse(booking.meetingLink!),
                    mode: LaunchMode.externalApplication,
                  );
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Không thể mở phòng học (Jitsi).'),
                      backgroundColor: Color(0xFFDC2626),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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
                color:
                    valueColor ??
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
          const SectionHeader(
            title: 'Tài chính',
            icon: Icons.account_balance_wallet,
          ),
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
                [
                      BookingStatus.cancelled,
                      BookingStatus.rejected,
                      BookingStatus.refunded,
                    ].contains(booking.status)
                    ? price
                    : 0,
              ),
              color:
                  [
                    BookingStatus.cancelled,
                    BookingStatus.rejected,
                    BookingStatus.refunded,
                  ].contains(booking.status)
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
              color:
                  color ??
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
      events.add(
        _TimelineEvent(
          label: 'Booking được tạo',
          time: booking.createdAt!,
          color: AppTheme.accentCyan,
        ),
      );
    }

    if (booking.status != BookingStatus.pending &&
        booking.status != BookingStatus.cancelled &&
        booking.status != BookingStatus.rejected) {
      events.add(
        _TimelineEvent(
          label: 'Đã xác nhận',
          time: booking.createdAt ?? booking.startTime,
          color: AppTheme.successColor,
        ),
      );
    }

    if (booking.mentorCompletedAt != null) {
      events.add(
        _TimelineEvent(
          label: 'Mentor đánh dấu hoàn tất',
          time: booking.mentorCompletedAt!,
          color: AppTheme.themePurpleStart,
        ),
      );
    }

    if (booking.learnerCompletedAt != null) {
      events.add(
        _TimelineEvent(
          label: 'Learner xác nhận hoàn tất',
          time: booking.learnerCompletedAt!,
          color: AppTheme.successColor,
        ),
      );
    }

    if (booking.status == BookingStatus.cancelled) {
      events.add(
        _TimelineEvent(
          label: 'Đã hủy',
          time: booking.createdAt ?? DateTime.now(),
          color: AppTheme.errorColor,
        ),
      );
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

  // ─── Dispute ───────────────────────────────────────────────────────────

  void _showOpenDisputeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => OpenDisputeSheet(
        bookingId: _booking!.id,
        onSuccess: (dispute) {
          _loadBooking();
          context.push('/booking-dispute/${dispute.id}');
        },
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
                () => context.read<MentorBookingProvider>().cancelBooking(
                  _booking!.id,
                ),
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

  void _showConfirmCompleteDialog({bool earlyConfirm = false}) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận hoàn thành'),
        content: Text(
          earlyConfirm
              ? 'Buổi học đã kết thúc. Bạn xác nhận hoàn thành? Tiền sẽ được chuyển cho mentor sau khi cả hai bên xác nhận.'
              : 'Bạn xác nhận buổi mentoring đã hoàn thành? Tiền sẽ được chuyển cho mentor.',
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
                () => context.read<MentorBookingProvider>().confirmComplete(
                  _booking!.id,
                ),
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
