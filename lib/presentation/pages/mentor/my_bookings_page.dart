import 'package:flutter/material.dart';
import '../../widgets/common_loading.dart';
import '../../widgets/skeleton_loaders.dart';
import '../../widgets/skillverse_app_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/mentor_models.dart';
import '../../providers/mentor_booking_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/glass_card.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../../core/utils/error_handler.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MentorBookingProvider>().loadBookings(refresh: true);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<MentorBookingProvider>();
      if (provider.hasMoreBookings && !provider.isLoadingBookingsMore) {
        provider.loadMoreBookings();
      }
    }
  }

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<MentorBooking> _filterBookings(
    List<MentorBooking> bookings,
    int tabIndex,
  ) {
    switch (tabIndex) {
      case 0: // Sắp tới
        return bookings
            .where(
              (b) =>
                  b.status == BookingStatus.pending ||
                  b.status == BookingStatus.confirmed ||
                  b.status == BookingStatus.ongoing ||
                  b.status == BookingStatus.mentoringActive ||
                  b.status == BookingStatus.pendingCompletion,
            )
            .toList();
      case 1: // Hoàn thành
        return bookings
            .where((b) => b.status == BookingStatus.completed)
            .toList();
      case 2: // Đã hủy
        return bookings
            .where(
              (b) =>
                  b.status == BookingStatus.cancelled ||
                  b.status == BookingStatus.rejected ||
                  b.status == BookingStatus.refunded,
            )
            .toList();
      case 3: // Tranh chấp
        return bookings
            .where((b) => b.status == BookingStatus.disputed)
            .toList();
      default:
        return bookings;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: SkillVerseAppBar(
        title: 'LỊCH HẸN CỦA TÔI',
        icon: Icons.calendar_today_outlined,
        useGradientTitle: true,
        onBack: () => context.pop(),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          tabs: const [
            Tab(text: 'Sắp tới'),
            Tab(text: 'Hoàn thành'),
            Tab(text: 'Đã hủy'),
            Tab(text: 'Tranh chấp'),
          ],
          labelColor: isDark ? AppTheme.primaryBlueDark : AppTheme.primaryBlue,
          unselectedLabelColor: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
          indicatorColor: isDark
              ? AppTheme.primaryBlueDark
              : AppTheme.primaryBlue,
          dividerColor: Colors.transparent,
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Consumer<MentorBookingProvider>(
          builder: (context, provider, _) {
            if (provider.isLoadingBookings && provider.bookings.isEmpty) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 4,
                itemBuilder: (_, __) =>
                    const ListItemSkeleton(hasTrailing: true),
              );
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildBookingList(context, provider, 0, isDark),
                _buildBookingList(context, provider, 1, isDark),
                _buildBookingList(context, provider, 2, isDark),
                _buildBookingList(context, provider, 3, isDark),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBookingList(
    BuildContext context,
    MentorBookingProvider provider,
    int tabIndex,
    bool isDark,
  ) {
    final filteredBookings = _filterBookings(provider.bookings, tabIndex);

    if (filteredBookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => provider.loadBookings(refresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 64,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có lịch hẹn nào',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadBookings(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: filteredBookings.length + (provider.hasMoreBookings ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == filteredBookings.length) {
            // Load more indicator at the bottom
            if (provider.isLoadingBookingsMore && provider.hasMoreBookings) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: CommonLoading.center(),
              );
            }
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: TextButton(
                  onPressed: () => provider.loadMoreBookings(),
                  child: const Text('Xem thêm'),
                ),
              ),
            );
          }
          final booking = filteredBookings[index];
          return _buildBookingCard(context, booking, isDark, provider);
        },
      ),
    );
  }

  Widget _buildBookingCard(
    BuildContext context,
    MentorBooking booking,
    bool isDark,
    MentorBookingProvider provider,
  ) {
    final isRoadmapMentoring = booking.isRoadmapMentoring;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        onTap: () => context.push('/mentor-booking-detail/${booking.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with mentor info
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryBlueDark.withValues(
                    alpha: 0.2,
                  ),
                  backgroundImage: booking.mentorAvatar != null
                      ? NetworkImage(booking.mentorAvatar!)
                      : null,
                  child: booking.mentorAvatar == null
                      ? Text(
                          (booking.mentorName ?? 'M')[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlueDark,
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
                        booking.mentorName ?? 'Mentor',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.lightTextPrimary,
                            ),
                      ),
                      const SizedBox(height: 2),
                      StatusBadge(status: booking.status.name),
                      if (isRoadmapMentoring) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Đồng hành roadmap'
                          '${booking.journeyId != null ? ' • Hành trình #${booking.journeyId}' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  booking.formattedPrice,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isRoadmapMentoring)
              Row(
                children: [
                  Icon(
                    Icons.workspace_premium_outlined,
                    size: 16,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking.hasRoadmapWorkspace
                          ? 'Mở không gian mentor để theo dõi follow-up và tiến độ.'
                          : 'Gói đồng hành sẽ mở workspace sau khi booking vào trạng thái hoạt động.',
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      DateTimeHelper.formatDateWithWeekday(booking.startTime),
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${DateTimeHelper.formatTime(booking.startTime)} - ${DateTimeHelper.formatTime(booking.endTime)}',
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            // Actions
            if (booking.canCancel ||
                booking.canRate ||
                booking.canConfirmComplete ||
                booking.canChat ||
                booking.hasRoadmapWorkspace) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (booking.hasRoadmapWorkspace)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.push(
                          '/roadmap/${booking.roadmapSessionId}/workspace?bookingId=${booking.id}&journeyId=${booking.journeyId}',
                        ),
                        icon: const Icon(
                          Icons.workspace_premium_outlined,
                          size: 16,
                        ),
                        label: const Text('Workspace'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  if (booking.hasRoadmapWorkspace && booking.canChat)
                    const SizedBox(width: 8),
                  if (booking.canChat)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(
                          '/messaging/chat/${booking.mentorId}?bookingId=${booking.id}',
                        ),
                        icon: const Icon(Icons.chat_outlined, size: 16),
                        label: const Text('Nhắn tin'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.infoColor,
                          side: const BorderSide(color: AppTheme.infoColor),
                        ),
                      ),
                    ),
                  if ((booking.canChat || booking.hasRoadmapWorkspace) &&
                      (booking.canCancel ||
                          booking.canConfirmComplete ||
                          booking.canRate))
                    const SizedBox(width: 8),
                  if (booking.canCancel)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            _showCancelDialog(context, booking, provider),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                          side: const BorderSide(color: AppTheme.errorColor),
                        ),
                        child: const Text('Hủy'),
                      ),
                    ),
                  if (booking.canCancel && booking.canConfirmComplete)
                    const SizedBox(width: 8),
                  if (booking.canConfirmComplete)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showConfirmCompleteDialog(
                          context,
                          booking,
                          provider,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Xác nhận hoàn thành'),
                        ),
                      ),
                    ),
                  if (booking.canRate)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.push(
                          '/booking-review/${booking.id}?mentorName=${Uri.encodeComponent(booking.mentorName ?? '')}',
                        ),
                        child: const Text('Đánh giá'),
                      ),
                    ),
                ],
              ),
            ],
            // Dispute shortcut
            if (booking.status == BookingStatus.disputed &&
                booking.disputeId != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/booking-dispute/${booking.disputeId}'),
                  icon: const Icon(Icons.gavel, size: 16),
                  label: const Text('Xem khiếu nại'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.warningColor,
                    side: const BorderSide(color: AppTheme.warningColor),
                  ),
                ),
              ),
            ],
            // Meeting link
            if (booking.meetingLink != null &&
                booking.status == BookingStatus.confirmed) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await launchUrl(
                        Uri.parse(booking.meetingLink!),
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ErrorHandler.showErrorSnackBar(
                          context,
                          'Không thể mở phòng học (Jitsi).',
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.video_call),
                  label: const Text('Tham gia cuộc họp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(
    BuildContext context,
    MentorBooking booking,
    MentorBookingProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận hủy'),
        content: const Text(
          'Bạn có chắc chắn muốn hủy lịch hẹn này? Tiền sẽ được hoàn lại vào ví.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await provider.cancelBooking(booking.id);
              if (!mounted) return;
              if (provider.hasError) {
                ErrorHandler.showErrorSnackBar(
                  this.context,
                  provider.errorMessage ?? 'Có lỗi xảy ra',
                );
              } else {
                ErrorHandler.showSuccessSnackBar(
                  this.context,
                  'Đã hủy lịch hẹn',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Hủy lịch'),
          ),
        ],
      ),
    );
  }

  void _showConfirmCompleteDialog(
    BuildContext context,
    MentorBooking booking,
    MentorBookingProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận hoàn thành'),
        content: const Text(
          'Bạn xác nhận buổi mentoring đã hoàn thành? Tiền sẽ được chuyển cho mentor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Chưa'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await provider.confirmComplete(booking.id);
              if (!mounted) return;
              if (provider.hasError) {
                ErrorHandler.showErrorSnackBar(
                  this.context,
                  provider.errorMessage ?? 'Có lỗi xảy ra',
                );
              } else {
                ErrorHandler.showSuccessSnackBar(
                  this.context,
                  'Đã xác nhận hoàn thành! Cảm ơn bạn.',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}
