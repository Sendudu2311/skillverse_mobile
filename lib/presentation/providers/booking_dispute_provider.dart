import 'package:flutter/foundation.dart';
import '../../data/models/booking_dispute_models.dart';
import '../../data/services/booking_dispute_service.dart';
import '../../core/utils/error_handler.dart';

class BookingDisputeProvider extends ChangeNotifier {
  final BookingDisputeService _service = BookingDisputeService();

  BookingDisputeDto? _dispute;
  List<BookingDisputeEvidenceDto> _evidences = [];
  bool _isLoading = false;
  bool _isBusy = false;
  String? _errorMessage;

  BookingDisputeDto? get dispute => _dispute;
  List<BookingDisputeEvidenceDto> get evidences => List.unmodifiable(_evidences);
  bool get isLoading => _isLoading;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;

  bool get isResolved =>
      _dispute?.status == DisputeStatus.resolved ||
      _dispute?.status == DisputeStatus.dismissed;

  bool get canSubmitEvidence =>
      _dispute != null &&
      (_dispute!.status == DisputeStatus.open ||
          _dispute!.status == DisputeStatus.awaitingResponse ||
          _dispute!.status == DisputeStatus.underInvestigation);

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadDispute(int disputeId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.getDispute(disputeId),
        _service.getEvidence(disputeId),
      ]);
      _dispute = results[0] as BookingDisputeDto;
      _evidences = results[1] as List<BookingDisputeEvidenceDto>;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDisputeByBooking(int bookingId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final d = await _service.getDisputeByBooking(bookingId);
      if (d != null) {
        _dispute = d;
        _evidences = await _service.getEvidence(d.id);
      } else {
        _dispute = null;
        _evidences = [];
      }
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Open Dispute ──────────────────────────────────────────────────────────

  /// Returns the created dispute on success, throws on failure.
  Future<BookingDisputeDto> openDispute({
    required int bookingId,
    required String reason,
  }) async {
    _isBusy = true;
    notifyListeners();
    try {
      final dispute = await _service.openDispute(
        bookingId: bookingId,
        reason: reason,
      );
      _dispute = dispute;
      _evidences = [];
      notifyListeners();
      return dispute;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  // ── Submit Evidence ───────────────────────────────────────────────────────

  Future<void> submitEvidence({
    required EvidenceType type,
    String? content,
    String? fileUrl,
    String? fileName,
    String? description,
  }) async {
    if (_dispute == null) return;
    _isBusy = true;
    notifyListeners();
    try {
      final evidence = await _service.submitEvidence(
        disputeId: _dispute!.id,
        type: type,
        content: content,
        fileUrl: fileUrl,
        fileName: fileName,
        description: description,
      );
      _evidences = [..._evidences, evidence];
      notifyListeners();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  // ── Respond to Evidence ───────────────────────────────────────────────────

  Future<void> respondToEvidence({
    required int evidenceId,
    required String content,
  }) async {
    if (_dispute == null) return;
    _isBusy = true;
    notifyListeners();
    try {
      final response = await _service.respondToEvidence(
        disputeId: _dispute!.id,
        evidenceId: evidenceId,
        content: content,
      );
      // Append response to the matching evidence item
      _evidences = _evidences.map((e) {
        if (e.id == evidenceId) {
          return BookingDisputeEvidenceDto(
            id: e.id,
            disputeId: e.disputeId,
            submittedBy: e.submittedBy,
            evidenceType: e.evidenceType,
            content: e.content,
            fileUrl: e.fileUrl,
            fileName: e.fileName,
            description: e.description,
            isOfficial: e.isOfficial,
            reviewStatus: e.reviewStatus,
            reviewNotes: e.reviewNotes,
            reviewedBy: e.reviewedBy,
            reviewedAt: e.reviewedAt,
            createdAt: e.createdAt,
            responses: [...e.responses, response],
          );
        }
        return e;
      }).toList();
      notifyListeners();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  // ── Upload Evidence File ──────────────────────────────────────────────────

  /// Upload a file to media storage and return its public URL.
  Future<String> uploadEvidenceFile(
    String filePath,
    String fileName, {
    required int actorId,
  }) async {
    _isBusy = true;
    notifyListeners();
    try {
      return await _service.uploadEvidenceFile(
        filePath,
        fileName,
        actorId: actorId,
      );
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void clear() {
    _dispute = null;
    _evidences = [];
    _errorMessage = null;
    notifyListeners();
  }
}
