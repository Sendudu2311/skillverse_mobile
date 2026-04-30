import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/job_provider.dart';
import '../../../data/models/job_models.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/common_loading.dart';
import '../../themes/app_theme.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/utils/date_time_helper.dart';
import 'job_apply_sheet.dart';
import 'interview_schedule_page.dart';
import 'short_term_submit_sheet.dart';
import 'package:go_router/go_router.dart';
import '../../providers/contract_provider.dart';
import '../../widgets/status_badge.dart';
import '../../../data/models/contract_models.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/enum_helper.dart';

class JobDetailPage extends StatefulWidget {
  final int jobId;
  final bool isShortTerm;

  const JobDetailPage({
    super.key,
    required this.jobId,
    required this.isShortTerm,
  });

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<JobProvider>();
      if (widget.isShortTerm) {
        provider.loadShortTermJobDetails(widget.jobId);
        provider.loadMyShortTermApplications();
      } else {
        provider.loadJobDetails(widget.jobId);
        provider.loadMyLongTermApplications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SkillVerseAppBar(
        title: widget.isShortTerm ? 'Chi Tiết Freelance' : 'Chi Tiết Việc Làm',
      ),
      body: Consumer<JobProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return CommonLoading.center(message: 'Đang tải...');
          }

          if (widget.isShortTerm) {
            final job = provider.selectedShortTermJob;
            if (job == null) {
              return CommonLoading.center(message: 'Không tìm thấy');
            }
            return _buildShortTermDetail(job);
          } else {
            final job = provider.selectedJob;
            if (job == null) {
              return CommonLoading.center(message: 'Không tìm thấy');
            }
            return _buildLongTermDetail(job);
          }
        },
      ),
    );
  }

  // ==================== LONG-TERM DETAIL ====================

  Widget _buildLongTermDetail(JobPostingResponse job) {
    final provider = context.watch<JobProvider>();
    final app = _findLongTermApplication(provider);
    final shouldSyncApplication = app == null && (job.hasApplied ?? false);
    if (shouldSyncApplication) {
      _scheduleApplicationSync(isShortTerm: false);
    }
    final primaryAction = _buildLongTermPrimaryActionState(
      job: job,
      app: app,
      isSyncingApplication: shouldSyncApplication,
      provider: provider,
    );

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + Company
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title ?? '',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: job.recruiterUserId != null
                          ? () => context.push(
                              '/business/profile/${job.recruiterUserId}',
                            )
                          : null,
                      child: Row(
                        children: [
                          Icon(
                            Icons.business,
                            size: 16,
                            color: Theme.of(context).hintColor,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              job.recruiterCompanyName ?? 'Công ty',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    decoration: job.recruiterUserId != null
                                        ? TextDecoration.underline
                                        : null,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (job.recruiterUserId != null) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.open_in_new,
                              size: 14,
                              color: Theme.of(context).hintColor,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (job.createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Đăng ${DateTimeHelper.formatRelativeTime(DateTimeHelper.tryParseIso8601(job.createdAt!) ?? DateTime.now())}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ====== LONG-TERM PROGRESS TIMELINE ======
              _buildLongTermProgressTimeline(),

              const SizedBox(height: 16),

              // Key Info
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (job.negotiable == true &&
                        (job.minBudget == null || job.minBudget == 0))
                      _buildDetailRow(
                        Icons.payments_outlined,
                        'Ngân sách',
                        'Thỏa thuận',
                      )
                    else if (job.minBudget != null && job.maxBudget != null)
                      _buildDetailRow(
                        Icons.payments_outlined,
                        'Ngân sách',
                        '${NumberFormatter.formatPrice(job.minBudget!)} - ${NumberFormatter.formatCurrency(job.maxBudget!)}',
                      ),
                    if (job.deadline != null)
                      _buildDetailRow(
                        Icons.calendar_today_outlined,
                        'Hạn nộp',
                        DateTimeHelper.formatDate(
                          DateTimeHelper.tryParseIso8601(job.deadline!) ??
                              DateTime.now(),
                        ),
                      ),
                    if (job.remote != null)
                      _buildDetailRow(
                        Icons.location_on_outlined,
                        'Hình thức',
                        job.remote == true
                            ? 'Remote'
                            : (job.location ?? 'Onsite'),
                      ),
                    if (job.experienceLevel != null)
                      _buildDetailRow(
                        Icons.bar_chart_outlined,
                        'Kinh nghiệm',
                        job.experienceLevel!,
                      ),
                    if (job.jobType != null)
                      _buildDetailRow(Icons.work_outline, 'Loại', job.jobType!),
                    if (job.hiringQuantity != null)
                      _buildDetailRow(
                        Icons.people_outline,
                        'Số lượng',
                        '${job.hiringQuantity} người',
                      ),
                    if (job.applicantCount != null)
                      _buildDetailRow(
                        Icons.person_outline,
                        'Ứng viên',
                        '${job.applicantCount} người đã ứng tuyển',
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Skills
              if (job.requiredSkills != null &&
                  job.requiredSkills!.isNotEmpty) ...[
                _buildSectionTitle('Kỹ Năng Yêu Cầu'),
                const SizedBox(height: 8),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: job.requiredSkills!.map((skill) {
                      return Chip(
                        label: Text(
                          skill,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: AppTheme.themeBlueStart.withValues(
                          alpha: 0.1,
                        ),
                        side: BorderSide(
                          color: AppTheme.themeBlueStart.withValues(alpha: 0.3),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Description
              _buildSectionTitle('Mô Tả Công Việc'),
              const SizedBox(height: 8),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Text(
                  job.description ?? 'Không có mô tả',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
              ),

              if (job.benefits != null) ...[
                const SizedBox(height: 16),
                _buildSectionTitle('Quyền Lợi'),
                const SizedBox(height: 8),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    job.benefits!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                ),
              ],

              const SizedBox(height: 100), // Space for bottom button
            ],
          ),
        ),

        _buildBottomActionBar(primaryAction),
      ],
    );
  }

  // ==================== SHORT-TERM DETAIL ====================

  Widget _buildShortTermDetail(ShortTermJobResponse job) {
    final provider = context.watch<JobProvider>();
    final app = _findShortTermApplication(provider);
    final shouldSyncApplication = app == null && (job.hasApplied ?? false);
    if (shouldSyncApplication) {
      _scheduleApplicationSync(isShortTerm: true);
    }
    final jobStatus = job.status ?? ShortTermJobStatus.published;
    final primaryAction = _buildShortTermPrimaryActionState(
      job: job,
      app: app,
      isSyncingApplication: shouldSyncApplication,
    );

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + Recruiter + Status Badge
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            job.title ?? '',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (job.urgency != null &&
                            job.urgency != JobUrgency.normal)
                          _buildUrgencyChip(job.urgency!),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // ====== STATUS BADGE ======
                    _buildStatusChip(jobStatus),
                    if (job.recruiterInfo?.companyName != null) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap:
                            (job.recruiterId ?? job.recruiterInfo?.id) != null
                            ? () => context.push(
                                '/business/profile/${job.recruiterId ?? job.recruiterInfo?.id}',
                              )
                            : null,
                        child: Row(
                          children: [
                            Icon(
                              Icons.business,
                              size: 16,
                              color: Theme.of(context).hintColor,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                job.recruiterInfo!.companyName!,
                                style: TextStyle(
                                  decoration:
                                      (job.recruiterId ??
                                              job.recruiterInfo?.id) !=
                                          null
                                      ? TextDecoration.underline
                                      : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (job.recruiterInfo?.rating != null) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.star,
                                size: 14,
                                color: Colors.amber.shade600,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                NumberFormatter.formatRating(
                                  job.recruiterInfo!.rating!,
                                ),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                            if ((job.recruiterId ?? job.recruiterInfo?.id) !=
                                null) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.open_in_new,
                                size: 14,
                                color: Theme.of(context).hintColor,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    if (job.createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Đăng ${DateTimeHelper.formatRelativeTime(DateTimeHelper.tryParseIso8601(job.createdAt!) ?? DateTime.now())}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ====== JOB PROGRESS TIMELINE ======
              _buildProgressTimeline(job),

              const SizedBox(height: 16),

              // ====== APPLICANT SECTION (shown when user has applied) ======
              _buildShortTermApplicationSection(job),

              // Key Info
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (job.negotiable == true &&
                        (job.budget == null || job.budget == 0))
                      _buildDetailRow(
                        Icons.payments_outlined,
                        'Ngân sách',
                        'Thỏa thuận',
                      )
                    else if (job.budget != null)
                      _buildDetailRow(
                        Icons.payments_outlined,
                        'Ngân sách',
                        '${NumberFormatter.formatCurrency(job.budget!)}${job.negotiable == true ? ' (Thương lượng)' : ''}',
                      ),
                    if (job.estimatedDuration != null)
                      _buildDetailRow(
                        Icons.schedule_outlined,
                        'Thời gian',
                        job.estimatedDuration!,
                      ),
                    if (job.deadline != null)
                      _buildDetailRow(
                        Icons.calendar_today_outlined,
                        'Hạn nộp',
                        DateTimeHelper.formatDate(
                          DateTimeHelper.tryParseIso8601(job.deadline!) ??
                              DateTime.now(),
                        ),
                      ),
                    _buildDetailRow(
                      Icons.location_on_outlined,
                      'Hình thức',
                      job.remote == true
                          ? 'Remote'
                          : (job.location ?? 'Onsite'),
                    ),
                    if (job.applicantCount != null)
                      _buildDetailRow(
                        Icons.people_outline,
                        'Ứng viên',
                        '${job.applicantCount}${job.maxApplicants != null ? '/${job.maxApplicants}' : ''} người',
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Skills
              if (job.requiredSkills != null &&
                  job.requiredSkills!.isNotEmpty) ...[
                _buildSectionTitle('Kỹ Năng Yêu Cầu'),
                const SizedBox(height: 8),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: job.requiredSkills!.map((skill) {
                      return Chip(
                        label: Text(
                          skill,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: AppTheme.themePurpleStart.withValues(
                          alpha: 0.1,
                        ),
                        side: BorderSide(
                          color: AppTheme.themePurpleStart.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Description
              _buildSectionTitle('Mô Tả Công Việc'),
              const SizedBox(height: 8),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Text(
                  job.description ?? 'Không có mô tả',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
              ),

              // Milestones
              if (job.milestones != null && job.milestones!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSectionTitle('Milestones'),
                const SizedBox(height: 8),
                ...job.milestones!.map(
                  (m) => GlassCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.themeBlueStart.withValues(
                              alpha: 0.1,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${m.order ?? 0}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.themeBlueStart,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.title ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (m.amount != null)
                                Text(
                                  NumberFormatter.formatCurrency(m.amount!),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppTheme.themeGreenStart,
                                      ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 100),
            ],
          ),
        ),

        _buildBottomActionBar(primaryAction),
      ],
    );
  }

  void _showApplySheet(BuildContext context, ShortTermJobResponse job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JobApplySheet(
        jobId: job.id!,
        jobTitle: job.title ?? '',
        isShortTerm: true,
      ),
    );
  }

  void _showLongTermApplySheet(BuildContext context, JobPostingResponse job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JobApplySheet(
        jobId: job.id!,
        jobTitle: job.title ?? '',
        isShortTerm: false,
      ),
    );
  }

  // ==================== STATUS & TIMELINE ====================

  Widget _buildStatusChip(ShortTermJobStatus status) {
    final (label, color, icon) = switch (status) {
      ShortTermJobStatus.draft => (
        'Bản nháp',
        Colors.grey,
        Icons.edit_outlined,
      ),
      ShortTermJobStatus.pendingApproval => (
        'Chờ duyệt',
        Colors.orange,
        Icons.hourglass_empty,
      ),
      ShortTermJobStatus.published => (
        'Đang tuyển',
        AppTheme.themeBlueStart,
        Icons.campaign_outlined,
      ),
      ShortTermJobStatus.applied => (
        'Đã nhận đơn',
        Colors.indigo,
        Icons.inbox_outlined,
      ),
      ShortTermJobStatus.inProgress => (
        'Đang thực hiện',
        AppTheme.themeOrangeStart,
        Icons.construction_outlined,
      ),
      ShortTermJobStatus.submitted => (
        'Đã nộp bài',
        Colors.teal,
        Icons.upload_file_outlined,
      ),
      ShortTermJobStatus.underReview => (
        'Đang review',
        Colors.deepPurple,
        Icons.rate_review_outlined,
      ),
      ShortTermJobStatus.approved => (
        'Đã duyệt',
        AppTheme.themeGreenStart,
        Icons.check_circle_outline,
      ),
      ShortTermJobStatus.completed => (
        'Hoàn thành',
        AppTheme.themeGreenStart,
        Icons.done_all,
      ),
      ShortTermJobStatus.paid => (
        'Đã thanh toán',
        AppTheme.themeGreenStart,
        Icons.payments_outlined,
      ),
      ShortTermJobStatus.rejected => (
        'Từ chối',
        Colors.red,
        Icons.cancel_outlined,
      ),
      ShortTermJobStatus.cancelled => (
        'Đã hủy',
        Colors.red,
        Icons.block_outlined,
      ),
      ShortTermJobStatus.disputed => (
        'Tranh chấp',
        Colors.deepOrange,
        Icons.gavel_outlined,
      ),
      ShortTermJobStatus.escalated => (
        'Leo thang',
        Colors.red.shade700,
        Icons.warning_amber_outlined,
      ),
      ShortTermJobStatus.closed => (
        'Đã đóng',
        Colors.grey.shade600,
        Icons.lock_outline,
      ),
      ShortTermJobStatus.autoApproved => (
        'Tự động duyệt',
        AppTheme.themeGreenStart,
        Icons.check_circle_outline,
      ),
      ShortTermJobStatus.cancellationRequested => (
        'Yêu cầu hủy',
        Colors.red,
        Icons.cancel_outlined,
      ),
      ShortTermJobStatus.autoCancelled => (
        'Tự động hủy',
        Colors.red,
        Icons.block_outlined,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTimeline(ShortTermJobResponse job) {
    final steps = <_TimelineStep>[
      _TimelineStep(
        label: 'Đăng tuyển',
        time: job.publishedAt,
        icon: Icons.campaign_outlined,
        isCompleted: job.publishedAt != null,
      ),
      _TimelineStep(
        label: 'Đang thực hiện',
        time: null,
        icon: Icons.construction_outlined,
        isCompleted: [
          ShortTermJobStatus.inProgress,
          ShortTermJobStatus.submitted,
          ShortTermJobStatus.underReview,
          ShortTermJobStatus.approved,
          ShortTermJobStatus.completed,
          ShortTermJobStatus.paid,
        ].contains(job.status),
      ),
      _TimelineStep(
        label: 'Hoàn thành',
        time: job.completedAt,
        icon: Icons.done_all,
        isCompleted: job.completedAt != null,
      ),
      _TimelineStep(
        label: 'Thanh toán',
        time: job.paidAt,
        icon: Icons.payments_outlined,
        isCompleted: job.paidAt != null,
      ),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tiến Độ',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index.isOdd) {
                // connector line
                final prevCompleted = steps[index ~/ 2].isCompleted;
                final nextCompleted = steps[index ~/ 2 + 1].isCompleted;
                return Expanded(
                  child: Container(
                    height: 3,
                    color: prevCompleted && nextCompleted
                        ? AppTheme.themeGreenStart
                        : Colors.grey.shade300,
                  ),
                );
              } else {
                // step circle
                final step = steps[index ~/ 2];
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: step.isCompleted
                            ? AppTheme.themeGreenStart
                            : Colors.grey.shade300,
                      ),
                      child: Icon(
                        step.isCompleted ? Icons.check : step.icon,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      step.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: step.isCompleted
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: step.isCompleted
                            ? Theme.of(context).textTheme.bodyMedium?.color
                            : Theme.of(context).hintColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (step.time != null)
                      Text(
                        DateTimeHelper.formatDate(
                          DateTimeHelper.tryParseIso8601(step.time!) ??
                              DateTime.now(),
                        ),
                        style: TextStyle(
                          fontSize: 9,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                  ],
                );
              }
            }),
          ),
        ],
      ),
    );
  }

  // ==================== SHORT-TERM APPLICANT SECTION ====================

  /// Shows applicant-specific timeline + action buttons when user has applied.
  /// Triggers a background load if hasApplied flag is set but app list is empty.
  Widget _buildShortTermApplicationSection(ShortTermJobResponse job) {
    final provider = context.watch<JobProvider>();

    // If not applied yet, show nothing
    final hasApplied = provider.hasAppliedToShortTermJob(widget.jobId);
    final jobHasAppliedFlag = job.hasApplied ?? false;
    if (!hasApplied && !jobHasAppliedFlag) return const SizedBox.shrink();

    // Try to find the application record
    ShortTermApplicationResponse? app = provider.myShortTermApplications
        .cast<ShortTermApplicationResponse?>()
        .firstWhere((a) => a!.jobId == widget.jobId, orElse: () => null);

    // Edge case: flag says applied but local list hasn't loaded → trigger fetch
    if (app == null && jobHasAppliedFlag) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<JobProvider>().loadMyShortTermApplications();
      });
      return GlassCard(
        padding: const EdgeInsets.all(16),
        borderColor: AppTheme.themeBlueStart.withValues(alpha: 0.3),
        child: Center(child: CommonLoading.small()),
      );
    }

    if (app == null) return const SizedBox.shrink();

    final statusStr = app.status?.toApiString() ?? 'PENDING';

    const statusToStep = {
      'PENDING': 0,
      'ACCEPTED': 1,
      'WORKING': 1,
      'IN_PROGRESS': 1,
      'SUBMITTED': 2,
      'SUBMITTED_OVERDUE': 2,
      'REVISION_REQUIRED': 2,
      'REVISION_RESPONSE_OVERDUE': 2,
      'UNDER_REVIEW': 2,
      'APPROVED': 3,
      'COMPLETED': 3,
      'PAID': 3,
    };

    const failedStatuses = {
      'REJECTED',
      'CANCELLED',
      'WITHDRAWN',
      'AUTO_CANCELLED',
      'CANCELLATION_REQUESTED',
      'DISPUTE_OPENED',
    };
    const revisionStatuses = {
      'REVISION_REQUIRED',
      'REVISION_RESPONSE_OVERDUE',
      'SUBMITTED_OVERDUE',
    };

    final isRejected = failedStatuses.contains(statusStr);
    final isRevision = revisionStatuses.contains(statusStr);
    final currentIndex = isRejected ? 0 : (statusToStep[statusStr] ?? 0);

    final canSubmit =
        app.status == ShortTermApplicationStatus.working ||
        app.status == ShortTermApplicationStatus.inProgress ||
        app.status == ShortTermApplicationStatus.revisionRequired;
    final canWithdraw = app.status == ShortTermApplicationStatus.pending;

    return Column(
      children: [
        GlassCard(
          padding: const EdgeInsets.all(16),
          borderColor: isRejected
              ? Colors.red.withValues(alpha: 0.3)
              : isRevision
              ? AppTheme.themeOrangeStart.withValues(alpha: 0.3)
              : AppTheme.themeBlueStart.withValues(alpha: 0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 18,
                    color: isRejected
                        ? Colors.red
                        : isRevision
                        ? AppTheme.themeOrangeStart
                        : AppTheme.themeBlueStart,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Đơn Ứng Tuyển Của Bạn',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  StatusBadge(status: statusStr),
                ],
              ),

              const SizedBox(height: 14),

              // 4-step applicant timeline
              _buildApplicantTimelineDots(
                stepLabels: const [
                  'Đã nộp',
                  'Đang làm',
                  'Chờ duyệt',
                  'Hoàn thành',
                ],
                currentIndex: currentIndex,
                isRejected: isRejected,
                isRevision: isRevision,
              ),

              // Revision notes
              if (isRevision &&
                  app.revisionNotes != null &&
                  app.revisionNotes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildRevisionBanner(app.revisionNotes!.last),
              ],

              // Failure banner
              if (isRejected) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cancel_outlined,
                        size: 14,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statusStr == 'DISPUTE_OPENED'
                            ? 'Đang tranh chấp — liên hệ hỗ trợ nếu cần.'
                            : statusStr == 'CANCELLATION_REQUESTED'
                            ? 'Yêu cầu hủy đang được xử lý.'
                            : 'Đơn ứng tuyển đã kết thúc.',
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],

              // Action buttons
              if (canSubmit || canWithdraw) ...[
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (canWithdraw)
                      OutlinedButton.icon(
                        onPressed: () => _confirmShortTermWithdraw(app.id!),
                        icon: const Icon(Icons.undo, size: 14),
                        label: const Text(
                          'Rút đơn',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(
                            color: Colors.red.withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    if (canSubmit)
                      ElevatedButton.icon(
                        onPressed: app.id != null
                            ? () => _showShortTermSubmitSheet(app)
                            : null,
                        icon: const Icon(Icons.upload_rounded, size: 14),
                        label: Text(
                          isRevision ? 'Nộp lại' : 'Nộp bài',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isRevision
                              ? AppTheme.themeOrangeStart
                              : AppTheme.themePurpleStart,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildApplicantTimelineDots({
    required List<String> stepLabels,
    required int currentIndex,
    required bool isRejected,
    required bool isRevision,
  }) {
    return Row(
      children: List.generate(stepLabels.length * 2 - 1, (i) {
        if (i.isOdd) {
          final stepIdx = i ~/ 2;
          final isCompleted = !isRejected && currentIndex > stepIdx;
          return Expanded(
            child: Container(
              height: 2,
              color: isRejected
                  ? Colors.red.withValues(alpha: 0.25)
                  : isCompleted
                  ? AppTheme.themeGreenStart
                  : Colors.grey.shade300,
            ),
          );
        }

        final stepIdx = i ~/ 2;
        final isCurrent = !isRejected && currentIndex == stepIdx;
        final isCompleted = !isRejected && currentIndex > stepIdx;
        final isCurrentRevision = isCurrent && isRevision;

        final Color dotColor;
        if (isRejected && stepIdx == 0) {
          dotColor = Colors.red;
        } else if (isCurrentRevision) {
          dotColor = AppTheme.themeOrangeStart;
        } else if (isCompleted) {
          dotColor = AppTheme.themeGreenStart;
        } else if (isCurrent) {
          dotColor = AppTheme.themeBlueStart;
        } else {
          dotColor = Colors.grey.shade300;
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
              ),
              child: Icon(
                isRejected && stepIdx == 0
                    ? Icons.close
                    : isCompleted
                    ? Icons.check
                    : Icons.circle_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              stepLabels[stepIdx],
              style: TextStyle(
                fontSize: 10,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                color: isRejected && stepIdx == 0
                    ? Colors.red
                    : isCurrent || isCompleted
                    ? Theme.of(context).textTheme.bodyMedium?.color
                    : Theme.of(context).hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      }),
    );
  }

  Widget _buildRevisionBanner(RevisionNoteResponse note) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.themeOrangeStart.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.themeOrangeStart.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.rate_review_outlined,
                size: 13,
                color: AppTheme.themeOrangeStart,
              ),
              const SizedBox(width: 6),
              Text(
                'Yêu cầu chỉnh sửa',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.themeOrangeStart,
                ),
              ),
            ],
          ),
          if (note.note != null && note.note!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              note.note!,
              style: const TextStyle(fontSize: 12),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (note.specificIssues != null &&
              note.specificIssues!.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...note.specificIssues!.map(
              (issue) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: Text(issue, style: const TextStyle(fontSize: 12)),
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

  void _confirmShortTermWithdraw(int applicationId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn rút đơn ứng tuyển này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              final provider = context.read<JobProvider>();
              Navigator.of(ctx).pop();
              final success = await provider.withdrawApplication(applicationId);
              if (mounted && success) {
                await provider.loadMyShortTermApplications(refresh: true);
                await provider.loadShortTermJobDetails(widget.jobId);
                if (!mounted) return;
                ErrorHandler.showSuccessSnackBar(
                  context,
                  'Đã rút đơn thành công',
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Rút đơn'),
          ),
        ],
      ),
    );
  }

  void _showShortTermSubmitSheet(ShortTermApplicationResponse app) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ShortTermSubmitSheet(
        applicationId: app.id!,
        jobTitle: app.jobTitle ?? 'Freelance Job',
        existingDeliverables: app.deliverables,
      ),
    ).then((submitted) {
      if (submitted == true && mounted) {
        context.read<JobProvider>().loadMyShortTermApplications();
      }
    });
  }

  // ==================== LONG-TERM TIMELINE ====================

  Widget _buildLongTermProgressTimeline() {
    final provider = context.watch<JobProvider>();
    final app = _findLongTermApplication(provider);

    if (app == null) return const SizedBox.shrink();

    final status = app.status ?? JobApplicationStatus.pending;

    // Determine path from job metadata on the application response
    // Remote OR Negotiable salary → uses full Offer negotiation flow
    final isOfferPath = app.remote == true || app.negotiable == true;

    final isRejected = status == JobApplicationStatus.rejected;
    final isOfferRejected = status == JobApplicationStatus.offerRejected;
    final isAnyFail = isRejected || isOfferRejected;

    // ── Status → step mapping (path-aware) ────────────────────────────
    final statusToStep = isOfferPath
        ? {
            JobApplicationStatus.pending: 0,
            JobApplicationStatus.reviewed: 1,
            JobApplicationStatus.interviewScheduled: 2,
            JobApplicationStatus.interviewed: 2,
            JobApplicationStatus.offerSent: 3,
            JobApplicationStatus.offerAccepted: 3,
            JobApplicationStatus.offerRejected: 3,
            JobApplicationStatus.accepted: 2,
            JobApplicationStatus.contractSigned: 4,
            JobApplicationStatus.rejected: 1,
          }
        : {
            JobApplicationStatus.pending: 0,
            JobApplicationStatus.reviewed: 1,
            JobApplicationStatus.interviewScheduled: 2,
            JobApplicationStatus.interviewed: 2,
            JobApplicationStatus.accepted: 3,
            JobApplicationStatus.contractSigned: 4,
            JobApplicationStatus.rejected: 1,
          };

    final currentStep = statusToStep[status] ?? 0;

    // Step 3 label differs by path
    final step3Label = isOfferPath ? 'Đề nghị' : 'Trúng tuyển';
    final step3Icon = isOfferPath
        ? Icons.emoji_events_outlined
        : Icons.how_to_reg_outlined;

    // Step indices: 0=Nộp đơn, 1=Xét duyệt, 2=Phỏng vấn, 3=Đề nghị/Trúng tuyển, 4=Ký HĐ
    final steps = <_TimelineStep>[
      _TimelineStep(
        label: 'Nộp đơn',
        time: app.appliedAt,
        icon: Icons.send_outlined,
        isCompleted: currentStep > 0 || isAnyFail,
      ),
      _TimelineStep(
        label: 'Xét duyệt',
        time: app.reviewedAt,
        icon: Icons.fact_check_outlined,
        isCompleted: currentStep > 1 && !isRejected,
      ),
      _TimelineStep(
        label: 'Phỏng vấn',
        time: null,
        icon: Icons.record_voice_over_outlined,
        isCompleted: currentStep > 2 && !isAnyFail,
      ),
      _TimelineStep(
        label: step3Label,
        time: app.processedAt,
        icon: step3Icon,
        isCompleted: currentStep > 3 && !isAnyFail,
      ),
      _TimelineStep(
        label: 'Ký HĐ',
        time: null,
        icon: Icons.description_outlined,
        isCompleted: status == JobApplicationStatus.contractSigned,
      ),
    ];

    // Fail step index: where the red ✕ should appear
    final int? failStepIdx = isRejected
        ? 1
        : isOfferRejected
        ? 3
        : null;

    final borderColor = isAnyFail
        ? Colors.red.withValues(alpha: 0.3)
        : status == JobApplicationStatus.contractSigned
        ? AppTheme.themeGreenStart.withValues(alpha: 0.3)
        : AppTheme.themeBlueStart.withValues(alpha: 0.3);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(
                isAnyFail ? Icons.cancel_outlined : Icons.timeline,
                size: 20,
                color: isAnyFail ? Colors.red : AppTheme.themeBlueStart,
              ),
              const SizedBox(width: 8),
              Text(
                'Tiến Độ Ứng Tuyển',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),

          // Rejection banner
          if (isRejected) ...[
            const SizedBox(height: 10),
            _buildInfoBanner(
              color: Colors.red,
              icon: Icons.info_outline,
              text: app.rejectionReason ?? 'Đơn ứng tuyển đã bị từ chối.',
            ),
          ],

          // Offer rejected banner
          if (isOfferRejected) ...[
            const SizedBox(height: 10),
            _buildInfoBanner(
              color: Colors.red,
              icon: Icons.info_outline,
              text: 'Đề nghị công việc đã bị từ chối.',
            ),
          ],

          // Interview result (when available)
          if (app.interviewResult != null &&
              app.interviewResult!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildInfoBanner(
              color: AppTheme.themePurpleStart,
              icon: Icons.record_voice_over_outlined,
              text: 'Kết quả phỏng vấn: ${app.interviewResult}',
            ),
          ],

          if (status == JobApplicationStatus.reviewed) ...[
            const SizedBox(height: 10),
            _buildInfoBanner(
              color: AppTheme.themeBlueStart,
              icon: Icons.schedule_outlined,
              text:
                  'Đơn của bạn đang được xem xét. Hệ thống sẽ cập nhật khi nhà tuyển dụng sắp lịch bước tiếp theo.',
            ),
          ],

          // Offer section card (always shown when offer flow is active)
          if (isOfferPath &&
              (status == JobApplicationStatus.offerSent ||
                  status == JobApplicationStatus.offerAccepted ||
                  status == JobApplicationStatus.offerRejected)) ...[
            const SizedBox(height: 10),
            _buildOfferCard(app),
          ],

          // Acceptance message (direct-accept path)
          if (status == JobApplicationStatus.accepted &&
              app.acceptanceMessage != null) ...[
            const SizedBox(height: 10),
            _buildInfoBanner(
              color: AppTheme.themeGreenStart,
              icon: Icons.thumb_up_outlined,
              text: app.acceptanceMessage!,
            ),
          ],

          const SizedBox(height: 16),

          // ── Timeline dots & connectors ─────────────────────────────
          Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index.isOdd) {
                final stepIdx = index ~/ 2;
                final prevCompleted = steps[stepIdx].isCompleted;
                final nextCompleted = steps[stepIdx + 1].isCompleted;
                final isFailConnector =
                    failStepIdx != null && stepIdx == failStepIdx - 1;
                return Expanded(
                  child: Container(
                    height: 3,
                    color: isFailConnector
                        ? Colors.red.withValues(alpha: 0.4)
                        : prevCompleted && nextCompleted
                        ? AppTheme.themeGreenStart
                        : Colors.grey.shade300,
                  ),
                );
              }

              final stepIdx = index ~/ 2;
              final step = steps[stepIdx];
              final isFailDot = failStepIdx == stepIdx;
              final isCurrent = !isAnyFail && currentStep == stepIdx;

              final Color dotColor;
              if (isFailDot) {
                dotColor = Colors.red;
              } else if (step.isCompleted) {
                dotColor = AppTheme.themeGreenStart;
              } else if (isCurrent) {
                dotColor = AppTheme.themeBlueStart;
              } else {
                dotColor = Colors.grey.shade300;
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor,
                    ),
                    child: Icon(
                      isFailDot
                          ? Icons.close
                          : step.isCompleted
                          ? Icons.check
                          : step.icon,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: step.isCompleted || isCurrent
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isFailDot
                          ? Colors.red
                          : step.isCompleted || isCurrent
                          ? Theme.of(context).textTheme.bodyMedium?.color
                          : Theme.of(context).hintColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (step.time != null)
                    Text(
                      DateTimeHelper.formatDate(
                        DateTimeHelper.tryParseIso8601(step.time!) ??
                            DateTime.now(),
                      ),
                      style: TextStyle(
                        fontSize: 9,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                ],
              );
            }),
          ),

          // ── Action buttons ─────────────────────────────────────────
          if (!isRejected && status != JobApplicationStatus.pending) ...[
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Interview schedule button
                if (app.id != null &&
                    (status == JobApplicationStatus.interviewScheduled ||
                        status == JobApplicationStatus.interviewed ||
                        (status == JobApplicationStatus.accepted &&
                            isOfferPath)))
                  OutlinedButton.icon(
                    onPressed: () => _openInterviewSchedule(app),
                    icon: const Icon(
                      Icons.record_voice_over_outlined,
                      size: 16,
                    ),
                    label: const Text(
                      'Lịch phỏng vấn',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.themeBlueStart,
                      side: BorderSide(
                        color: AppTheme.themeBlueStart.withValues(alpha: 0.4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                // Contract button
                if (status == JobApplicationStatus.offerAccepted ||
                    (status == JobApplicationStatus.accepted && !isOfferPath) ||
                    status == JobApplicationStatus.contractSigned)
                  () {
                    final contractReady = _hasContractReady(app);
                    return OutlinedButton.icon(
                      onPressed: contractReady
                          ? () => _openApplicationContract(app)
                          : null,
                      icon: const Icon(Icons.description_outlined, size: 16),
                      label: Text(
                        !contractReady
                            ? 'Chờ tạo hợp đồng'
                            : status == JobApplicationStatus.contractSigned
                            ? 'Xem hợp đồng'
                            : 'Ký hợp đồng',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: contractReady
                            ? AppTheme.themeGreenStart
                            : Colors.grey,
                        side: BorderSide(
                          color:
                              (contractReady
                                      ? AppTheme.themeGreenStart
                                      : Colors.grey)
                                  .withValues(alpha: 0.4),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }(),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoBanner({
    required Color color,
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(JobApplicationResponse app) {
    final isPending = app.status == JobApplicationStatus.offerSent;
    final isAccepted = app.status == JobApplicationStatus.offerAccepted;
    final Color headerColor = isPending
        ? const Color(0xFFAA55FF)
        : isAccepted
        ? AppTheme.themeGreenStart
        : Colors.red;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: headerColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: headerColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(Icons.local_offer_outlined, size: 14, color: headerColor),
              const SizedBox(width: 6),
              Text(
                isPending ? 'Đề nghị từ nhà tuyển dụng' : 'Đề nghị việc làm',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: headerColor,
                ),
              ),
              if (app.offerRound != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: headerColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Vòng ${app.offerRound}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: headerColor,
                    ),
                  ),
                ),
              ],
            ],
          ),

          if (_hasOfferSummary(app)) ...[
            const SizedBox(height: 8),
            ..._buildOfferSummaryContent(app),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              'Nhà tuyển dụng chưa cung cấp đủ thông tin đề nghị.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).hintColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          // Candidate response (if already responded)
          if ((app.candidateOfferResponse?.trim().isNotEmpty ?? false) ||
              app.counterSalaryAmount != null ||
              (app.counterAdditionalRequirements?.trim().isNotEmpty ??
                  false)) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phản hồi của bạn',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  if (app.candidateOfferResponse?.trim().isNotEmpty ??
                      false) ...[
                    const SizedBox(height: 4),
                    Text(
                      app.candidateOfferResponse!.trim(),
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                  if (app.counterSalaryAmount != null) ...[
                    const SizedBox(height: 6),
                    _buildOfferMetaRow(
                      icon: Icons.payments_outlined,
                      label: 'Lương đề xuất lại',
                      value: NumberFormatter.formatCurrency(
                        app.counterSalaryAmount!.toDouble(),
                      ),
                    ),
                  ],
                  if (app.counterAdditionalRequirements?.trim().isNotEmpty ??
                      false) ...[
                    const SizedBox(height: 6),
                    _buildOfferMetaRow(
                      icon: Icons.notes_outlined,
                      label: 'Yêu cầu thêm',
                      value: app.counterAdditionalRequirements!.trim(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _hasOfferSummary(JobApplicationResponse app) {
    return (app.offerDetails?.trim().isNotEmpty ?? false) ||
        app.offerSalary != null ||
        (app.offerAdditionalRequirements?.trim().isNotEmpty ?? false);
  }

  List<Widget> _buildOfferSummaryContent(JobApplicationResponse app) {
    final widgets = <Widget>[];

    if (app.offerDetails?.trim().isNotEmpty ?? false) {
      widgets.add(
        Text(
          app.offerDetails!.trim(),
          style: const TextStyle(fontSize: 13, height: 1.5),
        ),
      );
    }

    if (app.offerSalary != null) {
      if (widgets.isNotEmpty) {
        widgets.add(const SizedBox(height: 8));
      }
      widgets.add(
        _buildOfferMetaRow(
          icon: Icons.payments_outlined,
          label: 'Mức đề nghị',
          value: NumberFormatter.formatCurrency(app.offerSalary!.toDouble()),
        ),
      );
    }

    if (app.offerAdditionalRequirements?.trim().isNotEmpty ?? false) {
      if (widgets.isNotEmpty) {
        widgets.add(const SizedBox(height: 8));
      }
      widgets.add(
        _buildOfferMetaRow(
          icon: Icons.assignment_outlined,
          label: 'Điều kiện thêm',
          value: app.offerAdditionalRequirements!.trim(),
        ),
      );
    }

    return widgets;
  }

  Widget _buildOfferMetaRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).hintColor),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(height: 1.5),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  JobApplicationResponse? _findLongTermApplication(JobProvider provider) {
    return provider.myLongTermApplications
        .cast<JobApplicationResponse?>()
        .firstWhere((a) => a!.jobId == widget.jobId, orElse: () => null);
  }

  ShortTermApplicationResponse? _findShortTermApplication(
    JobProvider provider,
  ) {
    return provider.myShortTermApplications
        .cast<ShortTermApplicationResponse?>()
        .firstWhere((a) => a!.jobId == widget.jobId, orElse: () => null);
  }

  void _scheduleApplicationSync({required bool isShortTerm}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<JobProvider>();
      if (isShortTerm) {
        provider.loadMyShortTermApplications(refresh: true);
      } else {
        provider.loadMyLongTermApplications(refresh: true);
      }
    });
  }

  _DetailActionState _buildLongTermPrimaryActionState({
    required JobPostingResponse job,
    required JobApplicationResponse? app,
    required bool isSyncingApplication,
    required JobProvider provider,
  }) {
    final isOfferPath = app?.remote == true || app?.negotiable == true;

    if (isSyncingApplication) {
      return const _DetailActionState(
        label: 'Đang đồng bộ đơn ứng tuyển',
        icon: Icons.sync,
        color: Colors.grey,
      );
    }

    if (app == null) {
      final jobStatus = job.status ?? JobStatus.open;
      return switch (jobStatus) {
        JobStatus.open => _DetailActionState(
          label: 'Ứng Tuyển Ngay',
          icon: Icons.send_outlined,
          color: AppTheme.themeBlueStart,
          enabled: true,
          onPressed: () => _showLongTermApplySheet(context, job),
        ),
        JobStatus.inProgress ||
        JobStatus.pendingApproval => const _DetailActionState(
          label: 'Chưa mở ứng tuyển',
          icon: Icons.hourglass_empty,
          color: Colors.grey,
        ),
        JobStatus.closed => const _DetailActionState(
          label: 'Đã đóng tuyển dụng',
          icon: Icons.lock_outline,
          color: Colors.grey,
        ),
        JobStatus.rejected => const _DetailActionState(
          label: 'Tin tuyển dụng không khả dụng',
          icon: Icons.cancel_outlined,
          color: Colors.red,
        ),
      };
    }

    final status = app.status ?? JobApplicationStatus.pending;
    return switch (status) {
      JobApplicationStatus.pending => const _DetailActionState(
        label: 'Đã nộp đơn',
        icon: Icons.check_circle_outline,
        color: Colors.grey,
      ),
      JobApplicationStatus.reviewed => const _DetailActionState(
        label: 'Đang chờ phản hồi',
        icon: Icons.hourglass_empty,
        color: Colors.grey,
      ),
      JobApplicationStatus.interviewScheduled ||
      JobApplicationStatus.interviewed => _DetailActionState(
        label: 'Lịch phỏng vấn',
        icon: Icons.record_voice_over_outlined,
        color: AppTheme.themeBlueStart,
        enabled: app.id != null,
        onPressed: app.id != null ? () => _openInterviewSchedule(app) : null,
      ),
      JobApplicationStatus.offerSent => _DetailActionState(
        label: provider.isRespondingToOffer
            ? 'Đang xử lý...'
            : 'Phản hồi đề nghị',
        icon: Icons.handshake_outlined,
        color: AppTheme.themeGreenStart,
        enabled: app.id != null && !provider.isRespondingToOffer,
        onPressed: (app.id != null && !provider.isRespondingToOffer)
            ? () => _showRespondToOfferDialog(app)
            : null,
      ),
      JobApplicationStatus.accepted =>
        isOfferPath
            ? _DetailActionState(
                label: 'Lịch phỏng vấn',
                icon: Icons.record_voice_over_outlined,
                color: AppTheme.themeBlueStart,
                enabled: app.id != null,
                onPressed: app.id != null
                    ? () => _openInterviewSchedule(app)
                    : null,
              )
            : _DetailActionState(
                label: _hasContractReady(app)
                    ? 'Ký hợp đồng'
                    : 'Chờ tạo hợp đồng',
                icon: Icons.description_outlined,
                color: _hasContractReady(app)
                    ? AppTheme.themeGreenStart
                    : Colors.grey,
                enabled: _hasContractReady(app),
                onPressed: _hasContractReady(app)
                    ? () => _openApplicationContract(app)
                    : null,
              ),
      JobApplicationStatus.offerAccepted => _DetailActionState(
        label: _hasContractReady(app) ? 'Ký hợp đồng' : 'Chờ tạo hợp đồng',
        icon: Icons.description_outlined,
        color: _hasContractReady(app) ? AppTheme.themeGreenStart : Colors.grey,
        enabled: _hasContractReady(app),
        onPressed: _hasContractReady(app)
            ? () => _openApplicationContract(app)
            : null,
      ),
      JobApplicationStatus.contractSigned => _DetailActionState(
        label: _hasContractReady(app) ? 'Xem hợp đồng' : 'Chờ đồng bộ hợp đồng',
        icon: Icons.description_outlined,
        color: _hasContractReady(app) ? AppTheme.themeGreenStart : Colors.grey,
        enabled: _hasContractReady(app),
        onPressed: _hasContractReady(app)
            ? () => _openApplicationContract(app)
            : null,
      ),
      JobApplicationStatus.offerRejected => const _DetailActionState(
        label: 'Đã từ chối đề nghị',
        icon: Icons.cancel_outlined,
        color: Colors.red,
      ),
      JobApplicationStatus.rejected => const _DetailActionState(
        label: 'Đơn đã bị từ chối',
        icon: Icons.cancel_outlined,
        color: Colors.red,
      ),
    };
  }

  bool _hasContractReady(JobApplicationResponse app) {
    final status = (app.contractStatus ?? '').toUpperCase();
    const readyStatuses = {
      'DRAFT',
      'PENDING_SIGNER',
      'PENDING_EMPLOYER',
      'SIGNED',
      'REJECTED',
      'CANCELLED',
    };
    return app.contractId != null || readyStatuses.contains(status);
  }

  _DetailActionState _buildShortTermPrimaryActionState({
    required ShortTermJobResponse job,
    required ShortTermApplicationResponse? app,
    required bool isSyncingApplication,
  }) {
    if (isSyncingApplication) {
      return const _DetailActionState(
        label: 'Đang đồng bộ đơn ứng tuyển',
        icon: Icons.sync,
        color: Colors.grey,
      );
    }

    if (app != null) {
      final status = app.status ?? ShortTermApplicationStatus.pending;
      return switch (status) {
        ShortTermApplicationStatus.pending => _DetailActionState(
          label: 'Rút đơn',
          icon: Icons.undo,
          color: Colors.red,
          enabled: app.id != null,
          outlined: true,
          onPressed: app.id != null
              ? () => _confirmShortTermWithdraw(app.id!)
              : null,
        ),
        ShortTermApplicationStatus.working ||
        ShortTermApplicationStatus.inProgress => _DetailActionState(
          label: 'Nộp bài',
          icon: Icons.upload_rounded,
          color: AppTheme.themePurpleStart,
          enabled: app.id != null,
          onPressed: app.id != null
              ? () => _showShortTermSubmitSheet(app)
              : null,
        ),
        ShortTermApplicationStatus.revisionRequired => _DetailActionState(
          label: 'Nộp lại',
          icon: Icons.upload_rounded,
          color: AppTheme.themeOrangeStart,
          enabled: app.id != null,
          onPressed: app.id != null
              ? () => _showShortTermSubmitSheet(app)
              : null,
        ),
        ShortTermApplicationStatus.accepted => const _DetailActionState(
          label: 'Đã được nhận',
          icon: Icons.check_circle_outline,
          color: AppTheme.themeBlueStart,
        ),
        ShortTermApplicationStatus.submitted ||
        ShortTermApplicationStatus.underReview => const _DetailActionState(
          label: 'Đang chờ duyệt',
          icon: Icons.hourglass_top,
          color: AppTheme.themeOrangeStart,
        ),
        ShortTermApplicationStatus.submittedOverdue => const _DetailActionState(
          label: 'Đã nộp trễ hạn',
          icon: Icons.schedule,
          color: Colors.red,
        ),
        ShortTermApplicationStatus.revisionResponseOverdue =>
          const _DetailActionState(
            label: 'Quá hạn phản hồi sửa',
            icon: Icons.warning_amber_outlined,
            color: Colors.red,
          ),
        ShortTermApplicationStatus.approved ||
        ShortTermApplicationStatus.completed => const _DetailActionState(
          label: 'Đã hoàn thành',
          icon: Icons.done_all,
          color: AppTheme.themeGreenStart,
        ),
        ShortTermApplicationStatus.paid => const _DetailActionState(
          label: 'Đã thanh toán',
          icon: Icons.payments_outlined,
          color: AppTheme.themeGreenStart,
        ),
        ShortTermApplicationStatus.rejected => const _DetailActionState(
          label: 'Đơn đã bị từ chối',
          icon: Icons.cancel_outlined,
          color: Colors.red,
        ),
        ShortTermApplicationStatus.cancelled => const _DetailActionState(
          label: 'Đơn đã bị hủy',
          icon: Icons.block_outlined,
          color: Colors.red,
        ),
        ShortTermApplicationStatus.withdrawn => const _DetailActionState(
          label: 'Đã rút đơn',
          icon: Icons.undo,
          color: Colors.grey,
        ),
        ShortTermApplicationStatus.autoCancelled => const _DetailActionState(
          label: 'Đã tự động hủy',
          icon: Icons.block_outlined,
          color: Colors.red,
        ),
        ShortTermApplicationStatus.cancellationRequested =>
          const _DetailActionState(
            label: 'Đang yêu cầu hủy',
            icon: Icons.cancel_outlined,
            color: Colors.red,
          ),
        ShortTermApplicationStatus.disputeOpened => const _DetailActionState(
          label: 'Đang tranh chấp',
          icon: Icons.gavel_outlined,
          color: AppTheme.warningColor,
        ),
      };
    }

    final jobStatus = job.status ?? ShortTermJobStatus.published;
    final isApplyable =
        jobStatus == ShortTermJobStatus.published && job.canApply == true;

    return switch (jobStatus) {
      ShortTermJobStatus.published => _DetailActionState(
        label: isApplyable ? 'Ứng Tuyển Ngay' : 'Không thể ứng tuyển',
        icon: Icons.send_outlined,
        color: isApplyable ? AppTheme.themeBlueStart : Colors.grey,
        enabled: isApplyable,
        onPressed: isApplyable ? () => _showApplySheet(context, job) : null,
      ),
      ShortTermJobStatus.draft ||
      ShortTermJobStatus.pendingApproval => const _DetailActionState(
        label: 'Chưa mở ứng tuyển',
        icon: Icons.hourglass_empty,
        color: Colors.grey,
      ),
      ShortTermJobStatus.cancelled ||
      ShortTermJobStatus.rejected ||
      ShortTermJobStatus.closed ||
      ShortTermJobStatus.autoCancelled => const _DetailActionState(
        label: 'Công việc không khả dụng',
        icon: Icons.lock_outline,
        color: Colors.red,
      ),
      _ => const _DetailActionState(
        label: 'Đang xử lý công việc',
        icon: Icons.work_outline,
        color: Colors.grey,
      ),
    };
  }

  Widget _buildBottomActionBar(_DetailActionState action) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: action.outlined
                ? OutlinedButton.icon(
                    onPressed: action.enabled ? action.onPressed : null,
                    icon: Icon(action.icon),
                    label: Text(
                      action.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: action.color,
                      side: BorderSide(
                        color: action.color.withValues(alpha: 0.7),
                      ),
                      disabledForegroundColor: action.color.withValues(
                        alpha: 0.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: action.enabled ? action.onPressed : null,
                    icon: Icon(action.icon),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: action.color,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: action.color.withValues(
                        alpha: 0.5,
                      ),
                      disabledForegroundColor: Colors.white70,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    label: Text(
                      action.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _openInterviewSchedule(JobApplicationResponse app) {
    if (app.id == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InterviewSchedulePage(
          applicationId: app.id,
          jobTitle: app.jobTitle,
        ),
      ),
    );
  }

  Future<void> _openApplicationContract(JobApplicationResponse app) async {
    if (app.contractId != null) {
      context.push('/contracts/${app.contractId}');
      return;
    }

    final contractProvider = context.read<ContractProvider>();
    if (contractProvider.contracts.isEmpty) {
      await contractProvider.loadMyContracts();
    }
    if (!mounted) return;

    final match = contractProvider.contracts
        .cast<ContractResponse?>()
        .firstWhere((c) => c!.applicationId == app.id, orElse: () => null);

    if (match != null) {
      context.push('/contracts/${match.id}');
      return;
    }

    ErrorHandler.showWarningSnackBar(
      context,
      'Chưa có hợp đồng cho đơn ứng tuyển này.',
    );
  }

  Future<void> _showRespondToOfferDialog(JobApplicationResponse app) async {
    final responseController = TextEditingController();
    final counterSalaryController = TextEditingController();
    final counterNoteController = TextEditingController();
    bool accepting = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: const Text('Phản hồi đề nghị'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Intent toggle
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => accepting = true),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: accepting
                              ? AppTheme.themeGreenStart.withValues(alpha: 0.1)
                              : null,
                          side: BorderSide(
                            color: accepting
                                ? AppTheme.themeGreenStart
                                : Colors.grey,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          'Chấp nhận',
                          style: TextStyle(
                            color: accepting
                                ? AppTheme.themeGreenStart
                                : Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => accepting = false),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: !accepting
                              ? Colors.red.withValues(alpha: 0.1)
                              : null,
                          side: BorderSide(
                            color: !accepting ? Colors.red : Colors.grey,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          'Từ chối',
                          style: TextStyle(
                            color: !accepting ? Colors.red : Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: responseController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú (tùy chọn)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                if (!accepting) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Đề xuất lại (tùy chọn):',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: counterSalaryController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Đề xuất lương (VNĐ, tùy chọn)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: counterNoteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Yêu cầu thêm (tùy chọn)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx, accepting),
              style: ElevatedButton.styleFrom(
                backgroundColor: accepting
                    ? AppTheme.themeGreenStart
                    : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                accepting ? 'Xác nhận chấp nhận' : 'Xác nhận từ chối',
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed == null || !mounted) return;
    final provider = context.read<JobProvider>();
    final counterSalary = int.tryParse(counterSalaryController.text.trim());
    final success = await provider.respondToOffer(
      applicationId: app.id!,
      accept: confirmed,
      candidateOfferResponse: responseController.text.trim().isNotEmpty
          ? responseController.text.trim()
          : null,
      counterSalaryAmount: confirmed ? null : counterSalary,
      counterAdditionalRequirements: confirmed
          ? null
          : counterNoteController.text.trim().isNotEmpty
          ? counterNoteController.text.trim()
          : null,
    );
    if (!mounted) return;
    if (success) {
      ErrorHandler.showSuccessSnackBar(
        context,
        confirmed ? 'Đã chấp nhận đề nghị.' : 'Đã từ chối đề nghị.',
      );
      provider.loadMyLongTermApplications();
    } else {
      ErrorHandler.showErrorSnackBar(
        context,
        provider.errorMessage ?? 'Không thể phản hồi đề nghị.',
      );
    }
  }

  // ==================== SHARED WIDGETS ====================

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.themeBlueStart),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildUrgencyChip(JobUrgency urgency) {
    final (label, color) = switch (urgency) {
      JobUrgency.urgent => ('Gấp', AppTheme.themeOrangeStart),
      JobUrgency.veryUrgent => ('Rất gấp', Colors.red),
      JobUrgency.asap => ('ASAP', Colors.red.shade700),
      _ => ('', Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Simple data holder for timeline steps
class _TimelineStep {
  final String label;
  final String? time;
  final IconData icon;
  final bool isCompleted;

  const _TimelineStep({
    required this.label,
    this.time,
    required this.icon,
    required this.isCompleted,
  });
}

class _DetailActionState {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final bool outlined;
  final VoidCallback? onPressed;

  const _DetailActionState({
    required this.label,
    required this.icon,
    required this.color,
    this.enabled = false,
    this.outlined = false,
    this.onPressed,
  });
}
