import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/job_provider.dart';
import '../../../data/models/job_models.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/common_loading.dart';
import '../../themes/app_theme.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/utils/date_time_helper.dart';
import 'job_detail_page.dart';

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
        itemBuilder: (context, index) =>
            _buildAnimatedCard(index, _buildLongTermAppCard(apps[index])),
      ),
    );
  }

  Widget _buildLongTermAppCard(JobApplicationResponse app) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: app.jobId != null
          ? () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    JobDetailPage(jobId: app.jobId!, isShortTerm: false),
              ))
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
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (app.recruiterCompanyName != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.business,
                              size: 13, color: Theme.of(context).hintColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(app.recruiterCompanyName!,
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(app.status?.name ?? 'PENDING'),
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
                Icon(Icons.access_time,
                    size: 12, color: Theme.of(context).hintColor),
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
        itemBuilder: (context, index) => _buildAnimatedCard(
            index, _buildShortTermAppCard(apps[index], provider)),
      ),
    );
  }

  Widget _buildShortTermAppCard(
      ShortTermApplicationResponse app, JobProvider provider) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: app.jobId != null
          ? () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    JobDetailPage(jobId: app.jobId!, isShortTerm: true),
              ))
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
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildStatusBadge(app.status ?? 'PENDING'),
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
          _buildStatusTimeline(app.status ?? 'PENDING', isLongTerm: false),

          // Applied date
          if (app.appliedAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time,
                    size: 12, color: Theme.of(context).hintColor),
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

          // Actions row
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Withdraw for pending
              if (app.status == 'PENDING' || app.status == 'APPLIED')
                TextButton.icon(
                  onPressed: () => _confirmWithdraw(app.id!, provider),
                  icon: const Icon(Icons.undo, size: 14),
                  label:
                      const Text('Rút đơn', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              final success =
                  await provider.withdrawApplication(applicationId);
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã rút đơn thành công'),
                    backgroundColor: AppTheme.themeGreenStart,
                  ),
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

  // ==================== TIMELINE WIDGET ====================

  Widget _buildStatusTimeline(String currentStatus,
      {required bool isLongTerm}) {
    final steps = isLongTerm
        ? ['PENDING', 'REVIEWED', 'ACCEPTED']
        : ['APPLIED', 'REVIEWED', 'APPROVED', 'IN_PROGRESS', 'COMPLETED'];

    // Check if rejected/cancelled (show as failed state)
    final isRejected = currentStatus == 'REJECTED' ||
        currentStatus == 'CANCELLED' ||
        currentStatus == 'WITHDRAWN';

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
                    width: 2)
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
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCard(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('app_card_$index'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 60).clamp(0, 300)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: child,
    );
  }

  Widget _buildStatusBadge(String status) {
    final (label, color) = switch (status.toUpperCase()) {
      'PENDING' || 'APPLIED' => ('Đang chờ', AppTheme.themeOrangeStart),
      'REVIEWED' => ('Đã xem', AppTheme.themeBlueStart),
      'ACCEPTED' || 'APPROVED' => ('Đã chấp nhận', AppTheme.themeGreenStart),
      'REJECTED' => ('Bị từ chối', Colors.red),
      'IN_PROGRESS' => ('Đang làm', AppTheme.themeBlueStart),
      'SUBMITTED' => ('Đã nộp bài', AppTheme.themePurpleStart),
      'COMPLETED' => ('Hoàn thành', AppTheme.themeGreenStart),
      'PAID' => ('Đã thanh toán', AppTheme.themeGreenEnd),
      'WITHDRAWN' => ('Đã rút đơn', Colors.blueGrey),
      'CANCELLED' => ('Đã hủy', Colors.grey),
      _ => (status, Colors.grey),
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
            color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildEmptyState(String message, {required bool isLongTerm}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).hintColor.withValues(alpha: 0.4)),
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
