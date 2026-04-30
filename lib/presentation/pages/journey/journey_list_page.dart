import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/journey_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/skeleton_loaders.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../widgets/animated_list_item.dart';
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
      body: SafeArea(
        top: false,
        bottom: true,
        child: Consumer<JourneyProvider>(
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
    final canCreate = !context.read<JourneyProvider>().hasActiveJourney;

    return RefreshIndicator(
      onRefresh: () => context.read<JourneyProvider>().refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: journeys.length + (canCreate ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == journeys.length) {
            return _buildCreateNewBanner(context, isDark);
          }
          return AnimatedListItem(
            index: index,
            child: _JourneyCard(
              journey: journeys[index],
              isDark: isDark,
              onTap: () => context.push('/journey/${journeys[index].id}'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCreateNewBanner(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryBlueDark.withValues(alpha: 0.12),
              AppTheme.accentCyan.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryBlueDark.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.add_road, size: 32, color: AppTheme.primaryBlueDark),
            const SizedBox(height: 8),
            Text(
              'Bắt đầu hành trình mới',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hành trình trước đã kết thúc. Sẵn sàng chinh phục mục tiêu tiếp theo?',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/journey/create'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tạo hành trình mới'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlueDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
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
                  Expanded(
                    child: Container(
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
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
        return (
          'Chưa bắt đầu',
          AppTheme.darkTextSecondary,
          Icons.hourglass_empty,
        );
      case JourneyStatus.assessmentPending:
        return ('Đang tạo test', AppTheme.warningColor, Icons.pending);
      case JourneyStatus.testInProgress:
        return ('Đang làm bài', AppTheme.primaryBlue, Icons.edit_note);
      case JourneyStatus.evaluationPending:
        return ('Đang đánh giá', AppTheme.secondaryPurple, Icons.psychology);
      case JourneyStatus.roadmapGenerated:
        return ('Có lộ trình', AppTheme.accentCyan, Icons.map);
      case JourneyStatus.studyPlanInProgress:
        return ('Đang học', AppTheme.accentCyan, Icons.menu_book);
      case JourneyStatus.active:
        return ('Đang hoạt động', AppTheme.successColor, Icons.play_circle);
      case JourneyStatus.completed:
      case JourneyStatus.completedVerified:
        return ('Hoàn thành', AppTheme.successColor, Icons.check_circle);
      case JourneyStatus.completedUnverified:
        return ('Hoàn thành (chưa xác minh)', Colors.amber, Icons.pending_actions);
      case JourneyStatus.awaitingVerification:
        return ('Đang chờ xác minh', AppTheme.warningColor, Icons.verified_outlined);
      case JourneyStatus.paused:
        return ('Tạm dừng', AppTheme.warningColor, Icons.pause_circle);
      case JourneyStatus.cancelled:
        return ('Đã hủy', AppTheme.errorColor, Icons.cancel);
    }
  }

  Color _getDomainColor() {
    switch (journey.domain.toUpperCase()) {
      case 'IT':
        return AppTheme.primaryBlue;
      case 'DESIGN':
        return AppTheme.secondaryPurple;
      case 'BUSINESS':
        return AppTheme.warningColor;
      case 'ENGINEERING':
        return AppTheme.accentCyan;
      case 'HEALTHCARE':
        return AppTheme.errorColor;
      case 'EDUCATION':
        return AppTheme.successColor;
      default:
        return AppTheme.primaryBlueDark;
    }
  }

  Color _getProgressColor() {
    if (journey.progressPercentage >= 80) return AppTheme.successColor;
    if (journey.progressPercentage >= 40) return AppTheme.warningColor;
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
