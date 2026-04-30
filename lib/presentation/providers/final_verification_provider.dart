import 'package:flutter/foundation.dart';
import '../../data/models/final_verification_models.dart';
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

  // ─── Getters ─────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  bool get isBusy => _isBusy;
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String? get error => _error;
  JourneyCompletionGateResponse? get gate => _gate;
  JourneyOutputAssessmentResponse? get outputAssessment => _outputAssessment;
  List<VerificationEvidenceReportResponse> get history => _history;

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
      _error = e.toString().replaceFirst('Exception: ', '');
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
      _error = e.toString().replaceFirst('Exception: ', '');
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
      _error = e.toString().replaceFirst('Exception: ', '');
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
      _error = e.toString().replaceFirst('Exception: ', '');
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
}
