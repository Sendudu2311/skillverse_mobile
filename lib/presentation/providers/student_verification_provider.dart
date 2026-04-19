import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/student_verification_models.dart';
import '../../data/services/student_verification_service.dart';
import '../../core/mixins/provider_loading_mixin.dart';

/// Provider for student verification flow.
///
/// Uses [LoadingStateProviderMixin] to auto-manage:
/// - `isLoading` — whether an async operation is in progress
/// - `hasError` / `errorMessage` — error tracking
class StudentVerificationProvider extends ChangeNotifier
    with LoadingStateProviderMixin {
  final StudentVerificationService _service = StudentVerificationService();
  final ImagePicker _picker = ImagePicker();

  StudentVerificationDetailResponse? _currentRequest;
  StudentVerificationEligibilityResponse? _eligibility;
  File? _selectedImage;
  String? _schoolEmail;
  int? _pendingRequestId;
  String? _otpExpiresAt;

  // ── Getters ──────────────────────────────────────────────────────────────

  StudentVerificationDetailResponse? get currentRequest => _currentRequest;
  StudentVerificationEligibilityResponse? get eligibility => _eligibility;
  File? get selectedImage => _selectedImage;
  String? get schoolEmail => _schoolEmail;
  int? get pendingRequestId => _pendingRequestId;
  String? get otpExpiresAt => _otpExpiresAt;
  bool get hasSelectedImage => _selectedImage != null;

  /// Whether the user already has an approved student verification.
  bool get isVerified => _eligibility?.approved == true;

  /// Whether the user can buy student premium.
  bool get canBuyStudentPremium =>
      _eligibility?.canBuyStudentPremium == true;

  // ── Image Picker ─────────────────────────────────────────────────────────

  /// Pick student card image from camera or gallery.
  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        _selectedImage = File(image.path);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Pick image error: $e');
    }
  }

  void clearImage() {
    _selectedImage = null;
    notifyListeners();
  }

  // ── Verification Flow ────────────────────────────────────────────────────

  /// Step 1: Start verification — submit school email + student card image.
  Future<bool> startVerification(String schoolEmail) async {
    if (_selectedImage == null) return false;
    _schoolEmail = schoolEmail;

    final result = await executeAsync(() async {
      final resp = await _service.startVerification(
        schoolEmail: schoolEmail,
        imagePath: _selectedImage!.path,
      );
      _pendingRequestId = resp.requestId;
      _otpExpiresAt = resp.otpExpiresAt;
      notifyListeners();
    });
    return result != null;
  }

  /// Step 2: Resend OTP if it expired.
  Future<void> resendOtp() async {
    if (_pendingRequestId == null) return;
    await executeAsync(() async {
      final resp = await _service.resendOtp(_pendingRequestId!);
      _otpExpiresAt = resp.otpExpiresAt;
      notifyListeners();
    });
  }

  /// Step 3: Verify OTP — move from EMAIL_OTP_PENDING → PENDING_REVIEW.
  Future<bool> verifyOtp(String otp) async {
    if (_pendingRequestId == null) return false;
    final result = await executeAsync(() async {
      _currentRequest = await _service.verifyOtp(
        requestId: _pendingRequestId!,
        otp: otp,
      );
      _pendingRequestId = null;
      notifyListeners();
    });
    return result != null;
  }

  // ── Data Loading ─────────────────────────────────────────────────────────

  /// Load the current user's latest verification request.
  Future<void> loadCurrentRequest() async {
    await executeAsync(() async {
      try {
        _currentRequest = await _service.getLatestRequest();
      } catch (e) {
        // 404 = no request yet — that's fine
        _currentRequest = null;
      }
      notifyListeners();
    });
  }

  /// Load eligibility for student premium.
  Future<void> loadEligibility() async {
    await executeAsync(() async {
      _eligibility = await _service.getEligibility();
      notifyListeners();
    });
  }

  /// Load both request and eligibility on app start.
  Future<void> initialize() async {
    await Future.wait([
      loadCurrentRequest(),
      loadEligibility(),
    ]);
  }

  // ── Reset ────────────────────────────────────────────────────────────────

  void reset() {
    _currentRequest = null;
    _eligibility = null;
    _selectedImage = null;
    _schoolEmail = null;
    _pendingRequestId = null;
    _otpExpiresAt = null;
    resetState();
  }
}
