import 'package:flutter/foundation.dart';
import '../../data/models/user_models.dart';
import '../../data/services/user_service.dart';
import '../../core/utils/error_handler.dart';
import '../../core/mixins/provider_loading_mixin.dart';

class UserProvider with ChangeNotifier, LoadingStateProviderMixin {
  final UserService _userService = UserService();

  // State variables
  UserProfileResponse? _userProfile;
  List<UserSkillResponse> _userSkills = [];
  List<Province> _provinces = [];
  List<District> _districts = [];
  MentorProfileResponse? _mentorProfile;
  BusinessProfileResponse? _businessProfile;
  ApplicationStatusResponse? _applicationStatus;

  // Getters
  UserProfileResponse? get userProfile => _userProfile;
  List<UserSkillResponse> get userSkills => _userSkills;
  List<Province> get provinces => _provinces;
  List<District> get districts => _districts;
  MentorProfileResponse? get mentorProfile => _mentorProfile;
  BusinessProfileResponse? get businessProfile => _businessProfile;
  ApplicationStatusResponse? get applicationStatus => _applicationStatus;

  // ==================== User Registration ====================

  Future<bool> registerUser(UserRegistrationRequest request) async {
    final result = await executeAsync<bool>(() async {
      final response = await _userService.registerUser(request);
      return response.success;
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
    return result ?? false;
  }

  Future<bool> registerMentor(MentorRegistrationRequest request) async {
    final result = await executeAsync<bool>(() async {
      final response = await _userService.registerMentor(request);
      return response.success;
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
    return result ?? false;
  }

  Future<bool> registerBusiness(BusinessRegistrationRequest request) async {
    final result = await executeAsync<bool>(() async {
      final response = await _userService.registerBusiness(request);
      return response.success;
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
    return result ?? false;
  }

  // ==================== User Profile ====================

  Future<bool> loadUserProfile({int? userId}) async {
    final result = await executeAsync<bool>(() async {
      if (userId != null) {
        _userProfile = await _userService.getUserProfile(userId);
      } else {
        _userProfile = await _userService.getMyProfile();
      }
      notifyListeners();
      return true;
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
    return result ?? false;
  }

  Future<bool> updateUserProfile(Map<String, dynamic> updateData) async {
    final result = await executeAsync<bool>(() async {
      _userProfile = await _userService.updateUserProfile(updateData);
      notifyListeners();
      return true;
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
    return result ?? false;
  }

  // ==================== User Skills ====================

  Future<bool> loadUserSkills(int userId) async {
    final result = await executeAsync<bool>(() async {
      _userSkills = await _userService.getUserSkills(userId);
      notifyListeners();
      return true;
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
    return result ?? false;
  }

  Future<bool> addUserSkill(Map<String, dynamic> skillData) async {
    final result = await executeAsync<bool>(() async {
      final newSkill = await _userService.addUserSkill(skillData);
      _userSkills.add(newSkill);
      notifyListeners();
      return true;
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
    return result ?? false;
  }

  Future<bool> updateUserSkill(
    int skillId,
    Map<String, dynamic> skillData,
  ) async {
    final result = await executeAsync<bool>(() async {
      final updatedSkill = await _userService.updateUserSkill(
        skillId,
        skillData,
      );
      final index = _userSkills.indexWhere((skill) => skill.id == skillId);
      if (index != -1) {
        _userSkills[index] = updatedSkill;
      }
      notifyListeners();
      return true;
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
    return result ?? false;
  }

  Future<bool> deleteUserSkill(int skillId) async {
    final result = await executeAsync<bool>(() async {
      await _userService.deleteUserSkill(skillId);
      _userSkills.removeWhere((skill) => skill.id == skillId);
      notifyListeners();
      return true;
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
    return result ?? false;
  }

  // ==================== Location Data ====================

  Future<bool> loadProvinces() async {
    final result = await executeAsync<bool>(() async {
      _provinces = await _userService.getProvinces();
      notifyListeners();
      return true;
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
    return result ?? false;
  }

  Future<bool> loadDistrictsByProvince(String provinceCode) async {
    final result = await executeAsync<bool>(() async {
      _districts = await _userService.getDistrictsByProvince(provinceCode);
      notifyListeners();
      return true;
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
    return result ?? false;
  }

  // ==================== Profiles ====================

  Future<bool> loadMentorProfile(int mentorId) async {
    final result = await executeAsync<bool>(() async {
      _mentorProfile = await _userService.getMentorProfile(mentorId);
      notifyListeners();
      return true;
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
    return result ?? false;
  }

  Future<bool> loadBusinessProfile(int businessId) async {
    final result = await executeAsync<bool>(() async {
      _businessProfile = await _userService.getBusinessProfile(businessId);
      notifyListeners();
      return true;
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
    return result ?? false;
  }

  Future<bool> loadApplicationStatus() async {
    final result = await executeAsync<bool>(() async {
      _applicationStatus = await _userService.getApplicationStatus();
      notifyListeners();
      return true;
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
    return result ?? false;
  }

  // ==================== Helper Methods ====================

  void clearData() {
    _userProfile = null;
    _userSkills = [];
    _provinces = [];
    _districts = [];
    _mentorProfile = null;
    _businessProfile = null;
    _applicationStatus = null;
    resetState();
  }

  /// Called by app-level logout listener to purge user data.
  void clearOnLogout() => clearData();
}
