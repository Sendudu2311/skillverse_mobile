import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/error/exceptions.dart';
import '../../core/network/api_client.dart';
import '../models/roadmap_follow_up_models.dart';

/// Service for Roadmap Follow-Up Meeting API calls.
/// Base: /api/v1/mentor-roadmap-bookings/{bookingId}/follow-ups
class RoadmapFollowUpService {
  static final RoadmapFollowUpService _instance =
      RoadmapFollowUpService._internal();
  factory RoadmapFollowUpService() => _instance;
  RoadmapFollowUpService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Get all follow-up meetings for a booking.
  /// GET /api/v1/mentor-roadmap-bookings/{bookingId}/follow-ups
  Future<List<RoadmapFollowUpMeetingDto>> getFollowUps(int bookingId) async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/v1/mentor-roadmap-bookings/$bookingId/follow-ups',
      );
      if (response.data == null) return [];
      return response.data!
          .map(
            (json) => RoadmapFollowUpMeetingDto.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e, 'Lỗi lấy danh sách follow-up meetings');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  /// Accept a follow-up meeting.
  /// POST /api/v1/mentor-roadmap-bookings/{bookingId}/follow-ups/{meetingId}/accept
  Future<RoadmapFollowUpMeetingDto> acceptFollowUp(
    int bookingId,
    int meetingId,
  ) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/v1/mentor-roadmap-bookings/$bookingId/follow-ups/$meetingId/accept',
      );
      if (response.data == null) {
        throw UnknownException('Không có dữ liệu phản hồi');
      }
      return RoadmapFollowUpMeetingDto.fromJson(response.data!);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Không thể chấp nhận meeting');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  /// Reject a follow-up meeting with optional reason.
  /// POST /api/v1/mentor-roadmap-bookings/{bookingId}/follow-ups/{meetingId}/reject
  Future<RoadmapFollowUpMeetingDto> rejectFollowUp(
    int bookingId,
    int meetingId, {
    String? reason,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/v1/mentor-roadmap-bookings/$bookingId/follow-ups/$meetingId/reject',
        data: reason != null ? {'reason': reason} : null,
      );
      if (response.data == null) {
        throw UnknownException('Không có dữ liệu phản hồi');
      }
      return RoadmapFollowUpMeetingDto.fromJson(response.data!);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Không thể từ chối meeting');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  /// Create a new follow-up meeting (student or mentor initiated).
  /// POST /api/v1/mentor-roadmap-bookings/{bookingId}/follow-ups
  Future<RoadmapFollowUpMeetingDto> createFollowUp(
    int bookingId, {
    required String title,
    required String purpose,
    required String scheduledAt,
    int durationMinutes = 45,
    String? agenda,
    String? meetingLink,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/v1/mentor-roadmap-bookings/$bookingId/follow-ups',
        data: {
          'title': title,
          'purpose': purpose,
          'scheduledAt': scheduledAt,
          'durationMinutes': durationMinutes,
          if (agenda != null) 'agenda': agenda,
          if (meetingLink != null) 'meetingLink': meetingLink,
        },
      );
      if (response.data == null) {
        throw UnknownException('Không có dữ liệu phản hồi');
      }
      return RoadmapFollowUpMeetingDto.fromJson(response.data!);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Không thể tạo meeting');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  /// Converts DioException to AppException, preserving backend message.
  AppException _handleDioError(DioException e, String defaultMessage) {
    debugPrint(
      '🛑 RoadmapFollowUpService Error: ${e.type} | ${e.response?.statusCode}',
    );
    if (e.error is AppException) return e.error as AppException;
    if (e.response?.data != null) {
      try {
        final dynamic data = e.response?.data;
        Map<String, dynamic>? errorMap;
        if (data is Map) {
          errorMap = Map<String, dynamic>.from(data);
        } else if (data is String) {
          final decoded = jsonDecode(data);
          if (decoded is Map) errorMap = Map<String, dynamic>.from(decoded);
        }
        if (errorMap != null) {
          final msg =
              errorMap['message'] ?? errorMap['error'] ?? errorMap['details'];
          if (msg != null) {
            return ServerException(
              msg.toString(),
              statusCode: e.response?.statusCode,
            );
          }
        }
      } catch (_) {}
    }
    return ServerException(defaultMessage, statusCode: e.response?.statusCode);
  }
}
