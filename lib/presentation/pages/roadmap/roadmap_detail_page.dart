import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/roadmap_detail_provider.dart';
import '../../providers/roadmap_provider.dart';
import '../../providers/journey_provider.dart';
import '../../providers/mentor_booking_provider.dart';
import '../../themes/app_theme.dart';
import '../../../data/models/roadmap_models.dart';
import '../../../data/models/mentor_models.dart';
import '../../../data/models/journey_models.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';
import 'widgets/grid_painter.dart';
import '../../../core/utils/error_handler.dart';
import '../../widgets/common_loading.dart';
import '../../widgets/error_state_widget.dart';
import 'roadmap_node_card.dart';

/// Computed stats for the Roadmap header — mirrors prototype's
/// `derivedStats` (commitment vs effort, approx duration).
class _RoadmapDerivedStats {
  final int totalEstimatedHours;
  final int? approxMonths;
  final double? commitmentMonths;
  final bool commitmentMet;
  final double? commitmentGapMonths; // positive = over commitment
  final int dailyMinutes;

  const _RoadmapDerivedStats({
    required this.totalEstimatedHours,
    required this.approxMonths,
    required this.commitmentMonths,
    required this.commitmentMet,
    required this.commitmentGapMonths,
    required this.dailyMinutes,
  });

  factory _RoadmapDerivedStats.from(RoadmapResponse roadmap) {
    final hours = roadmap.statistics.totalEstimatedHours;
    final dailyMinutes = _parseDailyMinutes(roadmap.metadata.dailyTime);
    final approxDays = dailyMinutes > 0
        ? (hours * 60 / dailyMinutes).round()
        : null;
    final approxMonths = approxDays != null
        ? (approxDays / 30).round()
        : null;
    final commitmentMonths = _parseCommitmentMonths(roadmap.metadata.duration);
    final commitmentMet = approxMonths != null &&
        commitmentMonths != null &&
        approxMonths <= commitmentMonths;
    final gap = (approxMonths != null && commitmentMonths != null)
        ? ((approxMonths - commitmentMonths) * 10).round() / 10
        : null;
    return _RoadmapDerivedStats(
      totalEstimatedHours: hours,
      approxMonths: approxMonths,
      commitmentMonths: commitmentMonths,
      commitmentMet: commitmentMet,
      commitmentGapMonths: gap,
      dailyMinutes: dailyMinutes,
    );
  }

  /// Mirror of BE `AiRoadmapServiceImpl.parseDailyTimeMinutes()`.
  static int _parseDailyMinutes(String? dailyTime) {
    if (dailyTime == null || dailyTime.isEmpty) return 60;
    final s = dailyTime.toLowerCase();
    final numMatch = s.replaceAll(RegExp(r'[^0-9]'), '');
    if (numMatch.isNotEmpty) {
      final num = int.tryParse(numMatch);
      if (num != null) {
        if (s.contains('hour') || s.contains('giờ')) return num * 60;
        if (s.contains('min')) return num;
      }
    }
    if (s.contains('30') && !s.contains('1')) return 30;
    if (s.contains('2') && !s.contains('12') && !s.contains('15')) return 120;
    if (s.contains('1') && !s.contains('12') && !s.contains('15')) return 60;
    return 60;
  }

  static double? _parseCommitmentMonths(String? duration) {
    if (duration == null || duration.isEmpty) return null;
    final s = duration.toLowerCase();
    final numMatch = s.replaceAll(RegExp(r'[^0-9.]'), '');
    final num = numMatch.isNotEmpty ? double.tryParse(numMatch) : null;
    if (num == null || num == 0) return null;
    if (s.contains('tháng') || s.contains('month')) return num;
    if (s.contains('tuần') || s.contains('week')) {
      return ((num * 30 / 7).round()) / 30;
    }
    return num;
  }
}

class RoadmapDetailPage extends StatefulWidget {
  final int sessionId;

  const RoadmapDetailPage({super.key, required this.sessionId});

  @override
  State<RoadmapDetailPage> createState() => _RoadmapDetailPageState();
}

class _RoadmapDetailPageState extends State<RoadmapDetailPage>
    with WidgetsBindingObserver {
  String? _expandedNodeId;
  String? _creatingPlanNodeId;
  int? _resolvedJourneyId;
  MentorBookingProvider? _bookingProvider;

  // V3 ROADMAP_MENTORING state
  /// null = not checked yet, 'NONE' = no booking, otherwise the booking status
  String? _mentorBookingStatus;
  int? _mentorBookingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attachBookingProviderListener();
      context.read<RoadmapDetailProvider>().loadRoadmapById(widget.sessionId);
      _resolveJourneyId();
    });
  }

  void _attachBookingProviderListener() {
    final provider = context.read<MentorBookingProvider>();
    if (identical(_bookingProvider, provider)) return;
    _bookingProvider?.removeListener(_handleBookingsChanged);
    _bookingProvider = provider;
    _bookingProvider?.addListener(_handleBookingsChanged);
  }

  void _handleBookingsChanged() {
    final journeyId = _resolvedJourneyId;
    final provider = _bookingProvider;
    if (!mounted || journeyId == null || provider == null) return;
    _applyMentorBookingStatus(provider.bookings, journeyId);
  }

  Future<void> _resolveJourneyId() async {
    final jp = context.read<JourneyProvider>();
    JourneySummaryDto? journey = jp.journeys
        .where((j) => j.roadmapSessionId == widget.sessionId)
        .firstOrNull;

    if (journey == null) {
      try {
        await jp.loadJourneys(page: 0, size: 100);
      } catch (_) {
        // Ignore here; roadmap detail can still render without mentor CTA
      }
      journey = jp.journeys
          .where((j) => j.roadmapSessionId == widget.sessionId)
          .firstOrNull;
    }

    if (journey != null && mounted) {
      final resolvedJourneyId = journey.id;
      setState(() => _resolvedJourneyId = resolvedJourneyId);
      _resolveMentorBooking(resolvedJourneyId, refresh: true);
    }
  }

  /// V3: Check if there's an active ROADMAP_MENTORING booking for this journey
  Future<void> _resolveMentorBooking(
    int journeyId, {
    bool refresh = false,
  }) async {
    try {
      final bookingProvider = context.read<MentorBookingProvider>();
      if (refresh || bookingProvider.bookings.isEmpty) {
        await bookingProvider.loadBookings(refresh: true);
      }
      _applyMentorBookingStatus(bookingProvider.bookings, journeyId);
    } catch (_) {
      if (mounted) setState(() => _mentorBookingStatus = 'NONE');
    }
  }

  void _applyMentorBookingStatus(List<MentorBooking> bookings, int journeyId) {
    final match = bookings
        .where(
          (b) =>
              b.bookingType == 'ROADMAP_MENTORING' &&
              b.journeyId == journeyId &&
              (b.status == BookingStatus.pending ||
                  b.status == BookingStatus.confirmed ||
                  b.status == BookingStatus.mentoringActive),
        )
        .firstOrNull;
    if (!mounted) return;

    final nextStatus = match?.status.name ?? 'NONE';
    final nextBookingId = match?.id;
    if (_mentorBookingStatus == nextStatus &&
        _mentorBookingId == nextBookingId) {
      return;
    }

    setState(() {
      _mentorBookingStatus = nextStatus;
      _mentorBookingId = nextBookingId;
    });
  }

  Future<void> _openMentorDiscoveryFlow(BuildContext context) async {
    final journeyId = _resolvedJourneyId;
    if (journeyId == null) return;
    await context.push(
      '/mentors?action=roadmap_mentoring&journeyId=$journeyId',
    );
    if (!mounted) return;
    await _resolveMentorBooking(journeyId, refresh: true);
  }

  Future<void> _openPendingBookingDetail(BuildContext context) async {
    final bookingId = _mentorBookingId;
    final journeyId = _resolvedJourneyId;
    if (bookingId == null) return;
    await context.push('/mentor-booking-detail/$bookingId');
    if (!mounted || journeyId == null) return;
    await _resolveMentorBooking(journeyId, refresh: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final journeyId = _resolvedJourneyId;
    if (journeyId == null) return;
    _resolveMentorBooking(journeyId, refresh: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bookingProvider?.removeListener(_handleBookingsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: true,
        child: Consumer<RoadmapDetailProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return _buildLoadingState(context, isDark);
            }

            if (provider.errorMessage != null) {
              // ── Paused roadmap → show activate UI ──
              if (provider.isPausedError) {
                return _buildPausedState(context, provider, isDark);
              }
              return ErrorStateWidget(
                message: provider.errorMessage!,
                onRetry: () => context.go('/roadmap'),
              );
            }

            final roadmap = provider.currentRoadmap;
            if (roadmap == null) {
              return ErrorStateWidget(
                message: 'Không tìm thấy lộ trình',
                onRetry: () => context.go('/roadmap'),
              );
            }

            return _buildContent(context, roadmap, provider, isDark);
          },
        ),
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

  Widget _buildPausedState(
    BuildContext context,
    RoadmapDetailProvider provider,
    bool isDark,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.pause_circle_outline,
                size: 64,
                color: Colors.amber.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Lộ trình đang tạm dừng',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Kích hoạt lại lộ trình để tiếp tục xem nội dung và theo dõi tiến độ học tập.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            if (provider.isLoading)
              const CircularProgressIndicator()
            else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final roadmapProvider = context.read<RoadmapProvider>();
                    await provider.activateAndReload(widget.sessionId);
                    if (mounted && !provider.hasError) {
                      // Refresh list provider so back-navigation shows updated status
                      roadmapProvider.loadUserRoadmaps(force: true);
                      roadmapProvider.loadStatusCounts();
                    }
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Kích hoạt lại'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Quay lại'),
              ),
            ],
          ],
        ),
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

              // Entry-point CTA row
              _buildActionRow(context, isDark),

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
                  : [
                      AppTheme.lightBackgroundSecondary,
                      AppTheme.lightBackgroundPrimary,
                    ],
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
    final stats = _RoadmapDerivedStats.from(roadmap);
    final durationValue = stats.approxMonths != null
        ? '~${stats.approxMonths} tháng'
        : roadmap.metadata.duration;
    final durationSub = stats.totalEstimatedHours > 0
        ? '~${stats.totalEstimatedHours}h @ ${stats.dailyMinutes}m/ngày'
        : roadmap.metadata.duration;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.schedule_outlined,
                    label: 'Thời lượng',
                    value: durationValue,
                    subValue: durationSub,
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
          if (stats.commitmentGapMonths != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildEffortBanner(stats, isDark),
            ),
        ],
      ),
    );
  }

  /// Inline banner comparing effort (totalHours / dailyMinutes) vs commitment.
  /// Mirror prototype's `rm-warning-effort` / `rm-warning-ahead`.
  Widget _buildEffortBanner(_RoadmapDerivedStats stats, bool isDark) {
    final gap = stats.commitmentGapMonths!;
    final isOver = !stats.commitmentMet && gap > 0;
    final isAhead = stats.commitmentMet && gap < 0;
    if (!isOver && !isAhead) return const SizedBox.shrink();

    final color = isOver ? AppTheme.warningColor : AppTheme.successColor;
    final icon = isOver ? Icons.warning_amber_rounded : Icons.check_circle;
    final absGap = gap.abs().toStringAsFixed(gap.abs() == gap.abs().roundToDouble() ? 0 : 1);
    final message = isOver
        ? 'Effort vượt cam kết $absGap tháng — cân nhắc giảm scope'
        : 'Effort thấp hơn cam kết $absGap tháng — có thể hoàn thành sớm';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Top status bar of metadata section: active dot + mode tag + difficulty badge.
  /// Mirror prototype's `rm-status-bar`.
  Widget _buildStatusBar(
    BuildContext context,
    bool isSkillBased,
    String? difficultyLevel,
    bool isDark,
  ) {
    final modeTag = isSkillBased ? 'Kỹ năng' : 'Sự nghiệp';
    Color difficultyColor() {
      switch ((difficultyLevel ?? '').toLowerCase()) {
        case 'beginner':
        case 'easy':
          return AppTheme.successColor;
        case 'intermediate':
        case 'medium':
          return AppTheme.warningColor;
        case 'advanced':
        case 'hard':
        case 'expert':
          return AppTheme.errorColor;
        default:
          return AppTheme.primaryBlue;
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Active dot + label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.successColor.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppTheme.successColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Hoạt động',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.successColor,
                ),
              ),
            ],
          ),
        ),
        // Mode tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: (isDark ? AppTheme.accentCyan : AppTheme.primaryBlue)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            modeTag,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.accentCyan : AppTheme.primaryBlue,
            ),
          ),
        ),
        // Difficulty badge
        if (difficultyLevel != null && difficultyLevel.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: difficultyColor().withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: difficultyColor().withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              difficultyLevel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: difficultyColor(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionRow(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/my-bookings'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark
                        ? AppTheme.accentCyan
                        : AppTheme.primaryBlue,
                    side: BorderSide(
                      color:
                          (isDark ? AppTheme.accentCyan : AppTheme.primaryBlue)
                              .withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Xem Booking'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _resolvedJourneyId != null
                      ? () => context.push(
                          '/journey/${_resolvedJourneyId!}/final-verification',
                        )
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark
                        ? AppTheme.accentGold
                        : AppTheme.warningColor,
                    side: BorderSide(
                      color:
                          (isDark ? AppTheme.accentGold : AppTheme.warningColor)
                              .withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    disabledForegroundColor: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  child: const Text('Xác minh cuối'),
                ),
              ),
            ],
          ),
          // V3: Dynamic Mentor button
          if (_resolvedJourneyId != null) ...[
            const SizedBox(height: 10),
            _buildMentorActionButton(context, isDark),
          ],
        ],
      ),
    );
  }

  /// V3: Dynamic button that changes based on ROADMAP_MENTORING booking status
  Widget _buildMentorActionButton(BuildContext context, bool isDark) {
    if (_mentorBookingStatus == null || _mentorBookingStatus == 'NONE') {
      // No booking: show "Tìm Mentor đồng hành"
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _openMentorDiscoveryFlow(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlueDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Tìm Mentor đồng hành',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    if (_mentorBookingStatus == 'pending') {
      // Booking pending mentor approval
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _mentorBookingId == null
              ? null
              : () => _openPendingBookingDetail(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
            side: BorderSide(
              color: (isDark
                  ? AppTheme.darkBorderColor
                  : AppTheme.lightBorderColor),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
              const SizedBox(width: 8),
              const Text('Xem yêu cầu đang chờ duyệt'),
            ],
          ),
        ),
      );
    }

    // MENTORING_ACTIVE or CONFIRMED: show Workspace button
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          final query = <String, String>{};
          if (_mentorBookingId != null) {
            query['bookingId'] = _mentorBookingId.toString();
          }
          if (_resolvedJourneyId != null) {
            query['journeyId'] = _resolvedJourneyId.toString();
          }
          final uri = Uri(
            path: '/roadmap/${widget.sessionId}/workspace',
            queryParameters: query.isNotEmpty ? query : null,
          );
          context.push(uri.toString());
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.successColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Không gian Mentor',
          style: TextStyle(fontWeight: FontWeight.w600),
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
  /// Return the first non-empty string, or [fallback] if all empty/null.
  /// Mirror JS `||` semantics — falls through both null AND empty strings,
  /// unlike Dart `??` which only handles null.
  String _firstNonEmpty(List<String?> values, String fallback) {
    for (final v in values) {
      if (v != null && v.trim().isNotEmpty) return v;
    }
    return fallback;
  }

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
            // Status bar: active dot + mode tag + difficulty badge
            _buildStatusBar(context, isSkillBased, metadata.difficultyLevel, isDark),
            const SizedBox(height: 16),
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
                          _firstNonEmpty(
                            [metadata.validatedGoal, metadata.originalGoal],
                            'AI chưa xác định mục tiêu cụ thể.',
                          ),
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                          height: 1.5,
                          fontStyle: _firstNonEmpty(
                                    [metadata.validatedGoal, metadata.originalGoal],
                                    '',
                                  ) ==
                                  ''
                              ? FontStyle.italic
                              : FontStyle.normal,
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
                        _firstNonEmpty(
                          [metadata.target, metadata.skillMode?.skillName],
                          'Chưa xác định',
                        ),
                        isDark,
                      ),
                      _buildMetadataItem(
                        context,
                        'Cấp độ hiện tại',
                        _firstNonEmpty(
                          [
                            metadata.currentLevel,
                            metadata.skillMode?.currentSkillLevel,
                          ],
                          'Chưa xác định',
                        ),
                        isDark,
                      ),
                      _buildMetadataItem(
                        context,
                        'Thời gian/ngày',
                        _firstNonEmpty(
                          [metadata.dailyTime],
                          'Chưa xác định',
                        ),
                        isDark,
                      ),
                      _buildMetadataItem(
                        context,
                        'Phong cách học',
                        _firstNonEmpty(
                          [metadata.learningStyle],
                          'Chưa xác định',
                        ),
                        isDark,
                      ),
                    ]
                  : [
                      _buildMetadataItem(
                        context,
                        'Vị trí mục tiêu',
                        _firstNonEmpty(
                          [metadata.target, metadata.careerMode?.targetRole],
                          'Chưa xác định',
                        ),
                        isDark,
                      ),
                      _buildMetadataItem(
                        context,
                        'Background',
                        _firstNonEmpty(
                          [metadata.currentLevel, metadata.background],
                          'Chưa xác định',
                        ),
                        isDark,
                      ),
                      _buildMetadataItem(
                        context,
                        'Thời gian cam kết',
                        _firstNonEmpty(
                          [
                            metadata.careerMode?.timelineToWork,
                            metadata.duration,
                          ],
                          'Chưa xác định',
                        ),
                        isDark,
                      ),
                      _buildMetadataItem(
                        context,
                        'Môi trường',
                        _firstNonEmpty(
                          [
                            metadata.targetEnvironment,
                            metadata.careerMode?.companyType,
                          ],
                          'Chưa xác định',
                        ),
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
                _expandedNodeId = _expandedNodeId == node.id ? null : node.id;
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
