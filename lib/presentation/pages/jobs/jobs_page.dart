import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/job_provider.dart';
import '../../../data/models/job_models.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/skeleton_loaders.dart';
import '../../widgets/animated_list_item.dart';
import '../../themes/app_theme.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/utils/date_time_helper.dart';
import 'job_detail_page.dart';
import 'my_applications_page.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // Filter state
  bool _filterRemote = false;
  String? _filterUrgency;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<JobProvider>();
      provider.loadPublicJobs();
      provider.loadShortTermJobs();
      // Pre-load applications for "Đã ứng tuyển" badges
      provider.loadMyApplications();
      provider.loadMyShortTermApplications();
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      context.read<JobProvider>().setSelectedTab(_tabController.index);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<JobProvider>().searchJobs(query);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildSearchBar()),
                  const SizedBox(width: 8),
                  _buildMyApplicationsButton(),
                ],
              ),
              const SizedBox(height: 12),
              _buildTabBar(),
              // Filter chips (short-term only)
              Consumer<JobProvider>(
                builder: (context, provider, _) {
                  if (provider.selectedTab == 1) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _buildFilterChips(),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildLongTermJobList(), _buildShortTermJobList()],
          ),
        ),
      ],
    );
  }

  // ==================== SEARCH BAR ====================

  Widget _buildSearchBar() {
    return GlassCard(
      showBorder: false,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.6),
          ),
          hintText: 'Tìm kiếm việc làm...',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          hintStyle: TextStyle(
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    context.read<JobProvider>().searchJobs('');
                    setState(() {});
                  },
                )
              : null,
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildMyApplicationsButton() {
    return Consumer<JobProvider>(
      builder: (context, provider, _) {
        final pendingCount =
            provider.myLongTermApplications
                .where(
                  (a) =>
                      a.status == JobApplicationStatus.pending ||
                      a.status == JobApplicationStatus.reviewed,
                )
                .length +
            provider.myShortTermApplications
                .where((a) => a.status == 'PENDING' || a.status == 'APPLIED')
                .length;

        return GlassCard(
          showBorder: false,
          padding: EdgeInsets.zero,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MyApplicationsPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.assignment_outlined),
                tooltip: 'Đơn ứng tuyển',
                style: IconButton.styleFrom(fixedSize: const Size(48, 48)),
              ),
              if (pendingCount > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 18),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.themeOrangeStart,
                          AppTheme.themeOrangeEnd,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$pendingCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ==================== FILTER CHIPS ====================

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            label: 'Remote',
            icon: Icons.wifi,
            isSelected: _filterRemote,
            onTap: () {
              setState(() => _filterRemote = !_filterRemote);
              _applyFilters();
            },
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Gấp',
            icon: Icons.bolt,
            isSelected: _filterUrgency == 'URGENT',
            onTap: () {
              setState(() {
                _filterUrgency = _filterUrgency == 'URGENT' ? null : 'URGENT';
              });
              _applyFilters();
            },
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Rất gấp',
            icon: Icons.flash_on,
            isSelected: _filterUrgency == 'VERY_URGENT',
            onTap: () {
              setState(() {
                _filterUrgency = _filterUrgency == 'VERY_URGENT'
                    ? null
                    : 'VERY_URGENT';
              });
              _applyFilters();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppTheme.themeBlueStart, AppTheme.themeBlueEnd],
                )
              : null,
          color: isSelected ? null : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : Theme.of(context).hintColor,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyFilters() {
    // Client-side filtering — just rebuild to apply filters
    setState(() {});
  }

  /// Apply local filters to short-term jobs
  List<ShortTermJobResponse> _getFilteredShortTermJobs(
    List<ShortTermJobResponse> jobs,
  ) {
    var filtered = jobs;
    if (_filterRemote) {
      filtered = filtered.where((j) => j.remote == true).toList();
    }
    if (_filterUrgency != null) {
      filtered = filtered.where((j) {
        final u = j.urgency;
        if (_filterUrgency == 'URGENT') return u == JobUrgency.urgent;
        if (_filterUrgency == 'VERY_URGENT')
          return u == JobUrgency.veryUrgent || u == JobUrgency.asap;
        return true;
      }).toList();
    }
    return filtered;
  }

  // ==================== TAB BAR ====================

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            colors: [AppTheme.themeBlueStart, AppTheme.themeBlueEnd],
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 13,
        ),
        tabs: const [
          Tab(text: 'Việc Làm'),
          Tab(text: 'Freelance'),
        ],
      ),
    );
  }

  // ==================== LONG-TERM JOB LIST ====================

  Widget _buildLongTermJobList() {
    return Consumer<JobProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingJobs) {
          return _buildSkeletonList();
        }

        if (provider.hasError) {
          return ErrorStateWidget(
            message: provider.errorMessage ?? 'Lỗi tải dữ liệu',
            onRetry: () => provider.loadPublicJobs(),
          );
        }

        final jobs = provider.filteredLongTermJobs;

        if (jobs.isEmpty) {
          return _buildEmptyState('Không có việc làm nào');
        }

        return RefreshIndicator(
          onRefresh: () async {
            await provider.loadPublicJobs();
            await provider.loadMyApplications();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jobs.length,
            itemBuilder: (context, index) => AnimatedListItem(
              index: index,
              child: _buildLongTermJobCard(jobs[index]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLongTermJobCard(JobPostingResponse job) {
    final gradientColors = _getGradientForIndex(job.id ?? 0);
    final hasApplied = context.watch<JobProvider>().hasAppliedToJob(
      job.id ?? 0,
    );

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => JobDetailPage(jobId: job.id!, isShortTerm: false),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              _buildCompanyAvatar(gradientColors),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title ?? 'Không có tiêu đề',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.recruiterCompanyName ?? 'Công ty',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasApplied) _buildAppliedBadge(),
              if (!hasApplied && job.highlighted == true) _buildHotBadge(),
            ],
          ),

          // Salary highlight
          if (job.minBudget != null && job.maxBudget != null) ...[
            const SizedBox(height: 12),
            _buildSalaryRow(
              '${NumberFormatter.formatPrice(job.minBudget!)} - ${NumberFormatter.formatCurrency(job.maxBudget!)}',
              isNegotiable: job.negotiable == true,
            ),
          ],

          const SizedBox(height: 10),

          // Description
          if (job.description != null)
            Text(
              job.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

          const SizedBox(height: 10),

          // Skills
          if (job.requiredSkills != null && job.requiredSkills!.isNotEmpty)
            _buildSkillChips(job.requiredSkills!, gradientColors.first),

          const SizedBox(height: 12),

          // Info row
          _buildInfoRow([
            if (job.remote == true) _buildInfoChip(Icons.wifi, 'Remote'),
            if (job.location != null && job.remote != true)
              _buildInfoChip(Icons.location_on_outlined, job.location!),
            if (job.experienceLevel != null)
              _buildInfoChip(Icons.bar_chart_outlined, job.experienceLevel!),
            if (job.jobType != null)
              _buildInfoChip(Icons.work_outline, job.jobType!),
          ]),

          const SizedBox(height: 12),

          // Footer: countdown + applicants
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (job.deadline != null)
                _buildDeadlineCountdown(DateTime.parse(job.deadline!)),
              if (job.applicantCount != null)
                Text(
                  '${job.applicantCount} ứng viên',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                  ),
                ),
              if (job.createdAt != null && job.deadline == null)
                Text(
                  DateTimeHelper.formatRelativeTime(
                    DateTime.parse(job.createdAt!),
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== SHORT-TERM JOB LIST ====================

  Widget _buildShortTermJobList() {
    return Consumer<JobProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingJobs) {
          return _buildSkeletonList();
        }

        if (provider.hasError) {
          return ErrorStateWidget(
            message: provider.errorMessage ?? 'Lỗi tải dữ liệu',
            onRetry: () => provider.loadShortTermJobs(),
          );
        }

        final allJobs = provider.shortTermJobs;
        final jobs = _getFilteredShortTermJobs(allJobs);

        if (allJobs.isEmpty) {
          return _buildEmptyState('Không có việc freelance nào');
        }

        if (jobs.isEmpty) {
          return _buildEmptyState('Không có kết quả phù hợp với bộ lọc');
        }

        return RefreshIndicator(
          onRefresh: () async {
            await provider.loadShortTermJobs();
            await provider.loadMyShortTermApplications();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jobs.length,
            itemBuilder: (context, index) => AnimatedListItem(
              index: index,
              child: _buildShortTermJobCard(jobs[index]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShortTermJobCard(ShortTermJobResponse job) {
    final gradientColors = _getGradientForIndex(job.id ?? 0);
    final hasApplied = context.watch<JobProvider>().hasAppliedToShortTermJob(
      job.id ?? 0,
    );

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => JobDetailPage(jobId: job.id!, isShortTerm: true),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              _buildCompanyAvatar(gradientColors),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title ?? 'Không có tiêu đề',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (job.recruiterInfo?.companyName != null)
                      Text(
                        job.recruiterInfo!.companyName!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
              if (hasApplied)
                _buildAppliedBadge()
              else if (job.urgency != null && job.urgency != JobUrgency.normal)
                _buildUrgencyBadge(job.urgency!),
            ],
          ),

          // Salary highlight
          if (job.budget != null) ...[
            const SizedBox(height: 12),
            _buildSalaryRow(
              NumberFormatter.formatCurrency(job.budget!),
              isNegotiable: job.negotiable == true,
            ),
          ],

          const SizedBox(height: 10),

          // Description
          if (job.description != null)
            Text(
              job.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

          const SizedBox(height: 10),

          // Skills
          if (job.requiredSkills != null && job.requiredSkills!.isNotEmpty)
            _buildSkillChips(job.requiredSkills!, gradientColors.first),

          const SizedBox(height: 12),

          // Info row
          _buildInfoRow([
            if (job.estimatedDuration != null)
              _buildInfoChip(Icons.schedule_outlined, job.estimatedDuration!),
            if (job.remote == true) _buildInfoChip(Icons.wifi, 'Remote'),
            if (job.location != null && job.remote != true)
              _buildInfoChip(Icons.location_on_outlined, job.location!),
          ]),

          const SizedBox(height: 12),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (job.deadline != null)
                    _buildDeadlineCountdown(DateTime.parse(job.deadline!)),
                  if (job.applicantCount != null) ...[
                    if (job.deadline != null) const SizedBox(width: 12),
                    Text(
                      '${job.applicantCount}${job.maxApplicants != null ? '/${job.maxApplicants}' : ''} ứng viên',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
              if (job.createdAt != null && job.deadline == null)
                Text(
                  DateTimeHelper.formatRelativeTime(
                    DateTime.parse(job.createdAt!),
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== NEW SHARED WIDGETS ====================

  /// Salary row with gradient icon + highlight text
  Widget _buildSalaryRow(String salary, {bool isNegotiable = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.themeGreenStart.withValues(alpha: 0.1),
            AppTheme.themeGreenEnd.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.themeGreenStart.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.payments_outlined,
            size: 18,
            color: AppTheme.themeGreenStart,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              salary,
              style: const TextStyle(
                color: AppTheme.themeGreenStart,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          if (isNegotiable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.themeGreenStart.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Thương lượng',
                style: TextStyle(
                  color: AppTheme.themeGreenStart,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Deadline countdown with color coding
  Widget _buildDeadlineCountdown(DateTime deadline) {
    final now = DateTime.now();
    final diff = deadline.difference(now);
    final days = diff.inDays;

    String label;
    Color color;

    if (diff.isNegative) {
      label = 'Đã hết hạn';
      color = Colors.grey;
    } else if (days == 0) {
      label = 'Hôm nay';
      color = Colors.red;
    } else if (days <= 3) {
      label = 'Còn $days ngày';
      color = Colors.red;
    } else if (days <= 7) {
      label = 'Còn $days ngày';
      color = AppTheme.themeOrangeStart;
    } else {
      label = 'Còn $days ngày';
      color = AppTheme.themeBlueStart;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_outlined, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// "Đã ứng tuyển" badge
  Widget _buildAppliedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.themeGreenStart.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.themeGreenStart.withValues(alpha: 0.4),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 12, color: AppTheme.themeGreenStart),
          SizedBox(width: 4),
          Text(
            'Đã ứng tuyển',
            style: TextStyle(
              color: AppTheme.themeGreenStart,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// HOT badge
  Widget _buildHotBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.themeOrangeStart, AppTheme.themeOrangeEnd],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'HOT',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ==================== ORIGINAL SHARED WIDGETS ====================

  Widget _buildCompanyAvatar(List<Color> gradientColors) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.business, color: Colors.white, size: 24),
    );
  }

  Widget _buildSkillChips(List<String> skills, Color color) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: skills.take(4).map((skill) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            skill,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoRow(List<Widget> chips) {
    return Wrap(spacing: 12, runSpacing: 8, children: chips);
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildUrgencyBadge(JobUrgency urgency) {
    final (label, colors) = switch (urgency) {
      JobUrgency.urgent => (
        'Gấp',
        [AppTheme.themeOrangeStart, AppTheme.themeOrangeEnd],
      ),
      JobUrgency.veryUrgent => (
        'Rất gấp',
        [Colors.red.shade400, Colors.red.shade600],
      ),
      JobUrgency.asap => ('ASAP', [Colors.red.shade600, Colors.red.shade800]),
      _ => ('', <Color>[]),
    };

    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => const JobCardSkeleton(),
    );
  }

  Widget _buildEmptyState(String message) {
    return EmptyStateWidget(
      icon: Icons.work_off_outlined,
      title: message,
      subtitle: 'Thử tải lại hoặc thay đổi bộ lọc',
      ctaLabel: 'Tải lại',
      onCtaPressed: () => context.read<JobProvider>().refresh(),
      iconGradient: AppTheme.blueGradient,
    );
  }

  List<Color> _getGradientForIndex(int index) {
    final gradients = [
      [AppTheme.themePurpleStart, AppTheme.themePurpleEnd],
      [AppTheme.themeBlueStart, AppTheme.themeBlueEnd],
      [AppTheme.themeGreenStart, AppTheme.themeGreenEnd],
      [AppTheme.themeOrangeStart, AppTheme.themeOrangeEnd],
    ];
    return gradients[index % gradients.length];
  }
}
