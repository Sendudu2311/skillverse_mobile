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
  final double? approxMonths;
  final double? commitmentMonths;
  final bool commitmentMet;
  final double? commitmentGapMonths; // positive = over commitment
  final int dailyMinutes;
  final int? approxDays;

  const _RoadmapDerivedStats({
    required this.totalEstimatedHours,
    required this.approxMonths,
    required this.commitmentMonths,
    required this.commitmentMet,
    required this.commitmentGapMonths,
    required this.dailyMinutes,
    required this.approxDays,
  });

  factory _RoadmapDerivedStats.from(RoadmapResponse roadmap) {
    final hours = roadmap.statistics.totalEstimatedHours.round();
    final dailyMinutes = _parseDailyMinutes(roadmap.metadata.dailyTime);
    final approxDays = dailyMinutes > 0
        ? (hours * 60 / dailyMinutes).round()
        : null;
    final approxMonths = approxDays != null ? (approxDays / 30) : null;
    final commitmentMonths = _parseCommitmentMonths(roadmap.metadata.duration);
    final commitmentMet =
        approxMonths != null &&
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
      approxDays: approxDays,
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
  final int? journeyId;

  const RoadmapDetailPage({super.key, required this.sessionId, this.journeyId});

  @override
  State<RoadmapDetailPage> createState() => _RoadmapDetailPageState();
}

class _RoadmapDetailPageState extends State<RoadmapDetailPage>
    with WidgetsBindingObserver {
  String? _expandedNodeId;
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
      if (widget.journeyId != null) {
        _resolvedJourneyId = widget.journeyId;
        _resolveMentorBooking(widget.journeyId!, refresh: true);
      }
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
    if (widget.journeyId != null) {
      if (mounted && _resolvedJourneyId != widget.journeyId) {
        setState(() => _resolvedJourneyId = widget.journeyId);
      }
      await _resolveMentorBooking(widget.journeyId!, refresh: true);
      return;
    }

    final jp = context.read<JourneyProvider>();

    // 1️⃣ Priority 1: currentJourney (set when navigating from Journey → Roadmap)
    JourneySummaryDto? journey;
    final current = jp.currentJourney;
    if (current != null && current.roadmapSessionId == widget.sessionId) {
      journey = current;
    }

    // 2️⃣ Priority 2: activeJourneys (always populated, not paginated)
    journey ??= jp.activeJourneys
        .where((j) => j.roadmapSessionId == widget.sessionId)
        .firstOrNull;

    // 3️⃣ Priority 3: journeys (paginated list — may be stale)
    journey ??= jp.journeys
        .where((j) => j.roadmapSessionId == widget.sessionId)
        .firstOrNull;

    // 4️⃣ Fallback: load active journeys from network (avoids overwriting paginated data)
    if (journey == null) {
      try {
        await jp.loadActiveJourneys();
      } catch (_) {
        // Ignore here; roadmap detail can still render without mentor CTA
      }
      // Re-check after network fetch
      journey = jp.activeJourneys
          .where((j) => j.roadmapSessionId == widget.sessionId)
          .firstOrNull;
      journey ??= jp.journeys
          .where((j) => j.roadmapSessionId == widget.sessionId)
          .firstOrNull;
    }

    if (journey != null && mounted) {
      final resolvedJourneyId = journey.id;
      setState(() => _resolvedJourneyId = resolvedJourneyId);
      _resolveMentorBooking(resolvedJourneyId, refresh: true);
    }
  }

  Future<void> _loadRoadmapData() async {
    await context.read<RoadmapDetailProvider>().loadRoadmapById(
      widget.sessionId,
    );
    await _resolveJourneyId();
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
                  b.status == BookingStatus.mentoringActive ||
                  b.status == BookingStatus.pendingCompletion ||
                  b.status == BookingStatus.completed),
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

    // Resolve skill name: journey.skillName > roadmap.metadata.skillMode > target
    String? skillName;
    final jp = context.read<JourneyProvider>();
    // Search in same priority order as _resolveJourneyId
    JourneySummaryDto? journey;
    final current = jp.currentJourney;
    if (current != null && current.id == journeyId) {
      journey = current;
    }
    journey ??= jp.activeJourneys.where((j) => j.id == journeyId).firstOrNull;
    journey ??= jp.journeys.where((j) => j.id == journeyId).firstOrNull;
    if (journey?.skillName != null && journey!.skillName!.isNotEmpty) {
      skillName = journey.skillName;
    } else {
      final roadmap = context.read<RoadmapDetailProvider>().currentRoadmap;
      skillName =
          roadmap?.metadata.skillMode?.skillName ?? roadmap?.metadata.target;
    }

    var url =
        '/mentors?action=roadmap_mentoring&journeyId=$journeyId&roadmapSessionId=${widget.sessionId}';
    if (skillName != null && skillName.isNotEmpty) {
      url += '&skillName=${Uri.encodeComponent(skillName)}';
    }

    await context.push(url);
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
    return RefreshIndicator(
      onRefresh: _loadRoadmapData,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                const SizedBox(height: 20),

                // V2 Overview section
                if (roadmap.overview != null)
                  _buildOverviewSection(
                    context,
                    roadmap.overview!,
                    isDark,
                    metadataPrerequisites: roadmap.metadata.prerequisites,
                  ),

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
                  StatusBadge(
                    status: roadmap.progressPercentage >= 100
                        ? 'COMPLETED'
                        : (roadmap.roadmapStatus ?? 'ACTIVE'),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.signal_cellular_alt,
                    size: 16,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _mapExperienceLevel(roadmap.metadata.experienceLevel),
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

    String durationValue = roadmap.metadata.duration;
    if (stats.approxDays != null) {
      if (stats.approxDays! < 7) {
        durationValue = '~${stats.approxDays} ngày';
      } else if (stats.approxDays! < 30) {
        final w = (stats.approxDays! / 7).round();
        durationValue = '~$w tuần';
      } else {
        final m = (stats.approxDays! / 30 * 10).round() / 10;
        durationValue =
            '~${m.toString().replaceAll(RegExp(r'\.0$'), '')} tháng';
      }
    }

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
                    label: 'Mục tiêu chính',
                    value: '${roadmap.statistics.mainNodes}',
                    subValue: null,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.tag,
                    label: 'Mục tiêu phụ',
                    value: '${roadmap.statistics.sideNodes}',
                    subValue: null,
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
    final absGap = gap.abs().toStringAsFixed(
      gap.abs() == gap.abs().roundToDouble() ? 0 : 1,
    );
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

  Widget _buildActionRow(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final query = <String, String>{};
                if (_resolvedJourneyId != null) {
                  query['journeyId'] = _resolvedJourneyId.toString();
                }
                final uri = Uri(
                  path: '/roadmap/${widget.sessionId}/workspace',
                  queryParameters: query.isNotEmpty ? query : null,
                );
                context.push(uri.toString());
              },
              icon: const Icon(Icons.assignment_turned_in_outlined, size: 18),
              label: const Text('Đi đến Workspace'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlueDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
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
                      ? () {
                          final roadmap = context
                              .read<RoadmapDetailProvider>()
                              .currentRoadmap;
                          context.push(
                            '/journey/${_resolvedJourneyId!}/final-verification',
                            extra: roadmap != null
                                ? {
                                    'nodeIds': roadmap.roadmap
                                        .map((n) => n.id)
                                        .toList(),
                                    'nodeTitles': {
                                      for (final n in roadmap.roadmap)
                                        n.id: n.title,
                                    },
                                  }
                                : null,
                          );
                        }
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
            const SizedBox(height: 16),
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

    // COMPLETED / MENTORING_ACTIVE / CONFIRMED: show Workspace button
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
  String _cleanAiText(String text) {
    return text
        .replaceAll(RegExp(r'\*{2,}'), '') // ** or ***
        .replaceAll(RegExp(r'_{2,}'), '') // __ or ___
        .replaceAll(RegExp(r'(?<=\s)\*(?=\S)|(?<=\S)\*(?=\s)'), '') // lone *
        .trim();
  }

  /// Map backend experience level to Vietnamese display text
  String _mapExperienceLevel(String level) {
    switch (level.toLowerCase()) {
      case 'zero':
      case 'beginner':
      case 'mới bắt đầu':
        return 'Mới bắt đầu';
      case 'intermediate':
      case 'trung cấp':
        return 'Trung cấp';
      case 'advanced':
      case 'nâng cao':
        return 'Nâng cao';
      default:
        return level;
    }
  }

  /// V2 Overview section — shows purpose, audience, expected outcomes
  Widget _buildOverviewSection(
    BuildContext context,
    RoadmapOverview overview,
    bool isDark, {
    List<String>? metadataPrerequisites,
  }) {
    final items = <MapEntry<String, String>>[
      if (overview.purpose != null && overview.purpose!.isNotEmpty)
        MapEntry('Mục đích', overview.purpose!),
      if (overview.audience != null && overview.audience!.isNotEmpty)
        MapEntry('Đối tượng', overview.audience!),
      if (overview.postRoadmapState != null &&
          overview.postRoadmapState!.isNotEmpty)
        MapEntry('Kết quả mong đợi', overview.postRoadmapState!),
      if (metadataPrerequisites != null && metadataPrerequisites.isNotEmpty)
        MapEntry('Yêu cầu', metadataPrerequisites.join(', ')),
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
              hasStudyPlan: provider.hasStudyPlan(node.id),
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
