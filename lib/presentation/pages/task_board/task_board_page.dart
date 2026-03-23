import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/task_board_provider.dart';
import '../../themes/app_theme.dart';
import 'widgets/ai_study_planner_dialog.dart';
import 'widgets/timeline_view.dart';
import 'widgets/kanban_view.dart';

/// Main Task Board Page - Mission Control
class TaskBoardPage extends StatefulWidget {
  const TaskBoardPage({super.key});

  @override
  State<TaskBoardPage> createState() => _TaskBoardPageState();
}

class _TaskBoardPageState extends State<TaskBoardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TaskBoardProvider>();
      provider.loadBoard();
      provider.loadNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: Row(
          children: [
            Icon(
              Icons.satellite_alt,
              color: AppTheme.primaryBlueDark,
              size: 28,
            ),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppTheme.primaryBlueDark, AppTheme.accentCyan],
              ).createShader(bounds),
              child: const Text(
                'MISSION CONTROL',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '>> ',
                  style: TextStyle(
                    color: AppTheme.primaryBlueDark,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Lập kế hoạch học tập thông minh và quản lý nhiệm vụ hiệu quả với công cụ AI tích hợp.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Consumer<TaskBoardProvider>(
              builder: (context, provider, _) => Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      icon: Icons.auto_awesome,
                      label: 'AI STRATEGIST',
                      isSelected: provider.selectedTabIndex == 0,
                      onTap: () => provider.setSelectedTab(0),
                      color: AppTheme.accentOrange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTabButton(
                      icon: Icons.calendar_month,
                      label: 'TIMELINE',
                      isSelected: provider.selectedTabIndex == 1,
                      onTap: () => provider.setSelectedTab(1),
                      color: AppTheme.primaryBlueDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTabButton(
                      icon: Icons.view_column,
                      label: 'KANBAN',
                      isSelected: provider.selectedTabIndex == 2,
                      onTap: () => provider.setSelectedTab(2),
                      color: AppTheme.primaryBlueDark,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Tab Content
          Expanded(
            child: Consumer<TaskBoardProvider>(
              builder: (context, provider, _) {
                switch (provider.selectedTabIndex) {
                  case 0:
                    return _buildAIStrategistView();
                  case 1:
                    return const TimelineView();
                  case 2:
                    return const KanbanView();
                  default:
                    return const TimelineView();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark
                      ? AppTheme.darkBorderColor
                      : AppTheme.lightBorderColor),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? color
                  : (isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontFamily: 'monospace',
                  color: isSelected
                      ? color
                      : (isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary),
                  letterSpacing: 1,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIStrategistView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 80,
              color: AppTheme.accentOrange.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 24),
            Text(
              'AI STUDY PLANNER',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: AppTheme.accentOrange,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tạo lịch học tối ưu với AI. Chỉ cần nhập môn học,\nmục tiêu và thời gian - AI sẽ lên kế hoạch cho bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showAIStudyPlannerDialog(),
              icon: const Icon(Icons.rocket_launch),
              label: const Text('TẠO LỊCH HỌC TỰ ĐỘNG'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAIStudyPlannerDialog() {
    showDialog(
      context: context,
      builder: (context) => const AIStudyPlannerDialog(),
    );
  }
}
