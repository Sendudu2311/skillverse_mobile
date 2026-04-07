import 'package:flutter/material.dart';
import '../../data/models/roadmap_models.dart';
import '../../data/services/roadmap_service.dart';
import '../../core/mixins/provider_loading_mixin.dart';

/// Manages state for AI roadmap generation flow:
/// pre-validation → clarification → generation.
class RoadmapGenerateProvider with ChangeNotifier, LoadingStateProviderMixin {
  final RoadmapService _roadmapService = RoadmapService();

  bool _isGenerating = false;
  String? _generationError;
  List<ValidationResult> _validationResults = [];
  List<ClarificationQuestion> _clarificationQuestions = [];

  // ============================================================================
  // GETTERS
  // ============================================================================

  bool get isGenerating => _isGenerating;
  String? get generationError => _generationError;
  List<ValidationResult> get validationResults => _validationResults;
  List<ClarificationQuestion> get clarificationQuestions =>
      _clarificationQuestions;

  // ============================================================================
  // GENERATE
  // ============================================================================

  Future<RoadmapResponse?> generateRoadmap(
    GenerateRoadmapRequest request,
  ) async {
    _isGenerating = true;
    _generationError = null;
    notifyListeners();

    try {
      final roadmap = await _roadmapService.generateRoadmap(request);
      _isGenerating = false;
      notifyListeners();
      return roadmap;
    } catch (e) {
      debugPrint('🚨 RoadmapGenerateProvider Generation Error: $e');
      _generationError = e.toString();
      _isGenerating = false;
      notifyListeners();
      return null;
    }
  }

  // ============================================================================
  // PRE-VALIDATE
  // ============================================================================

  Future<List<ValidationResult>> preValidate(
    GenerateRoadmapRequest request,
  ) async {
    final result = await executeAsync(
      () async {
        _validationResults = await _roadmapService.preValidate(request);
        notifyListeners();
        return _validationResults;
      },
      errorMessageBuilder: (error) => 'Lỗi xác thực: ${error.toString()}',
    );
    return result ?? [];
  }

  // ============================================================================
  // CLARIFICATION
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
          'Lỗi lấy câu hỏi làm rõ: ${error.toString()}',
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
}
