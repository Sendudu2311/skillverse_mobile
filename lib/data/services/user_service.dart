import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/exceptions/api_exception.dart';
import '../models/user_models.dart';
import 'api_client.dart';

class UserService {
  final ApiClient _apiClient = ApiClient();

  // User Registration
  Future<UserRegistrationResponse> registerUser(UserRegistrationRequest request) async {
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
  Future<MentorRegistrationResponse> registerMentor(MentorRegistrationRequest request) async {
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
  Future<BusinessRegistrationResponse> registerBusiness(BusinessRegistrationRequest request) async {
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
      final response = await _apiClient.dio.get('/users/$userId/profile');

      return UserProfileResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get My Profile
  Future<UserProfileResponse> getMyProfile() async {
    try {
      final response = await _apiClient.dio.get('/users/profile');

      return UserProfileResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Update User Profile
  Future<UserProfileResponse> updateUserProfile(Map<String, dynamic> updateData) async {
    try {
      final response = await _apiClient.dio.put(
        '/users/profile',
        data: updateData,
      );

      return UserProfileResponse.fromJson(response.data);
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
  Future<UserSkillResponse> updateUserSkill(int skillId, Map<String, dynamic> skillData) async {
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
      final response = await _apiClient.dio.get('/locations/districts/$provinceCode');

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
      final response = await _apiClient.dio.get('/businesses/$businessId/profile');

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