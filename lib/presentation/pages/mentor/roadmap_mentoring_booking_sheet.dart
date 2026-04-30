import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/error_handler.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../data/models/journey_models.dart';
import '../../../data/models/mentor_models.dart';
import '../../../data/services/journey_service.dart';
import '../../../data/services/mentor_service.dart';
import '../../providers/mentor_booking_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/animated_success_overlay.dart';
import '../../widgets/common_loading.dart';
import '../../widgets/glass_card.dart';

class RoadmapMentoringBookingSheet extends StatefulWidget {
  final MentorProfile mentor;
  final int? journeyId;
  final double? roadmapMentoringPrice;

  const RoadmapMentoringBookingSheet({
    super.key,
    required this.mentor,
    this.journeyId,
    this.roadmapMentoringPrice,
  });

  @override
  State<RoadmapMentoringBookingSheet> createState() =>
      _RoadmapMentoringBookingSheetState();
}

class _RoadmapMentoringBookingSheetState
    extends State<RoadmapMentoringBookingSheet> {
  final MentorService _mentorService = MentorService();

  List<JourneySummaryDto> _activeJourneys = [];
  bool _isLoadingJourneys = false;
  bool _isRefreshingRoadmapPrice = false;
  bool _isLoading = false;
  int? _selectedJourneyId;
  MentorProfile? _latestMentorProfile;

  MentorProfile get _effectiveMentorProfile =>
      _latestMentorProfile ?? widget.mentor;

  double get _effectiveRoadmapPrice =>
      _effectiveMentorProfile.roadmapMentoringPrice ??
      widget.roadmapMentoringPrice ??
      widget.mentor.roadmapMentoringPrice ??
      _effectiveMentorProfile.hourlyRate ??
      widget.mentor.hourlyRate ??
      0;

  JourneySummaryDto? get _selectedJourney {
    final journeyId = _selectedJourneyId ?? widget.journeyId;
    if (journeyId == null) return null;
    for (final journey in _activeJourneys) {
      if (journey.id == journeyId) return journey;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _selectedJourneyId = widget.journeyId;
    _refreshRoadmapMentorProfile(silent: true);
    _loadActiveJourneys();
  }

  Future<void> _loadActiveJourneys() async {
    setState(() => _isLoadingJourneys = true);
    try {
      final journeys = await JourneyService().getUserJourneys(
        page: 0,
        size: 50,
      );
      final activeJourneys = journeys
          .where(
            (journey) =>
                journey.status == JourneyStatus.active ||
                journey.status == JourneyStatus.studyPlanInProgress ||
                journey.status == JourneyStatus.roadmapGenerated,
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _activeJourneys = activeJourneys;
        if (_selectedJourneyId == null && activeJourneys.length == 1) {
          _selectedJourneyId = activeJourneys.first.id;
        }
      });
    } catch (e) {
      debugPrint('Failed to load journeys for roadmap mentoring: $e');
    } finally {
      if (mounted) setState(() => _isLoadingJourneys = false);
    }
  }

  Future<bool> _refreshRoadmapMentorProfile({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _isRefreshingRoadmapPrice = true);
    }

    try {
      final latestProfile = await _mentorService.getMentorProfile(
        widget.mentor.id,
      );
      if (!mounted) return true;
      setState(() {
        _latestMentorProfile = latestProfile;
      });
      return true;
    } catch (e) {
      debugPrint('Failed to refresh roadmap mentoring price: $e');
      if (!silent && mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          'Không thể cập nhật giá mới nhất của mentor. Vui lòng thử lại.',
        );
      }
      return false;
    } finally {
      if (!silent && mounted) {
        setState(() => _isRefreshingRoadmapPrice = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkBackgroundPrimary
            : AppTheme.lightBackgroundPrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor,
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context, isDark),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroCard(context, isDark),
                  const SizedBox(height: 20),
                  _buildJourneySection(context, isDark),
                  const SizedBox(height: 20),
                  _buildPriceSection(context, isDark),
                ],
              ),
            ),
          ),
          _buildBottomButton(context, isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppTheme.darkBorderColor
                : AppTheme.lightBorderColor,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Thuê Mentor đồng hành',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.successColor.withValues(alpha: 0.14),
                backgroundImage: widget.mentor.avatar != null
                    ? NetworkImage(widget.mentor.avatar!)
                    : null,
                child: widget.mentor.avatar == null
                    ? Text(
                        widget.mentor.fullName.isNotEmpty
                            ? widget.mentor.fullName[0].toUpperCase()
                            : 'M',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.successColor,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.mentor.fullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mentor sẽ theo sát hành trình học, follow-up tiến độ và hỗ trợ xác thực kết quả.',
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
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.successColor.withValues(alpha: 0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gói này bao gồm',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.successColor,
                  ),
                ),
                const SizedBox(height: 8),
                _buildFeatureRow(
                  context,
                  isDark,
                  Icons.route_outlined,
                  'Theo dõi và điều chỉnh roadmap theo tiến độ thực tế.',
                ),
                const SizedBox(height: 8),
                _buildFeatureRow(
                  context,
                  isDark,
                  Icons.event_available_outlined,
                  'Tạo các buổi follow-up khi mentor thấy cần thiết.',
                ),
                const SizedBox(height: 8),
                _buildFeatureRow(
                  context,
                  isDark,
                  Icons.verified_outlined,
                  'Đồng hành đến bước xác thực cuối hành trình.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(
    BuildContext context,
    bool isDark,
    IconData icon,
    String text,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.successColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJourneySection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn hành trình cần đồng hành',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Mentor sẽ được gắn trực tiếp với roadmap bạn chọn.',
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingJourneys)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_activeJourneys.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Bạn chưa có hành trình nào đang hoạt động.\nHãy tạo hoặc kích hoạt một roadmap trước khi thuê mentor đồng hành.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
            ),
          )
        else
          ..._activeJourneys.map(
            (journey) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildJourneyCard(context, journey, isDark),
            ),
          ),
      ],
    );
  }

  Widget _buildJourneyCard(
    BuildContext context,
    JourneySummaryDto journey,
    bool isDark,
  ) {
    final isSelected = (_selectedJourneyId ?? widget.journeyId) == journey.id;
    final levelLabel = journey.currentLevel?.name.toUpperCase();

    return GestureDetector(
      onTap: () => setState(() => _selectedJourneyId = journey.id),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlueDark.withValues(alpha: 0.14)
              : (isDark
                    ? AppTheme.darkCardBackground
                    : AppTheme.lightCardBackground),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryBlueDark
                : (isDark
                      ? AppTheme.darkBorderColor
                      : AppTheme.lightBorderColor),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        journey.domain,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppTheme.primaryBlueDark
                              : (isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.lightTextPrimary),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        journey.goal,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                const SizedBox(width: 12),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.primaryBlueDark,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMetaChip(
                  context,
                  icon: Icons.flag_outlined,
                  text: 'Journey #${journey.id}',
                  isDark: isDark,
                ),
                _buildMetaChip(
                  context,
                  icon: Icons.track_changes_outlined,
                  text: '${journey.progressPercentage}%',
                  isDark: isDark,
                ),
                if (levelLabel != null)
                  _buildMetaChip(
                    context,
                    icon: Icons.school_outlined,
                    text: levelLabel,
                    isDark: isDark,
                  ),
                if (journey.skillName?.isNotEmpty == true)
                  _buildMetaChip(
                    context,
                    icon: Icons.auto_awesome_outlined,
                    text: journey.skillName!,
                    isDark: isDark,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaChip(
    BuildContext context, {
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkBackgroundPrimary
            : AppTheme.lightBackgroundPrimary,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(BuildContext context, bool isDark) {
    final selectedJourney = _selectedJourney;
    final roadmapPrice = _effectiveRoadmapPrice;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thanh toán một lần cho gói đồng hành',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedJourney != null
                          ? 'Áp dụng cho hành trình #${selectedJourney.id}.'
                          : 'Giá được khóa theo cấu hình hiện tại của mentor.',
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
              const SizedBox(width: 12),
              Text(
                NumberFormatter.formatCurrency(roadmapPrice),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successColor,
                ),
              ),
            ],
          ),
          if (_isRefreshingRoadmapPrice) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đang đồng bộ giá roadmap mới nhất từ mentor...',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context, bool isDark) {
    final canProceed =
        (_selectedJourneyId ?? widget.journeyId) != null &&
        _activeJourneys.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppTheme.darkBorderColor
                : AppTheme.lightBorderColor,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canProceed && !_isLoading
                ? () => _submitBooking(context)
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.successColor,
              disabledBackgroundColor: isDark
                  ? AppTheme.darkCardBackground
                  : AppTheme.lightCardBackground,
            ),
            child: _isLoading
                ? CommonLoading.small()
                : Text(
                    'THUÊ GÓI ĐỒNG HÀNH',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: canProceed
                          ? Colors.white
                          : AppTheme.darkTextSecondary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitBooking(BuildContext context) async {
    final selectedJourneyId = _selectedJourneyId ?? widget.journeyId;
    if (selectedJourneyId == null) return;

    setState(() => _isLoading = true);

    final provider = context.read<MentorBookingProvider>();
    final navigator = Navigator.of(context);
    final router = GoRouter.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final synced = await _refreshRoadmapMentorProfile();
      if (!synced || !context.mounted) return;

      final roadmapPrice = _effectiveRoadmapPrice;
      if (roadmapPrice <= 0) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text(
              'Mentor chưa cấu hình giá đồng hành roadmap hợp lệ.',
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        return;
      }

      final booking = await provider.createBookingWithWallet(
        mentorId: widget.mentor.id,
        startTime: DateTime.now().add(const Duration(minutes: 5)),
        durationMinutes: 0,
        priceVnd: roadmapPrice,
        journeyId: selectedJourneyId,
        bookingType: 'ROADMAP_MENTORING',
      );

      if (!context.mounted) return;

      if (booking != null) {
        navigator.pop();
        AnimatedSuccessOverlay.show(
          context: context,
          title: 'Gửi yêu cầu thành công! 🎉',
          subtitle: 'Đang chờ mentor duyệt yêu cầu đồng hành.',
          primaryButtonText: 'Xem lịch hẹn',
          onPrimaryAction: () => router.push('/my-bookings'),
        );
      } else {
        navigator.pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Đặt lịch thất bại'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        navigator.pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
