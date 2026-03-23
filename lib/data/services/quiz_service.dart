import '../../core/exceptions/api_exception.dart';
import '../../core/network/api_client.dart';
import '../models/quiz_models.dart';

class QuizService {
  static final QuizService _instance = QuizService._internal();
  factory QuizService() => _instance;
  QuizService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Get quiz details by ID (learner-safe view)
  /// Uses /attempt-view endpoint (GET /quizzes/{id} now requires MENTOR/ADMIN)
  Future<QuizDetailDto> getQuiz(int quizId) async {
    try {
      final response = await _apiClient.dio.get('/quizzes/$quizId/attempt-view');
      return QuizDetailDto.fromJson(response.data);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Lấy thông tin bài kiểm tra thất bại: ${e.toString()}',
      );
    }
  }

  /// Get quizzes by module ID
  Future<List<QuizSummaryDto>> getQuizzesByModule(int moduleId) async {
    try {
      final response = await _apiClient.dio.get(
        '/quizzes/modules/$moduleId/quizzes',
      );
      return (response.data as List)
          .map((json) => QuizSummaryDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      // Return empty list if 404 or other non-critical error?
      // Better to throw so we can handle it in UI
      throw ApiException(
        'Lấy danh sách bài kiểm tra thất bại: ${e.toString()}',
      );
    }
  }

  /// Submit quiz answers (userId extracted from JWT by backend)
  Future<QuizSubmitResponseDto> submitQuiz({
    required int quizId,
    required SubmitQuizDto submitData,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/quizzes/$quizId/submit',
        data: submitData.toJson(),
      );

      final data = response.data as Map<String, dynamic>;

      return QuizSubmitResponseDto(
        score: data['score'] as int,
        passed: data['passed'] as bool,
        attempt: QuizAttemptDto.fromJson(
          data['attempt'] as Map<String, dynamic>,
        ),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Nộp bài thất bại: ${e.toString()}');
    }
  }

  /// Get user attempts for a quiz (userId extracted from JWT by backend)
  Future<List<QuizAttemptDto>> getUserAttempts({
    required int quizId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/quizzes/$quizId/attempts',
      );

      return (response.data as List)
          .map((json) => QuizAttemptDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Lấy lịch sử làm bài thất bại: ${e.toString()}');
    }
  }

  /// Get quiz attempt status with retry information (userId extracted from JWT)
  Future<QuizAttemptStatusDto> getQuizAttemptStatus({
    required int quizId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/quizzes/$quizId/attempt-status',
      );

      return QuizAttemptStatusDto.fromJson(response.data);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Lấy trạng thái quiz thất bại: ${e.toString()}');
    }
  }
}
