import 'package:flutter/foundation.dart';
import '../../data/models/node_mentoring_models.dart';
import '../../data/services/node_mentoring_service.dart';
import '../../data/services/mentor_roadmap_workspace_service.dart';
import '../../core/utils/error_handler.dart';

/// Provider for the Learner Roadmap Workspace.
/// Manages node selection, assignment, evidence, meetings, and output assessment.
class WorkspaceProvider extends ChangeNotifier {
  final NodeMentoringService _nodeMentoringService = NodeMentoringService();
  final MentorRoadmapWorkspaceService _workspaceService =
      MentorRoadmapWorkspaceService();

  // ─── State ──────────────────────────────────────────────────────────────

  int? _journeyId;
  int? _bookingId;
  String? _selectedNodeId; // null = Final Assessment mode
  bool _isLoadingNode = false;
  bool _isLoadingMeetings = false;
  bool _isSubmitting = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _error;

  NodeAssignmentResponse? _assignment;
  NodeEvidenceRecordResponse? _evidence;
  JourneyOutputAssessmentResponse? _outputAssessment;
  List<RoadmapFollowUpMeetingDTO> _meetings = [];

  // Completion Gate + Verification + Skills
  JourneyCompletionGateResponse? _completionGate;
  List<VerificationEvidenceReportResponse> _verificationHistory = [];
  List<UserVerifiedSkillDTO> _verifiedSkills = [];
  bool _isLoadingGate = false;
  bool _isLoadingHistory = false;
  bool _isLoadingSkills = false;
  bool _hasLoadedVerificationHistory = false;
  bool _hasLoadedVerifiedSkills = false;

  // ─── Getters ────────────────────────────────────────────────────────────

  int? get journeyId => _journeyId;
  int? get bookingId => _bookingId;
  String? get selectedNodeId => _selectedNodeId;
  bool get isLoadingNode => _isLoadingNode;
  bool get isLoadingMeetings => _isLoadingMeetings;
  bool get isSubmitting => _isSubmitting;
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String? get error => _error;

  NodeAssignmentResponse? get assignment => _assignment;
  NodeEvidenceRecordResponse? get evidence => _evidence;
  JourneyOutputAssessmentResponse? get outputAssessment => _outputAssessment;
  List<RoadmapFollowUpMeetingDTO> get meetings => _meetings;

  JourneyCompletionGateResponse? get completionGate => _completionGate;
  List<VerificationEvidenceReportResponse> get verificationHistory =>
      _verificationHistory;
  List<UserVerifiedSkillDTO> get verifiedSkills => _verifiedSkills;
  bool get isLoadingGate => _isLoadingGate;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isLoadingSkills => _isLoadingSkills;
  bool get hasLoadedVerificationHistory => _hasLoadedVerificationHistory;
  bool get hasLoadedVerifiedSkills => _hasLoadedVerifiedSkills;

  bool get isFinalAssessmentMode => _selectedNodeId == null;

  // ─── Init ───────────────────────────────────────────────────────────────

  /// Initialize workspace context.
  void init({required int journeyId, int? bookingId}) {
    final journeyChanged = _journeyId != journeyId;
    _journeyId = journeyId;
    _bookingId = bookingId;
    _error = null;
    if (journeyChanged) {
      _verificationHistory = [];
      _verifiedSkills = [];
      _hasLoadedVerificationHistory = false;
      _hasLoadedVerifiedSkills = false;
    }
  }

  // ─── Node Selection ─────────────────────────────────────────────────────

  /// Select a node to view/edit. Pass null for Final Assessment.
  Future<void> selectNode(String? nodeId) async {
    _selectedNodeId = nodeId;
    _assignment = null;
    _evidence = null;
    _outputAssessment = null;
    _error = null;
    notifyListeners();

    if (_journeyId == null) return;

    _isLoadingNode = true;
    notifyListeners();

    try {
      if (nodeId != null) {
        // Load assignment and evidence in parallel
        final results = await Future.wait([
          _nodeMentoringService.getAssignment(_journeyId!, nodeId),
          _nodeMentoringService.getEvidence(_journeyId!, nodeId),
        ]);
        _assignment = results[0] as NodeAssignmentResponse?;
        _evidence = results[1] as NodeEvidenceRecordResponse?;
      } else {
        // Final Assessment mode
        _outputAssessment = await _nodeMentoringService
            .getLatestOutputAssessment(_journeyId!);
      }
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      debugPrint('WorkspaceProvider.selectNode error: $e');
    } finally {
      _isLoadingNode = false;
      notifyListeners();
    }
  }

  // ─── Upload Attachment ──────────────────────────────────────────────────

  /// Upload an attachment file to backend, return public URL.
  /// Updates [uploadProgress] and [isUploading] for the UI to react.
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
      final url = await _nodeMentoringService.uploadAttachment(
        filePath: filePath,
        fileName: fileName,
        actorId: actorId,
        onProgress: (p) {
          _uploadProgress = p;
          notifyListeners();
        },
      );
      return url;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      debugPrint('WorkspaceProvider.uploadAttachment error: $e');
      return null;
    } finally {
      _isUploading = false;
      _uploadProgress = 0;
      notifyListeners();
    }
  }

  // ─── Submit Evidence ────────────────────────────────────────────────────

  /// Submit evidence for the currently selected node, or output assessment.
  Future<bool> submitEvidence({
    required String submissionText,
    String? evidenceUrl,
    String? attachmentUrl,
  }) async {
    if (_journeyId == null) return false;

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      if (_selectedNodeId != null) {
        _evidence = await _nodeMentoringService.submitEvidence(
          _journeyId!,
          _selectedNodeId!,
          SubmitNodeEvidenceRequest(
            submissionText: submissionText,
            evidenceUrl: evidenceUrl,
            attachmentUrl: attachmentUrl,
          ),
        );
      } else {
        _outputAssessment = await _nodeMentoringService.submitOutputAssessment(
          _journeyId!,
          SubmitJourneyOutputAssessmentRequest(
            submissionText: submissionText,
            evidenceUrl: evidenceUrl,
            attachmentUrl: attachmentUrl,
          ),
        );
      }
      return true;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      debugPrint('WorkspaceProvider.submitEvidence error: $e');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // ─── Meetings ───────────────────────────────────────────────────────────

  /// Load follow-up meetings for the booking.
  Future<void> loadMeetings() async {
    if (_bookingId == null) {
      _meetings = [];
      notifyListeners();
      return;
    }

    _isLoadingMeetings = true;
    notifyListeners();

    try {
      _meetings = await _workspaceService.getFollowUps(_bookingId!);
    } catch (e) {
      debugPrint('Load meetings error: $e');
      _meetings = [];
    } finally {
      _isLoadingMeetings = false;
      notifyListeners();
    }
  }

  /// Create a new follow-up meeting.
  Future<bool> createMeeting(CreateFollowUpMeetingRequest request) async {
    if (_bookingId == null) return false;

    try {
      await _workspaceService.createFollowUp(_bookingId!, request);
      await loadMeetings();
      return true;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// Accept a follow-up meeting.
  Future<bool> acceptMeeting(int meetingId) async {
    if (_bookingId == null) return false;

    try {
      await _workspaceService.acceptFollowUp(_bookingId!, meetingId);
      await loadMeetings();
      return true;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// Reject a follow-up meeting with optional reason.
  Future<bool> rejectMeeting(int meetingId, {String? reason}) async {
    if (_bookingId == null) return false;

    try {
      await _workspaceService.rejectFollowUp(
        _bookingId!,
        meetingId,
        reason: reason,
      );
      await loadMeetings();
      return true;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// Delete a follow-up meeting.
  Future<bool> deleteMeeting(int meetingId) async {
    if (_bookingId == null) return false;

    try {
      await _workspaceService.deleteFollowUp(_bookingId!, meetingId);
      await loadMeetings();
      return true;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // ─── Completion Gate ────────────────────────────────────────────────

  /// Load completion gate status for the journey.
  Future<void> loadCompletionGate() async {
    if (_journeyId == null) return;

    _isLoadingGate = true;
    notifyListeners();

    try {
      _completionGate = await _nodeMentoringService.getCompletionGate(
        _journeyId!,
      );
    } catch (e) {
      debugPrint('Load completion gate error: $e');
      _completionGate = null;
    } finally {
      _isLoadingGate = false;
      notifyListeners();
    }
  }

  // ─── Verification History ──────────────────────────────────────────

  /// Load verification history (all attempts) — lazy loaded.
  Future<void> loadVerificationHistory() async {
    if (_journeyId == null || _isLoadingHistory) return;

    _isLoadingHistory = true;
    notifyListeners();

    try {
      _verificationHistory = await _nodeMentoringService.getVerificationHistory(
        _journeyId!,
      );
    } catch (e) {
      debugPrint('Load verification history error: $e');
      _verificationHistory = [];
    } finally {
      _hasLoadedVerificationHistory = true;
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  // ─── Verified Skills ───────────────────────────────────────────────

  /// Load verified skills for the learner's portfolio — lazy loaded.
  Future<void> loadVerifiedSkills() async {
    if (_isLoadingSkills) return;

    _isLoadingSkills = true;
    notifyListeners();

    try {
      _verifiedSkills = await _nodeMentoringService.getVerifiedSkills();
    } catch (e) {
      debugPrint('Load verified skills error: $e');
      _verifiedSkills = [];
    } finally {
      _hasLoadedVerifiedSkills = true;
      _isLoadingSkills = false;
      notifyListeners();
    }
  }

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
