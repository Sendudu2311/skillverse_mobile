import 'package:dio/dio.dart';
import '../models/learning_report_model.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/error_handler.dart';

class LearningReportService {
  final ApiClient _apiClient = ApiClient();
  static const _basePath = '/student/learning-report';

  /// Extended timeout for AI generation requests (2 minutes)
  static const _aiTimeout = Duration(seconds: 120);

  /// Generate a new learning report (rate limit: 1 per 6 hours)
  Future<StudentLearningReportResponse> generateReport({
    String reportType = 'COMPREHENSIVE',
    bool includeChatHistory = true,
    bool includeDetailedSkills = true,
  }) async {
    try {
      final response = await _apiClient.post(
        '$_basePath/generate',
        data: GenerateReportRequest(
          reportType: reportType,
          includeChatHistory: includeChatHistory,
          includeDetailedSkills: includeDetailedSkills,
        ).toJson(),
        options: Options(receiveTimeout: _aiTimeout),
      );
      return StudentLearningReportResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Generate a quick report with defaults
  Future<StudentLearningReportResponse> generateQuickReport() async {
    try {
      final response = await _apiClient.post(
        '$_basePath/generate/quick',
        options: Options(receiveTimeout: _aiTimeout),
      );
      return StudentLearningReportResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get report history with pagination
  Future<List<StudentLearningReportResponse>> getReportHistory({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await _apiClient.get(
        '$_basePath/history',
        queryParameters: {'page': page, 'size': size},
      );
      final List<dynamic> data = response.data;
      return data
          .map(
            (json) => StudentLearningReportResponse.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get the latest report
  Future<StudentLearningReportResponse?> getLatestReport() async {
    try {
      final response = await _apiClient.get('$_basePath/latest');
      if (response.statusCode == 204 || response.data == null) {
        return null;
      }
      return StudentLearningReportResponse.fromJson(response.data);
    } catch (e) {
      // 204 No Content = no report yet
      if (e.toString().contains('204')) return null;
      throw _handleError(e);
    }
  }

  /// Get a specific report by ID
  Future<StudentLearningReportResponse> getReportById(int reportId) async {
    try {
      final response = await _apiClient.get('$_basePath/$reportId');
      return StudentLearningReportResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Centralized error handling
  Exception _handleError(dynamic error) {
    return Exception(ErrorHandler.getErrorMessage(error));
  }
}
