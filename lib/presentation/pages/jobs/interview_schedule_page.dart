import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/interview_provider.dart';
import '../../../data/models/interview_models.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/common_loading.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../widgets/status_badge.dart';
import '../../themes/app_theme.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/enum_helper.dart';

/// Interview Schedule Page — shows all interviews for the current user
/// or interviews for a specific application if [applicationId] is provided.
class InterviewSchedulePage extends StatefulWidget {
  final int? applicationId; // optional: filter by app
  final String? jobTitle;

  const InterviewSchedulePage({super.key, this.applicationId, this.jobTitle});

  @override
  State<InterviewSchedulePage> createState() => _InterviewSchedulePageState();
}

class _InterviewSchedulePageState extends State<InterviewSchedulePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<InterviewProvider>();
      if (widget.applicationId != null) {
        provider.loadInterviewByApplication(widget.applicationId!);
      } else {
        provider.loadMyInterviews();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SkillVerseAppBar(
        title: widget.jobTitle != null
            ? 'Phỏng vấn: ${widget.jobTitle}'
            : 'Lịch Phỏng Vấn',
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Consumer<InterviewProvider>(
          builder: (context, provider, _) {
            final hasVisibleData = widget.applicationId != null
                ? provider.currentInterview != null
                : provider.myInterviews.isNotEmpty;
  
            if (provider.isLoading && !hasVisibleData) {
              return CommonLoading.center(message: 'Đang tải...');
            }
  
            // Single interview view (by application)
            if (widget.applicationId != null) {
              final interview = provider.currentInterview;
              if (interview == null) {
                return _buildEmptyState('Chưa có lịch phỏng vấn cho đơn này');
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildInterviewCard(interview, provider),
              );
            }
  
            // List view (all my interviews)
            final interviews = provider.myInterviews;
            if (interviews.isEmpty) {
              return _buildEmptyState('Bạn chưa có lịch phỏng vấn nào');
            }
  
            return RefreshIndicator(
              onRefresh: () => provider.loadMyInterviews(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: interviews.length,
                itemBuilder: (context, index) =>
                    _buildInterviewCard(interviews[index], provider),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInterviewCard(
    InterviewScheduleResponse interview,
    InterviewProvider provider,
  ) {
    final meetingLabel = _getMeetingTypeLabel(interview.meetingType);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Job + Status
          Row(
            children: [
              Expanded(
                child: Text(
                  interview.jobTitle ?? 'Phỏng vấn',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: interview.status?.toApiString() ?? 'PENDING'),
            ],
          ),
          const SizedBox(height: 12),

          // Schedule time
          if (interview.scheduledAt != null) ...[
            _buildInfoRow(
              Icons.calendar_today_outlined,
              'Thời gian',
              DateTimeHelper.formatSmart(
                DateTimeHelper.tryParseIso8601(interview.scheduledAt!) ??
                    DateTime.now(),
              ),
            ),
            const SizedBox(height: 6),
          ],

          // Duration
          if (interview.durationMinutes != null) ...[
            _buildInfoRow(
              Icons.schedule_outlined,
              'Thời lượng',
              '${interview.durationMinutes} phút',
            ),
            const SizedBox(height: 6),
          ],

          // Meeting type
          _buildInfoRow(
            _getMeetingTypeIcon(interview.meetingType),
            'Hình thức',
            meetingLabel,
          ),

          // Meeting link
          if (interview.meetingLink != null &&
              interview.meetingLink!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildInfoRow(
              Icons.link,
              'Link tham gia',
              interview.meetingLink!,
              isLink: true,
            ),
          ],

          // Location
          if (interview.location != null && interview.location!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildInfoRow(
              Icons.location_on_outlined,
              'Địa điểm',
              interview.location!,
            ),
          ],

          // Interviewer
          if (interview.interviewerName != null) ...[
            const SizedBox(height: 6),
            _buildInfoRow(
              Icons.person_outline,
              'Người phỏng vấn',
              interview.interviewerName!,
            ),
          ],

          // Notes
          if (interview.interviewNotes != null &&
              interview.interviewNotes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Ghi chú',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              interview.interviewNotes!,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ],

          // Response deadline (shown when PENDING)
          if (interview.status == InterviewStatus.pending &&
              interview.responseDeadlineAt != null) ...[
            const SizedBox(height: 6),
            _buildInfoRow(
              Icons.timer_outlined,
              'Hạn phản hồi',
              DateTimeHelper.formatSmart(
                DateTimeHelper.tryParseIso8601(interview.responseDeadlineAt!) ??
                    DateTime.now(),
              ),
            ),
          ],

          // Cancel reason (shown when CANCELLED)
          if (interview.status == InterviewStatus.cancelled &&
              interview.cancelReason != null &&
              interview.cancelReason!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildInfoRow(
              Icons.info_outline,
              'Lý do hủy',
              interview.cancelReason!,
            ),
          ],

          // Completed at (shown when COMPLETED)
          if (interview.status == InterviewStatus.completed &&
              interview.completedAt != null) ...[
            const SizedBox(height: 6),
            _buildInfoRow(
              Icons.check_circle_outline,
              'Hoàn thành lúc',
              DateTimeHelper.formatSmart(
                DateTimeHelper.tryParseIso8601(interview.completedAt!) ??
                    DateTime.now(),
              ),
            ),
          ],

          // Action buttons — candidate can confirm or decline a PENDING interview
          if (interview.status == InterviewStatus.pending) ...[
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),
            _buildInterviewActions(interview, provider),
            if (provider.isSubmittingAction) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Đang cập nhật phản hồi của bạn...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildInterviewActions(
    InterviewScheduleResponse interview,
    InterviewProvider provider,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            onPressed: provider.isSubmittingAction
                ? null
                : () => _onDecline(interview, provider),
            child: const Text('Từ chối'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.themeBlueStart,
              foregroundColor: Colors.white,
            ),
            onPressed: provider.isSubmittingAction
                ? null
                : () => _onConfirm(interview, provider),
            child: const Text('Xác nhận'),
          ),
        ),
      ],
    );
  }

  Future<void> _onConfirm(
    InterviewScheduleResponse interview,
    InterviewProvider provider,
  ) async {
    final ok = await provider.confirmInterview(interview.id!);
    if (!mounted) return;
    if (ok) {
      ErrorHandler.showSuccessSnackBar(context, 'Đã xác nhận lịch phỏng vấn.');
    } else {
      ErrorHandler.showErrorSnackBar(
        context,
        provider.errorMessage ?? 'Xác nhận thất bại.',
      );
    }
  }

  Future<void> _onDecline(
    InterviewScheduleResponse interview,
    InterviewProvider provider,
  ) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối phỏng vấn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn có chắc muốn từ chối lịch phỏng vấn này?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Lý do từ chối (tùy chọn)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final reason = reasonController.text.trim().isEmpty
        ? null
        : reasonController.text.trim();
    final ok = await provider.declineInterview(interview.id!, reason: reason);
    if (!mounted) return;
    if (ok) {
      ErrorHandler.showSuccessSnackBar(context, 'Đã từ chối lịch phỏng vấn.');
    } else {
      ErrorHandler.showErrorSnackBar(
        context,
        provider.errorMessage ?? 'Từ chối thất bại.',
      );
    }
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isLink = false,
  }) {
    final textWidget = Text(
      value,
      style: TextStyle(
        fontSize: 13,
        color: isLink ? AppTheme.themeBlueStart : null,
        decoration: isLink ? TextDecoration.underline : null,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).hintColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: isLink
              ? GestureDetector(
                  onTap: () async {
                    final uri = Uri.tryParse(value);
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      if (mounted) {
                        ErrorHandler.showWarningSnackBar(
                          context,
                          'Không thể mở link: $value',
                        );
                      }
                    }
                  },
                  child: textWidget,
                )
              : textWidget,
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 64,
            color: Theme.of(context).hintColor.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getMeetingTypeLabel(MeetingType? type) {
    return switch (type) {
      MeetingType.googleMeet => 'Google Meet',
      MeetingType.zoom => 'Zoom',
      MeetingType.microsoftTeams => 'Microsoft Teams',
      MeetingType.skillverseRoom => 'SkillVerse Room',
      MeetingType.phoneCall => 'Gọi điện',
      MeetingType.onsite => 'Trực tiếp',
      _ => 'Chưa xác định',
    };
  }

  IconData _getMeetingTypeIcon(MeetingType? type) {
    return switch (type) {
      MeetingType.googleMeet ||
      MeetingType.zoom ||
      MeetingType.microsoftTeams ||
      MeetingType.skillverseRoom => Icons.videocam_outlined,
      MeetingType.phoneCall => Icons.phone_outlined,
      MeetingType.onsite => Icons.meeting_room_outlined,
      _ => Icons.event_outlined,
    };
  }
}
