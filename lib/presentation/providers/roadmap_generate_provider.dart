import 'package:flutter/material.dart';
import '../../data/models/roadmap_models.dart';
import '../../data/services/roadmap_service.dart';
import '../../core/mixins/provider_loading_mixin.dart';
import '../../core/utils/error_handler.dart';

/// Tracks which phase of the AI generation pipeline is active.
enum GenerationPhase { idle, validating, generating }

/// Manages state for AI roadmap generation flow:
/// pre-validation → generation (single unified pipeline).
class RoadmapGenerateProvider with ChangeNotifier, LoadingStateProviderMixin {
  final RoadmapService _roadmapService = RoadmapService();

  GenerationPhase _phase = GenerationPhase.idle;
  String? _generationError;
  List<ValidationResult> _validationResults = [];
  List<ClarificationQuestion> _clarificationQuestions = [];
  RoadmapResponse? _lastResult;

  // ============================================================================
  // GETTERS
  // ============================================================================

  GenerationPhase get phase => _phase;

  /// True while validating OR generating — use this to show the loading screen.
  bool get isBusy => _phase != GenerationPhase.idle;

  String? get generationError => _generationError;
  List<ValidationResult> get validationResults => _validationResults;
  List<ClarificationQuestion> get clarificationQuestions =>
      _clarificationQuestions;

  /// Result of the last completed generation. Consumed once by the page via [clearLastResult].
  RoadmapResponse? get lastResult => _lastResult;

  // ============================================================================
  // FULL GENERATION PIPELINE
  // ============================================================================

  /// Unified fire-and-forget pipeline: validate → generate.
  ///
  /// Phase transitions:
  ///   idle → validating → (error: idle) → generating → idle
  ///
  /// The loading screen should be shown whenever [isBusy] is true, covering
  /// both the fast validation step and the slower AI generation step.
  /// Result is stored in [lastResult]; page navigates via listener.
  /// Deduplication: silently ignored if already running.
  Future<void> startFullGeneration(GenerateRoadmapRequest request) async {
    if (isBusy) return;

    _phase = GenerationPhase.validating;
    _generationError = null;
    _validationResults = [];
    _lastResult = null;
    notifyListeners();

    try {
      // ── Phase 1: pre-validate ─────────────────────────────────────────────
      _validationResults = await _roadmapService.preValidate(request);
      notifyListeners();

      if (_validationResults.any((r) => r.isError)) {
        // Blocking errors → drop back to idle so form + error panel render
        _phase = GenerationPhase.idle;
        notifyListeners();
        return;
      }

      // ── Phase 2: generate ─────────────────────────────────────────────────
      _phase = GenerationPhase.generating;
      _validationResults =
          []; // clear non-blocking warnings before loading screen
      notifyListeners();

      final roadmap = await _roadmapService.generateRoadmap(request);
      _lastResult = roadmap;
      _phase = GenerationPhase.idle;
      notifyListeners();
    } catch (e) {
      debugPrint('🚨 RoadmapGenerateProvider Error: $e');
      _generationError = ErrorHandler.getErrorMessage(e);
      _phase = GenerationPhase.idle;
      notifyListeners();
    }
  }

  /// Consume the result after navigating to the detail page.
  void clearLastResult() {
    _lastResult = null;
  }

  // ============================================================================
  // CLARIFICATION (optional pre-generation step, not part of main pipeline)
  // ============================================================================

  Future<List<ClarificationQuestion>> getClarificationQuestions(
    GenerateRoadmapRequest request,
  ) async {
    final result = await executeAsync(
      () async {
        _clarificationQuestions = await _roadmapService.clarify(request);
        notifyListeners();
        return _clarificationQuestions;
      },
      errorMessageBuilder: (error) =>
          'Lỗi lấy câu hỏi làm rõ: ${ErrorHandler.getErrorMessage(error)}',
    );
    return result ?? [];
  }

  // ============================================================================
  // CLEAR
  // ============================================================================

  void clearValidationResults() {
    _validationResults = [];
    notifyListeners();
  }

  void clearGenerationError() {
    _generationError = null;
    notifyListeners();
  }

  /// Called by app-level logout listener to purge user data.
  void clearOnLogout() {
    clearLastResult();
    clearValidationResults();
    clearGenerationError();
    resetState();
  }
}
