import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

/// DateTimeHelper - Centralized date/time formatting utility
///
/// Best practices implemented:
/// - Singleton pattern for DateFormat instances (performance)
/// - Vietnamese localization support
/// - Timezone awareness
/// - Null safety
class DateTimeHelper {
  // Private constructor to prevent instantiation
  DateTimeHelper._();

  // === FORMATTERS (Created once, reused for performance) ===

  /// Standard date format: 15/12/2025
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  /// Date with weekday: Thứ 6, 15/12/2025
  static final DateFormat _dateWithWeekday = DateFormat('EEEE, dd/MM/yyyy', 'vi_VN');

  /// Short date: 15/12
  static final DateFormat _shortDate = DateFormat('dd/MM');

  /// Time only: 14:30
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  /// Full datetime: 15/12/2025 14:30
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  /// Month and year: Tháng 12 2025
  static final DateFormat _monthYear = DateFormat('MMMM yyyy', 'vi_VN');

  /// Time with seconds: 14:30:45
  static final DateFormat _timeWithSeconds = DateFormat('HH:mm:ss');

  /// ISO 8601 format for API: 2025-12-15T14:30:00Z
  static final DateFormat _iso8601Format = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");

  // === INITIALIZATION ===

  /// Initialize Vietnamese locale for timeago
  /// Call this in main() before runApp()
  static void initialize() {
    // Register Vietnamese messages for timeago
    timeago.setLocaleMessages('vi', VietnameseMessages());
  }

  // === FORMATTING METHODS ===

  /// Format date: 15/12/2025
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Format date with weekday: Thứ 6, 15/12/2025
  static String formatDateWithWeekday(DateTime date) {
    return _dateWithWeekday.format(date);
  }

  /// Format short date: 15/12
  static String formatShortDate(DateTime date) {
    return _shortDate.format(date);
  }

  /// Format time: 14:30
  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }

  /// Format datetime: 15/12/2025 14:30
  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  /// Format month and year: Tháng 12 2025
  static String formatMonthYear(DateTime date) {
    return _monthYear.format(date);
  }

  /// Format time with seconds: 14:30:45
  static String formatTimeWithSeconds(DateTime date) {
    return _timeWithSeconds.format(date);
  }

  /// Format to ISO 8601 for API: 2025-12-15T14:30:00Z
  static String formatIso8601(DateTime date) {
    return _iso8601Format.format(date.toUtc());
  }

  // === RELATIVE TIME (Vietnamese) ===

  /// Get relative time in Vietnamese: "2 giờ trước", "5 phút trước"
  ///
  /// Uses timeago package with custom Vietnamese messages
  /// Falls back to full date if older than specified days
  static String formatRelativeTime(
    DateTime dateTime, {
    int fallbackAfterDays = 7,
    bool allowFromNow = false,
  }) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    // If older than fallbackAfterDays, show full date instead
    if (difference.inDays.abs() > fallbackAfterDays) {
      return formatDateTime(dateTime);
    }

    return timeago.format(
      dateTime,
      locale: 'vi',
      allowFromNow: allowFromNow,
    );
  }

  /// Smart relative time: Shows "Hôm nay 14:30" or "Hôm qua 09:15" or relative
  static String formatSmart(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (dateOnly == today) {
      return 'Hôm nay ${formatTime(dateTime)}';
    } else if (dateOnly == yesterday) {
      return 'Hôm qua ${formatTime(dateTime)}';
    } else if (now.difference(dateTime).inDays < 7) {
      return formatRelativeTime(dateTime);
    } else {
      return formatDateTime(dateTime);
    }
  }

  // === DATE RANGES ===

  /// Format date range: 15/12/2025 - 20/12/2025
  static String formatDateRange(DateTime start, DateTime end) {
    // Same month and year
    if (start.year == end.year && start.month == end.month) {
      return '${start.day} - ${end.day}/${end.month}/${end.year}';
    }
    // Same year
    if (start.year == end.year) {
      return '${start.day}/${start.month} - ${end.day}/${end.month}/${end.year}';
    }
    // Different years
    return '${formatDate(start)} - ${formatDate(end)}';
  }

  // === TIMEZONE HANDLING ===

  /// Convert UTC to local time
  static DateTime utcToLocal(DateTime utcTime) {
    return utcTime.toLocal();
  }

  /// Convert local to UTC time
  static DateTime localToUtc(DateTime localTime) {
    return localTime.toUtc();
  }

  /// Format UTC time to local display
  static String formatUtcToLocal(DateTime utcTime) {
    return formatDateTime(utcToLocal(utcTime));
  }

  // === UTILITY METHODS ===

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
           date.month == yesterday.month &&
           date.day == yesterday.day;
  }

  /// Check if date is this week
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return date.isAfter(startOfWeek) && date.isBefore(endOfWeek);
  }

  /// Get difference in days
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  /// Get difference in hours
  static int hoursBetween(DateTime from, DateTime to) {
    return to.difference(from).inHours;
  }

  /// Get difference in minutes
  static int minutesBetween(DateTime from, DateTime to) {
    return to.difference(from).inMinutes;
  }

  /// Parse ISO 8601 string safely
  static DateTime? tryParseIso8601(String? isoString) {
    if (isoString == null || isoString.isEmpty) return null;
    try {
      return DateTime.parse(isoString);
    } catch (e) {
      return null;
    }
  }

  /// Parse date string with custom format
  static DateTime? tryParse(String? dateString, String format) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateFormat(format).parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // === CUSTOM FORMATTING ===

  /// Custom format with pattern
  static String formatCustom(DateTime date, String pattern, {String? locale}) {
    return DateFormat(pattern, locale).format(date);
  }

  // === COMPARISON METHODS ===

  /// Check if two dates are the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Check if date is in the past
  static bool isPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  /// Check if date is in the future
  static bool isFuture(DateTime date) {
    return date.isAfter(DateTime.now());
  }

  // === DATE MANIPULATION ===

  /// Add days to date
  static DateTime addDays(DateTime date, int days) {
    return date.add(Duration(days: days));
  }

  /// Subtract days from date
  static DateTime subtractDays(DateTime date, int days) {
    return date.subtract(Duration(days: days));
  }

  /// Get start of day (00:00:00)
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day (23:59:59)
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  /// Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get end of month
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59);
  }
}

// === VIETNAMESE MESSAGES FOR TIMEAGO ===

/// Custom Vietnamese messages for timeago package
class VietnameseMessages implements timeago.LookupMessages {
  @override
  String prefixAgo() => '';

  @override
  String prefixFromNow() => '';

  @override
  String suffixAgo() => 'trước';

  @override
  String suffixFromNow() => 'sau';

  @override
  String lessThanOneMinute(int seconds) => 'vừa xong';

  @override
  String aboutAMinute(int minutes) => '1 phút';

  @override
  String minutes(int minutes) => '$minutes phút';

  @override
  String aboutAnHour(int minutes) => '1 giờ';

  @override
  String hours(int hours) => '$hours giờ';

  @override
  String aDay(int hours) => '1 ngày';

  @override
  String days(int days) => '$days ngày';

  @override
  String aboutAMonth(int days) => '1 tháng';

  @override
  String months(int months) => '$months tháng';

  @override
  String aboutAYear(int year) => '1 năm';

  @override
  String years(int years) => '$years năm';

  @override
  String wordSeparator() => ' ';
}
