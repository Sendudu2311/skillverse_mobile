import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/journey_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/skeleton_loaders.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../widgets/status_badge.dart';
import '../../../data/models/journey_models.dart';

class JourneyListPage extends StatefulWidget {
  const JourneyListPage({super.key});

  @override
  State<JourneyListPage> createState() => _JourneyListPageState();
}

class _JourneyListPageState extends State<JourneyListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JourneyProvider>().loadJourneys();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: SkillVerseAppBar(
        title: 'HÀNH TRÌNH CỦA TÔI',
        icon: Icons.explore,
        useGradientTitle: true,
        onBack: () => context.go('/dashboard'),
      ),
      body: Consumer<JourneyProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return _buildLoadingState();
          }

          if (provider.hasError) {
            return ErrorStateWidget(
              message: provider.errorMessage!,
              onRetry: () => provider.loadJourneys(),
            );
          }

          if (provider.journeys.isEmpty) {
            return _buildEmptyState(context, isDark);
          }

          return _buildJourneyList(context, provider.journeys, isDark);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/journey/create'),
        icon: const Icon(Icons.add),
        label: const Text('Tạo hành trình'),
        backgroundColor: AppTheme.primaryBlueDark,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => const CardSkeleton(imageHeight: null),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return EmptyStateWidget(
      icon: Icons.explore_outlined,
      title: 'Bắt đầu hành trình đầu tiên',
      subtitle:
          'AI sẽ đánh giá kỹ năng và tạo lộ trình học tập cá nhân hóa cho bạn',
      ctaLabel: 'Tạo hành trình mới',
      onCtaPressed: () => context.push('/journey/create'),
      iconGradient: AppTheme.blueGradient,
    );
  }

  Widget _buildJourneyList(
    BuildContext context,
    List<JourneySummaryDto> journeys,
    bool isDark,
  ) {
    return RefreshIndicator(
      onRefresh: () => context.read<JourneyProvider>().refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: journeys.length,
        itemBuilder: (context, index) {
          return _JourneyCard(
            journey: journeys[index],
            isDark: isDark,
            onTap: () => context.push('/journey/${journeys[index].id}'),
          );
        },
      ),
    );
  }
}

// ============================================================================
// Journey List Card Widget
// ============================================================================

class _JourneyCard extends StatelessWidget {
  final JourneySummaryDto journey;
  final bool isDark;
  final VoidCallback onTap;

  const _JourneyCard({
    required this.journey,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? AppTheme.darkCardBackground : Colors.white,
      elevation: isDark ? 0 : 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Domain + Status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getDomainColor().withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      journey.domain,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getDomainColor(),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Builder(
                    builder: (_) {
                      final info = _getStatusInfo();
                      return StatusBadge.custom(
                        label: info.$1,
                        color: info.$2,
                        icon: info.$3,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Goal
              Text(
                _getGoalLabel(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
              if (journey.jobRole != null) ...[
                const SizedBox(height: 4),
                Text(
                  journey.jobRole!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: journey.progressPercentage / 100,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getProgressColor(),
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),

              // Footer: Progress % + Level
              Row(
                children: [
                  Text(
                    '${journey.progressPercentage}% hoàn thành',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (journey.currentLevel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlueDark.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getLevelLabel(journey.currentLevel!),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryBlueDark,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  (String, Color, IconData) _getStatusInfo() {
    switch (journey.status) {
      case JourneyStatus.notStarted:
        return ('Chưa bắt đầu', Colors.grey, Icons.hourglass_empty);
      case JourneyStatus.assessmentPending:
        return ('Đang tạo test', Colors.orange, Icons.pending);
      case JourneyStatus.testInProgress:
        return ('Đang làm bài', Colors.blue, Icons.edit_note);
      case JourneyStatus.evaluationPending:
        return ('Đang đánh giá', Colors.purple, Icons.psychology);
      case JourneyStatus.roadmapGenerated:
        return ('Có lộ trình', Colors.teal, Icons.map);
      case JourneyStatus.studyPlanInProgress:
        return ('Đang học', Colors.indigo, Icons.menu_book);
      case JourneyStatus.active:
        return ('Đang hoạt động', Colors.green, Icons.play_circle);
      case JourneyStatus.completed:
        return ('Hoàn thành', AppTheme.successColor, Icons.check_circle);
      case JourneyStatus.paused:
        return ('Tạm dừng', Colors.amber, Icons.pause_circle);
      case JourneyStatus.cancelled:
        return ('Đã hủy', Colors.red, Icons.cancel);
    }
  }

  Color _getDomainColor() {
    switch (journey.domain.toUpperCase()) {
      case 'IT':
        return Colors.blue;
      case 'DESIGN':
        return Colors.purple;
      case 'BUSINESS':
        return Colors.orange;
      case 'ENGINEERING':
        return Colors.teal;
      case 'HEALTHCARE':
        return Colors.red;
      case 'EDUCATION':
        return Colors.green;
      default:
        return AppTheme.primaryBlueDark;
    }
  }

  Color _getProgressColor() {
    if (journey.progressPercentage >= 80) return AppTheme.successColor;
    if (journey.progressPercentage >= 40) return Colors.orange;
    return AppTheme.primaryBlueDark;
  }

  String _getGoalLabel() {
    switch (journey.goal.toUpperCase()) {
      case 'EXPLORE':
        return 'Khám phá ngành';
      case 'INTERNSHIP':
        return 'Chuẩn bị thực tập';
      case 'CAREER_CHANGE':
        return 'Chuyển ngành';
      case 'UPSKILL':
        return 'Nâng cao kỹ năng';
      case 'FROM_SCRATCH':
        return 'Bắt đầu từ đầu';
      default:
        return journey.goal;
    }
  }

  String _getLevelLabel(SkillLevel level) {
    switch (level) {
      case SkillLevel.beginner:
        return 'Mới bắt đầu';
      case SkillLevel.elementary:
        return 'Sơ cấp';
      case SkillLevel.intermediate:
        return 'Trung cấp';
      case SkillLevel.advanced:
        return 'Nâng cao';
      case SkillLevel.expert:
        return 'Chuyên gia';
    }
  }
}
