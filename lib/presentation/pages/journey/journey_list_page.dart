import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/journey_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/skeleton_loaders.dart';
import '../../widgets/empty_state_widget.dart';
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: Row(
          children: [
            Icon(Icons.explore, color: AppTheme.primaryBlueDark, size: 28),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppTheme.primaryBlueDark, AppTheme.accentCyan],
              ).createShader(bounds),
              child: const Text(
                'HÀNH TRÌNH CỦA TÔI',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<JourneyProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return _buildLoadingState();
          }

          if (provider.hasError) {
            return _buildErrorState(context, provider.errorMessage!, isDark);
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

  Widget _buildErrorState(BuildContext context, String error, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text('Đã xảy ra lỗi', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<JourneyProvider>().loadJourneys(),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return EmptyStateWidget(
      icon: Icons.explore_outlined,
      title: 'Bắt đầu hành trình đầu tiên',
      subtitle: 'AI sẽ đánh giá kỹ năng và tạo lộ trình học tập cá nhân hóa cho bạn',
      ctaLabel: 'Tạo hành trình mới',
      onCtaPressed: () => context.push('/journey/create'),
      iconGradient: AppTheme.blueGradient,
    );
  }

  Widget _buildJourneyList(
      BuildContext context, List<JourneySummaryDto> journeys, bool isDark) {
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  _buildStatusBadge(),
                ],
              ),
              const SizedBox(height: 12),

              // Goal
              Text(
                _getGoalLabel(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
              ),
              if (journey.jobRole != null) ...[
                const SizedBox(height: 4),
                Text(
                  journey.jobRole!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
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
                  valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor()),
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
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (journey.currentLevel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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

  Widget _buildStatusBadge() {
    final statusInfo = _getStatusInfo();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusInfo.$2.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusInfo.$3, size: 12, color: statusInfo.$2),
          const SizedBox(width: 4),
          Text(
            statusInfo.$1,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusInfo.$2),
          ),
        ],
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
