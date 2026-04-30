import 'package:flutter/foundation.dart';
import '../../data/services/interview_service.dart';
import '../../data/models/interview_models.dart';
import '../../core/exceptions/api_exception.dart';
import '../../core/utils/error_handler.dart';

/// Provider for Interview Schedule feature
/// Manages fetching, cancelling interviews for the current user
class InterviewProvider extends ChangeNotifier {
  final InterviewService _service = InterviewService();

  // State
  bool _isLoading = false;
  bool _isSubmittingAction = false;
  String? _errorMessage;
  List<InterviewScheduleResponse> _myInterviews = [];
  InterviewScheduleResponse? _currentInterview; // for single-app lookup

  // Getters
  bool get isLoading => _isLoading;
  bool get isSubmittingAction => _isSubmittingAction;
  String? get errorMessage => _errorMessage;
  List<InterviewScheduleResponse> get myInterviews => _myInterviews;
  InterviewScheduleResponse? get currentInterview => _currentInterview;

  /// Load all interviews for current user
  Future<void> loadMyInterviews() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myInterviews = await _service.getMyInterviews();
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      _myInterviews = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch interview by application ID (for Job Detail page)
  Future<void> loadInterviewByApplication(int applicationId) async {
    _isLoading = true;
    _errorMessage = null;
    _currentInterview = null;
    notifyListeners();

    try {
      _currentInterview = await _service.getByApplication(applicationId);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        // 404 means no interview scheduled yet — that's OK
        _currentInterview = null;
        debugPrint('ℹ️ No interview found for application $applicationId');
      } else {
        _errorMessage = e.message;
        debugPrint('❌ Error loading interview: ${e.message}');
      }
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      debugPrint('❌ Error loading interview: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Candidate confirms a PENDING interview
  Future<bool> confirmInterview(int interviewId) async {
    _isSubmittingAction = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final updated = await _service.confirmInterview(interviewId);
      _replaceInState(interviewId, updated);
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      return false;
    } finally {
      _isSubmittingAction = false;
      notifyListeners();
    }
  }

  /// Candidate declines a PENDING interview
  Future<bool> declineInterview(int interviewId, {String? reason}) async {
    _isSubmittingAction = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final updated = await _service.declineInterview(
        interviewId,
        reason: reason,
      );
      _replaceInState(interviewId, updated);
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      return false;
    } finally {
      _isSubmittingAction = false;
      notifyListeners();
    }
  }

  /// Cancel an interview (recruiter-only — candidate should use declineInterview)
  Future<bool> cancelInterview(int interviewId) async {
    try {
      final updated = await _service.cancelInterview(interviewId);
      _replaceInState(interviewId, updated);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  void _replaceInState(int interviewId, InterviewScheduleResponse updated) {
    final idx = _myInterviews.indexWhere((i) => i.id == interviewId);
    if (idx != -1) _myInterviews[idx] = updated;
    if (_currentInterview?.id == interviewId) _currentInterview = updated;
  }

  /// Clears state when navigating away
  void clearCurrent() {
    _currentInterview = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Called by app-level logout listener to purge user data.
  void clearOnLogout() => clearCurrent();
}
