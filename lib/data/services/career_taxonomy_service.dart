import '../models/career_taxonomy_models.dart';
import '../../core/network/api_client.dart';

/// Service for Career Taxonomy public read-only API.
/// Mirrors prototype careerTaxonomyService.ts (user-facing endpoints only).
class CareerTaxonomyService {
  final ApiClient _api = ApiClient();

  /// GET /domains — list all active domains.
  Future<List<DomainDto>> getActiveDomains() async {
    final response = await _api.get('/domains');
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((e) => DomainDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /job-positions?domainId=X — list active job positions for a domain.
  Future<List<JobPositionDto>> getActiveJobPositions(int domainId) async {
    final response = await _api.get(
      '/job-positions',
      queryParameters: {'domainId': domainId},
    );
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((e) => JobPositionDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /job-positions/{id}/tracks — list active tracks for a job position.
  Future<List<JobPositionTrackDto>> getActiveTracks(int jobPositionId) async {
    final response = await _api.get('/job-positions/$jobPositionId/tracks');
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((e) => JobPositionTrackDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /job-position-tracks/{trackId}/skills — list skills for a track.
  Future<List<JobPositionTrackSkillDto>> getTrackSkills(int trackId) async {
    final response =
        await _api.get('/job-position-tracks/$trackId/skills');
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((e) =>
            JobPositionTrackSkillDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
