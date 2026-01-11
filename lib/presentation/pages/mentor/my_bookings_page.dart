import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../data/models/mentor_models.dart';
import '../../providers/mentor_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/glass_card.dart';

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
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MentorProvider>().loadBookings(refresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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
                  b.status == BookingStatus.ongoing,
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
      default:
        return bookings;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch hẹn của tôi'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sắp tới'),
            Tab(text: 'Hoàn thành'),
            Tab(text: 'Đã hủy'),
          ],
          labelColor: isDark ? AppTheme.primaryBlueDark : AppTheme.primaryBlue,
          unselectedLabelColor: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
          indicatorColor: isDark
              ? AppTheme.primaryBlueDark
              : AppTheme.primaryBlue,
        ),
      ),
      body: Consumer<MentorProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingBookings && provider.bookings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBookingList(context, provider, 0, isDark),
              _buildBookingList(context, provider, 1, isDark),
              _buildBookingList(context, provider, 2, isDark),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingList(
    BuildContext context,
    MentorProvider provider,
    int tabIndex,
    bool isDark,
  ) {
    final filteredBookings = _filterBookings(provider.bookings, tabIndex);

    if (filteredBookings.isEmpty) {
      return Center(
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
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadBookings(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredBookings.length,
        itemBuilder: (context, index) {
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
    MentorProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with mentor info
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryBlueDark.withOpacity(0.2),
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
                      _buildStatusBadge(booking.status, isDark),
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
            // Date and time
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
                Text(
                  _formatDate(booking.startTime),
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(booking.startTime, booking.endTime),
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
              ],
            ),
            // Actions
            if (booking.canCancel || booking.canRate) ...[
              const SizedBox(height: 16),
              Row(
                children: [
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
                  if (booking.canCancel && booking.canRate)
                    const SizedBox(width: 12),
                  if (booking.canRate)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            _showRatingDialog(context, booking, provider),
                        child: const Text('Đánh giá'),
                      ),
                    ),
                ],
              ),
            ],
            // Meeting link
            if (booking.meetingLink != null &&
                booking.status == BookingStatus.confirmed) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Open meeting link
                    // launchUrl(Uri.parse(booking.meetingLink!));
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

  Widget _buildStatusBadge(BookingStatus status, bool isDark) {
    Color color;
    String text;

    switch (status) {
      case BookingStatus.pending:
        color = AppTheme.warningColor;
        text = 'Chờ xác nhận';
        break;
      case BookingStatus.confirmed:
        color = AppTheme.successColor;
        text = 'Đã xác nhận';
        break;
      case BookingStatus.rejected:
        color = AppTheme.errorColor;
        text = 'Đã từ chối';
        break;
      case BookingStatus.ongoing:
        color = AppTheme.infoColor;
        text = 'Đang diễn ra';
        break;
      case BookingStatus.completed:
        color = AppTheme.successColor;
        text = 'Hoàn thành';
        break;
      case BookingStatus.cancelled:
        color = AppTheme.errorColor;
        text = 'Đã hủy';
        break;
      case BookingStatus.disputed:
        color = AppTheme.errorColor;
        text = 'Tranh chấp';
        break;
      case BookingStatus.refunded:
        color = AppTheme.warningColor;
        text = 'Đã hoàn tiền';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showCancelDialog(
    BuildContext context,
    MentorBooking booking,
    MentorProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy'),
        content: const Text(
          'Bạn có chắc chắn muốn hủy lịch hẹn này? Tiền sẽ được hoàn lại vào ví.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await provider.cancelBooking(booking.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã hủy lịch hẹn'),
                    backgroundColor: AppTheme.successColor,
                  ),
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

  void _showRatingDialog(
    BuildContext context,
    MentorBooking booking,
    MentorProvider provider,
  ) {
    int rating = 5;
    final reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Đánh giá buổi mentoring'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    onPressed: () => setState(() => rating = i + 1),
                    icon: Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      color: AppTheme.warningColor,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reviewController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Nhận xét của bạn (tùy chọn)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await provider.rateBooking(
                  booking.id,
                  rating,
                  review: reviewController.text.isNotEmpty
                      ? reviewController.text
                      : null,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cảm ơn bạn đã đánh giá!'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              },
              child: const Text('Gửi đánh giá'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime start, DateTime end) {
    final startStr =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return '$startStr - $endStr';
  }
}
