import 'package:flutter/foundation.dart';
import '../../core/utils/error_handler.dart';
import '../../data/models/final_verification_models.dart';
import '../../data/models/node_mentoring_models.dart'
    show NodeEvidenceRecordResponse;
import '../../data/services/final_verification_service.dart';
import '../../data/services/node_mentoring_service.dart';

class FinalVerificationProvider extends ChangeNotifier {
  final FinalVerificationService _service = FinalVerificationService();
  final NodeMentoringService _uploadService = NodeMentoringService();

  // ─── State ────────────────────────────────────────────────────────────────

  bool _isLoading = false;
  bool _isBusy = false;
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _error;

  JourneyCompletionGateResponse? _gate;
  JourneyOutputAssessmentResponse? _outputAssessment;
  List<VerificationEvidenceReportResponse> _history = [];

  // Dossier (batch node evidence)
  Map<String, NodeEvidenceRecordResponse?> _nodeEvidences = {};
  bool _isLoadingDossier = false;

  // ─── Getters ─────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  bool get isBusy => _isBusy;
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String? get error => _error;
  JourneyCompletionGateResponse? get gate => _gate;
  JourneyOutputAssessmentResponse? get outputAssessment => _outputAssessment;
  List<VerificationEvidenceReportResponse> get history => _history;

  Map<String, NodeEvidenceRecordResponse?> get nodeEvidences => _nodeEvidences;
  bool get isLoadingDossier => _isLoadingDossier;

  /// Only entries where evidence was actually submitted (non-null).
  List<MapEntry<String, NodeEvidenceRecordResponse>> get submittedEvidences =>
      _nodeEvidences.entries
          .where((e) => e.value != null)
          .map((e) => MapEntry(e.key, e.value!))
          .toList();

  // ─── Load ─────────────────────────────────────────────────────────────────

  Future<void> load(int journeyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.getGate(journeyId),
        _service.getOutputAssessment(journeyId),
        _service.getVerificationHistory(journeyId),
      ]);
      _gate = results[0] as JourneyCompletionGateResponse;
      _outputAssessment = results[1] as JourneyOutputAssessmentResponse?;
      _history = results[2] as List<VerificationEvidenceReportResponse>;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Upload attachment ────────────────────────────────────────────────────

  Future<String?> uploadAttachment({
    required String filePath,
    required String fileName,
    required int actorId,
  }) async {
    _isUploading = true;
    _uploadProgress = 0;
    _error = null;
    notifyListeners();
    try {
      return await _uploadService.uploadAttachment(
        filePath: filePath,
        fileName: fileName,
        actorId: actorId,
        onProgress: (p) {
          _uploadProgress = p;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      return null;
    } finally {
      _isUploading = false;
      _uploadProgress = 0;
      notifyListeners();
    }
  }

  // ─── Submit output assessment ─────────────────────────────────────────────

  Future<bool> submitOutput(
    int journeyId,
    SubmitJourneyOutputRequest request,
  ) async {
    _isBusy = true;
    notifyListeners();
    try {
      _outputAssessment =
          await _service.submitOutputAssessment(journeyId, request);
      await load(journeyId);
      return true;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      notifyListeners();
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  // ─── Create final meeting ─────────────────────────────────────────────────

  Future<String?> createFinalMeeting(int journeyId) async {
    _isBusy = true;
    notifyListeners();
    try {
      return await _service.createFinalMeeting(journeyId);
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      return null;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ─── Dossier (batch node evidence) ────────────────────────────────────────

  /// Load evidence for all given nodeIds in parallel.
  /// Call after gate/main data is loaded.
  Future<void> loadDossier(int journeyId, List<String> nodeIds) async {
    if (nodeIds.isEmpty) return;
    _isLoadingDossier = true;
    notifyListeners();
    try {
      _nodeEvidences = await _uploadService.getBatchEvidence(
        journeyId,
        nodeIds,
      );
    } catch (e) {
      debugPrint('⚠️ loadDossier error: $e');
      // Non-fatal: dossier is supplementary, don't overwrite _error
    } finally {
      _isLoadingDossier = false;
      notifyListeners();
    }
  }
}
