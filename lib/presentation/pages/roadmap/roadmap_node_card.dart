import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../data/models/roadmap_models.dart';
import '../../../data/models/node_mentoring_models.dart';
import '../../../data/services/node_mentoring_service.dart';
import '../../providers/roadmap_detail_provider.dart';
import '../../providers/task_board_provider.dart';
import '../../providers/journey_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/common_loading.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../widgets/formatted_ai_response.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';

/// Collapsible node card for the roadmap detail page.
///
/// Manages its own study-plan-creation loading state;
/// delegates quest-completion toggling to the parent via [onToggleQuestCompletion].
class RoadmapNodeCard extends StatefulWidget {
  final RoadmapNode node;
  final bool isExpanded;
  final bool isCompleted;
  final bool isDark;
  final int sessionId;
  final bool hasStudyPlan;
  final VoidCallback onToggleExpand;
  final void Function(String questId, bool completed) onToggleQuestCompletion;

  const RoadmapNodeCard({
    super.key,
    required this.node,
    required this.isExpanded,
    required this.isCompleted,
    required this.isDark,
    required this.sessionId,
    this.hasStudyPlan = false,
    required this.onToggleExpand,
    required this.onToggleQuestCompletion,
  });

  @override
  State<RoadmapNodeCard> createState() => _RoadmapNodeCardState();
}

class _RoadmapNodeCardState extends State<RoadmapNodeCard> {
  bool _isCreatingPlan = false;
  bool _isCompletingNode = false;

  // ── Feature B: Per-Node Mentoring ──────────────────────────────────────────
  final NodeMentoringService _mentoringService = NodeMentoringService();
  int? _journeyId;
  NodeAssignmentResponse? _assignment;
  NodeEvidenceRecordResponse? _evidence;
  bool _mentoringLoaded = false;
  bool _isLoadingMentoring = false;

  // ============================================================================
  // LIFECYCLE
  // ============================================================================

  @override
  void didUpdateWidget(covariant RoadmapNodeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded && !oldWidget.isExpanded && !_mentoringLoaded) {
      _loadMentoringData();
    }
  }

  Future<void> _loadMentoringData() async {
    if (!mounted) return;
    // Resolve journeyId from JourneyProvider cache (roadmapSessionId match)
    final jp = context.read<JourneyProvider>();
    final journey = jp.journeys
        .where((j) => j.roadmapSessionId == widget.sessionId)
        .firstOrNull;
    if (journey == null) {
      setState(() => _mentoringLoaded = true);
      return;
    }
    _journeyId = journey.id;

    setState(() => _isLoadingMentoring = true);
    try {
      final results = await Future.wait([
        _mentoringService.getAssignment(journey.id, widget.node.id),
        _mentoringService.getEvidence(journey.id, widget.node.id),
      ]);
      if (!mounted) return;
      setState(() {
        _assignment = results[0] as NodeAssignmentResponse?;
        _evidence = results[1] as NodeEvidenceRecordResponse?;
        _mentoringLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _mentoringLoaded = true);
    } finally {
      if (mounted) setState(() => _isLoadingMentoring = false);
    }
  }

  // ============================================================================
  // STATIC HELPERS
  // ============================================================================

  static String _cleanAiText(String text) {
    return text
        .replaceAll(RegExp(r'\*{2,}'), '')
        .replaceAll(RegExp(r'_{2,}'), '')
        .replaceAll(RegExp(r'(?<=\s)\*(?=\S)|(?<=\S)\*(?=\s)'), '')
        .trim();
  }

  static IconData _getNodeStatusIcon(String status) {
    return switch (status.toUpperCase()) {
      'LOCKED' => Icons.lock_outline,
      'AVAILABLE' => Icons.lock_open,
      'IN_PROGRESS' => Icons.play_circle_outline,
      'COMPLETED' => Icons.check_circle_outline,
      _ => Icons.help_outline,
    };
  }

  /// Resolves prerequisite node IDs to human-readable titles.
  List<String> _resolvePrerequisiteLabels(List<String> prerequisites) {
    final provider = context.read<RoadmapDetailProvider>();
    final allNodes = provider.currentRoadmap?.roadmap;
    if (allNodes == null || allNodes.isEmpty) return prerequisites;
    final byId = {for (final n in allNodes) n.id: n.title};
    return prerequisites.map((item) => byId[item] ?? item).toList();
  }

  // ============================================================================
  // BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final isMainQuest = node.isMainQuest;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.isDark
            ? AppTheme.darkCardBackground
            : AppTheme.lightCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMainQuest
              ? (widget.isDark
                        ? AppTheme.primaryBlueDark
                        : AppTheme.primaryBlue)
                    .withValues(alpha: 0.3)
              : widget.isDark
              ? AppTheme.darkBorderColor
              : AppTheme.lightBorderColor,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: widget.onToggleExpand,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge & checkbox row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isMainQuest
                                    ? AppTheme.primaryBlueDark.withValues(
                                        alpha: 0.15,
                                      )
                                    : AppTheme.secondaryPurple.withValues(
                                        alpha: 0.15,
                                      ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isMainQuest
                                        ? Icons.star
                                        : Icons.bookmark_outline,
                                    size: 12,
                                    color: isMainQuest
                                        ? AppTheme.primaryBlueDark
                                        : AppTheme.secondaryPurple,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isMainQuest
                                        ? 'Nhiệm vụ chính'
                                        : 'Nhiệm vụ phụ',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isMainQuest
                                          ? AppTheme.primaryBlueDark
                                          : AppTheme.secondaryPurple,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (node.nodeStatus != null)
                              StatusBadge(
                                status: node.nodeStatus!,
                                icon: _getNodeStatusIcon(node.nodeStatus!),
                              ),
                            if (widget.hasStudyPlan)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentCyan.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppTheme.accentCyan.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.event_note_outlined,
                                      size: 11,
                                      color: AppTheme.accentCyan,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Kế hoạch',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.accentCyan,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildQuestCheckbox(node),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    _cleanAiText(node.title),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: widget.isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                      decoration: widget.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  // Skill requirement tags
                  if (node.skills != null && node.skills!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: node.skills!.map((skill) {
                        final (Color tagColor, String tagLabel) = switch (skill.requirementType?.toUpperCase()) {
                          'REQUIRED' => (const Color(0xFF22d3ee), 'Bắt buộc'),
                          'IMPORTANT' => (const Color(0xFFf59e0b), 'Quan trọng'),
                          'NICE_TO_HAVE' => (const Color(0xFF6366f1), 'Nên có'),
                          _ => (const Color(0xFF22d3ee), 'Bắt buộc'),
                        };
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: tagColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: tagColor.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                skill.skillName ?? '',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: tagColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                tagLabel,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: tagColor.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    _cleanAiText(node.description),
                    maxLines: widget.isExpanded ? null : 2,
                    overflow: widget.isExpanded ? null : TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: widget.isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Footer: estimated time + difficulty + expand arrow
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 14,
                        color: widget.isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${node.estimatedTimeHours.toStringAsFixed(0)}h',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: widget.isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                      const Spacer(),
                      if (node.difficulty != null)
                        _buildDifficultyBadge(node.difficulty!),
                      const SizedBox(width: 8),
                      Icon(
                        widget.isExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: widget.isDark
                            ? AppTheme.primaryBlueDark
                            : AppTheme.primaryBlue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (widget.isExpanded) _buildExpandedContent(context, node),
        ],
      ),
    );
  }

  // ============================================================================
  // PRIVATE BUILDERS
  // ============================================================================

  /// Checkbox that is disabled for LOCKED nodes with an explanatory tooltip.
  Widget _buildQuestCheckbox(RoadmapNode node) {
    final isLocked = node.nodeStatus?.toUpperCase() == 'LOCKED';
    if (isLocked) {
      return Tooltip(
        message: 'Hoàn thành node trước để mở khóa',
        child: Icon(
          Icons.lock_outline,
          size: 22,
          color: widget.isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        ),
      );
    }
    return Checkbox(
      value: widget.isCompleted,
      onChanged: (value) =>
          widget.onToggleQuestCompletion(node.id, value ?? false),
      activeColor: AppTheme.successColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    String label;
    Color color;
    switch (difficulty.toLowerCase()) {
      case 'easy':
      case 'beginner':
        label = 'EASY';
        color = AppTheme.successColor;
        break;
      case 'medium':
      case 'intermediate':
        label = 'MEDIUM';
        color = AppTheme.warningColor;
        break;
      case 'hard':
      case 'advanced':
      case 'expert':
      case 'research':
        label = difficulty.toUpperCase();
        color = AppTheme.errorColor;
        break;
      default:
        label = difficulty.toUpperCase();
        color = AppTheme.warningColor;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context, RoadmapNode node) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 12),
          if (node.learningObjectives != null &&
              node.learningObjectives!.isNotEmpty)
            _buildExpandedSection(
              context,
              'Mục tiêu học tập',
              Icons.check_circle_outline,
              node.learningObjectives!,
            ),
          if (node.keyConcepts != null && node.keyConcepts!.isNotEmpty)
            _buildExpandedSection(
              context,
              'Khái niệm chính',
              Icons.lightbulb_outline,
              node.keyConcepts!,
            ),
          if (node.practicalExercises != null &&
              node.practicalExercises!.isNotEmpty)
            _buildExpandedSection(
              context,
              'Bài tập thực hành',
              Icons.code,
              node.practicalExercises!,
            ),
          if (node.suggestedResources != null &&
              node.suggestedResources!.isNotEmpty)
            _buildExpandedSection(
              context,
              'Tài nguyên đề xuất',
              Icons.link,
              node.suggestedResources!,
            ),
          if (node.successCriteria != null &&
              node.successCriteria!.isNotEmpty)
            _buildExpandedSection(
              context,
              'Tiêu chí hoàn thành',
              Icons.verified_outlined,
              node.successCriteria!,
            ),
          if (node.prerequisites != null &&
              node.prerequisites!.isNotEmpty)
            _buildExpandedSection(
              context,
              'Điều kiện tiên quyết',
              Icons.account_tree_outlined,
              _resolvePrerequisiteLabels(node.prerequisites!),
            ),
          // Lessons
          if (node.lessons != null && node.lessons!.isNotEmpty)
            _buildLessonsSection(context, node.lessons!),
          // ── Feature B: Assignment + Evidence ─────────────────────────────
          if (_isLoadingMentoring)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: CommonLoading.small(),
            )
          else if (_mentoringLoaded) ...[
            if (_assignment != null || _evidence != null)
              const Divider(height: 24),
            if (_assignment != null) _buildAssignmentSection(context),
            _buildEvidenceSection(context),
          ],
          const SizedBox(height: 8),
          _buildCreateStudyPlanButton(context, node),
        ],
      ),
    );
  }

  Widget _buildAssignmentSection(BuildContext context) {
    final a = _assignment!;
    final isMentor = a.assignmentSource == AssignmentSource.mentorRefined;
    final sourceLabel = isMentor ? 'Mentor cập nhật' : 'Hệ thống gợi ý';
    final sourceColor = isMentor ? AppTheme.primaryBlue : AppTheme.warningColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 16,
                    color: widget.isDark
                        ? AppTheme.primaryBlueDark
                        : AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Nhiệm vụ chi tiết',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark
                            ? AppTheme.primaryBlueDark
                            : AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: sourceColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      sourceLabel,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: sourceColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (a.title != null)
                Text(
                  a.title!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: widget.isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
              if (a.description != null) ...[
                const SizedBox(height: 4),
                FormattedAIResponse(
                  content: a.description!,
                  isDark: widget.isDark,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEvidenceSection(BuildContext context) {
    final ev = _evidence;
    // No journey found — nothing to show
    if (_journeyId == null) return const SizedBox.shrink();

    if (ev == null) {
      // Not yet submitted
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showEvidenceSubmissionSheet(context),
            icon: Icon(
              Icons.upload_outlined,
              size: 18,
              color: widget.isDark ? AppTheme.accentCyan : AppTheme.primaryBlue,
            ),
            label: Text(
              'Nộp bằng chứng',
              style: TextStyle(
                color: widget.isDark
                    ? AppTheme.accentCyan
                    : AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: widget.isDark
                    ? AppTheme.accentCyan.withValues(alpha: 0.4)
                    : AppTheme.primaryBlue.withValues(alpha: 0.4),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      );
    }

    // Has evidence
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.fact_check_outlined, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Bằng chứng đã nộp',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                    ),
                  ),
                  if (ev.submissionStatus != null && ev.latestReview == null)
                    Flexible(
                      child: StatusBadge(status: ev.submissionStatus!.name),
                    ),
                ],
              ),
              if (ev.submittedAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Nộp lúc: ${DateTimeHelper.formatDateTime(ev.submittedAt!)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
              // Mentor feedback
              if (ev.mentorFeedback != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.errorColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.feedback_outlined,
                            size: 13,
                            color: AppTheme.errorColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Phản hồi từ mentor',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.errorColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ev.mentorFeedback!,
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Latest review
              if (ev.latestReview != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Đánh giá: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                    if (ev.latestReview!.reviewResult != null)
                      StatusBadge(status: ev.latestReview!.reviewResult!.name),
                    if (ev.latestReview!.score != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${ev.latestReview!.score!.toStringAsFixed(0)}/100',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              // Rework CTA
              if (ev.reworkRequested) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showEvidenceSubmissionSheet(context),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Cập nhật bằng chứng'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warningColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showEvidenceSubmissionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _NodeEvidenceSubmissionSheet(
        isDark: widget.isDark,
        existingEvidence: _evidence,
        onSubmit: (request) async {
          final jId = _journeyId;
          if (jId == null) return;
          await _mentoringService.submitEvidence(jId, widget.node.id, request);
          // Reload evidence after submit
          final updated = await _mentoringService.getEvidence(
            jId,
            widget.node.id,
          );
          if (mounted) {
            setState(() => _evidence = updated);
          }
        },
      ),
    );
  }

  Widget _buildExpandedSection(
    BuildContext context,
    String title,
    IconData icon,
    List<String> items,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: widget.isDark
                    ? AppTheme.primaryBlueDark
                    : AppTheme.primaryBlue,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: widget.isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      color: widget.isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: widget.isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsSection(
    BuildContext context,
    List<RoadmapLesson> lessons,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 16,
                color: widget.isDark
                    ? AppTheme.primaryBlueDark
                    : AppTheme.primaryBlue,
              ),
              const SizedBox(width: 8),
              Text(
                'Nội dung bài học (${lessons.length})',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: widget.isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...lessons.asMap().entries.map((entry) {
            final index = entry.key;
            final lesson = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: widget.isDark
                      ? AppTheme.accentCyan.withValues(alpha: 0.15)
                      : AppTheme.primaryBlue.withValues(alpha: 0.12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Bài ${index + 1}: ${lesson.title}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: widget.isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                          ),
                        ),
                      ),
                      if (lesson.estimatedMinutes != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentCyan.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${lesson.estimatedMinutes} phút',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.accentCyan,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (lesson.description != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      lesson.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                  if (lesson.learningObjective != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: widget.isDark
                                ? AppTheme.darkBorderColor
                                : AppTheme.lightBorderColor,
                          ),
                        ),
                      ),
                      child: Text(
                        'Mục tiêu: ${lesson.learningObjective}',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: widget.isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCreateStudyPlanButton(BuildContext context, RoadmapNode node) {
    final status = node.nodeStatus?.toUpperCase();
    if (status == 'COMPLETED') return const SizedBox.shrink();

    // LOCKED node: show hint instead of action buttons
    if (status == 'LOCKED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:
              (widget.isDark
                      ? AppTheme.darkBorderColor
                      : AppTheme.lightBorderColor)
                  .withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lock_outline,
              size: 16,
              color: widget.isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Hoàn thành node trước để mở khóa',
              style: TextStyle(
                fontSize: 12,
                color: widget.isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _isCreatingPlan || _isCompletingNode
                  ? null
                  : widget.hasStudyPlan
                      ? () {
                          // Navigate to Task Board scoped to this roadmap
                          context.read<TaskBoardProvider>().loadBoardForRoadmap(
                            widget.sessionId,
                          );
                          context.push('/task-board');
                        }
                      : () => _createStudyPlan(node),
              icon: _isCreatingPlan
                  ? CommonLoading.small()
                  : Icon(
                      Icons.event_note_outlined,
                      size: 18,
                      color: widget.isDark
                          ? AppTheme.accentCyan
                          : AppTheme.primaryBlue,
                    ),
              label: Text(
                _isCreatingPlan 
                    ? 'Đang tạo KH...' 
                    : widget.hasStudyPlan
                        ? 'Xem kế hoạch'
                        : (_assignment != null ? 'Tạo Task học tập' : 'Lên kế hoạch'),
                style: TextStyle(
                  color: _isCreatingPlan || _isCompletingNode
                      ? (widget.isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary)
                      : (widget.isDark
                            ? AppTheme.accentCyan
                            : AppTheme.primaryBlue),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: widget.isDark
                      ? AppTheme.accentCyan.withValues(alpha: 0.4)
                      : AppTheme.primaryBlue.withValues(alpha: 0.4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
        if (_assignment == null) ...[
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            width: 48,
            child: ElevatedButton(
              onPressed: _isCreatingPlan || _isCompletingNode
                  ? null
                  : () => _showCompleteNodeDialog(node),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: AppTheme.successColor.withValues(alpha: 0.15),
                foregroundColor: AppTheme.successColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isCompletingNode
                  ? CommonLoading.small()
                  : const Icon(Icons.done_all, size: 20),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showCompleteNodeDialog(RoadmapNode node) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hoàn thành trọn vẹn?'),
        content: const Text(
          'Xác nhận hoàn thành chặng này? Tiến độ sẽ được cập nhật và node tiếp theo sẽ được mở khóa nếu có.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
            ),
            child: const Text('Chắc chắn'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _completeNode(node);
    }
  }

  Future<void> _completeNode(RoadmapNode node) async {
    if (!mounted) return;
    setState(() => _isCompletingNode = true);

    try {
      // Backend handles completing all related tasks — no extra call needed
      await context.read<RoadmapDetailProvider>().completeNode(
        widget.sessionId,
        node.id,
      );
      if (!mounted) return;
      // Invalidate board cache so any open Task Board reflects the backend changes
      context.read<TaskBoardProvider>().loadBoard();
      ErrorHandler.showSuccessSnackBar(context, 'Đã hoàn thành chặng!');
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isCompletingNode = false);
    }
  }

  Future<void> _createStudyPlan(RoadmapNode node) async {
    if (!mounted) return;
    setState(() => _isCreatingPlan = true);

    try {
      final provider = context.read<RoadmapDetailProvider>();
      final result = await provider.createStudyPlanForNode(
        roadmapSessionId: widget.sessionId,
        nodeId: node.id,
      );

      if (!mounted) return;

      final message =
          result?['message'] as String? ?? 'Đã tạo kế hoạch học tập!';
      final taskCount = result?['taskCount'] as int? ?? 0;
      final displayMsg = taskCount > 0 ? '$message ($taskCount task)' : message;

      // Show snackbar with CTA to navigate to the task board
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayMsg,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          action: SnackBarAction(
            label: 'Xem board',
            textColor: Colors.white,
            onPressed: () {
              if (context.mounted) {
                // Scope the board to this roadmap session so created tasks are visible
                context.read<TaskBoardProvider>().loadBoardForRoadmap(
                  widget.sessionId,
                );
                context.push('/task-board');
              }
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isCreatingPlan = false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Evidence Submission Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _NodeEvidenceSubmissionSheet extends StatefulWidget {
  final bool isDark;
  final NodeEvidenceRecordResponse? existingEvidence;
  final Future<void> Function(SubmitNodeEvidenceRequest) onSubmit;

  const _NodeEvidenceSubmissionSheet({
    required this.isDark,
    required this.onSubmit,
    this.existingEvidence,
  });

  @override
  State<_NodeEvidenceSubmissionSheet> createState() =>
      _NodeEvidenceSubmissionSheetState();
}

class _NodeEvidenceSubmissionSheetState
    extends State<_NodeEvidenceSubmissionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _textCtrl = TextEditingController();
  final _evidenceUrlCtrl = TextEditingController();
  final _attachmentUrlCtrl = TextEditingController();
  final _nodeMentoringService = NodeMentoringService();
  bool _isBusy = false;
  bool _submitted = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  PlatformFile? _pickedAttachment;
  String? _attachmentPickError;

  static const _maxAttachmentBytes = 10 * 1024 * 1024; // 10MB
  static const _allowedExtensions = [
    'pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'zip', 'rar'
  ];

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = (bytes.toDouble() == 0) ? 0 : (bytes.toDouble().abs().toString().length / 3).floor();
    if (i >= suffixes.length) i = suffixes.length - 1;
    final value = bytes / (1024 * i);
    return '${value.toStringAsFixed(1)} ${suffixes[i]}';
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _onPickAttachment() async {
    setState(() => _attachmentPickError = null);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
        withData: false,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.size > _maxAttachmentBytes) {
        setState(() => _attachmentPickError = 'File vượt quá 10MB');
        return;
      }
      final ext = (file.extension ?? '').toLowerCase();
      if (!_allowedExtensions.contains(ext)) {
        setState(() => _attachmentPickError =
            'Định dạng không hỗ trợ. Cho phép: ${_allowedExtensions.join(", ")}');
        return;
      }
      setState(() => _pickedAttachment = file);
    } catch (e) {
      setState(() => _attachmentPickError = 'Lỗi chọn file: $e');
    }
  }

  void _onRemoveAttachment() {
    setState(() {
      _pickedAttachment = null;
      _attachmentPickError = null;
    });
  }

  @override
  void initState() {
    super.initState();
    final ev = widget.existingEvidence;
    if (ev != null) {
      _textCtrl.text = ev.submissionText ?? '';
      _evidenceUrlCtrl.text = ev.evidenceUrl ?? '';
      _attachmentUrlCtrl.text = ev.attachmentUrl ?? '';
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _evidenceUrlCtrl.dispose();
    _attachmentUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isBusy = true);
    try {
      if (_pickedAttachment != null && _pickedAttachment!.path != null) {
        final actorId = context.read<AuthProvider>().user?.id;
        if (actorId == null) {
          ErrorHandler.showErrorSnackBar(context, 'Bạn cần đăng nhập lại.');
          setState(() => _isBusy = false);
          return;
        }

        setState(() {
          _isUploading = true;
          _uploadProgress = 0;
        });

        final uploadedUrl = await _nodeMentoringService.uploadAttachment(
          filePath: _pickedAttachment!.path!,
          fileName: _pickedAttachment!.name,
          actorId: actorId,
          onProgress: (p) => setState(() => _uploadProgress = p),
        );
        _attachmentUrlCtrl.text = uploadedUrl;
      }

      await widget.onSubmit(
        SubmitNodeEvidenceRequest(
          submissionText: _textCtrl.text.trim(),
          evidenceUrl: _evidenceUrlCtrl.text.trim().isEmpty
              ? null
              : _evidenceUrlCtrl.text.trim(),
          attachmentUrl: _attachmentUrlCtrl.text.trim().isEmpty
              ? null
              : _attachmentUrlCtrl.text.trim(),
        ),
      );
      if (mounted) {
        setState(() => _submitted = true);
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _isUploading = false;
        });
      }
    }
  }

  Widget _buildAttachmentZone() {
    final picked = _pickedAttachment;
    final existingUrl = widget.existingEvidence?.attachmentUrl;
    final isDark = widget.isDark;
    final borderColor = isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor;
    final accent = isDark ? AppTheme.accentCyan : AppTheme.primaryBlue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _isBusy || _isUploading || picked != null ? null : _onPickAttachment,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: picked != null
                  ? accent.withValues(alpha: 0.06)
                  : (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: picked != null ? accent : borderColor,
                width: picked != null ? 1.5 : 1,
              ),
            ),
            child: picked != null
                ? Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          (picked.extension ?? 'FILE').toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              picked.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatBytes(picked.size),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!_isBusy && !_isUploading)
                        IconButton(
                          onPressed: _onRemoveAttachment,
                          icon: const Icon(Icons.close, size: 18),
                          tooltip: 'Bỏ file',
                        ),
                    ],
                  )
                : Column(
                    children: [
                      Icon(
                        Icons.upload_file_outlined,
                        size: 28,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Đính kèm file (PDF / DOCX / Ảnh)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tối đa 10MB',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (_attachmentPickError != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 14, color: AppTheme.errorColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _attachmentPickError!,
                  style: const TextStyle(fontSize: 12, color: AppTheme.errorColor),
                ),
              ),
            ],
          ),
        ],
        if (_isUploading) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _uploadProgress > 0 ? _uploadProgress : null,
              minHeight: 6,
              backgroundColor: borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
        if (picked == null && existingUrl != null && existingUrl.isNotEmpty) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _openUrl(existingUrl),
            child: Row(
              children: [
                const Icon(Icons.attach_file, size: 14, color: AppTheme.primaryBlue),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'File đã đính kèm — Tải xuống',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryBlue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCardBackground : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          bottom: true,
          child: _submitted
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 56,
                        color: AppTheme.successColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Đã nộp bằng chứng!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  controller: scrollCtrl,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          children: [
                            // Handle
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.existingEvidence != null
                                  ? 'Cập nhật bằng chứng'
                                  : 'Nộp bằng chứng',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Submission text
                              TextFormField(
                                controller: _textCtrl,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  labelText: 'Mô tả bằng chứng *',
                                  hintText: 'Mô tả những gì bạn đã làm...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Vui lòng nhập mô tả';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              // Evidence URL
                              TextFormField(
                                controller: _evidenceUrlCtrl,
                                keyboardType: TextInputType.url,
                                decoration: InputDecoration(
                                  labelText: 'URL bằng chứng (GitHub, Demo...)',
                                  hintText: 'https://github.com/...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  prefixIcon: const Icon(Icons.link),
                                ),
                                validator: (v) {
                                  if (v != null &&
                                      v.trim().isNotEmpty &&
                                      !Uri.tryParse(
                                        v.trim(),
                                      )!.hasAbsolutePath) {
                                    return 'URL không hợp lệ';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildAttachmentZone(),
                              const SizedBox(height: 24),
                              // Submit button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isBusy ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryBlue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isBusy || _isUploading
                                      ? CommonLoading.small()
                                      : const Text(
                                          'Nộp bằng chứng',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
