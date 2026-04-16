import '../models/module_models.dart';
import '../models/lesson_models.dart';
import '../models/module_with_content_models.dart';
import '../../core/network/api_client.dart';

class ModuleService {
  static final ModuleService _instance = ModuleService._internal();
  factory ModuleService() => _instance;
  ModuleService._internal();

  final ApiClient _apiClient = ApiClient();

  /// List all modules with full content (lessons, quizzes, assignments)
  /// GET /courses/{courseId}/modules/full
  Future<List<ModuleWithContentDto>> listModulesWithContent({
    required int courseId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/courses/$courseId/modules/full',
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map(
            (json) =>
                ModuleWithContentDto.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e, stackTrace) {
      print('=== ERROR IN listModulesWithContent ===');
      print(e);
      print(stackTrace);
      rethrow;
    }
  }

  /// List all modules for a course
  /// GET /courses/{courseId}/modules
  Future<List<ModuleSummaryDto>> listModules({required int courseId}) async {
    try {
      final response = await _apiClient.dio.get('/courses/$courseId/modules');

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map(
            (json) => ModuleSummaryDto.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get module progress for a user
  /// GET /modules/{moduleId}/progress?userId={userId}
  Future<ModuleProgressDto> getModuleProgress({
    required int moduleId,
    required int userId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/modules/$moduleId/progress',
        queryParameters: {'userId': userId},
      );
      return ModuleProgressDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// List lessons in a module
  /// GET /modules/{moduleId}/lessons
  Future<List<LessonBriefDto>> listLessons({required int moduleId}) async {
    try {
      final response = await _apiClient.dio.get('/modules/$moduleId/lessons');

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => LessonBriefDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
