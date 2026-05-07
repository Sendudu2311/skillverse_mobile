import 'package:flutter/material.dart';
import '../../../data/models/learning_report_model.dart';
import '../../themes/app_theme.dart';
import '../glass_card.dart';
import '../../../core/utils/number_formatter.dart';

class ReportBreakdownWidget extends StatefulWidget {
  final List<RoadmapBreakdownItem>? roadmaps;
  final List<CourseBreakdownItem>? courses;
  final List<JobBreakdownItem>? jobs;
  final bool isDark;

  const ReportBreakdownWidget({
    super.key,
    this.roadmaps,
    this.courses,
    this.jobs,
    required this.isDark,
  });

  @override
  State<ReportBreakdownWidget> createState() => _ReportBreakdownWidgetState();
}

class _ReportBreakdownWidgetState extends State<ReportBreakdownWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<_TabItem> _tabs;

  @override
  void initState() {
    super.initState();
    _setupTabs();
  }

  @override
  void didUpdateWidget(ReportBreakdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roadmaps != widget.roadmaps ||
        oldWidget.courses != widget.courses ||
        oldWidget.jobs != widget.jobs) {
      _setupTabs();
    }
  }

  void _setupTabs() {
    _tabs = [];
    if (widget.roadmaps != null && widget.roadmaps!.isNotEmpty) {
      _tabs.add(_TabItem('Lộ trình', Icons.map_outlined, _buildRoadmapList));
    }
    if (widget.courses != null && widget.courses!.isNotEmpty) {
      _tabs.add(_TabItem('Khóa học', Icons.school_outlined, _buildCourseList));
    }
    if (widget.jobs != null && widget.jobs!.isNotEmpty) {
      _tabs.add(_TabItem('Jobs', Icons.work_outline, _buildJobList));
    }

    if (_tabs.isEmpty) {
      _tabs.add(_TabItem('Chưa có dữ liệu', Icons.hourglass_empty, () => const SizedBox()));
    }

    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_tabs.isEmpty || (_tabs.length == 1 && _tabs.first.title == 'Chưa có dữ liệu')) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 14,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.primaryBlueDark, AppTheme.accentCyan],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'CHI TIẾT HOẠT ĐỘNG',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlueDark,
                fontFamily: 'monospace',
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.accentCyan,
                labelColor: AppTheme.accentCyan,
                unselectedLabelColor: widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                isScrollable: _tabs.length > 2,
                tabAlignment: _tabs.length > 2 ? TabAlignment.center : null,
                tabs: _tabs.map((t) => Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(t.icon, size: 16),
                      const SizedBox(width: 6),
                      Text(t.title),
                    ],
                  ),
                )).toList(),
              ),
              SizedBox(
                // Arbitrary height so it fits within CustomScrollView nicely
                height: 350,
                child: TabBarView(
                  controller: _tabController,
                  children: _tabs.map((t) => t.builder()).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoadmapList() {
    final list = widget.roadmaps!;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => Divider(
        height: 24,
        color: widget.isDark ? Colors.white12 : Colors.black12,
      ),
      itemBuilder: (context, index) {
        final item = list[index];
        final progress = item.progressPercent ?? 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title ?? 'Lộ trình',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: widget.isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                ),
                Text(
                  '$progress%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlueDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: widget.isDark ? Colors.white12 : Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlueDark),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${item.completedMissions ?? 0}/${item.totalMissions ?? 0} node',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(item.status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatStatus(item.status),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(item.status),
                    ),
                  ),
                ),
              ],
            ),
            if (item.nextMissionTitle != null && item.nextMissionTitle!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.arrow_forward_rounded, size: 12, color: AppTheme.accentCyan),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Tiếp theo: ${item.nextMissionTitle}',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCourseList() {
    final list = widget.courses!;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => Divider(
        height: 24,
        color: widget.isDark ? Colors.white12 : Colors.black12,
      ),
      itemBuilder: (context, index) {
        final item = list[index];
        final progress = item.progressPercent ?? 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.courseTitle ?? 'Khóa học',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: widget.isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                ),
                Text(
                  '$progress%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: widget.isDark ? Colors.white12 : Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondaryPurple),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(item.status).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatStatus(item.status),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(item.status),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildJobList() {
    final list = widget.jobs!;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => Divider(
        height: 24,
        color: widget.isDark ? Colors.white12 : Colors.black12,
      ),
      itemBuilder: (context, index) {
        final item = list[index];
        final isCompleted = item.status?.toUpperCase() == 'COMPLETED' || item.status?.toUpperCase() == 'DONE';
        final hasMilestones = (item.milestonesTotal ?? 0) > 0;
        final progress = hasMilestones 
          ? (item.milestonesCompleted ?? 0) / item.milestonesTotal! 
          : (isCompleted ? 1.0 : 0.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.jobTitle ?? 'Công việc',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: widget.isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Budget: ${NumberFormatter.formatCurrency((item.budget ?? 0).toDouble(), currency: 'đ')} | Thu nhập: ${NumberFormatter.formatCurrency((item.earnedAmount ?? 0).toDouble(), currency: 'đ')}',
              style: TextStyle(
                fontSize: 12,
                color: widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: widget.isDark ? Colors.white12 : Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.successColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (hasMilestones)
                  Text(
                    '${item.milestonesCompleted ?? 0}/${item.milestonesTotal} mốc',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  )
                else
                  const SizedBox(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(item.status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatStatus(item.status),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(item.status),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'IN_PROGRESS':
      case 'ACTIVE':
        return AppTheme.primaryBlueDark;
      case 'COMPLETED':
      case 'DONE':
        return AppTheme.successColor;
      case 'NOT_STARTED':
      case 'PENDING':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'IN_PROGRESS':
        return 'ĐANG HỌC';
      case 'ACTIVE':
        return 'ĐANG HOẠT ĐỘNG';
      case 'COMPLETED':
      case 'DONE':
        return 'HOÀN THÀNH';
      case 'NOT_STARTED':
        return 'CHƯA BẮT ĐẦU';
      case 'PENDING':
        return 'CHỜ DUYỆT';
      default:
        return status ?? 'UNKNOWN';
    }
  }
}

class _TabItem {
  final String title;
  final IconData icon;
  final Widget Function() builder;

  _TabItem(this.title, this.icon, this.builder);
}
