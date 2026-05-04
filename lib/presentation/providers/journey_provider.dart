import 'package:flutter/material.dart';
import '../../data/models/journey_models.dart';
import '../../data/services/journey_service.dart';
import '../../core/utils/error_handler.dart';
import '../../core/mixins/provider_loading_mixin.dart';

class JourneyProvider
    with ChangeNotifier, LoadingStateProviderMixin, MultiLoadingProviderMixin {
  final JourneyService _journeyService = JourneyService();
  static const String activeJourneyBlockReason =
      'Bạn đang có một hành trình chưa hoàn thành. Hãy hoàn thành hoặc xóa hành trình cũ trước khi tạo mới.';

  // State
  List<JourneySummaryDto> _journeys = [];
  List<JourneySummaryDto> _activeJourneys = [];
  JourneySummaryDto? _currentJourney;
  GenerateTestResponseDto? _generatedTest;
  TestResultDto? _testResult;
  JourneySummaryDto? _pendingJourneyForTestGeneration;
  bool _hasLoadedActiveJourneys = false;

  // Wizard state
  int _wizardStep = 1;
  bool _isCreating = false;
  bool _isAutoGenerating = false;

  // ============================================================================
  // GETTERS
  // ============================================================================

  List<JourneySummaryDto> get journeys => _journeys;
  List<JourneySummaryDto> get activeJourneys => _activeJourneys;
  JourneySummaryDto? get currentJourney => _currentJourney;
  GenerateTestResponseDto? get generatedTest => _generatedTest;
  TestResultDto? get testResult => _testResult;
  int get wizardStep => _wizardStep;
  bool get isCreating => _isCreating;
  bool get isAutoGenerating => _isAutoGenerating;

  /// True if any active-journey entry is still non-terminal for creation.
  bool get hasActiveJourney =>
      _activeJourneys.any((journey) => !_isTerminalForCreation(journey.status));

  // ============================================================================
  // WIZARD CONTROL
  // ============================================================================

  void setWizardStep(int step) {
    _wizardStep = step;
    notifyListeners();
  }

  void nextWizardStep() {
    if (_wizardStep < 4) {
      _wizardStep++;
      notifyListeners();
    }
  }

  void previousWizardStep() {
    if (_wizardStep > 1) {
      _wizardStep--;
      notifyListeners();
    }
  }

  void resetWizard() {
    _wizardStep = 1;
    notifyListeners();
  }

  // ============================================================================
  // JOURNEY LIFECYCLE
  // ============================================================================

  /// Load all journeys for current user
  Future<void> loadJourneys({int page = 0, int size = 20}) async {
    await executeAsync(() async {
      _journeys = await _journeyService.getUserJourneys(page: page, size: size);
      notifyListeners();
    }, errorMessageBuilder: (error) => error.toString());
  }

  /// Load active journeys from the dedicated backend endpoint.
  Future<List<JourneySummaryDto>> loadActiveJourneys({
    bool force = false,
    bool silent = false,
  }) async {
    if (!force && _hasLoadedActiveJourneys) {
      return _activeJourneys;
    }

    try {
      final journeys = await _journeyService.getActiveJourneys();
      _activeJourneys = journeys;
      _hasLoadedActiveJourneys = true;
      if (!silent) {
        notifyListeners();
      }
      return _activeJourneys;
    } catch (e) {
      if (!silent) {
        setError(ErrorHandler.getErrorMessage(e));
      }
      rethrow;
    }
  }

  /// Returns whether user can create a new journey based on backend-active data.
  Future<bool> canCreateJourney({
    bool force = false,
    bool silent = false,
  }) async {
    try {
      await loadActiveJourneys(force: force, silent: silent);
      return !hasActiveJourney;
    } catch (_) {
      // Allow navigation when pre-check fails; backend still enforces the rule.
      return true;
    }
  }

  /// Load a single journey by ID
  Future<JourneySummaryDto?> loadJourneyById(int journeyId) async {
    return await executeAsync(() async {
      _currentJourney = await _journeyService.getJourneyById(journeyId);
      _syncJourneyInCollections(_currentJourney!);
      notifyListeners();
      return _currentJourney!;
    }, errorMessageBuilder: (error) => error.toString());
  }

  /// Start a new journey and generate its first assessment test before navigating.
  Future<JourneySummaryDto?> startJourneyAndGenerateTest(
    StartJourneyRequest request,
  ) async {
    _isCreating = true;
    clearError();
    _generatedTest = null;
    _testResult = null;
    notifyListeners();

    JourneySummaryDto? journey = _pendingJourneyForTestGeneration;
    try {
      journey ??= await _journeyService.startJourney(request);
      _pendingJourneyForTestGeneration = journey;
      _currentJourney = journey;
      _syncJourneyInCollections(journey);

      _generatedTest = await _journeyService.generateTest(journey.id);
      _currentJourney = await _journeyService.getJourneyById(journey.id);
      _pendingJourneyForTestGeneration = null;
      _syncJourneyInCollections(_currentJourney!);

      _isCreating = false;
      notifyListeners();
      return _currentJourney;
    } catch (e) {
      _isCreating = false;
      final fallbackMessage = journey != null
          ? 'Không thể tạo bài test lúc này. Vui lòng thử lại.'
          : 'Tạo hành trình thất bại';
      final errorMessage = ErrorHandler.getErrorMessage(e);
      setError(errorMessage.isNotEmpty ? errorMessage : fallbackMessage);
      return null;
    }
  }

  /// Auto-generate test after navigating to detail page (non-blocking)
  Future<void> autoGenerateTestIfNeeded(int journeyId) async {
    final journey = _currentJourney;
    if (journey == null) return;

    // Guard: skip if test exists OR already generating
    if (journey.assessmentTestId != null) return;
    if (_isAutoGenerating) return;

    _isAutoGenerating = true;
    notifyListeners();

    try {
      _generatedTest = await _journeyService.generateTest(journeyId);
      // Reload journey to get updated status (now has assessmentTestId)
      await loadJourneyById(journeyId);
    } catch (e) {
      debugPrint('⚠️ Test generation failed: $e');
      setError(ErrorHandler.getErrorMessage(e));
    } finally {
      _isAutoGenerating = false;
      notifyListeners();
    }
  }

  // ============================================================================
  // ASSESSMENT TEST FLOW
  // ============================================================================

  /// Generate AI assessment test
  Future<GenerateTestResponseDto?> generateTest(int journeyId) async {
    return await performAsyncFor<GenerateTestResponseDto>(
      'generateTest',
      () async {
        _generatedTest = await _journeyService.generateTest(journeyId);
        _currentJourney = await _journeyService.getJourneyById(journeyId);
        _syncJourneyInCollections(_currentJourney!);
        notifyListeners();
        return _generatedTest!;
      },
    );
  }

  /// Get assessment test details
  Future<AssessmentTestDto?> getAssessmentTest({
    required int journeyId,
    required int testId,
  }) async {
    return await performAsyncFor<AssessmentTestDto>('getTest', () async {
      return await _journeyService.getAssessmentTest(
        journeyId: journeyId,
        testId: testId,
      );
    });
  }

  /// Submit test answers
  Future<TestResultDto?> submitTest({
    required int journeyId,
    required SubmitTestRequest request,
  }) async {
    return await performAsyncFor<TestResultDto>('submitTest', () async {
      _testResult = await _journeyService.submitTest(
        journeyId: journeyId,
        request: request,
      );

      // Reload journey to get updated status
      await loadJourneyById(journeyId);

      notifyListeners();
      return _testResult!;
    });
  }

  /// Get test result
  Future<TestResultDto?> getTestResult({
    required int journeyId,
    required int resultId,
  }) async {
    return await performAsyncFor<TestResultDto>('getResult', () async {
      _testResult = await _journeyService.getTestResult(
        journeyId: journeyId,
        resultId: resultId,
      );
      notifyListeners();
      return _testResult!;
    });
  }

  // ============================================================================
  // ROADMAP INTEGRATION
  // ============================================================================

  /// Generate roadmap from test results
  Future<JourneySummaryDto?> generateRoadmap(int journeyId) async {
    return await performAsyncFor<JourneySummaryDto>(
      'generateRoadmap',
      () async {
        _currentJourney = await _journeyService.generateRoadmap(journeyId);
        _syncJourneyInCollections(_currentJourney!);
        notifyListeners();
        return _currentJourney!;
      },
    );
  }

  // ============================================================================
  // STATUS CONTROL
  // ============================================================================

  Future<JourneySummaryDto?> pauseJourney(int journeyId) async {
    return await _lifecycleAction(
      journeyId,
      () => _journeyService.pauseJourney(journeyId),
    );
  }

  Future<JourneySummaryDto?> resumeJourney(int journeyId) async {
    return await _lifecycleAction(
      journeyId,
      () => _journeyService.resumeJourney(journeyId),
    );
  }

  Future<JourneySummaryDto?> cancelJourney(int journeyId) async {
    return await _lifecycleAction(
      journeyId,
      () => _journeyService.cancelJourney(journeyId),
    );
  }

  Future<JourneySummaryDto?> completeJourney(int journeyId) async {
    return await _lifecycleAction(
      journeyId,
      () => _journeyService.completeJourney(journeyId),
    );
  }

  Future<JourneySummaryDto?> requestVerification(int journeyId) async {
    return await _lifecycleAction(
      journeyId,
      () => _journeyService.requestVerification(journeyId),
    );
  }

  /// Delete a journey and optimistically remove it from the list
  Future<bool> deleteJourney(int journeyId) async {
    // Optimistic removal
    final backup = List<JourneySummaryDto>.from(_journeys);
    final activeBackup = List<JourneySummaryDto>.from(_activeJourneys);
    _journeys.removeWhere((j) => j.id == journeyId);
    _activeJourneys.removeWhere((j) => j.id == journeyId);
    if (_currentJourney?.id == journeyId) _currentJourney = null;
    if (_pendingJourneyForTestGeneration?.id == journeyId) {
      _pendingJourneyForTestGeneration = null;
    }
    notifyListeners();

    try {
      await _journeyService.deleteJourney(journeyId);
      return true;
    } catch (e) {
      // Rollback on failure
      _journeys = backup;
      _activeJourneys = activeBackup;
      setError(ErrorHandler.getErrorMessage(e));
      notifyListeners();
      return false;
    }
  }

  /// Generate study plans for all nodes of a journey's roadmap
  Future<Map<String, dynamic>?> generateStudyPlans(int journeyId) async {
    return await performAsyncFor<Map<String, dynamic>>(
      'generateStudyPlans',
      () => _journeyService.generateStudyPlans(journeyId),
    );
  }

  Future<JourneySummaryDto?> generateAiReport(int journeyId) async {
    return await performAsyncFor<JourneySummaryDto>('generateReport', () async {
      _currentJourney = await _journeyService.generateAiReport(journeyId);
      notifyListeners();
      return _currentJourney!;
    });
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  Future<JourneySummaryDto?> _lifecycleAction(
    int journeyId,
    Future<JourneySummaryDto> Function() action,
  ) async {
    return await executeAsync(() async {
      _currentJourney = await action();
      _syncJourneyInCollections(_currentJourney!);
      notifyListeners();
      return _currentJourney!;
    }, errorMessageBuilder: (error) => error.toString());
  }

  bool _isTerminalForCreation(JourneyStatus status) {
    const terminal = {
      JourneyStatus.completed,
      JourneyStatus.completedVerified,
      JourneyStatus.completedUnverified,
      JourneyStatus.cancelled,
    };
    return terminal.contains(status);
  }

  void _syncJourneyInCollections(JourneySummaryDto journey) {
    final listIndex = _journeys.indexWhere((j) => j.id == journey.id);
    if (listIndex == -1) {
      _journeys.insert(0, journey);
    } else {
      _journeys[listIndex] = journey;
    }

    final activeIndex = _activeJourneys.indexWhere((j) => j.id == journey.id);
    if (_isTerminalForCreation(journey.status)) {
      if (activeIndex != -1) {
        _activeJourneys.removeAt(activeIndex);
      }
      return;
    }

    if (activeIndex == -1) {
      _activeJourneys.insert(0, journey);
    } else {
      _activeJourneys[activeIndex] = journey;
    }
  }

  /// Clear current journey detail
  void clearCurrentJourney() {
    _currentJourney = null;
    _generatedTest = null;
    _testResult = null;
    _pendingJourneyForTestGeneration = null;
    notifyListeners();
  }

  void clearPendingJourneyForTestGeneration() {
    if (_pendingJourneyForTestGeneration == null) return;
    _pendingJourneyForTestGeneration = null;
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refresh() async {
    try {
      await Future.wait([loadJourneys(), loadActiveJourneys(force: true)]);
    } catch (_) {
      // Errors are already surfaced through provider state when not silent.
    }
  }

  /// Called by app-level logout listener to purge user data.
  void clearOnLogout() {
    resetWizard();
    clearCurrentJourney();
    _journeys = [];
    _activeJourneys = [];
    _hasLoadedActiveJourneys = false;
    clearAllLoading();
  }
}
