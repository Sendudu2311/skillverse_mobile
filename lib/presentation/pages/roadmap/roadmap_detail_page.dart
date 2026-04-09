import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/roadmap_detail_provider.dart';
import '../../themes/app_theme.dart';
import '../../../data/models/roadmap_models.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/painters/grid_painter.dart';
import '../../../core/utils/error_handler.dart';
import '../../widgets/common_loading.dart';
import 'roadmap_node_card.dart';

class RoadmapDetailPage extends StatefulWidget {
  final int sessionId;

  const RoadmapDetailPage({super.key, required this.sessionId});

  @override
  State<RoadmapDetailPage> createState() => _RoadmapDetailPageState();
}

class _RoadmapDetailPageState extends State<RoadmapDetailPage> {
  String? _expandedNodeId;
  String? _creatingPlanNodeId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoadmapDetailProvider>().loadRoadmapById(widget.sessionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Consumer<RoadmapDetailProvider>(
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
          CommonLoading.center(),
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
    RoadmapDetailProvider provider,
    bool isDark,
  ) {
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 250,
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

              // V2 Overview section
              if (roadmap.overview != null)
                _buildOverviewSection(context, roadmap.overview!, isDark),

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
        // Background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppTheme.indigoDark,
                      AppTheme.primaryBlueDark.withValues(alpha: 0.5),
                      AppTheme.galaxyDark,
                    ]
                  : [AppTheme.lightBackgroundSecondary, AppTheme.lightBackgroundPrimary],
            ),
          ),
        ),

        // Grid texture
        if (isDark)
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(painter: GridPainter()),
            ),
          ),

        // Gradient overlay
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
              Text(
                _cleanAiText(roadmap.metadata.title),
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
              Row(
                children: [
                  StatusBadge(status: roadmap.roadmapStatus ?? 'ACTIVE'),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.signal_cellular_alt,
                    size: 16,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    roadmap.metadata.experienceLevel,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    roadmap.metadata.duration,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
          ? AppTheme.darkCardBackground
          : AppTheme.lightCardBackground,
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

  /// Strip markdown bold/italic markers from AI-generated text
  String _cleanAiText(String text) {
    return text
        .replaceAll(RegExp(r'\*{2,}'), '') // ** or ***
        .replaceAll(RegExp(r'_{2,}'), '') // __ or ___
        .replaceAll(RegExp(r'(?<=\s)\*(?=\S)|(?<=\S)\*(?=\s)'), '') // lone *
        .trim();
  }

  /// Check if metadata value contains structured key=value pairs
  bool _hasStructuredSpec(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    return value.contains('=') || value.contains('\n') || value.contains(';');
  }

  /// Format camelCase/snake_case key to readable Vietnamese-friendly label
  String _formatSpecKey(String key) {
    const knownLabels = <String, String>{
      'assessmentscore': 'Assessment score',
      'level': 'Cấp độ',
      'scoreband': 'Score band',
      'recommendation': 'Khuyến nghị',
      'recommendationmode': 'Khuyến nghị',
      'strengths': 'Thế mạnh',
      'gaps': 'Khoảng trống',
      'background': 'Nền tảng',
    };
    final normalized = key
        .replaceAll(RegExp(r'[^a-z0-9]', caseSensitive: false), '')
        .toLowerCase();
    if (knownLabels.containsKey(normalized)) return knownLabels[normalized]!;
    return key
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .trim()
        .split(' ')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }

  /// Parse and render structured key=value metadata with chips
  Widget _buildStructuredSpecValue(
    BuildContext context,
    String value,
    bool isDark,
  ) {
    final tokens = value
        .split(RegExp(r'[\n;]+|,\s*'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final entries = <MapEntry<String, String>>[];
    for (final token in tokens) {
      final eqIdx = token.indexOf('=');
      if (eqIdx >= 0) {
        final k = token.substring(0, eqIdx).trim();
        final v = token.substring(eqIdx + 1).trim();
        if (k.isNotEmpty && v.isNotEmpty) {
          entries.add(MapEntry(k, v));
          continue;
        }
      }
      // Append to last entry or add as standalone
      if (entries.isNotEmpty) {
        final last = entries.removeLast();
        entries.add(MapEntry(last.key, '${last.value}, $token'));
      } else {
        entries.add(MapEntry('', token));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (e.key.isNotEmpty) ...[
                Text(
                  _formatSpecKey(e.key),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? AppTheme.accentCyan : AppTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  e.value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetadataSection(
    BuildContext context,
    RoadmapResponse roadmap,
    bool isDark,
  ) {
    final metadata = roadmap.metadata;
    final isSkillBased =
        metadata.roadmapType == 'SKILL_BASED' ||
        metadata.roadmapType == 'skill';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        borderRadius: 16,
        backgroundColor: isDark
            ? AppTheme.darkCardBackground
            : AppTheme.lightCardBackground,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Goal + Mode badge row
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
                            .withValues(alpha: 0.1),
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
                        _cleanAiText(
                          metadata.validatedGoal ?? metadata.originalGoal,
                        ),
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
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            const SizedBox(height: 24),

            // Mode-specific metadata grid
            Wrap(
              spacing: 24,
              runSpacing: 24,
              children: isSkillBased
                  ? [
                      _buildMetadataItem(
                        context,
                        'Kỹ năng trọng tâm',
                        metadata.target ??
                            metadata.skillMode?.skillName ??
                            'N/A',
                        isDark,
                      ),
                      _buildMetadataItem(
                        context,
                        'Cấp độ hiện tại',
                        metadata.currentLevel ?? 'Zero',
                        isDark,
                      ),
                      _buildMetadataItem(
                        context,
                        'Thời gian/ngày',
                        metadata.dailyTime ?? '1h',
                        isDark,
                      ),
                      _buildMetadataItem(
                        context,
                        'Phong cách học',
                        metadata.learningStyle,
                        isDark,
                      ),
                    ]
                  : [
                      _buildMetadataItem(
                        context,
                        'Vị trí mục tiêu',
                        metadata.target ??
                            metadata.careerMode?.targetRole ??
                            'N/A',
                        isDark,
                      ),
                      _buildMetadataItem(
                        context,
                        'Background',
                        metadata.currentLevel ?? metadata.background ?? 'N/A',
                        isDark,
                      ),
                      _buildMetadataItem(
                        context,
                        'Thời gian cam kết',
                        metadata.careerMode?.timelineToWork ??
                            metadata.duration,
                        isDark,
                      ),
                      _buildMetadataItem(
                        context,
                        'Môi trường',
                        metadata.targetEnvironment ??
                            metadata.careerMode?.companyType ??
                            'Startup',
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
    final isStructured = _hasStructuredSpec(value);

    return SizedBox(
      width: isStructured
          ? MediaQuery.of(context).size.width -
                80 // full width for structured
          : MediaQuery.of(context).size.width * 0.4 - 32,
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
          if (isStructured)
            _buildStructuredSpecValue(context, value, isDark)
          else
            Text(
              _cleanAiText(value),
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

  /// V2 Overview section — shows purpose, audience, expected outcomes
  Widget _buildOverviewSection(
    BuildContext context,
    RoadmapOverview overview,
    bool isDark,
  ) {
    final items = <MapEntry<String, String>>[
      if (overview.purpose != null && overview.purpose!.isNotEmpty)
        MapEntry('Mục đích', overview.purpose!),
      if (overview.audience != null && overview.audience!.isNotEmpty)
        MapEntry('Đối tượng', overview.audience!),
      if (overview.postRoadmapState != null &&
          overview.postRoadmapState!.isNotEmpty)
        MapEntry('Kết quả mong đợi', overview.postRoadmapState!),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        borderRadius: 16,
        backgroundColor: isDark
            ? AppTheme.darkCardBackground
            : AppTheme.lightCardBackground,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentCyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.explore_outlined,
                    size: 20,
                    color: AppTheme.accentCyan,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'TỔNG QUAN LỘ TRÌNH',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentCyan,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.key.toUpperCase(),
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
                      _cleanAiText(e.value),
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
            ),
          ],
        ),
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
    RoadmapDetailProvider provider,
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
            (node) => RoadmapNodeCard(
              key: ValueKey(node.id),
              node: node,
              isExpanded: _expandedNodeId == node.id,
              isCompleted: provider.isQuestCompleted(node.id),
              isDark: isDark,
              sessionId: widget.sessionId,
              onToggleExpand: () => setState(() {
                _expandedNodeId =
                    _expandedNodeId == node.id ? null : node.id;
              }),
              onToggleQuestCompletion: (questId, completed) =>
                  _toggleQuestCompletion(context, questId, completed),
            ),
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

  Future<void> _toggleQuestCompletion(
    BuildContext context,
    String questId,
    bool completed,
  ) async {
    final provider = context.read<RoadmapDetailProvider>();

    final response = await provider.updateQuestProgress(
      sessionId: widget.sessionId,
      questId: questId,
      completed: completed,
    );

    if (response != null && mounted) {
      if (completed) {
        ErrorHandler.showSuccessSnackBar(context, 'Đã hoàn thành nhiệm vụ! 🎉');
      } else {
        ErrorHandler.showWarningSnackBar(context, 'Đã bỏ đánh dấu hoàn thành');
      }
    }
  }

}
