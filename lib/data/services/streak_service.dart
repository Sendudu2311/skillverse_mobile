import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';

class CheckInResult {
  final bool success;
  final bool alreadyCheckedIn;
  final int coinsAwarded;
  final int currentStreak;
  final List<bool> weeklyActivity;
  final String message;

  CheckInResult({
    required this.success,
    required this.alreadyCheckedIn,
    required this.coinsAwarded,
    required this.currentStreak,
    required this.weeklyActivity,
    required this.message,
  });

  factory CheckInResult.fromJson(Map<String, dynamic> json) {
    return CheckInResult(
      success: json['success'] as bool? ?? false,
      alreadyCheckedIn: json['alreadyCheckedIn'] as bool? ?? false,
      coinsAwarded: json['coinsAwarded'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      weeklyActivity:
          (json['weeklyActivity'] as List<dynamic>?)
              ?.map((e) => e as bool)
              .toList() ??
          List.filled(7, false),
      message: json['message'] as String? ?? '',
    );
  }
}

class StreakInfo {
  final int currentStreak;
  final int longestStreak;
  final int totalCheckIns;
  final int monthlyCheckIns;
  final List<bool> weeklyActivity;
  final int powerLevel;
  final bool checkedInToday;
  final String? lastCheckInDate;

  StreakInfo({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalCheckIns,
    required this.monthlyCheckIns,
    required this.weeklyActivity,
    required this.powerLevel,
    required this.checkedInToday,
    this.lastCheckInDate,
  });

  factory StreakInfo.fromJson(Map<String, dynamic> json) {
    return StreakInfo(
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      totalCheckIns: json['totalCheckIns'] as int? ?? 0,
      monthlyCheckIns: json['monthlyCheckIns'] as int? ?? 0,
      weeklyActivity:
          (json['weeklyActivity'] as List<dynamic>?)
              ?.map((e) => e as bool)
              .toList() ??
          List.filled(7, false),
      powerLevel: json['powerLevel'] as int? ?? 0,
      checkedInToday: json['checkedInToday'] as bool? ?? false,
      lastCheckInDate: json['lastCheckInDate'] as String?,
    );
  }
}

class StreakService {
  static final StreakService _instance = StreakService._internal();
  factory StreakService() => _instance;
  StreakService._internal();

  final ApiClient _apiClient = ApiClient();

  /// POST /streak/check-in — điểm danh hàng ngày
  Future<CheckInResult> checkIn() async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/streak/check-in',
      );
      if (response.data == null) {
        return CheckInResult(
          success: false,
          alreadyCheckedIn: false,
          coinsAwarded: 0,
          currentStreak: 0,
          weeklyActivity: List.filled(7, false),
          message: 'Không có dữ liệu phản hồi',
        );
      }
      return CheckInResult.fromJson(response.data!);
    } catch (e) {
      debugPrint('StreakService.checkIn error: $e');
      rethrow;
    }
  }

  /// GET /streak/info — lấy thông tin streak
  Future<StreakInfo?> getStreakInfo() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/streak/info',
      );
      if (response.data == null) return null;
      return StreakInfo.fromJson(response.data!);
    } catch (e) {
      debugPrint('StreakService.getStreakInfo error: $e');
      return null;
    }
  }
}
