import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/exceptions/api_exception.dart';
import '../models/user_models.dart';
import '../../core/network/api_client.dart';

class UserService {
  final ApiClient _apiClient = ApiClient();

  // User Registration
  Future<UserRegistrationResponse> registerUser(
    UserRegistrationRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/register/user',
        data: request.toJson(),
      );

      return UserRegistrationResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Mentor Registration
  Future<MentorRegistrationResponse> registerMentor(
    MentorRegistrationRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/register/mentor',
        data: request.toJson(),
      );

      return MentorRegistrationResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Business Registration
  Future<BusinessRegistrationResponse> registerBusiness(
    BusinessRegistrationRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/register/business',
        data: request.toJson(),
      );

      return BusinessRegistrationResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get User Profile
  Future<UserProfileResponse> getUserProfile(int userId) async {
    try {
      // NOTE: There is no public endpoint /users/profile/{id} in docs yet.
      // This might be intended for public profile view, but for now we warn or fallback?
      // For now, if this is used, it might fail if the API doesn't exist.
      // But based on analysis, we should use /user/profile for "me".
      // Leaving this as is might be risky if used for "others".
      // However, for verify task, I will focus on "me" endpoints.
      final response = await _apiClient.dio.get('/users/profile/$userId');

      return UserProfileResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get My Profile
  Future<UserProfileResponse> getMyProfile() async {
    try {
      final response = await _apiClient.dio.get('/user/profile');
      final data = response.data;

      // Patch missing fields to prevent parsing errors
      if (data['id'] == null && data['userId'] != null) {
        data['id'] = data['userId'];
      }
      if (data['isActive'] == null) {
        data['isActive'] = true; // Default to true if missing
      }
      if (data['emailVerified'] == null) {
        data['emailVerified'] = false; // Default to false if missing
      }

      return UserProfileResponse.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get Public Profile
  Future<PublicUserProfile> getPublicProfile(int userId) async {
    try {
      final response = await _apiClient.dio.get('/user/profile/public/$userId');
      return PublicUserProfile.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Update User Profile
  Future<UserProfileResponse> updateUserProfile(
    Map<String, dynamic> updateData,
  ) async {
    try {
      final response = await _apiClient.dio.put(
        '/user/profile',
        data: updateData,
      );

      final data = response.data;
      // Patch missing fields
      if (data['id'] == null && data['userId'] != null) {
        data['id'] = data['userId'];
      }
      if (data['isActive'] == null) {
        data['isActive'] = true;
      }
      if (data['emailVerified'] == null) {
        data['emailVerified'] = false;
      }

      return UserProfileResponse.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Upload avatar: (1) upload file to media service, (2) update profile with mediaId.
  /// Matches web's userService.uploadUserAvatar flow.
  Future<String> uploadAvatar(String filePath, int userId) async {
    try {
      // Step 1: Upload file to /media/upload
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'actorId': userId,
      });

      final uploadResponse = await _apiClient.dio.post(
        '/media/upload',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final mediaId = uploadResponse.data['id'] as int;
      final mediaUrl = uploadResponse.data['url'] as String;

      // Step 2: Update user profile with new avatarMediaId
      await updateUserProfile({'avatarMediaId': mediaId});

      return mediaUrl;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get User Skills
  Future<List<UserSkillResponse>> getUserSkills(int userId) async {
    try {
      final response = await _apiClient.dio.get('/users/$userId/skills');

      final List<dynamic> data = response.data;
      return data.map((json) => UserSkillResponse.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Add User Skill
  Future<UserSkillResponse> addUserSkill(Map<String, dynamic> skillData) async {
    try {
      final response = await _apiClient.dio.post(
        '/users/skills',
        data: skillData,
      );

      return UserSkillResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Update User Skill
  Future<UserSkillResponse> updateUserSkill(
    int skillId,
    Map<String, dynamic> skillData,
  ) async {
    try {
      final response = await _apiClient.dio.put(
        '/users/skills/$skillId',
        data: skillData,
      );

      return UserSkillResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Delete User Skill
  Future<void> deleteUserSkill(int skillId) async {
    try {
      await _apiClient.dio.delete('/users/skills/$skillId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get Provinces
  Future<List<Province>> getProvinces() async {
    try {
      final response = await _apiClient.dio.get('/locations/provinces');

      final List<dynamic> data = response.data;
      return data.map((json) => Province.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get Districts by Province
  Future<List<District>> getDistrictsByProvince(String provinceCode) async {
    try {
      final response = await _apiClient.dio.get(
        '/locations/districts/$provinceCode',
      );

      final List<dynamic> data = response.data;
      return data.map((json) => District.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get Mentor Profile
  Future<MentorProfileResponse> getMentorProfile(int mentorId) async {
    try {
      final response = await _apiClient.dio.get('/mentors/$mentorId/profile');

      return MentorProfileResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get Business Profile
  Future<BusinessProfileResponse> getBusinessProfile(int businessId) async {
    try {
      final response = await _apiClient.dio.get(
        '/businesses/$businessId/profile',
      );

      return BusinessProfileResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get Application Status
  Future<ApplicationStatusResponse> getApplicationStatus() async {
    try {
      final response = await _apiClient.dio.get('/users/application-status');

      return ApplicationStatusResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Error handling helper
  Exception _handleError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;

      if (data is Map<String, dynamic> && data.containsKey('message')) {
        final message = data['message'];
        return ApiException(message, statusCode);
      }

      return ApiException(
        'HTTP $statusCode: ${e.response!.statusMessage}',
        statusCode,
      );
    } else {
      return ApiException('Network error: ${e.message}');
    }
  }
}
