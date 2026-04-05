import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/job_provider.dart';
import '../../../data/models/job_models.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/animated_list_item.dart';
import '../../widgets/common_loading.dart';
import '../../themes/app_theme.dart';
import '../../widgets/status_badge.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../../core/utils/error_handler.dart';
import 'job_detail_page.dart';
import 'short_term_submit_sheet.dart';

class MyApplicationsPage extends StatefulWidget {
  const MyApplicationsPage({super.key});

  @override
  State<MyApplicationsPage> createState() => _MyApplicationsPageState();
}

class _MyApplicationsPageState extends State<MyApplicationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<JobProvider>();
      provider.loadMyApplications();
      provider.loadMyShortTermApplications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn Ứng Tuyển'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Việc Làm'),
            Tab(text: 'Freelance'),
          ],
        ),
      ),
      body: Consumer<JobProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingApplications) {
            return CommonLoading.center(message: 'Đang tải...');
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildLongTermApplications(provider),
              _buildShortTermApplications(provider),
            ],
          );
        },
      ),
    );
  }

  // ==================== LONG-TERM APPLICATIONS ====================

  Widget _buildLongTermApplications(JobProvider provider) {
    final apps = provider.myLongTermApplications;

    if (apps.isEmpty) {
      return _buildEmptyState('Chưa có đơn ứng tuyển nào', isLongTerm: true);
    }

    return RefreshIndicator(
      onRefresh: () async => provider.loadMyApplications(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: apps.length,
        itemBuilder: (context, index) => AnimatedListItem(
          index: index,
          child: _buildLongTermAppCard(apps[index]),
        ),
      ),
    );
  }

  Widget _buildLongTermAppCard(JobApplicationResponse app) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: app.jobId != null
          ? () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    JobDetailPage(jobId: app.jobId!, isShortTerm: false),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.jobTitle ?? 'Không có tiêu đề',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (app.recruiterCompanyName != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.business,
                            size: 13,
                            color: Theme.of(context).hintColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              app.recruiterCompanyName!,
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: app.status?.name ?? 'PENDING'),
            ],
          ),

          // Salary info
          if (app.minBudget != null && app.maxBudget != null) ...[
            const SizedBox(height: 8),
            Text(
              '${NumberFormatter.formatPrice(app.minBudget!)} - ${NumberFormatter.formatCurrency(app.maxBudget!)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.themeGreenStart,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          // Timeline progress
          const SizedBox(height: 12),
          _buildStatusTimeline(app.status?.name ?? 'PENDING', isLongTerm: true),

          // Applied date
          if (app.appliedAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: Theme.of(context).hintColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'Nộp ${DateTimeHelper.formatSmart(DateTime.parse(app.appliedAt!))}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],

          // Messages from recruiter
          if (app.status == JobApplicationStatus.accepted &&
              app.acceptanceMessage != null) ...[
            const SizedBox(height: 10),
            _buildRecruiterMessage(
              app.acceptanceMessage!,
              AppTheme.themeGreenStart,
              Icons.thumb_up_outlined,
            ),
          ],
          if (app.status == JobApplicationStatus.rejected &&
              app.rejectionReason != null) ...[
            const SizedBox(height: 10),
            _buildRecruiterMessage(
              app.rejectionReason!,
              Colors.red,
              Icons.info_outline,
            ),
          ],

          // Tap hint
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Xem chi tiết →',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.themeBlueStart,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== SHORT-TERM APPLICATIONS ====================

  Widget _buildShortTermApplications(JobProvider provider) {
    final apps = provider.myShortTermApplications;

    if (apps.isEmpty) {
      return _buildEmptyState('Chưa có đơn freelance nào', isLongTerm: false);
    }

    return RefreshIndicator(
      onRefresh: () async => provider.loadMyShortTermApplications(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: apps.length,
        itemBuilder: (context, index) => AnimatedListItem(
          index: index,
          child: _buildShortTermAppCard(apps[index], provider),
        ),
      ),
    );
  }

  Widget _buildShortTermAppCard(
    ShortTermApplicationResponse app,
    JobProvider provider,
  ) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: app.jobId != null
          ? () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    JobDetailPage(jobId: app.jobId!, isShortTerm: true),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  app.jobTitle ?? 'Không có tiêu đề',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusBadge(status: app.status?.name ?? 'PENDING'),
            ],
          ),

          const SizedBox(height: 8),

          // Proposed info
          if (app.proposedPrice != null)
            Text(
              'Giá đề xuất: ${NumberFormatter.formatCurrency(app.proposedPrice!)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.themeBlueStart,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (app.proposedDuration != null) ...[
            const SizedBox(height: 2),
            Text(
              'Thời gian: ${app.proposedDuration}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],

          // Timeline progress
          const SizedBox(height: 12),
          _buildStatusTimeline(
            app.status?.name ?? 'PENDING',
            isLongTerm: false,
          ),

          // Applied date
          if (app.appliedAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: Theme.of(context).hintColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'Nộp ${DateTimeHelper.formatSmart(DateTime.parse(app.appliedAt!))}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],

          // Revision notes (khi bị yêu cầu sửa)
          if (app.status == ShortTermApplicationStatus.revisionRequired &&
              app.revisionNotes != null &&
              app.revisionNotes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildRevisionNotes(app.revisionNotes!),
          ],

          // Actions row
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Withdraw for pending
              if (app.status == ShortTermApplicationStatus.pending)
                TextButton.icon(
                  onPressed: () => _confirmWithdraw(app.id!, provider),
                  icon: const Icon(Icons.undo, size: 14),
                  label: const Text('Rút đơn', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                )
              // Nộp bài khi đang làm hoặc cần sửa lại
              else if (app.status == ShortTermApplicationStatus.working ||
                  app.status == ShortTermApplicationStatus.inProgress ||
                  app.status == ShortTermApplicationStatus.revisionRequired)
                ElevatedButton.icon(
                  onPressed: app.id != null
                      ? () => _showSubmitSheet(app, provider)
                      : null,
                  icon: const Icon(Icons.upload_rounded, size: 14),
                  label: Text(
                    app.status == ShortTermApplicationStatus.revisionRequired
                        ? 'Nộp lại'
                        : 'Nộp bài',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        app.status == ShortTermApplicationStatus.revisionRequired
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
                )
              else
                const SizedBox.shrink(),

              // Tap hint
              Text(
                'Xem chi tiết →',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.themeBlueStart,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmWithdraw(int applicationId, JobProvider provider) {
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
              Navigator.of(ctx).pop();
              final success = await provider.withdrawApplication(applicationId);
              if (mounted && success) {
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

  void _showSubmitSheet(ShortTermApplicationResponse app, JobProvider provider) {
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
      if (submitted == true) {
        provider.loadMyShortTermApplications();
      }
    });
  }

  Widget _buildRevisionNotes(List<RevisionNoteResponse> notes) {
    final latest = notes.last;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.themeOrangeStart.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.themeOrangeStart.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rate_review_outlined, size: 14, color: AppTheme.themeOrangeStart),
              const SizedBox(width: 6),
              Text(
                'Yêu cầu chỉnh sửa',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.themeOrangeStart,
                ),
              ),
              if (notes.length > 1) ...[
                const SizedBox(width: 4),
                Text(
                  '(lần ${notes.length})',
                  style: TextStyle(fontSize: 11, color: AppTheme.themeOrangeStart),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            latest.note ?? '',
            style: const TextStyle(fontSize: 12),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (latest.specificIssues != null && latest.specificIssues!.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...latest.specificIssues!.map(
              (issue) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 12)),
                    Expanded(child: Text(issue, style: const TextStyle(fontSize: 12))),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== TIMELINE WIDGET ====================

  Widget _buildStatusTimeline(
    String currentStatus, {
    required bool isLongTerm,
  }) {
    final steps = isLongTerm
        ? ['PENDING', 'REVIEWED', 'ACCEPTED']
        : ['PENDING', 'WORKING', 'SUBMITTED', 'UNDER_REVIEW', 'APPROVED', 'COMPLETED'];

    // Check if rejected/cancelled (show as failed state)
    final isRejected =
        currentStatus == 'REJECTED' ||
        currentStatus == 'CANCELLED' ||
        currentStatus == 'WITHDRAWN' ||
        currentStatus == 'AUTO_CANCELLED' ||
        currentStatus == 'CANCELLATION_REQUESTED';

    final currentIndex = steps.indexOf(currentStatus.toUpperCase());

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final stepIdx = i ~/ 2;
          final isCompleted = !isRejected && currentIndex > stepIdx;
          return Expanded(
            child: Container(
              height: 2,
              color: isCompleted
                  ? AppTheme.themeGreenStart
                  : Theme.of(context).dividerColor,
            ),
          );
        }

        // Step dot
        final stepIdx = i ~/ 2;
        final isCurrent = !isRejected && currentIndex == stepIdx;
        final isCompleted = !isRejected && currentIndex > stepIdx;

        return Container(
          width: isCurrent ? 14 : 10,
          height: isCurrent ? 14 : 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isRejected && stepIdx == 0
                ? Colors.red
                : isCompleted
                ? AppTheme.themeGreenStart
                : isCurrent
                ? AppTheme.themeBlueStart
                : Theme.of(context).dividerColor,
            border: isCurrent
                ? Border.all(
                    color: AppTheme.themeBlueStart.withValues(alpha: 0.3),
                    width: 2,
                  )
                : null,
          ),
          child: isCompleted
              ? const Icon(Icons.check, size: 7, color: Colors.white)
              : null,
        );
      }),
    );
  }

  // ==================== SHARED WIDGETS ====================

  Widget _buildRecruiterMessage(String message, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(fontSize: 12, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, {required bool isLongTerm}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Theme.of(context).hintColor.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Khám phá việc làm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.themeBlueStart,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
