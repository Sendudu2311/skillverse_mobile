import 'package:dio/dio.dart';
import '../models/student_verification_models.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/error_handler.dart';

/// Service for Student Verification API endpoints.
/// Endpoints: POST /student-verifications/requests, GET /student-verifications/eligibility, etc.
class StudentVerificationService {
  final ApiClient _apiClient = ApiClient();

  // ==================== Student Endpoints ====================

  /// Start verification — submit school email + student card image.
  /// POST /api/student-verifications/requests (multipart/form-data)
  Future<StudentVerificationStartResponse> startVerification({
    required String schoolEmail,
    required String imagePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'schoolEmail': schoolEmail,
        'studentCardImage': await MultipartFile.fromFile(imagePath),
      });
      final response = await _apiClient.dio.post(
        '/student-verifications/requests',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );
      return StudentVerificationStartResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Resend OTP for a pending request.
  /// POST /api/student-verifications/requests/{requestId}/resend-otp
  Future<StudentVerificationStartResponse> resendOtp(int requestId) async {
    try {
      final response = await _apiClient.post(
        '/student-verifications/requests/$requestId/resend-otp',
      );
      return StudentVerificationStartResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Verify OTP and submit for admin review.
  /// POST /api/student-verifications/requests/{requestId}/verify-otp
  Future<StudentVerificationDetailResponse> verifyOtp({
    required int requestId,
    required String otp,
  }) async {
    try {
      final response = await _apiClient.post(
        '/student-verifications/requests/$requestId/verify-otp',
        data: VerifyOtpRequest(otp: otp).toJson(),
      );
      return StudentVerificationDetailResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get the current user's latest verification request.
  /// GET /api/student-verifications/requests/latest
  Future<StudentVerificationDetailResponse> getLatestRequest() async {
    try {
      final response = await _apiClient.get(
        '/student-verifications/requests/latest',
      );
      return StudentVerificationDetailResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get a specific request detail by ID.
  /// GET /api/student-verifications/requests/{requestId}
  Future<StudentVerificationDetailResponse> getRequestDetail(
    int requestId,
  ) async {
    try {
      final response = await _apiClient.get(
        '/student-verifications/requests/$requestId',
      );
      return StudentVerificationDetailResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Check student premium eligibility.
  /// GET /api/student-verifications/eligibility
  Future<StudentVerificationEligibilityResponse> getEligibility() async {
    try {
      final response = await _apiClient.get(
        '/student-verifications/eligibility',
      );
      return StudentVerificationEligibilityResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get the student card image URL for a request.
  /// GET /api/student-verifications/requests/{requestId}/image
  /// Returns the binary image resource — caller should use the URL directly.
  String getImageUrl(int requestId) {
    final baseUrl = _apiClient.dio.options.baseUrl;
    return '$baseUrl/student-verifications/requests/$requestId/image';
  }

  /// Handle errors
  Exception _handleError(dynamic error) {
    return Exception(ErrorHandler.getErrorMessage(error));
  }
}
