import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/roadmap_provider.dart';
import '../../themes/app_theme.dart';
import '../../../data/models/roadmap_models.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/painters/grid_painter.dart';

class RoadmapDetailPage extends StatefulWidget {
  final int sessionId;

  const RoadmapDetailPage({super.key, required this.sessionId});

  @override
  State<RoadmapDetailPage> createState() => _RoadmapDetailPageState();
}

class _RoadmapDetailPageState extends State<RoadmapDetailPage> {
  String? _expandedNodeId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoadmapProvider>().loadRoadmapById(widget.sessionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Consumer<RoadmapProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return _buildLoadingState(context, isDark);
          }

          if (provider.errorMessage != null) {
            return _buildErrorState(context, provider.errorMessage!, isDark);
          }

          final roadmap = provider.currentRoadmap;
          if (roadmap == null) {
            return _buildErrorState(context, 'Không tìm thấy lộ trình', isDark);
          }

          return _buildContent(context, roadmap, provider, isDark);
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Đang tải lộ trình...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, bool isDark) {
    return SafeArea(
      child: Column(
        children: [
          _buildBackButton(context, isDark),
          Expanded(
            child: Center(
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
                    Text(
                      'Không thể tải lộ trình',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/roadmap'),
                      child: const Text('Quay lại danh sách'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    RoadmapResponse roadmap,
    RoadmapProvider provider,
    bool isDark,
  ) {
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: isDark
              ? AppTheme.galaxyDark
              : AppTheme.lightBackgroundPrimary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: _buildHeaderBackground(context, roadmap, isDark),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats cards
              _buildStatsRow(context, roadmap, isDark),

              // Metadata section
              _buildMetadataSection(context, roadmap, isDark),

              // Validation notes
              if (roadmap.metadata.validationNotes != null)
                _buildValidationNotes(
                  context,
                  roadmap.metadata.validationNotes!,
                  isDark,
                ),

              // Warnings
              if (roadmap.warnings != null && roadmap.warnings!.isNotEmpty)
                _buildWarnings(context, roadmap.warnings!, isDark),

              // Learning tips
              if (roadmap.learningTips != null &&
                  roadmap.learningTips!.isNotEmpty)
                _buildLearningTips(context, roadmap.learningTips!, isDark),

              // Roadmap nodes
              _buildNodesSection(context, roadmap, provider, isDark),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
    );
  }

  Widget _buildHeaderBackground(
    BuildContext context,
    RoadmapResponse roadmap,
    bool isDark,
  ) {
    return Stack(
      children: [
        // Background Image/Gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Color(0xFF1E1B4B), // Indigo 950
                      Color(0xFF312E81), // Indigo 900
                      Color(0xFF0F172A), // Slate 900
                    ]
                  : [
                      Color(0xFFE0E7FF), // Indigo 100
                      Color(0xFFF3F4F6), // Gray 100
                    ],
            ),
          ),
        ),

        // Grid texture (optional)
        if (isDark)
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(painter: GridPainter()),
            ),
          ),

        // Gradient overlay for text readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
              stops: const [0.6, 1.0],
            ),
          ),
        ),

        // Content
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Tags row
              Row(
                children: [
                  _buildTag(
                    'System Online',
                    AppTheme.successColor,
                    Icons.circle,
                    isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildTag(
                    roadmap.metadata.roadmapMode == RoadmapMode.careerBased
                        ? 'Career Protocol'
                        : 'Skill Protocol',
                    const Color(0xFF60A5FA), // Blue 400
                    Icons.schema,
                    isDark,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                roadmap.metadata.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle/Experience level
              Row(
                children: [
                  Icon(
                    Icons.signal_cellular_alt,
                    size: 16,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    roadmap.metadata.experienceLevel,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.timer_outlined, size: 16, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    'Updated: V2.1',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String label, Color color, IconData? icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 8, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    RoadmapResponse roadmap,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.schedule_outlined,
                label: 'Thời lượng',
                value: roadmap.metadata.duration,
                subValue: '${roadmap.statistics.totalEstimatedHours}h',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.layers_outlined,
                label: 'Tổng bước',
                value: '${roadmap.statistics.totalNodes}',
                subValue: 'Modules',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.star_outline,
                label: 'Nhiệm vụ',
                value: '${roadmap.statistics.mainNodes}',
                subValue: 'Chính',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.tag,
                label: 'Nhiệm vụ',
                value: '${roadmap.statistics.sideNodes}',
                subValue: 'Phụ',
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    String? subValue,
    required bool isDark,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 16,
      backgroundColor: isDark
          ? const Color(0xFF1E293B).withOpacity(0.6)
          : Colors.white.withOpacity(0.7),
      borderColor: isDark
          ? Colors.white.withOpacity(0.1)
          : Colors.black.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.primaryBlue.withOpacity(0.2)
                  : AppTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: isDark ? AppTheme.primaryBlueDark : AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
              ),
              if (subValue != null) ...[
                const SizedBox(height: 2),
                Text(
                  subValue,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection(
    BuildContext context,
    RoadmapResponse roadmap,
    bool isDark,
  ) {
    final metadata = roadmap.metadata;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        borderRadius: 16,
        backgroundColor: isDark
            ? const Color(0xFF1E293B).withOpacity(0.6)
            : Colors.white.withOpacity(0.7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Goal
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        (isDark
                                ? AppTheme.primaryBlueDark
                                : AppTheme.primaryBlue)
                            .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.flag_rounded,
                    size: 20,
                    color: isDark
                        ? AppTheme.primaryBlueDark
                        : AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mục tiêu chiến dịch',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppTheme.primaryBlueDark
                              : AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        metadata.validatedGoal ?? metadata.originalGoal,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
            const SizedBox(height: 24),

            // Grid of metadata items
            Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                if (metadata.target != null)
                  _buildMetadataItem(
                    context,
                    'Vị trí mục tiêu',
                    metadata.target!,
                    isDark,
                  ),
                if (metadata.background != null)
                  _buildMetadataItem(
                    context,
                    'Background',
                    metadata.background!,
                    isDark,
                  ),
                _buildMetadataItem(
                  context,
                  'Thời gian cam kết',
                  metadata.duration,
                  isDark,
                ),
                if (metadata.targetEnvironment != null)
                  _buildMetadataItem(
                    context,
                    'Môi trường',
                    metadata.targetEnvironment!,
                    isDark,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataItem(
    BuildContext context,
    String label,
    String value,
    bool isDark,
  ) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.4 - 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationNotes(
    BuildContext context,
    String notes,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? AppTheme.darkBorderColor
                : AppTheme.lightBorderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: isDark
                      ? AppTheme.primaryBlueDark
                      : AppTheme.primaryBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  'VALIDATION NOTES',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.primaryBlueDark
                        : AppTheme.primaryBlue,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              notes,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarnings(
    BuildContext context,
    List<String> warnings,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.warningColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.warningColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_outlined,
                  size: 18,
                  color: AppTheme.warningColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'WARNINGS',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.warningColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...warnings.map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: AppTheme.warningColor)),
                    Expanded(
                      child: Text(
                        w,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningTips(
    BuildContext context,
    List<String> tips,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.successColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.successColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tips_and_updates_outlined,
                  size: 18,
                  color: AppTheme.successColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'LEARNING TIPS',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.successColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...tips
                .take(3)
                .map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 14,
                          color: AppTheme.successColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tip,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: isDark
                                      ? AppTheme.darkTextPrimary
                                      : AppTheme.lightTextPrimary,
                                  height: 1.4,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildNodesSection(
    BuildContext context,
    RoadmapResponse roadmap,
    RoadmapProvider provider,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LỘ TRÌNH HỌC TẬP',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.primaryBlueDark : AppTheme.primaryBlue,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),

          // Progress overview
          _buildProgressOverview(context, roadmap, isDark),
          const SizedBox(height: 16),

          // Node list
          ...roadmap.roadmap.map(
            (node) => _buildNodeCard(context, node, provider, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressOverview(
    BuildContext context,
    RoadmapResponse roadmap,
    bool isDark,
  ) {
    final progress = roadmap.progressPercentage;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.1),
            AppTheme.secondaryPurple.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tiến độ tổng thể',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 8,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 80
                          ? AppTheme.successColor
                          : progress >= 50
                          ? AppTheme.warningColor
                          : AppTheme.primaryBlueDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              Text(
                '${progress.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppTheme.primaryBlueDark
                      : AppTheme.primaryBlue,
                ),
              ),
              Text(
                '${roadmap.completedQuestsCount}/${roadmap.roadmap.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNodeCard(
    BuildContext context,
    RoadmapNode node,
    RoadmapProvider provider,
    bool isDark,
  ) {
    final isExpanded = _expandedNodeId == node.id;
    final isCompleted = provider.isQuestCompleted(node.id);
    final isMainQuest = node.isMainQuest;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkCardBackground
            : AppTheme.lightCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMainQuest
              ? (isDark ? AppTheme.primaryBlueDark : AppTheme.primaryBlue)
                    .withValues(alpha: 0.3)
              : isDark
              ? AppTheme.darkBorderColor
              : AppTheme.lightBorderColor,
          style: isMainQuest ? BorderStyle.solid : BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                _expandedNodeId = isExpanded ? null : node.id;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge & checkbox
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
                      const Spacer(),
                      Checkbox(
                        value: isCompleted,
                        onChanged: (value) => _toggleQuestCompletion(
                          context,
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
                    node.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    node.description,
                    maxLines: isExpanded ? null : 2,
                    overflow: isExpanded ? null : TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Stats row
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 14,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${node.estimatedTimeHours.toStringAsFixed(0)}h',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                      const Spacer(),
                      if (node.difficulty != null)
                        _buildDifficultyBadge(
                          context,
                          node.difficulty!,
                          isDark,
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: isDark
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
          if (isExpanded) _buildExpandedContent(context, node, isDark),
        ],
      ),
    );
  }

  Widget _buildDifficultyBadge(
    BuildContext context,
    DifficultyLevel difficulty,
    bool isDark,
  ) {
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

  Widget _buildExpandedContent(
    BuildContext context,
    RoadmapNode node,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 12),

          // Learning objectives
          if (node.learningObjectives != null &&
              node.learningObjectives!.isNotEmpty)
            _buildExpandedSection(
              context,
              'Mục tiêu học tập',
              Icons.check_circle_outline,
              node.learningObjectives!,
              isDark,
            ),

          // Key concepts
          if (node.keyConcepts != null && node.keyConcepts!.isNotEmpty)
            _buildExpandedSection(
              context,
              'Khái niệm chính',
              Icons.lightbulb_outline,
              node.keyConcepts!,
              isDark,
            ),

          // Practical exercises
          if (node.practicalExercises != null &&
              node.practicalExercises!.isNotEmpty)
            _buildExpandedSection(
              context,
              'Bài tập thực hành',
              Icons.code,
              node.practicalExercises!,
              isDark,
            ),

          // Resources
          if (node.suggestedResources != null &&
              node.suggestedResources!.isNotEmpty)
            _buildExpandedSection(
              context,
              'Tài nguyên đề xuất',
              Icons.link,
              node.suggestedResources!,
              isDark,
            ),
        ],
      ),
    );
  }

  Widget _buildExpandedSection(
    BuildContext context,
    String title,
    IconData icon,
    List<String> items,
    bool isDark,
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
                color: isDark ? AppTheme.primaryBlueDark : AppTheme.primaryBlue,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
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
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
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

  Future<void> _toggleQuestCompletion(
    BuildContext context,
    String questId,
    bool completed,
  ) async {
    final provider = context.read<RoadmapProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final response = await provider.updateQuestProgress(
      sessionId: widget.sessionId,
      questId: questId,
      completed: completed,
    );

    if (response != null && mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            completed
                ? 'Đã hoàn thành nhiệm vụ! 🎉'
                : 'Đã bỏ đánh dấu hoàn thành',
          ),
          backgroundColor: completed
              ? AppTheme.successColor
              : AppTheme.warningColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
