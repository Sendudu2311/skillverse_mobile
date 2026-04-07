import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../data/models/mentor_models.dart';
import '../../providers/mentor_provider.dart';
import '../../providers/mentor_booking_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common_loading.dart';
import '../../widgets/glass_card.dart';

class MentorBookingSheet extends StatefulWidget {
  final MentorProfile mentor;
  final List<MentorAvailability> availability;

  const MentorBookingSheet({
    super.key,
    required this.mentor,
    required this.availability,
  });

  @override
  State<MentorBookingSheet> createState() => _MentorBookingSheetState();
}

class _MentorBookingSheetState extends State<MentorBookingSheet> {
  late DateTime _selectedDate;
  MentorAvailability? _selectedSlot;
  final int _durationMinutes = 60;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  List<DateTime> get _weekDates {
    final now = DateTime.now();
    return List.generate(7, (i) => now.add(Duration(days: i)));
  }

  List<MentorAvailability> get _slotsForSelectedDate {
    final dateOnly = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    return widget.availability.where((a) {
      final slotDate = DateTime(
        a.startTime.year,
        a.startTime.month,
        a.startTime.day,
      );
      return slotDate == dateOnly;
    }).toList();
  }

  double get _totalPrice {
    if (widget.mentor.hourlyRate == null) return 0;
    return widget.mentor.hourlyRate! * (_durationMinutes / 60);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
                  _buildDatePicker(context, isDark),
                  const SizedBox(height: 20),
                  _buildTimeSlots(context, isDark),
                  const SizedBox(height: 20),
                  _buildPriceSummary(context, isDark),
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
            'Đặt lịch hẹn',
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

  Widget _buildDatePicker(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Chọn ngày',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    // Navigate to previous week
                  },
                  icon: Icon(
                    Icons.chevron_left,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  onPressed: () {
                    // Navigate to next week
                  },
                  icon: Icon(
                    Icons.chevron_right,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: _weekDates.map((date) {
            final isSelected = _isSameDay(date, _selectedDate);
            final isToday = _isSameDay(date, DateTime.now());

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                    _selectedSlot = null;
                  });
                  // Reload availability for the new week if needed
                  context.read<MentorProvider>().loadAvailability(
                    widget.mentor.id,
                    from: _selectedDate,
                    to: _selectedDate.add(const Duration(days: 7)),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryBlueDark.withOpacity(0.2)
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
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _getDayName(date),
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? AppTheme.primaryBlueDark
                              : (isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppTheme.primaryBlueDark
                              : (isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.lightTextPrimary),
                        ),
                      ),
                      if (isToday)
                        Text(
                          'Hôm nay',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppTheme.successColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeSlots(BuildContext context, bool isDark) {
    final slots = _slotsForSelectedDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Giờ rảnh ngày ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (slots.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Không có lịch rảnh trong ngày này.',
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: slots.map((slot) {
              final isSelected = _selectedSlot?.id == slot.id;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedSlot = slot);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryBlueDark.withOpacity(0.2)
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
                    ),
                  ),
                  child: Text(
                    slot.formattedTimeRange,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryBlueDark
                          : (isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildPriceSummary(BuildContext context, bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Đơn giá:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
          ),
          Text(
            widget.mentor.formattedHourlyRate,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.successColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context, bool isDark) {
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
            onPressed: _selectedSlot != null && !_isLoading
                ? () => _proceedToPayment(context)
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.primaryBlueDark,
              disabledBackgroundColor: isDark
                  ? AppTheme.darkCardBackground
                  : AppTheme.lightCardBackground,
            ),
            child: _isLoading
                ? CommonLoading.small()
                : Text(
                    'TIẾP TỤC',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: _selectedSlot != null
                          ? Colors.white
                          : AppTheme.darkTextSecondary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _proceedToPayment(BuildContext context) async {
    if (_selectedSlot == null) return;

    setState(() => _isLoading = true);

    // Capture context-dependent objects before the async gap
    final provider = context.read<MentorBookingProvider>();
    final navigator = Navigator.of(context);
    final router = GoRouter.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final booking = await provider.createBookingWithWallet(
        mentorId: widget.mentor.id,
        startTime: _selectedSlot!.startTime,
        durationMinutes: _durationMinutes,
        priceVnd: _totalPrice,
      );

      if (!mounted) return;

      if (booking != null) {
        navigator.pop();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Đặt lịch thành công! Chờ mentor xác nhận.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        router.push('/my-bookings');
      } else {
        // Pop the sheet first so user sees the SnackBar
        navigator.pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Đặt lịch thất bại'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        navigator.pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getDayName(DateTime date) {
    const days = ['CN', 'Th 2', 'Th 3', 'Th 4', 'Th 5', 'Th 6', 'Th 7'];
    return days[date.weekday % 7];
  }
}
