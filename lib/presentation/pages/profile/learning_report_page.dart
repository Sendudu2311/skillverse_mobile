import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/learning_report_provider.dart';
import '../../../data/models/learning_report_model.dart';
import '../../themes/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../widgets/common_loading.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/learning_report/meowl_avatar_widget.dart';
import '../../widgets/learning_report/generating_steps_widget.dart';
import '../../widgets/learning_report/stats_grid_widget.dart';
import '../../widgets/learning_report/trend_banner_widget.dart';
import '../../widgets/learning_report/report_type_selector_widget.dart';
import '../../widgets/learning_report/section_navigation_widget.dart';
import '../../widgets/learning_report/report_section_card_widget.dart';
import '../../widgets/learning_report/report_history_item_widget.dart';
import '../../widgets/learning_report/skeleton_widgets.dart';
import '../../widgets/learning_report/animated_transitions.dart';

class LearningReportPage extends StatefulWidget {
  const LearningReportPage({super.key});

  @override
  State<LearningReportPage> createState() => _LearningReportPageState();
}

class _LearningReportPageState extends State<LearningReportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LearningReportProvider>();
      provider.loadLatestReport();
      provider.loadReportHistory();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: SkillVerseAppBar(
        title: 'Báo cáo học tập AI',
        icon: Icons.analytics,
        useGradientTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentCyan,
          labelColor: AppTheme.accentCyan,
          unselectedLabelColor:
              isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          tabs: const [
            Tab(text: 'Báo cáo'),
            Tab(text: 'Lịch sử'),
          ],
        ),
      ),
      body: Consumer<LearningReportProvider>(
        builder: (context, provider, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildLatestTab(provider, isDark),
              _buildHistoryTab(provider, isDark),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<LearningReportProvider>(
        builder: (context, provider, _) {
          final canGen = provider.canGenerate?.canGenerate ?? true;
          final cooldownMins =
              provider.canGenerate?.remainingCooldownMinutes ?? 0;
          final isDisabled = provider.isGenerating || !canGen;

          return FloatingActionButton.extended(
                  onPressed: isDisabled
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    _tabController.animateTo(0); // Switch tab immediately
                    await provider.generateReport();
                    if (!mounted) return;
                    if (provider.errorMessage == null) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Báo cáo đã được tạo thành công!'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  },
            icon: provider.isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(!canGen ? Icons.timer : Icons.auto_awesome),
            label: Text(
              provider.isGenerating
                  ? (provider.generatingStatus.isNotEmpty
                      ? provider.generatingStatus
                      : 'Đang tạo...')
                  : (!canGen
                      ? 'Đợi ${_formatCooldown(cooldownMins)}'
                      : 'Tạo báo cáo'),
              style: const TextStyle(fontSize: 12),
            ),
            backgroundColor:
                isDisabled ? Colors.grey : AppTheme.primaryBlueDark,
          );
        },
      ),
    );
  }

  // ==================== Latest Report Tab ====================

  String _getStateKey(LearningReportProvider provider) {
    if (provider.isLoading) return 'loading';
    if (provider.isGenerating && provider.errorMessage == null) {
      return 'generating';
    }
    if (provider.errorMessage != null && provider.latestReport == null) {
      return 'error';
    }
    if (provider.latestReport == null) {
      return 'no-report';
    }
    return 'report-${provider.latestReport!.id}';
  }

  Widget _buildLatestTab(LearningReportProvider provider, bool isDark) {
    Widget buildTab() {
      if (provider.isLoading) return _buildLoadingState(provider, isDark);
      if (provider.isGenerating && provider.errorMessage == null) {
        return _buildGeneratingState(provider, isDark);
      }
      if (provider.errorMessage != null && provider.latestReport == null) {
        return _buildErrorState(provider, isDark);
      }
      if (provider.latestReport == null) {
        return _buildNoReportState(provider, isDark);
      }
      return _buildReportView(provider, isDark);
    }

    return AnimatedSwitcher(
      duration: LrAnim.page,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: KeyedSubtree(key: ValueKey(_getStateKey(provider)), child: buildTab()),
    );
  }

  // ----- Loading State -----
  Widget _buildLoadingState(LearningReportProvider provider, bool isDark) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Center(child: SkeletonMeowl(isDark: isDark, avatarSize: 100)),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Đang đồng bộ dữ liệu...',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            SkeletonStatsGrid(isDark: isDark),
            const SizedBox(height: 16),
            SkeletonTrendBanner(isDark: isDark),
            const SizedBox(height: 16),
            SkeletonSectionNav(isDark: isDark),
            const SizedBox(height: 16),
            SkeletonSectionCard(isDark: isDark),
            const SizedBox(height: 12),
            SkeletonSectionCard(isDark: isDark),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ----- Generating State -----
  Widget _buildGeneratingState(LearningReportProvider provider, bool isDark) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 40),
              MeowlAvatarWidget(
                speech: provider.meowlSpeech,
                animate: true,
                size: 120,
              ),
              const SizedBox(height: 32),
              GeneratingStepsWidget(
                currentStep: provider.generatingStep,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              Text(
                'Quá trình phân tích AI có thể mất 15-30 giây',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (provider.generatingStatus.isNotEmpty)
                Text(
                  provider.generatingStatus,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.accentCyan,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(LearningReportProvider provider, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MeowlAvatarWidget(
              speech: provider.meowlSpeech,
              animate: false,
              size: 80,
            ),
            const SizedBox(height: 24),
            Icon(
              Icons.warning_amber_rounded,
              size: 56,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'TRỤC TRẶC HỆ THỐNG',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.errorColor,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage ?? 'Đã xảy ra lỗi không xác định.',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.loadLatestReport(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('THỬ LẠI'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlueDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----- No Report State -----
  Widget _buildNoReportState(LearningReportProvider provider, bool isDark) {
    final canGen = provider.canGenerate?.canGenerate ?? true;
    final cooldownMins =
        provider.canGenerate?.remainingCooldownMinutes ?? 0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              MeowlAvatarWidget(
                speech: provider.meowlSpeech,
                animate: true,
                size: 120,
              ),
              const SizedBox(height: 24),
              Text(
                'TẠO PHÂN TÍCH MỚI',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hệ thống AI Meowl đã sẵn sàng tổng hợp quá trình phát triển của bạn.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CẤU HÌNH PHẠM VI:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ReportTypeSelectorWidget(
                    value: provider.selectedReportType,
                    onChanged: (type) => provider.setReportType(type),
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: canGen
                      ? () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await provider.generateReport();
                          if (!mounted) return;
                          if (provider.errorMessage == null) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Báo cáo đã được tạo thành công!'),
                                backgroundColor: AppTheme.successColor,
                              ),
                            );
                          }
                        }
                      : null,
                  icon: Icon(
                    canGen ? Icons.bolt : Icons.timer,
                    size: 20,
                  ),
                  label: Text(
                    canGen
                        ? 'KÍCH HOẠT PHÂN TÍCH'
                        : 'Đợi ${_formatCooldown(cooldownMins)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        canGen ? AppTheme.primaryBlueDark : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (!canGen && cooldownMins > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Báo cáo mới sẽ sẵn sàng sau ${_formatCooldown(cooldownMins)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ----- Report View -----
  Widget _buildReportView(LearningReportProvider provider, bool isDark) {
    final report = provider.latestReport!;
    final sections = provider.getAvailableSections();
    final activeSection = provider.activeSection;

    return RefreshIndicator(
      onRefresh: () => provider.loadLatestReport(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReportHeader(report, provider, isDark),
                  const SizedBox(height: 16),
                  StatsGridWidget(
                    metrics: report.metrics,
                    streakInfo: provider.streakInfo,
                    overallProgress: report.overallProgress ?? 0,
                    streakDisplay: provider.getStreakDisplay(),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  TrendBannerWidget(
                    learningTrend: report.learningTrend,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  if (report.recommendedFocus != null &&
                      report.recommendedFocus!.isNotEmpty)
                    _buildFocusCard(report, isDark),
                  if (report.recommendedFocus != null &&
                      report.recommendedFocus!.isNotEmpty)
                    const SizedBox(height: 16),
                  _buildSummaryCard(report, provider, isDark),
                  const SizedBox(height: 16),
                  if (sections.isNotEmpty) ...[
                    Text(
                      'NỘI DUNG BÁO CÁO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentCyan,
                        fontFamily: 'monospace',
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SectionNavigationWidget(
                      sections: sections,
                      activeSection: activeSection,
                      onChanged: (s) => provider.setActiveSection(s),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (activeSection != 'overview' &&
                      report.sections != null) ...[
                    _buildActiveSectionContent(report, activeSection),
                    const SizedBox(height: 16),
                  ],
                  if (activeSection == 'overview' &&
                      report.sections != null) ...[
                    ...report.sections!.displaySections.entries.map((entry) {
                      final key = _getSectionKey(entry.key);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ReportSectionCardWidget(
                          sectionKey: key,
                          content: entry.value,
                          isDark: isDark,
                        ),
                      );
                    }),
                  ],
                  if (provider.errorMessage != null)
                    _buildInlineError(provider, isDark),
                  const SizedBox(height: 8),
                  _buildFooterActions(provider, isDark),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportHeader(
    StudentLearningReportResponse report,
    LearningReportProvider provider,
    bool isDark,
  ) {
    final typeKey = (report.reportType ?? 'COMPREHENSIVE').toUpperCase();
    final typeLabels = {
      'COMPREHENSIVE': ('Toàn diện', Color(0xFF8B5CF6)),
      'WEEKLY_SUMMARY': ('Tuần', Color(0xFF3B82F6)),
      'MONTHLY_SUMMARY': ('Tháng', Color(0xFF10B981)),
      'SKILL_ASSESSMENT': ('Kỹ năng', Color(0xFFF59E0B)),
      'GOAL_TRACKING': ('Mục tiêu', Color(0xFFEC4899)),
    };
    final (typeLabel, typeColor) =
        typeLabels[typeKey] ?? (typeKey, AppTheme.primaryBlueDark);

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            MeowlAvatarWidget(
              speech: provider.meowlSpeech,
              animate: false,
              size: 56,
              showSpeechBubble: false,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Báo cáo ',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: typeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (report.generatedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Tạo lúc: ${_formatDateTime(report.generatedAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusCard(StudentLearningReportResponse report, bool isDark) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.track_changes,
                  size: 16,
                  color: AppTheme.accentGold,
                ),
                const SizedBox(width: 8),
                Text(
                  'ĐỀ XUẤT TẬP TRUNG',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentGold,
                    fontFamily: 'monospace',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              report.recommendedFocus!,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    StudentLearningReportResponse report,
    LearningReportProvider provider,
    bool isDark,
  ) {
    final streak = provider.getStreakDisplay();
    final studyHours = report.metrics?.totalStudyHours ?? 0;
    final tasksCompleted = report.metrics?.totalTasksCompleted ?? 0;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 16,
                  color: AppTheme.primaryBlueDark,
                ),
                const SizedBox(width: 8),
                Text(
                  'TÓM TẮT NHANH',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlueDark,
                    fontFamily: 'monospace',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Báo cáo được tạo vào ',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  TextSpan(
                    text: _formatDateTime(report.generatedAt ?? ''),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  TextSpan(
                    text: '. Bạn đã dành ',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  TextSpan(
                    text: '$studyHours giờ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  TextSpan(
                    text: ' học tập và hoàn thành ',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  TextSpan(
                    text: '$tasksCompleted công việc',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  if ((report.metrics?.currentStreak ?? 0) > 0) ...[
                    TextSpan(
                      text: '. Chuỗi học tập hiện tại: ',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                    TextSpan(
                      text: '${streak.value} ngày',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    TextSpan(
                      text: '!',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSectionContent(
    StudentLearningReportResponse report,
    String activeSection,
  ) {
    if (report.sections == null) return const SizedBox.shrink();

    final keyMap = <String, String>{
      'currentSkills': 'currentSkills',
      'learningGoals': 'learningGoals',
      'progressSummary': 'progressSummary',
      'strengths': 'strengths',
      'areasToImprove': 'areasToImprove',
      'recommendations': 'recommendations',
      'skillGaps': 'skillGaps',
      'nextSteps': 'nextSteps',
      'motivation': 'motivation',
    };

    final internalKey = keyMap[activeSection] ?? activeSection;
    final sections = report.sections!;
    String? content;

    if (internalKey == 'currentSkills') content = sections.currentSkills;
    if (internalKey == 'learningGoals') content = sections.learningGoals;
    if (internalKey == 'progressSummary') content = sections.progressSummary;
    if (internalKey == 'strengths') content = sections.strengths;
    if (internalKey == 'areasToImprove') content = sections.areasToImprove;
    if (internalKey == 'recommendations') content = sections.recommendations;
    if (internalKey == 'skillGaps') content = sections.skillGaps;
    if (internalKey == 'nextSteps') content = sections.nextSteps;
    if (internalKey == 'motivation') content = sections.motivation;

    if (content == null || content.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.article_outlined,
                size: 40,
                color: Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                'Không có dữ liệu cho phần này',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ReportSectionCardWidget(
      sectionKey: activeSection,
      content: content,
      isDark: Theme.of(context).brightness == Brightness.dark,
    );
  }

  Widget _buildInlineError(
      LearningReportProvider provider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.errorColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 18,
              color: AppTheme.errorColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                provider.errorMessage!,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.errorColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () => provider.recheckLatestReport(),
              child: const Text('Kiểm tra lại', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterActions(
      LearningReportProvider provider, bool isDark) {

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.galaxyMid.withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: provider.isDownloadingPDF
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await provider.downloadPDF();
                      if (!mounted) return;
                      if (provider.lastSavedPdfPath != null) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'PDF đã lưu vào Downloads!',
                            ),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                      } else {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Lỗi khi lưu PDF'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              icon: provider.isDownloadingPDF
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child:
                          CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined, size: 18),
              label: Text(
                provider.isDownloadingPDF ? 'Đang tải...' : 'Tải PDF',
                style: const TextStyle(fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryBlueDark,
                side: BorderSide(
                  color: AppTheme.primaryBlueDark.withValues(alpha: 0.4),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: provider.isSharingPDF
                  ? null
                  : () async {
                      await provider.sharePDF();
                    },
              icon: provider.isSharingPDF
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.share_outlined, size: 18),
              label: Text(
                provider.isSharingPDF ? 'Đang xử lý...' : 'Chia sẻ',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlueDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== History Tab ====================

  Widget _buildHistoryTab(LearningReportProvider provider, bool isDark) {
    if (provider.isLoadingHistory && provider.reportHistory.isEmpty) {
      return CommonLoading.center(message: 'Đang tải lịch sử...');
    }

    if (provider.reportHistory.isEmpty) {
      return Center(
        child: EmptyStateWidget(
          icon: Icons.history,
          title: 'Chưa có lịch sử báo cáo',
          subtitle: 'Các báo cáo bạn đã tạo sẽ hiển thị ở đây',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadReportHistory(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.reportHistory.length + 1,
        itemBuilder: (context, index) {
          if (index == provider.reportHistory.length) {
            if (!provider.hasMoreHistory) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Đã hiển thị tất cả báo cáo',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                ),
              );
            }

            if (provider.isLoadingHistory) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: TextButton.icon(
                  onPressed: () => provider.loadMoreHistory(),
                  icon: const Icon(Icons.expand_more, size: 18),
                  label: const Text('Xem thêm'),
                ),
              ),
            );
          }

          final report = provider.reportHistory[index];
          return ReportHistoryItemWidget(
            report: report,
            isDark: isDark,
            onTap: () {
              if (report.id != null) {
                provider.viewReport(report.id!);
                _tabController.animateTo(0);
              }
            },
            onDownload: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Xem báo cáo và tải PDF từ tab Báo cáo'),
                  backgroundColor: AppTheme.accentCyan,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ==================== Helpers ====================

  String _getSectionKey(String displayName) {
    final map = <String, String>{
      'Kỹ năng hiện có': 'currentSkills',
      'Mục tiêu học tập': 'learningGoals',
      'Tổng kết tiến độ': 'progressSummary',
      'Điểm mạnh': 'strengths',
      'Cần cải thiện': 'areasToImprove',
      'Khuyến nghị': 'recommendations',
      'Khoảng trống kỹ năng': 'skillGaps',
      'Bước tiếp theo': 'nextSteps',
      'Động lực': 'motivation',
    };
    return map[displayName] ?? displayName;
  }

  String _formatDateTime(String isoString) {
    if (isoString.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }

  String _formatCooldown(int minutes) {
    if (minutes <= 0) return 'sẵn sàng';
    if (minutes < 60) return '$minutes phút';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '$hours giờ';
    return '$hours giờ $mins phút';
  }
}
