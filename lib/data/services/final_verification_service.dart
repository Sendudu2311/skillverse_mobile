import '../../core/network/api_client.dart';
import '../../core/utils/error_handler.dart';
import '../models/final_verification_models.dart';

class FinalVerificationService {
  final ApiClient _apiClient = ApiClient();

  String _base(int journeyId) => '/v1/journeys/$journeyId';

  // ─── Gate ────────────────────────────────────────────────────────────────

  /// GET /api/v1/journeys/{journeyId}/completion-gate
  Future<JourneyCompletionGateResponse> getGate(int journeyId) async {
    try {
      final res = await _apiClient.get('${_base(journeyId)}/completion-gate');
      return JourneyCompletionGateResponse.fromJson(res.data);
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  // ─── Output Assessment ───────────────────────────────────────────────────

  /// GET /api/v1/journeys/{journeyId}/output-assessment
  /// Returns null when backend returns 204.
  Future<JourneyOutputAssessmentResponse?> getOutputAssessment(
      int journeyId) async {
    try {
      final res =
          await _apiClient.get('${_base(journeyId)}/output-assessment');
      if (res.statusCode == 204 || res.data == null) return null;
      return JourneyOutputAssessmentResponse.fromJson(res.data);
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  /// POST /api/v1/journeys/{journeyId}/output-assessment
  Future<JourneyOutputAssessmentResponse> submitOutputAssessment(
      int journeyId, SubmitJourneyOutputRequest request) async {
    try {
      final res = await _apiClient.post(
        '${_base(journeyId)}/output-assessment',
        data: request.toJson(),
      );
      return JourneyOutputAssessmentResponse.fromJson(res.data);
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  // ─── Verification History ────────────────────────────────────────────────

  /// GET /api/v1/journeys/{journeyId}/verification-history
  Future<List<VerificationEvidenceReportResponse>> getVerificationHistory(
      int journeyId) async {
    try {
      final res =
          await _apiClient.get('${_base(journeyId)}/verification-history');
      final list = res.data as List<dynamic>;
      return list
          .map((e) => VerificationEvidenceReportResponse.fromJson(
              e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  // ─── Final Meeting ───────────────────────────────────────────────────────

  /// POST /api/v1/journeys/{journeyId}/final-meeting/create
  Future<String> createFinalMeeting(int journeyId) async {
    try {
      final res =
          await _apiClient.post('${_base(journeyId)}/final-meeting/create');
      return res.data['meetingLink'] as String;
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }
}
