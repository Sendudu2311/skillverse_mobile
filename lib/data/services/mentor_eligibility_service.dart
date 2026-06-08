import '../../core/error/exceptions.dart';
import '../../core/network/api_client.dart';
import '../models/mentor_eligibility_models.dart';

class MentorEligibilityService {
  final ApiClient _apiClient = ApiClient();

  Future<MentorTeachingEligibilityResponse> evaluateJourney({
    required int journeyId,
    required int mentorId,
    String? nodeId,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/v1/mentor-eligibility/journeys/$journeyId/mentors/$mentorId',
        queryParameters: nodeId == null || nodeId.isEmpty
            ? null
            : {'nodeId': nodeId},
      );
      return MentorTeachingEligibilityResponse.fromJson(response.data ?? {});
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Không thể đánh giá độ phù hợp mentor');
    }
  }

  Future<MentorTeachingEligibilityResponse> evaluateRoadmap({
    required int roadmapSessionId,
    required int mentorId,
    String? nodeId,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/v1/mentor-eligibility/roadmaps/$roadmapSessionId/mentors/$mentorId',
        queryParameters: nodeId == null || nodeId.isEmpty
            ? null
            : {'nodeId': nodeId},
      );
      return MentorTeachingEligibilityResponse.fromJson(response.data ?? {});
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Không thể đánh giá độ phù hợp mentor');
    }
  }
}
