import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/error/exceptions.dart';
import '../../core/network/api_client.dart';
import '../models/student_skill_verification_models.dart';

/// Service for Student Skill Verification API calls.
/// Endpoints: POST/GET /api/v1/student/skill-verifications
class StudentSkillVerificationService {
  static final StudentSkillVerificationService _instance =
      StudentSkillVerificationService._internal();
  factory StudentSkillVerificationService() => _instance;
  StudentSkillVerificationService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Submit a new skill verification request.
  /// POST /api/v1/student/skill-verifications
  Future<StudentSkillVerificationResponse> submitVerification(
    CreateStudentSkillVerificationRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/v1/student/skill-verifications',
        data: request.toJson(),
      );
      if (response.data == null) {
        throw UnknownException('Không có dữ liệu phản hồi');
      }
      return StudentSkillVerificationResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Gửi yêu cầu xác thực thất bại');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  /// Get all my skill verification requests.
  /// GET /api/v1/student/skill-verifications
  Future<List<StudentSkillVerificationResponse>> getMyVerifications() async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/v1/student/skill-verifications',
      );
      if (response.data == null) return [];
      return response.data!
          .map(
            (json) => StudentSkillVerificationResponse.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e, 'Lỗi lấy danh sách yêu cầu xác thực');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  /// Get my verified skill names.
  /// GET /api/v1/student/skill-verifications/verified-skills
  Future<List<String>> getMyVerifiedSkills() async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/v1/student/skill-verifications/verified-skills',
      );
      if (response.data == null) return [];
      return response.data!.map((e) => e as String).toList();
    } on DioException catch (e) {
      throw _handleDioError(e, 'Lỗi lấy danh sách kỹ năng đã xác thực');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  /// Converts DioException to AppException, preserving backend message.
  AppException _handleDioError(DioException e, String defaultMessage) {
    debugPrint(
      '🛑 StudentSkillVerificationService Error: ${e.type} | ${e.response?.statusCode}',
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
