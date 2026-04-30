import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/error/exceptions.dart';
import '../../core/network/api_client.dart';
import '../models/node_mentoring_models.dart';

/// Service for Mentor Roadmap Workspace APIs.
/// Handles workspace data + follow-up meetings.
/// Base: /api/v1/mentor-roadmap-bookings
class MentorRoadmapWorkspaceService {
  static final MentorRoadmapWorkspaceService _instance =
      MentorRoadmapWorkspaceService._internal();
  factory MentorRoadmapWorkspaceService() => _instance;
  MentorRoadmapWorkspaceService._internal();

  final ApiClient _apiClient = ApiClient();
  static const String _base = '/v1/mentor-roadmap-bookings';

  // ─── Workspace ───────────────────────────────────────────────────────────

  /// Get follow-up meetings for a booking.
  /// GET /api/v1/mentor-roadmap-bookings/{bookingId}/follow-ups
  Future<List<RoadmapFollowUpMeetingDTO>> getFollowUps(int bookingId) async {
    try {
      final response = await _apiClient.dio.get('$_base/$bookingId/follow-ups');
      if (response.data == null) return [];
      final list = response.data as List<dynamic>;
      return list
          .map(
            (json) => RoadmapFollowUpMeetingDTO.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw _handleDioError(e, 'Lấy danh sách lịch hẹn thất bại');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  /// Create a follow-up meeting.
  /// POST /api/v1/mentor-roadmap-bookings/{bookingId}/follow-ups
  Future<RoadmapFollowUpMeetingDTO> createFollowUp(
    int bookingId,
    CreateFollowUpMeetingRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '$_base/$bookingId/follow-ups',
        data: request.toJson(),
      );
      return RoadmapFollowUpMeetingDTO.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleDioError(e, 'Tạo lịch hẹn thất bại');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  /// Accept a follow-up meeting.
  /// POST /api/v1/mentor-roadmap-bookings/{bookingId}/follow-ups/{meetingId}/accept
  Future<RoadmapFollowUpMeetingDTO> acceptFollowUp(
    int bookingId,
    int meetingId,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '$_base/$bookingId/follow-ups/$meetingId/accept',
      );
      return RoadmapFollowUpMeetingDTO.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleDioError(e, 'Chấp nhận lịch hẹn thất bại');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  /// Reject a follow-up meeting with optional reason.
  /// POST /api/v1/mentor-roadmap-bookings/{bookingId}/follow-ups/{meetingId}/reject
  Future<RoadmapFollowUpMeetingDTO> rejectFollowUp(
    int bookingId,
    int meetingId, {
    String? reason,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '$_base/$bookingId/follow-ups/$meetingId/reject',
        data: reason != null ? {'reason': reason} : null,
      );
      return RoadmapFollowUpMeetingDTO.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleDioError(e, 'Từ chối lịch hẹn thất bại');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  /// Delete a follow-up meeting.
  /// DELETE /api/v1/mentor-roadmap-bookings/{bookingId}/follow-ups/{meetingId}
  Future<void> deleteFollowUp(int bookingId, int meetingId) async {
    try {
      await _apiClient.dio.delete('$_base/$bookingId/follow-ups/$meetingId');
    } on DioException catch (e) {
      throw _handleDioError(e, 'Xóa lịch hẹn thất bại');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  // ─── Error Handling ──────────────────────────────────────────────────────

  AppException _handleDioError(DioException e, String defaultMessage) {
    debugPrint(
      '🛑 WorkspaceService Error: ${e.type} | ${e.response?.statusCode}',
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
