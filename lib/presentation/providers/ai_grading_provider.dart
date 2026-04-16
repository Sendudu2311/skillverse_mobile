import 'package:flutter/foundation.dart';
import '../../data/services/ai_grading_service.dart';
import '../../data/models/ai_grading_models.dart';

/// Provider for AI Grading feature
/// Manages fetching AI grading results and dispute flow
class AiGradingProvider extends ChangeNotifier {
  final AiGradingService _service = AiGradingService();

  // State
  bool _isLoading = false;
  String? _errorMessage;
  AiGradingResult? _currentResult;
  bool _isDisputing = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AiGradingResult? get currentResult => _currentResult;
  bool get isDisputing => _isDisputing;

  /// Fetch AI grading result for a submission
  Future<void> fetchAiGradingResult(int submissionId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentResult = await _service.getAiGradeResult(submissionId);
    } catch (e) {
      _errorMessage = e.toString();
      _currentResult = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Student disputes AI grade — requests Mentor to re-review
  Future<bool> disputeAiGrade(int submissionId, {String? reason}) async {
    _isDisputing = true;
    notifyListeners();

    try {
      await _service.requestMentorReview(submissionId, reason: reason);
      _isDisputing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isDisputing = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear current result (e.g., when navigating away)
  void clearResult() {
    _currentResult = null;
    _errorMessage = null;
    notifyListeners();
  }
}
