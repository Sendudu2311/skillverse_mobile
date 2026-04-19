import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/roadmap_models.dart';
import '../../providers/roadmap_detail_provider.dart';
import '../../providers/task_board_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/common_loading.dart';
import '../../../core/utils/error_handler.dart';

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
              ? (widget.isDark ? AppTheme.primaryBlueDark : AppTheme.primaryBlue)
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
                              : AppTheme.secondaryPurple.withValues(alpha: 0.15),
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
                      Checkbox(
                        value: widget.isCompleted,
                        onChanged: (value) => widget.onToggleQuestCompletion(
                          node.id,
                          value ?? false,
                        ),
                        activeColor: AppTheme.successColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
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
                    overflow:
                        widget.isExpanded ? null : TextOverflow.ellipsis,
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
          const SizedBox(height: 8),
          _buildCreateStudyPlanButton(context, node),
        ],
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
    if (node.nodeStatus?.toUpperCase() == 'COMPLETED') {
      return const SizedBox.shrink(); 
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _isCreatingPlan || _isCompletingNode ? null : () => _createStudyPlan(node),
              icon: _isCreatingPlan
                  ? CommonLoading.small()
                  : Icon(
                      Icons.event_note_outlined,
                      size: 18,
                      color: widget.isDark ? AppTheme.accentCyan : AppTheme.primaryBlue,
                    ),
              label: Text(
                _isCreatingPlan ? 'Đang tạo KH...' : 'Lên kế hoạch',
                style: TextStyle(
                  color: _isCreatingPlan || _isCompletingNode
                      ? (widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)
                      : (widget.isDark ? AppTheme.accentCyan : AppTheme.primaryBlue),
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
            onPressed: _isCreatingPlan || _isCompletingNode ? null : () => _showCompleteNodeDialog(node),
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
          'Hành động này sẽ đánh dấu chặng này là đã hoàn thành, đồng thời chuyển trạng thái tất cả task liên quan trong Bảng công việc sang "Hoàn thành". Bạn chắc chắn chứ?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
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
      final roadmapProvider = context.read<RoadmapDetailProvider>();
      final taskProvider = context.read<TaskBoardProvider>();

      // Call APIs consecutively
      await roadmapProvider.completeNode(widget.sessionId, node.id);
      await taskProvider.completeAllTasksForNode(widget.sessionId, node.id);

      if (!mounted) return;
      ErrorHandler.showSuccessSnackBar(context, 'Đã đánh dấu hoàn thành chặng!');
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, 'Lỗi hoàn thành chặng: $e');
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
      final displayMsg =
          taskCount > 0 ? '$message ($taskCount task)' : message;
      ErrorHandler.showSuccessSnackBar(context, displayMsg);
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isCreatingPlan = false);
    }
  }
}
