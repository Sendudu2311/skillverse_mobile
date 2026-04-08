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
        provider.loadMyApplications();
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
                    Row(
                      children: [
                        Icon(
                          Icons.business,
                          size: 16,
                          color: Theme.of(context).hintColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          job.recruiterCompanyName ?? 'Công ty',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    if (job.createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Đăng ${DateTimeHelper.formatRelativeTime(DateTime.parse(job.createdAt!))}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Key Info
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (job.minBudget != null && job.maxBudget != null)
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
                          DateTime.parse(job.deadline!),
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

        // Bottom apply button
        Positioned(
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
                child: ElevatedButton(
                  onPressed:
                      context.watch<JobProvider>().hasAppliedToJob(widget.jobId)
                      ? null
                      : () => _showLongTermApplySheet(context, job),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.themeBlueStart,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    context.watch<JobProvider>().hasAppliedToJob(widget.jobId)
                        ? 'Đã Ứng Tuyển'
                        : 'Ứng Tuyển Ngay',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== SHORT-TERM DETAIL ====================

  Widget _buildShortTermDetail(ShortTermJobResponse job) {
    // Determine bottom button state based on job status
    final hasApplied = context.watch<JobProvider>().hasAppliedToShortTermJob(
      widget.jobId,
    );
    final jobStatus = job.status ?? ShortTermJobStatus.published;

    // Button logic
    final bool isApplyable =
        jobStatus == ShortTermJobStatus.published &&
        job.canApply == true &&
        !hasApplied;

    String bottomLabel;
    Color bottomColor;
    bool bottomEnabled;

    switch (jobStatus) {
      case ShortTermJobStatus.draft:
      case ShortTermJobStatus.pendingApproval:
        bottomLabel = 'Chưa mở ứng tuyển';
        bottomColor = Colors.grey;
        bottomEnabled = false;
      case ShortTermJobStatus.published:
        bottomLabel = hasApplied ? 'Đã Ứng Tuyển' : 'Ứng Tuyển Ngay';
        bottomColor = hasApplied
            ? Colors.grey.shade400
            : AppTheme.themeBlueStart;
        bottomEnabled = isApplyable;
      case ShortTermJobStatus.inProgress:
      case ShortTermJobStatus.submitted:
      case ShortTermJobStatus.underReview:
      case ShortTermJobStatus.approved:
        bottomLabel = 'Đang Thực Hiện';
        bottomColor = AppTheme.themeOrangeStart;
        bottomEnabled = false;
      case ShortTermJobStatus.completed:
        bottomLabel = 'Đã Hoàn Thành';
        bottomColor = AppTheme.themeGreenStart;
        bottomEnabled = false;
      case ShortTermJobStatus.paid:
        bottomLabel = 'Đã Thanh Toán';
        bottomColor = AppTheme.themeGreenStart;
        bottomEnabled = false;
      case ShortTermJobStatus.cancelled:
      case ShortTermJobStatus.rejected:
        bottomLabel = 'Đã Hủy';
        bottomColor = Colors.red;
        bottomEnabled = false;
      default:
        bottomLabel = 'Ứng Tuyển Ngay';
        bottomColor = AppTheme.themeBlueStart;
        bottomEnabled = isApplyable;
    }

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
                      Row(
                        children: [
                          Icon(
                            Icons.business,
                            size: 16,
                            color: Theme.of(context).hintColor,
                          ),
                          const SizedBox(width: 6),
                          Text(job.recruiterInfo!.companyName!),
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
                        ],
                      ),
                    ],
                    if (job.createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Đăng ${DateTimeHelper.formatRelativeTime(DateTime.parse(job.createdAt!))}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ====== PROGRESS TIMELINE ======
              _buildProgressTimeline(job),

              const SizedBox(height: 16),

              // Key Info
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (job.budget != null)
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
                          DateTime.parse(job.deadline!),
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

        // ====== DYNAMIC BOTTOM BUTTON ======
        Positioned(
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
                child: ElevatedButton(
                  onPressed: bottomEnabled
                      ? () => _showApplySheet(context, job)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bottomColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: bottomColor.withValues(alpha: 0.5),
                    disabledForegroundColor: Colors.white70,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    bottomLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
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
                        DateTimeHelper.formatDate(DateTime.parse(step.time!)),
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
