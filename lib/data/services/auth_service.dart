import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../../core/constants/app_constants.dart';
import '../../core/exceptions/api_exception.dart';
import 'api_client.dart';
import '../models/auth_models.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Đăng nhập người dùng
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: request.toJson(),
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      // Debug: In ra cấu trúc response để debug
      print('Login response data: ${response.data}');
      
      final authResponse = AuthResponse.fromJson(response.data!);
      
      // Lưu tokens và user data
      await _saveTokens(authResponse.accessToken, authResponse.refreshToken);
      await _saveUserData(authResponse.user);
      
      // Set auth token cho các request tiếp theo
      _apiClient.setAuthToken(authResponse.accessToken);
      
      return authResponse;
    } catch (e) {
      print('Login error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Đăng nhập thất bại: ${e.toString()}');
    }
  }

  /// Đăng ký người dùng mới
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: request.toJson(),
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return AuthResponse.fromJson(response.data!);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Đăng ký thất bại: ${e.toString()}');
    }
  }

  /// Xác thực email với OTP
  Future<void> verifyEmail(String email, String otp) async {
    try {
      await _apiClient.dio.post(
        '/auth/verify-email',
        data: {'email': email, 'otp': otp},
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Xác thực email thất bại: ${e.toString()}');
    }
  }

  /// Gửi lại OTP
  Future<void> resendOtp(String email) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/auth/resend-otp',
        data: {'email': email},
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gửi lại OTP thất bại: ${e.toString()}');
    }
  }

  /// Quên mật khẩu
  Future<void> forgotPassword(String email) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/auth/forgot-password',
        data: {'email': email},
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gửi email quên mật khẩu thất bại: ${e.toString()}');
    }
  }

  /// Đăng xuất
  Future<void> logout() async {
    try {
      // Call API logout nếu có token
      final token = await getAccessToken();
      if (token != null) {
        await _apiClient.dio.post('/auth/logout');
      }
    } catch (e) {
      // Ignore logout errors
    } finally {
      // Always clear local data
      await _clearLocalData();
    }
  }

  /// Refresh token
  Future<String?> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return null;

      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.data == null) return null;

      final newAccessToken = response.data!['accessToken'] as String?;
      final newRefreshToken = response.data!['refreshToken'] as String?;

      if (newAccessToken != null) {
        await _saveTokens(newAccessToken, newRefreshToken);
        _apiClient.setAuthToken(newAccessToken);
        return newAccessToken;
      }

      return null;
    } catch (e) {
      await _clearLocalData();
      return null;
    }
  }

  /// Kiểm tra trạng thái đăng nhập
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null;
  }

  /// Lấy access token
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: AppConstants.accessTokenKey);
  }

  /// Lấy refresh token
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: AppConstants.refreshTokenKey);
  }

  /// Lấy thông tin user đã lưu
  Future<UserDto?> getStoredUser() async {
    try {
      final userJson = await _secureStorage.read(key: AppConstants.userDataKey);
      if (userJson != null) {
        final userData = json.decode(userJson) as Map<String, dynamic>;
        return UserDto.fromJson(userData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Lưu tokens
  Future<void> _saveTokens(String accessToken, String? refreshToken) async {
    await _secureStorage.write(key: AppConstants.accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _secureStorage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
    }
  }

  /// Lưu thông tin user
  Future<void> _saveUserData(UserDto user) async {
    final userJson = json.encode(user.toJson());
    await _secureStorage.write(key: AppConstants.userDataKey, value: userJson);
  }

  /// Xóa toàn bộ dữ liệu local
  Future<void> _clearLocalData() async {
    await _secureStorage.delete(key: AppConstants.accessTokenKey);
    await _secureStorage.delete(key: AppConstants.refreshTokenKey);
    await _secureStorage.delete(key: AppConstants.userDataKey);
    _apiClient.clearAuthToken();
  }
}