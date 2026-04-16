import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../../core/exceptions/api_exception.dart';
import '../models/ai_grading_models.dart';

/// Service for AI-powered assignment grading
/// Backend: AiGradingController.java — /api/ai-grading
class AiGradingService {
  static final AiGradingService _instance = AiGradingService._internal();
  factory AiGradingService() => _instance;
  AiGradingService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Trigger AI grading for a submission (Mentor/Admin only)
  /// POST /api/ai-grading/generate/{submissionId}
  Future<AiGradingResult> generateAiGrade(int submissionId) async {
    try {
      final response = await _apiClient.dio.post(
        '/ai-grading/generate/$submissionId',
      );
      return AiGradingResult.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ Error generating AI grade: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Chấm điểm AI thất bại: ${e.toString()}');
    }
  }

  /// Get AI grade result for a submission
  /// GET /api/ai-grading/result/{submissionId}
  Future<AiGradingResult> getAiGradeResult(int submissionId) async {
    try {
      final response = await _apiClient.dio.get(
        '/ai-grading/result/$submissionId',
      );
      return AiGradingResult.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ Error getting AI grade result: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Lấy kết quả AI thất bại: ${e.toString()}');
    }
  }

  /// Student requests mentor to review an AI-graded submission (dispute)
  /// PUT /api/ai-grading/dispute/{submissionId}
  Future<void> requestMentorReview(int submissionId, {String? reason}) async {
    try {
      await _apiClient.dio.put(
        '/ai-grading/dispute/$submissionId',
        data: reason,
      );
    } catch (e) {
      debugPrint('❌ Error requesting mentor review: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Yêu cầu mentor chấm lại thất bại: ${e.toString()}');
    }
  }

  /// Toggle Trust AI for an assignment (Mentor/Admin only)
  /// PUT /api/ai-grading/assignment/{assignmentId}/trust-ai?enabled=true|false
  Future<void> toggleTrustAi(int assignmentId, {required bool enabled}) async {
    try {
      await _apiClient.dio.put(
        '/ai-grading/assignment/$assignmentId/trust-ai',
        queryParameters: {'enabled': enabled},
      );
    } catch (e) {
      debugPrint('❌ Error toggling trust AI: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Thay đổi cài đặt AI thất bại: ${e.toString()}');
    }
  }
}
