import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../models/skill_resolve_models.dart';

/// Question Bank Service
/// Handles API calls for Skill resolving via AI
class QuestionBankService {
  static final QuestionBankService _instance = QuestionBankService._internal();
  factory QuestionBankService() => _instance;
  QuestionBankService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Resolve a free-text skill string into a domain/industry/role
  Future<SkillResolveResponse> resolveSkill(String skillName) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/v1/question-banks/skills/resolve',
        data: {'skillName': skillName},
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.data == null) {
        throw Exception('No response data');
      }

      // Handle wrapped responses if 'data' wrapper exists
      Map<String, dynamic> jsonData = response.data!;
      if (jsonData.containsKey('data') && jsonData['data'] != null) {
        jsonData = jsonData['data'] as Map<String, dynamic>;
      }

      return SkillResolveResponse.fromJson(jsonData);
    } catch (e) {
      debugPrint('❌ Error resolving skill via AI: $e');
      rethrow;
    }
  }
}
