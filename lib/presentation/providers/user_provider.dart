import 'package:flutter/foundation.dart';
import '../../core/exceptions/api_exception.dart';
import '../../data/models/user_models.dart';
import '../../data/services/user_service.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService = UserService();

  // State variables
  UserProfileResponse? _userProfile;
  List<UserSkillResponse> _userSkills = [];
  List<Province> _provinces = [];
  List<District> _districts = [];
  MentorProfileResponse? _mentorProfile;
  BusinessProfileResponse? _businessProfile;
  ApplicationStatusResponse? _applicationStatus;

  bool _isLoading = false;
  String? _error;

  // Getters
  UserProfileResponse? get userProfile => _userProfile;
  List<UserSkillResponse> get userSkills => _userSkills;
  List<Province> get provinces => _provinces;
  List<District> get districts => _districts;
  MentorProfileResponse? get mentorProfile => _mentorProfile;
  BusinessProfileResponse? get businessProfile => _businessProfile;
  ApplicationStatusResponse? get applicationStatus => _applicationStatus;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // User Registration
  Future<bool> registerUser(UserRegistrationRequest request) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _userService.registerUser(request);
      _setLoading(false);
      return response.success;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  // Mentor Registration
  Future<bool> registerMentor(MentorRegistrationRequest request) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _userService.registerMentor(request);
      _setLoading(false);
      return response.success;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  // Business Registration
  Future<bool> registerBusiness(BusinessRegistrationRequest request) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _userService.registerBusiness(request);
      _setLoading(false);
      return response.success;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  // Load User Profile
  Future<bool> loadUserProfile({int? userId}) async {
    _setLoading(true);
    _clearError();

    try {
      if (userId != null) {
        _userProfile = await _userService.getUserProfile(userId);
      } else {
        _userProfile = await _userService.getMyProfile();
      }
      _setLoading(false);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to load user profile');
      _setLoading(false);
      return false;
    }
  }

  // Update User Profile
  Future<bool> updateUserProfile(Map<String, dynamic> updateData) async {
    _setLoading(true);
    _clearError();

    try {
      _userProfile = await _userService.updateUserProfile(updateData);
      _setLoading(false);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to update user profile');
      _setLoading(false);
      return false;
    }
  }

  // Load User Skills
  Future<bool> loadUserSkills(int userId) async {
    _setLoading(true);
    _clearError();

    try {
      _userSkills = await _userService.getUserSkills(userId);
      _setLoading(false);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to load user skills');
      _setLoading(false);
      return false;
    }
  }

  // Add User Skill
  Future<bool> addUserSkill(Map<String, dynamic> skillData) async {
    _setLoading(true);
    _clearError();

    try {
      final newSkill = await _userService.addUserSkill(skillData);
      _userSkills.add(newSkill);
      _setLoading(false);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to add user skill');
      _setLoading(false);
      return false;
    }
  }

  // Update User Skill
  Future<bool> updateUserSkill(int skillId, Map<String, dynamic> skillData) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedSkill = await _userService.updateUserSkill(skillId, skillData);
      final index = _userSkills.indexWhere((skill) => skill.id == skillId);
      if (index != -1) {
        _userSkills[index] = updatedSkill;
      }
      _setLoading(false);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to update user skill');
      _setLoading(false);
      return false;
    }
  }

  // Delete User Skill
  Future<bool> deleteUserSkill(int skillId) async {
    _setLoading(true);
    _clearError();

    try {
      await _userService.deleteUserSkill(skillId);
      _userSkills.removeWhere((skill) => skill.id == skillId);
      _setLoading(false);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to delete user skill');
      _setLoading(false);
      return false;
    }
  }

  // Load Provinces
  Future<bool> loadProvinces() async {
    _setLoading(true);
    _clearError();

    try {
      _provinces = await _userService.getProvinces();
      _setLoading(false);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to load provinces');
      _setLoading(false);
      return false;
    }
  }

  // Load Districts by Province
  Future<bool> loadDistrictsByProvince(String provinceCode) async {
    _setLoading(true);
    _clearError();

    try {
      _districts = await _userService.getDistrictsByProvince(provinceCode);
      _setLoading(false);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to load districts');
      _setLoading(false);
      return false;
    }
  }

  // Load Mentor Profile
  Future<bool> loadMentorProfile(int mentorId) async {
    _setLoading(true);
    _clearError();

    try {
      _mentorProfile = await _userService.getMentorProfile(mentorId);
      _setLoading(false);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to load mentor profile');
      _setLoading(false);
      return false;
    }
  }

  // Load Business Profile
  Future<bool> loadBusinessProfile(int businessId) async {
    _setLoading(true);
    _clearError();

    try {
      _businessProfile = await _userService.getBusinessProfile(businessId);
      _setLoading(false);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to load business profile');
      _setLoading(false);
      return false;
    }
  }

  // Load Application Status
  Future<bool> loadApplicationStatus() async {
    _setLoading(true);
    _clearError();

    try {
      _applicationStatus = await _userService.getApplicationStatus();
      _setLoading(false);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to load application status');
      _setLoading(false);
      return false;
    }
  }

  // Clear all data
  void clearData() {
    _userProfile = null;
    _userSkills = [];
    _provinces = [];
    _districts = [];
    _mentorProfile = null;
    _businessProfile = null;
    _applicationStatus = null;
    _error = null;
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}