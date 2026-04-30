import 'package:flutter/foundation.dart';
import '../../data/models/student_skill_verification_models.dart';
import '../../data/services/student_skill_verification_service.dart';

class StudentSkillVerificationProvider extends ChangeNotifier {
  final StudentSkillVerificationService _service =
      StudentSkillVerificationService();

  // ─── State ────────────────────────────────────────────────────────────────

  bool _isLoading = false;
  bool _isBusy = false;
  String? _error;

  List<StudentSkillVerificationResponse> _verifications = [];
  List<String> _verifiedSkills = [];

  // ─── Getters ─────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  bool get isBusy => _isBusy;
  String? get error => _error;
  bool get hasError => _error != null;
  List<StudentSkillVerificationResponse> get verifications => _verifications;
  List<String> get verifiedSkills => _verifiedSkills;

  // ─── Load verifications ───────────────────────────────────────────────────

  Future<void> loadVerifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _verifications = await _service.getMyVerifications();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadVerifiedSkills() async {
    try {
      _verifiedSkills = await _service.getMyVerifiedSkills();
      notifyListeners();
    } catch (_) {
      // Non-critical — ignore silently
    }
  }

  // ─── Submit ───────────────────────────────────────────────────────────────

  Future<bool> submit(CreateStudentSkillVerificationRequest request) async {
    _isBusy = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _service.submitVerification(request);
      _verifications = [result, ..._verifications];
      notifyListeners();
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

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearOnLogout() {
    _verifications = [];
    _verifiedSkills = [];
    _error = null;
    _isLoading = false;
    _isBusy = false;
    notifyListeners();
  }
}
