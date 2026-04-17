import 'package:intl/intl.dart';

/// Number formatting utilities
class NumberFormatter {
  // Prevent instantiation
  NumberFormatter._();

  /// Format currency with thousand separators
  /// Example: 1000000 VND -> "1.000.000 VND"
  static String formatCurrency(double amount, {String currency = 'VND'}) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)} $currency';
  }

  /// Format currency without currency symbol
  /// Example: 1000000 -> "1.000.000"
  static String formatAmount(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return formatter.format(amount);
  }

  /// Format number with thousand separators
  /// Example: 1000 -> "1.000"
  static String formatNumber(int number) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return formatter.format(number);
  }

  /// Compact format for floating-point prices (course cards, job budgets, etc.)
  /// Example: 1200000.0 → "1.2M", 299000.0 → "299K", 500.0 → "500"
  static String formatCompactPrice(double price) {
    if (price >= 1000000) {
      final m = price / 1000000;
      return m % 1 == 0 ? '${m.toInt()}M' : '${m.toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      final k = price / 1000;
      return k % 1 == 0 ? '${k.toInt()}K' : '${k.toStringAsFixed(0)}K';
    }
    return price.toStringAsFixed(0);
  }

  /// Format number to compact form (K, M, B)
  /// Example: 1000 -> "1K", 1000000 -> "1M"
  static String formatCompact(int number) {
    if (number < 1000) {
      return number.toString();
    } else if (number < 1000000) {
      final k = number / 1000;
      return k % 1 == 0 ? '${k.toInt()}K' : '${k.toStringAsFixed(1)}K';
    } else if (number < 1000000000) {
      final m = number / 1000000;
      return m % 1 == 0 ? '${m.toInt()}M' : '${m.toStringAsFixed(1)}M';
    } else {
      final b = number / 1000000000;
      return b % 1 == 0 ? '${b.toInt()}B' : '${b.toStringAsFixed(1)}B';
    }
  }

  /// Format percentage
  /// Example: 0.75 -> "75%"
  static String formatPercentage(double value, {int decimals = 0}) {
    return '${(value * 100).toStringAsFixed(decimals)}%';
  }

  /// Format price with proper decimal handling
  /// Example: 299000.0 -> "299.000", 299000.50 -> "299.000,50"
  static String formatPrice(double price) {
    if (price % 1 == 0) {
      // No decimal part
      return formatAmount(price);
    } else {
      // Has decimal part
      final formatter = NumberFormat('#,###.##', 'vi_VN');
      return formatter.format(price);
    }
  }

  /// Format score: show integer if whole number, else 1 decimal place
  /// Example: 85.0 -> "85", 76.5 -> "76.5", null -> "0"
  static String formatScore(double? score) {
    if (score == null) return '0';
    if (score == score.truncateToDouble()) return score.toInt().toString();
    return score.toStringAsFixed(1);
  }

  /// Format rating
  /// Example: 4.5 -> "4,5", 4.0 -> "4,0"
  static String formatRating(double rating) {
    return rating.toStringAsFixed(1).replaceAll('.', ',');
  }
}
