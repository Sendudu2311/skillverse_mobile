import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../../data/models/contract_models.dart';
import '../../data/services/contract_service.dart';
import '../../core/utils/error_handler.dart';
import '../pages/contract/widgets/contract_pdf_generator.dart';

class ContractProvider extends ChangeNotifier {
  final ContractService _service = ContractService();

  // ==================== STATE ====================
  List<ContractResponse> _contracts = [];
  ContractResponse? _selectedContract;
  bool _isLoadingList = false;
  bool _isLoadingDetail = false;
  String? _errorMessage;
  bool _isSubmitting = false;

  bool _isDownloadingPDF = false;
  bool _isSharingPDF = false;
  String? lastSavedPdfPath;

  // ==================== GETTERS ====================
  List<ContractResponse> get contracts => _contracts;
  ContractResponse? get selectedContract => _selectedContract;
  bool get isLoadingList => _isLoadingList;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get isLoading => _isLoadingList || _isLoadingDetail;
  String? get errorMessage => _errorMessage;
  bool get isSubmitting => _isSubmitting;
  bool get isDownloadingPDF => _isDownloadingPDF;
  bool get isSharingPDF => _isSharingPDF;

  // ==================== ACTIONS ====================

  /// Load current user's contracts as CANDIDATE.
  Future<void> loadMyContracts() async {
    _isLoadingList = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _contracts = await _service.getMyContracts('CANDIDATE');
      // Sort newest first
      _contracts.sort((a, b) {
        final aDate = a.createdAt ?? '';
        final bDate = b.createdAt ?? '';
        return bDate.compareTo(aDate);
      });
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
    } finally {
      _isLoadingList = false;
      notifyListeners();
    }
  }

  /// Load a single contract detail.
  Future<void> loadContractDetail(int id) async {
    _isLoadingDetail = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedContract = await _service.getContractById(id);
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  /// Sign the selected contract with signature image URL.
  Future<bool> signContract(int id, String signatureImageUrl) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = SignContractRequest(
        action: 'SIGN',
        signatureImageUrl: signatureImageUrl,
      );
      _selectedContract = await _service.signContract(id, request);

      // Update local list instead of re-fetching (avoid shared isLoading conflict)
      final idx = _contracts.indexWhere((c) => c.id == id);
      if (idx >= 0 && _selectedContract != null) {
        _contracts[idx] = _selectedContract!;
      }
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Reject the selected contract with a reason.
  Future<bool> rejectContract(int id, {String? reason}) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedContract = await _service.rejectContract(id, reason: reason);

      // Update local list
      final idx = _contracts.indexWhere((c) => c.id == id);
      if (idx >= 0 && _selectedContract != null) {
        _contracts[idx] = _selectedContract!;
      }
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Clear selected contract (when navigating away).
  void clearSelection() {
    _selectedContract = null;
    _errorMessage = null;
    lastSavedPdfPath = null;
  }

  // ==================== PDF EXPORT ====================

  Future<void> downloadPDF() async {
    if (_selectedContract == null || _isDownloadingPDF) return;

    _isDownloadingPDF = true;
    notifyListeners();

    try {
      final pdfBytes = await ContractPdfGeneratorWidget.generateContractPdf(
        contract: _selectedContract!,
      );

      final filename =
          'contract_${_selectedContract!.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir = await getExternalStorageDirectory();
        }
      } else {
        dir = await getDownloadsDirectory();
      }
      dir ??= await getApplicationDocumentsDirectory();

      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(pdfBytes);
      lastSavedPdfPath = file.path;
    } catch (e) {
      debugPrint('Error saving PDF: $e');
      lastSavedPdfPath = null;
    } finally {
      _isDownloadingPDF = false;
      notifyListeners();
    }
  }

  Future<void> sharePDF() async {
    if (_selectedContract == null || _isSharingPDF) return;

    _isSharingPDF = true;
    notifyListeners();

    try {
      final pdfBytes = await ContractPdfGeneratorWidget.generateContractPdf(
        contract: _selectedContract!,
      );

      final filename =
          'contract_${_selectedContract!.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await Printing.sharePdf(bytes: pdfBytes, filename: filename);
    } catch (e) {
      debugPrint('Error sharing PDF: $e');
    } finally {
      _isSharingPDF = false;
      notifyListeners();
    }
  }

  /// Called by app-level logout listener to purge user data.
  void clearOnLogout() {
    _contracts = [];
    _selectedContract = null;
    _errorMessage = null;
    lastSavedPdfPath = null;
    notifyListeners();
  }
}
