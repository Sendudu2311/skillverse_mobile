import '../../core/exceptions/api_exception.dart';
import '../../core/network/api_client.dart';
import '../models/quiz_models.dart';

class QuizService {
  static final QuizService _instance = QuizService._internal();
  factory QuizService() => _instance;
  QuizService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Get quiz details by ID
  Future<QuizDetailDto> getQuiz(int quizId) async {
    try {
      final response = await _apiClient.dio.get('/quizzes/$quizId');
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

  /// Submit quiz answers
  Future<QuizSubmitResponseDto> submitQuiz({
    required int quizId,
    required int userId,
    required SubmitQuizDto submitData,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/quizzes/$quizId/submit',
        queryParameters: {'userId': userId},
        data: submitData.toJson(),
      );

      // The backend returns a Map, we need to adapt it to QuizSubmitResponseDto
      // or ensure the DTO matches the backend response structure.
      // Based on controller: Map.of("score", score, "passed", passed, "attempt", attempt)
      final data = response.data as Map<String, dynamic>;

      // We can construct the response object here
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

  /// Get user attempts for a quiz
  Future<List<QuizAttemptDto>> getUserAttempts({
    required int quizId,
    required int userId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/quizzes/$quizId/attempts',
        queryParameters: {'userId': userId},
      );

      return (response.data as List)
          .map((json) => QuizAttemptDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Lấy lịch sử làm bài thất bại: ${e.toString()}');
    }
  }
}
