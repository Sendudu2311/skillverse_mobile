import 'package:flutter/foundation.dart';
import '../../data/models/auth_models.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/api_client.dart';
import '../../core/exceptions/api_exception.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiClient _apiClient = ApiClient();

  UserDto? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserDto? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  /// Khởi tạo provider và kiểm tra trạng thái đăng nhập
  Future<void> initialize() async {
    _setLoading(true);
    try {
      final isAuth = await _authService.isAuthenticated();
      if (isAuth) {
        _user = await _authService.getStoredUser();
        // IMPORTANT: Set token vào ApiClient sau khi load từ storage
        final token = await _authService.getAccessToken();
        if (token != null) {
          _apiClient.setAuthToken(token);
        }
      }
      _clearError();
    } catch (e) {
      _setError('Lỗi khởi tạo: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Đăng nhập
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final request = LoginRequest(email: email, password: password);
      final response = await _authService.login(request);
      _user = response.user;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  /// Đăng ký
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final request = RegisterRequest(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );
      await _authService.register(request);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  /// Đăng nhập bằng Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.signInWithGoogle();
      _user = response.user;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  /// Xác thực email
  Future<bool> verifyEmail(String email, String otp) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.verifyEmail(email, otp);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  /// Gửi lại OTP
  Future<bool> resendOtp(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.resendOtp(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  /// Đăng xuất
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
    } catch (e) {
      // Ignore logout errors - always clear local state
      debugPrint('Logout error: $e');
    } finally {
      // Always clear user and token regardless of API call result
      _user = null;
      _apiClient.clearAuthToken();
      _clearError();
      _setLoading(false);
    }
  }

  /// Làm mới token
  Future<bool> refreshToken() async {
    try {
      final newToken = await _authService.refreshAccessToken();
      if (newToken == null) return false;

      // Token đã được cập nhật trong service
      return true;
    } catch (e) {
      await logout(); // If refresh fails, logout user
      return false;
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    if (error is ApiException) {
      return error.message;
    }
    return error.toString();
  }

  /// Xóa lỗi hiện tại
  void clearError() {
    _clearError();
  }
}