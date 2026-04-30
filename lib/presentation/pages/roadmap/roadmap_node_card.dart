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
  final VoidCallback onToggleExpand;
  final void Function(String questId, bool completed) onToggleQuestCompletion;

  const RoadmapNodeCard({
    super.key,
    required this.node,
    required this.isExpanded,
    required this.isCompleted,
    required this.isDark,
    required this.sessionId,
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
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isMainQuest
                              ? AppTheme.primaryBlueDark.withValues(alpha: 0.15)
                              : AppTheme.secondaryPurple.withValues(
                                  alpha: 0.15,
                                ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isMainQuest ? Icons.star : Icons.bookmark_outline,
                              size: 12,
                              color: isMainQuest
                                  ? AppTheme.primaryBlueDark
                                  : AppTheme.secondaryPurple,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isMainQuest ? 'Nhiệm vụ chính' : 'Nhiệm vụ phụ',
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
                      if (node.nodeStatus != null) ...[
                        const SizedBox(width: 8),
                        StatusBadge(
                          status: node.nodeStatus!,
                          icon: _getNodeStatusIcon(node.nodeStatus!),
                        ),
                      ],
                      const Spacer(),
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

  Widget _buildDifficultyBadge(DifficultyLevel difficulty) {
    String label;
    Color color;
    switch (difficulty) {
      case DifficultyLevel.easy:
      case DifficultyLevel.beginner:
        label = 'EASY';
        color = AppTheme.successColor;
        break;
      case DifficultyLevel.medium:
      case DifficultyLevel.intermediate:
        label = 'MEDIUM';
        color = AppTheme.warningColor;
        break;
      case DifficultyLevel.hard:
      case DifficultyLevel.advanced:
        label = 'HARD';
        color = AppTheme.errorColor;
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
                      'Bài tập từ mentor',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark
                            ? AppTheme.primaryBlueDark
                            : AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                a.title ?? 'Bài tập',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: widget.isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
              if (a.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  a.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: widget.isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                    height: 1.4,
                  ),
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
                  Text(
                    'Bằng chứng đã nộp',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (ev.submissionStatus != null)
                    StatusBadge(status: ev.submissionStatus!.name),
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
                  : () => _showStudyPlanChoiceSheet(node),
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
                _isCreatingPlan ? 'Đang tạo KH...' : 'Lên kế hoạch',
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

  /// V3: Show bottom sheet offering Self-Study vs Mentor Verification
  void _showStudyPlanChoiceSheet(RoadmapNode node) {
    final isDark = widget.isDark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark
          ? AppTheme.darkBackgroundPrimary
          : AppTheme.lightBackgroundPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bạn muốn học node này như thế nào?',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  node.title,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                // Option 1: Self-study
                _buildChoiceOption(
                  ctx: ctx,
                  icon: Icons.auto_stories_outlined,
                  title: 'Tự học',
                  subtitle:
                      'Tạo kế hoạch và tự hoàn thành. Bạn có thể nộp minh chứng sau.',
                  color: isDark ? AppTheme.accentCyan : AppTheme.primaryBlue,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _createStudyPlan(node);
                  },
                ),
                const SizedBox(height: 12),
                // Option 2: Mentor verification
                _buildChoiceOption(
                  ctx: ctx,
                  icon: Icons.verified_user_outlined,
                  title: 'Xác thực với Mentor',
                  subtitle:
                      'Tìm mentor đánh giá và hỗ trợ bạn hoàn thành node này.',
                  color: AppTheme.warningColor,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    // Navigate to mentor list with context
                    context.push('/mentors?action=node_mentoring');
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChoiceOption({
    required BuildContext ctx,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = widget.isDark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color, size: 20),
          ],
        ),
      ),
    );
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
  bool _isBusy = false;
  bool _submitted = false;

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
      if (mounted) setState(() => _isBusy = false);
    }
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
                              // Attachment URL
                              TextFormField(
                                controller: _attachmentUrlCtrl,
                                keyboardType: TextInputType.url,
                                decoration: InputDecoration(
                                  labelText: 'Tệp đính kèm (tuỳ chọn)',
                                  hintText: 'https://...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  prefixIcon: const Icon(Icons.attach_file),
                                ),
                              ),
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
                                  child: _isBusy
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
