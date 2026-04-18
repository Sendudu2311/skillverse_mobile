import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/job_provider.dart';
import '../../../data/models/job_models.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/animated_list_item.dart';
import '../../widgets/common_loading.dart';
import '../../widgets/skeleton_loaders.dart';
import '../../themes/app_theme.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/error_state_widget.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/enum_helper.dart';
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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<JobProvider>();
      if (provider.myLongTermApplications.isEmpty) {
        provider.loadMyLongTermApplications();
      }
      if (provider.myShortTermApplications.isEmpty) {
        provider.loadMyShortTermApplications();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<JobProvider>();
      if (provider.hasMoreShortTermApps &&
          !provider.isLoadingMoreShortTermApps) {
        provider.loadMoreShortTermApplications();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SkillVerseAppBar(
        title: 'Đơn Ứng Tuyển',
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
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (_, __) => const ListItemSkeleton(lineCount: 3),
            );
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

    if (apps.isEmpty && provider.hasErrorLongTermApps) {
      return ErrorStateWidget(
        title: 'Không thể tải đơn ứng tuyển',
        message:
            provider.longTermApplicationsError ??
            'Đã có lỗi xảy ra khi tải đơn ứng tuyển của bạn.',
        onRetry: () => provider.loadMyLongTermApplications(refresh: true),
      );
    }

    if (apps.isEmpty) {
      return _buildEmptyState('Chưa có đơn ứng tuyển nào', isLongTerm: true);
    }

    return RefreshIndicator(
      onRefresh: () async => provider.loadMyLongTermApplications(refresh: true),
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
              StatusBadge(status: app.status?.toApiString() ?? 'PENDING'),
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
          _buildStatusTimeline(
            app.status?.toApiString() ?? 'PENDING',
            isLongTerm: true,
            isOfferPath: app.remote == true || app.negotiable == true,
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
                  'Nộp ${DateTimeHelper.formatSmart(DateTimeHelper.tryParseIso8601(app.appliedAt!) ?? DateTime.now())}',
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

          // Offer section: show when OFFER_SENT or after offer response
          if (app.status == JobApplicationStatus.offerSent ||
              app.status == JobApplicationStatus.offerAccepted ||
              app.status == JobApplicationStatus.offerRejected) ...[
            const SizedBox(height: 10),
            _buildOfferSection(app),
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

    if (apps.isEmpty &&
        provider.hasErrorShortTermApps &&
        !provider.isLoadingShortTermApps) {
      return ErrorStateWidget(
        title: 'Không thể tải đơn freelance',
        message:
            provider.shortTermAppsError ??
            'Đã có lỗi xảy ra khi tải danh sách freelance đã ứng tuyển.',
        onRetry: () => provider.loadMyShortTermApplications(refresh: true),
      );
    }

    if (apps.isEmpty && !provider.isLoadingShortTermApps) {
      return _buildEmptyState('Chưa có đơn freelance nào', isLongTerm: false);
    }

    return RefreshIndicator(
      onRefresh: () async =>
          provider.loadMyShortTermApplications(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: apps.length + (provider.hasMoreShortTermApps ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == apps.length) {
            if (provider.isLoadingMoreShortTermApps) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: CommonLoading.center(),
              );
            }
            if (provider.hasErrorShortTermApps) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () => provider.loadMoreShortTermApplications(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử tải thêm'),
                  ),
                ),
              );
            }
            if (!provider.hasMoreShortTermApps) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Đã hiển thị tất cả',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: TextButton(
                  onPressed: () => provider.loadMoreShortTermApplications(),
                  child: const Text('Xem thêm'),
                ),
              ),
            );
          }
          return AnimatedListItem(
            index: index,
            child: _buildShortTermAppCard(apps[index], provider),
          );
        },
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
              StatusBadge(status: app.status?.toApiString() ?? 'PENDING'),
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
            app.status?.toApiString() ?? 'PENDING',
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
                  'Nộp ${DateTimeHelper.formatSmart(DateTimeHelper.tryParseIso8601(app.appliedAt!) ?? DateTime.now())}',
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
                        app.status ==
                            ShortTermApplicationStatus.revisionRequired
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

  void _showSubmitSheet(
    ShortTermApplicationResponse app,
    JobProvider provider,
  ) {
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
                size: 14,
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
              if (notes.length > 1) ...[
                const SizedBox(width: 4),
                Text(
                  '(lần ${notes.length})',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.themeOrangeStart,
                  ),
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
          if (latest.specificIssues != null &&
              latest.specificIssues!.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...latest.specificIssues!.map(
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

  // ==================== TIMELINE WIDGET ====================

  Widget _buildStatusTimeline(
    String currentStatus, {
    required bool isLongTerm,
    bool isOfferPath = false,
  }) {
    if (isLongTerm) {
      return _buildLongTermDots(currentStatus, isOfferPath: isOfferPath);
    }
    return _buildShortTermTimeline(currentStatus);
  }

  /// Long-term: 5 labeled steps aligned with full backend status flow.
  ///
  /// Steps: Nộp đơn → Xét duyệt → Phỏng vấn → Đề nghị → Ký HĐ
  /// Fail states: REJECTED, OFFER_REJECTED → red dot at the rejection step.
  Widget _buildLongTermDots(String currentStatus, {bool isOfferPath = false}) {
    // Direct-accept path (Onsite/Fixed): no Offer step
    // Offer path (Remote/Negotiable): full Offer negotiation step
    final stepLabels = isOfferPath
        ? ['Nộp đơn', 'Xét duyệt', 'Phỏng vấn', 'Đề nghị', 'Ký HĐ']
        : ['Nộp đơn', 'Xét duyệt', 'Phỏng vấn', 'Trúng tuyển', 'Ký HĐ'];

    // Offer path: OFFER_* statuses map to step 3 (Đề nghị); ACCEPTED → also step 3 (post-offer)
    // Direct path: ACCEPTED maps to step 3 (Trúng tuyển); OFFER_* statuses won't appear
    final statusToStep = isOfferPath
        ? const {
            'PENDING': 0,
            'REVIEWED': 1,
            'INTERVIEW_SCHEDULED': 2,
            'INTERVIEWED': 2,
            'OFFER_SENT': 3,
            'OFFER_ACCEPTED': 3,
            'OFFER_REJECTED': 3,
            'ACCEPTED': 2,
            'CONTRACT_SIGNED': 4,
          }
        : const {
            'PENDING': 0,
            'REVIEWED': 1,
            'INTERVIEW_SCHEDULED': 2,
            'INTERVIEWED': 2,
            'ACCEPTED': 3,
            'CONTRACT_SIGNED': 4,
          };

    final failedStatuses = isOfferPath
        ? const {'REJECTED', 'OFFER_REJECTED', 'CANCELLED', 'WITHDRAWN'}
        : const {'REJECTED', 'CANCELLED', 'WITHDRAWN'};

    final upper = currentStatus.toUpperCase();
    final isRejected = failedStatuses.contains(upper);
    // Fail step: REJECTED at review (step 1), OFFER_REJECTED at offer (step 3)
    final currentIndex = isRejected
        ? (upper == 'OFFER_REJECTED' ? 3 : 1)
        : (statusToStep[upper] ?? 0);

    final String? failLabel;
    if (upper == 'OFFER_REJECTED') {
      failLabel = 'Từ chối đề nghị';
    } else if (isRejected) {
      failLabel = 'Đơn bị từ chối';
    } else {
      failLabel = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(stepLabels.length * 2 - 1, (i) {
            if (i.isOdd) {
              final stepIdx = i ~/ 2;
              final isCompleted = !isRejected && currentIndex > stepIdx;
              return Expanded(
                child: Container(
                  height: 2,
                  color: isRejected && stepIdx >= currentIndex
                      ? Colors.red.withValues(alpha: 0.2)
                      : isCompleted
                      ? AppTheme.themeGreenStart
                      : Theme.of(context).dividerColor,
                ),
              );
            }

            final stepIdx = i ~/ 2;
            final isCurrent = currentIndex == stepIdx;
            final isCompleted = !isRejected && currentIndex > stepIdx;
            final isFailDot = isRejected && isCurrent;

            final Color dotColor;
            if (isFailDot) {
              dotColor = Colors.red;
            } else if (isCompleted) {
              dotColor = AppTheme.themeGreenStart;
            } else if (isCurrent) {
              dotColor = AppTheme.themeBlueStart;
            } else {
              dotColor = Theme.of(context).dividerColor;
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isCurrent ? 14 : 10,
                  height: isCurrent ? 14 : 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    border: isCurrent
                        ? Border.all(
                            color: dotColor.withValues(alpha: 0.35),
                            width: 2,
                          )
                        : null,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 7, color: Colors.white)
                      : isFailDot
                      ? const Icon(Icons.close, size: 7, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 3),
                Text(
                  stepLabels[stepIdx],
                  style: TextStyle(
                    fontSize: 9,
                    color: isFailDot
                        ? Colors.red
                        : isCurrent || isCompleted
                        ? Theme.of(context).textTheme.bodySmall?.color
                        : Theme.of(context).hintColor,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            );
          }),
        ),

        // Failure label below timeline
        if (failLabel != null) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.cancel_outlined, size: 11, color: Colors.red),
              const SizedBox(width: 4),
              Text(
                failLabel,
                style: const TextStyle(fontSize: 10, color: Colors.red),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Short-term: 4 labeled steps with failure / revision visual states.
  ///
  /// Happy:    green completed steps → blue current dot
  /// Revision: orange current dot + inline warning text
  /// Failure:  red first dot + red connectors + failure label
  Widget _buildShortTermTimeline(String currentStatus) {
    const stepLabels = ['Đã nộp', 'Đang làm', 'Chờ duyệt', 'Hoàn thành'];

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

    final upper = currentStatus.toUpperCase();
    final isRejected = failedStatuses.contains(upper);
    final isRevision = revisionStatuses.contains(upper);
    final currentIndex = isRejected ? 0 : (statusToStep[upper] ?? 0);

    String? warningText;
    if (isRevision) {
      warningText = switch (upper) {
        'REVISION_REQUIRED' => 'Cần chỉnh sửa — nhấn "Nộp lại" để resubmit',
        'REVISION_RESPONSE_OVERDUE' => 'Quá hạn phản hồi yêu cầu chỉnh sửa',
        _ => 'Nộp bài trễ hạn',
      };
    } else if (isRejected) {
      warningText = switch (upper) {
        'DISPUTE_OPENED' => 'Đang tranh chấp',
        'CANCELLATION_REQUESTED' => 'Đang yêu cầu hủy',
        _ => 'Đơn ứng tuyển đã kết thúc',
      };
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                      : Theme.of(context).dividerColor,
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
              dotColor = Theme.of(context).dividerColor;
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isCurrent ? 14 : 10,
                  height: isCurrent ? 14 : 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    border: isCurrent
                        ? Border.all(
                            color: dotColor.withValues(alpha: 0.35),
                            width: 2,
                          )
                        : null,
                  ),
                  child: (isCompleted || (isRejected && stepIdx == 0))
                      ? Icon(
                          isRejected && stepIdx == 0
                              ? Icons.close
                              : Icons.check,
                          size: 7,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(height: 3),
                Text(
                  stepLabels[stepIdx],
                  style: TextStyle(
                    fontSize: 9,
                    color:
                        isCurrent || isCompleted || (isRejected && stepIdx == 0)
                        ? (isRejected && stepIdx == 0 ? Colors.red : null)
                        : Theme.of(context).hintColor,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            );
          }),
        ),

        // Warning / failure hint below the row
        if (warningText != null) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(
                isRevision ? Icons.rate_review_outlined : Icons.cancel_outlined,
                size: 11,
                color: isRevision ? AppTheme.themeOrangeStart : Colors.red,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  warningText,
                  style: TextStyle(
                    fontSize: 10,
                    color: isRevision ? AppTheme.themeOrangeStart : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
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

  // ==================== OFFER SECTION ====================

  Widget _buildOfferSection(JobApplicationResponse app) {
    final isPending = app.status == JobApplicationStatus.offerSent;
    final isResponding = context.watch<JobProvider>().isRespondingToOffer;
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
          // Header row: icon + title + round badge
          Row(
            children: [
              Icon(Icons.local_offer_outlined, size: 14, color: headerColor),
              const SizedBox(width: 6),
              Text(
                isPending ? 'Đề nghị từ nhà tuyển dụng' : 'Đề nghị việc làm',
                style: TextStyle(
                  fontSize: 12,
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
            ..._buildOfferSummaryContent(app, compact: true),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Nhà tuyển dụng chưa cung cấp đủ thông tin đề nghị.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).hintColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          // Previous candidate response (if already responded)
          if ((app.candidateOfferResponse?.trim().isNotEmpty ?? false) ||
              app.counterSalaryAmount != null ||
              (app.counterAdditionalRequirements?.trim().isNotEmpty ??
                  false)) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withValues(alpha: 0.4),
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
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).hintColor,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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

          // Accept / Reject buttons — only when status is OFFER_SENT
          if (isPending) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isResponding
                        ? null
                        : () => _showOfferResponseDialog(app, accept: false),
                    icon: const Icon(Icons.close, size: 14),
                    label: const Text(
                      'Từ chối',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isResponding
                        ? null
                        : () => _showOfferResponseDialog(app, accept: true),
                    icon: const Icon(Icons.check, size: 14),
                    label: const Text(
                      'Chấp nhận',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.themeGreenStart,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
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

  List<Widget> _buildOfferSummaryContent(
    JobApplicationResponse app, {
    required bool compact,
  }) {
    final widgets = <Widget>[];

    if (app.offerDetails?.trim().isNotEmpty ?? false) {
      widgets.add(
        Text(
          app.offerDetails!.trim(),
          style: TextStyle(fontSize: compact ? 12 : 13, height: 1.5),
          maxLines: compact ? 4 : null,
          overflow: compact ? TextOverflow.ellipsis : null,
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
        Icon(icon, size: 13, color: Theme.of(context).hintColor),
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

  void _showOfferResponseDialog(
    JobApplicationResponse app, {
    required bool accept,
  }) {
    final controller = TextEditingController();
    final counterSalaryController = TextEditingController();
    final counterNoteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(accept ? 'Chấp nhận đề nghị' : 'Từ chối đề nghị'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                accept
                    ? 'Bạn sắp chấp nhận đề nghị từ nhà tuyển dụng.'
                    : 'Bạn sắp từ chối đề nghị. ${(app.offerRound ?? 0) >= 2 ? "Đây là lần từ chối cuối — đơn sẽ kết thúc." : "Nhà tuyển dụng có thể gửi thêm 1 đề nghị nữa."}',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Lời nhắn cho nhà tuyển dụng (tùy chọn)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              if (!accept) ...[
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
                    hintText: 'Đề xuất lương (VNĐ)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: counterNoteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Yêu cầu thêm (tùy chọn)',
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<JobProvider>();
              final counterSalary = int.tryParse(
                counterSalaryController.text.trim(),
              );
              final ok = await provider.respondToOffer(
                applicationId: app.id!,
                accept: accept,
                candidateOfferResponse: controller.text.trim().isEmpty
                    ? null
                    : controller.text.trim(),
                counterSalaryAmount: accept ? null : counterSalary,
                counterAdditionalRequirements: accept
                    ? null
                    : counterNoteController.text.trim().isEmpty
                    ? null
                    : counterNoteController.text.trim(),
              );
              if (mounted) {
                if (ok) {
                  ErrorHandler.showSuccessSnackBar(
                    context,
                    accept ? 'Đã chấp nhận đề nghị' : 'Đã từ chối đề nghị',
                  );
                } else {
                  ErrorHandler.showErrorSnackBar(
                    context,
                    provider.errorMessage ?? 'Có lỗi xảy ra',
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accept ? AppTheme.themeGreenStart : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(accept ? 'Xác nhận chấp nhận' : 'Xác nhận từ chối'),
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
