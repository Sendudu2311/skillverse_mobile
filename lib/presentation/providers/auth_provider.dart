import 'package:flutter/foundation.dart';
import '../../core/mixins/provider_loading_mixin.dart';
import '../../data/models/auth_models.dart';
import '../../data/services/auth_service.dart';
import '../../core/network/api_client.dart';
import '../../core/exceptions/api_exception.dart';

/// Auth Provider
///
/// Uses [LoadingStateProviderMixin] to auto-manage:
/// - `isLoading` / `setLoading(bool)` — loading state
/// - `hasError` / `errorMessage` / `setError(String?)` — error state
/// - `executeAsync()` — try/catch/loading wrapper
/// - `resetState()` — clear loading + error
class AuthProvider extends ChangeNotifier with LoadingStateProviderMixin {
  final AuthService _authService = AuthService();
  final ApiClient _apiClient = ApiClient();

  UserDto? _user;

  // Getters
  UserDto? get user => _user;
  bool get isAuthenticated => _user != null;

  /// Khởi tạo provider và kiểm tra trạng thái đăng nhập
  Future<void> initialize() async {
    // Register force logout callback so the 401 interceptor can trigger logout
    _apiClient.onForceLogout = () => forceLogout();

    await executeAsync(() async {
      final isAuth = await _authService.isAuthenticated();
      if (isAuth) {
        _user = await _authService.getStoredUser();
        // IMPORTANT: Set token vào ApiClient sau khi load từ storage
        final token = await _authService.getAccessToken();
        if (token != null) {
          _apiClient.setAuthToken(token);
        }
      }
      notifyListeners();
    }, errorMessageBuilder: (e) => 'Lỗi khởi tạo: ${e.toString()}');
  }

  /// Đăng nhập
  Future<bool> login(String email, String password) async {
    final result = await executeAsync(() async {
      final request = LoginRequest(email: email, password: password);
      final response = await _authService.login(request);
      _user = response.user;
      _apiClient.setAuthToken(response.accessToken);
      notifyListeners();
      return true;
    }, errorMessageBuilder: (e) => _getErrorMessage(e));
    return result ?? false;
  }

  /// Đăng ký
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    final result = await executeAsync(() async {
      final request = RegisterRequest(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );
      final response = await _authService.register(request);
      _apiClient.setAuthToken(response.accessToken);
      notifyListeners();
      return true;
    }, errorMessageBuilder: (e) => _getErrorMessage(e));
    return result ?? false;
  }

  /// Đăng nhập bằng Google
  Future<bool> signInWithGoogle() async {
    final result = await executeAsync(() async {
      final response = await _authService.signInWithGoogle();
      _user = response.user;
      _apiClient.setAuthToken(response.accessToken);
      notifyListeners();
      return true;
    }, errorMessageBuilder: (e) => _getErrorMessage(e));
    return result ?? false;
  }

  /// Xác thực email
  Future<bool> verifyEmail(String email, String otp) async {
    final result = await executeAsync(() async {
      await _authService.verifyEmail(email, otp);
      return true;
    }, errorMessageBuilder: (e) => _getErrorMessage(e));
    return result ?? false;
  }

  /// Gửi lại OTP
  Future<bool> resendOtp(String email) async {
    final result = await executeAsync(() async {
      await _authService.resendOtp(email);
      return true;
    }, errorMessageBuilder: (e) => _getErrorMessage(e));
    return result ?? false;
  }

  /// Đăng xuất
  Future<void> logout() async {
    setLoading(true);
    try {
      await _authService.logout();
    } catch (e) {
      // Ignore logout errors - always clear local state
      debugPrint('Logout error: $e');
    } finally {
      // Always clear user and token regardless of API call result
      _user = null;
      _apiClient.clearAuthToken();
      resetState(); // Clears isLoading + errorMessage + notifyListeners()
    }
  }

  /// Force logout — called by ApiClient 401 interceptor when token refresh fails.
  /// Clears local state without calling the backend logout API (token is already invalid).
  /// Triggers notifyListeners() → GoRouter redirect → Login page.
  Future<void> forceLogout() async {
    debugPrint('🚪 Force logout triggered by 401 interceptor');
    _user = null;
    _apiClient.clearAuthToken();
    // Clear stored tokens silently
    try {
      await _authService.logout();
    } catch (_) {
      // Ignore — token is already invalid
    }
    notifyListeners(); // This triggers GoRouter redirect to /login
  }

  /// Làm mới token
  Future<bool> refreshToken() async {
    try {
      final newToken = await _authService.refreshAccessToken();
      if (newToken == null) return false;

      // Set new token to ApiClient
      _apiClient.setAuthToken(newToken);
      return true;
    } catch (e) {
      await logout(); // If refresh fails, logout user
      return false;
    }
  }

  // Helper: extract error from ApiException
  String _getErrorMessage(dynamic error) {
    if (error is ApiException) {
      return error.message;
    }
    return error.toString();
  }

  /// Xóa lỗi hiện tại
  void clearError() => super.clearError();
}

