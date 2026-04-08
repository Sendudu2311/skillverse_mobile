import 'package:flutter/foundation.dart';
import '../../core/mixins/provider_loading_mixin.dart';
import '../../data/models/auth_models.dart';
import '../../data/services/auth_service.dart';
import '../../core/network/api_client.dart';
import '../../core/exceptions/api_exception.dart';
import '../../core/utils/storage_helper.dart';
import '../../core/services/firebase_push_notification_service.dart';

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
        // Register FCM token after auto-login từ stored session
        _registerFcmToken();
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

      // Set onboarding prompt flag for subsequent dashboard load
      await StorageHelper.instance.writeBool(
        StorageKey.showOnboardingPrompt,
        true,
      );

      notifyListeners();
      // Register FCM token after successful login
      _registerFcmToken();
      return true;
    }, errorMessageBuilder: (e) => _getErrorMessage(e));
    return result ?? false;
  }

  /// Đăng ký
  Future<bool> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String fullName,
    String? phoneNumber,
  }) async {
    final result = await executeAsync(() async {
      final request = RegisterRequest(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );
      final response = await _authService.register(request);
      _apiClient.setAuthToken(response.accessToken);

      // Set onboarding prompt flag for subsequent dashboard load
      await StorageHelper.instance.writeBool(
        StorageKey.showOnboardingPrompt,
        true,
      );

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

      // Set onboarding prompt flag for subsequent dashboard load
      await StorageHelper.instance.writeBool(
        StorageKey.showOnboardingPrompt,
        true,
      );

      notifyListeners();
      // Register FCM token after Google sign-in
      _registerFcmToken();
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
      // Unregister FCM token BEFORE logout (needs auth token)
      await FirebasePushNotificationService.instance.unregisterTokenOnLogout();
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
  /// ONLY clears local state. Does NOT call backend logout API (token is already invalid).
  /// Triggers notifyListeners() → GoRouter redirect → Login page.
  bool _isForceLoggingOut = false;

  Future<void> forceLogout() async {
    // Prevent re-entrant calls (interceptor can fire multiple 401s)
    if (_isForceLoggingOut) return;
    _isForceLoggingOut = true;

    debugPrint('🚪 Force logout triggered by 401 interceptor');
    _user = null;
    _apiClient.clearAuthToken();
    // Clear stored refresh token locally (no API call!)
    await _authService.clearStoredTokens();
    notifyListeners(); // This triggers GoRouter redirect to /login

    _isForceLoggingOut = false;
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
  @override
  void clearError() => super.clearError();

  /// Register FCM token with backend (fire-and-forget, non-blocking).
  void _registerFcmToken() {
    FirebasePushNotificationService.instance
        .registerTokenAfterLogin()
        .catchError((e) {
          debugPrint('🔔 FCM token registration skipped: $e');
        });
  }
}
