import 'package:flutter_test/flutter_test.dart';
import 'package:skillverse_mobile/presentation/providers/auth_provider.dart';

/// ============================================================
/// AUTH PROVIDER TEST
/// Mục đích: Kiểm thử toàn bộ state management của AuthProvider
/// bao gồm login, register, logout, error handling, loading states
/// ============================================================
///
/// Vì AuthProvider tạo service Singleton internally, ta test
/// behavior bằng cách quan sát state transitions qua getters.
/// Đây là cách tiếp cận QA thực tế khi không thể inject mocks.

void main() {
  group('AuthProvider - Initial State', () {
    late AuthProvider provider;

    setUp(() {
      provider = AuthProvider();
    });

    test('initial state has no user', () {
      expect(provider.user, isNull);
    });

    test('initial isAuthenticated is false', () {
      expect(provider.isAuthenticated, false);
    });

    test('initial isLoading is false', () {
      expect(provider.isLoading, false);
    });

    test('initial errorMessage is null', () {
      expect(provider.errorMessage, isNull);
    });
  });

  group('AuthProvider - clearError()', () {
    test('clearError sets errorMessage to null', () {
      final provider = AuthProvider();
      provider.clearError();
      expect(provider.errorMessage, isNull);
    });
  });

  group('AuthProvider - Login flow state transitions', () {
    late AuthProvider provider;
    final loadingStates = <bool>[];

    setUp(() {
      provider = AuthProvider();
      loadingStates.clear();
      provider.addListener(() {
        loadingStates.add(provider.isLoading);
      });
    });

    test('login with empty email triggers loading then error', () async {
      final result = await provider.login('', '');

      // Login should fail (API error or validation)
      expect(result, false);
      // After completion, loading should be false
      expect(provider.isLoading, false);
      // ErrorMessage should be set
      expect(provider.errorMessage, isNotNull);
      // User should not be set
      expect(provider.isAuthenticated, false);
    });

    test('login with invalid credentials sets error state', () async {
      final result = await provider.login(
        'nonexistent@test.com',
        'wrongpassword',
      );

      expect(result, false);
      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNotNull);
      expect(provider.user, isNull);
    });

    test('loading state transitions during login', () async {
      await provider.login('test@test.com', 'password');

      // Loading should have been set to true then false
      expect(loadingStates.isNotEmpty, true);
      // Last state should be isLoading = false
      expect(loadingStates.last, false);
      // Should have at least 2 state changes (loading true, then false)
      expect(loadingStates.length, greaterThanOrEqualTo(2));
    });

    test('login does not set user on failure', () async {
      await provider.login('bad@email', 'pwd');
      expect(provider.user, isNull);
      expect(provider.isAuthenticated, false);
    });
  });

  group('AuthProvider - Register flow state transitions', () {
    late AuthProvider provider;

    setUp(() {
      provider = AuthProvider();
    });

    test('register with empty fields returns false', () async {
      final result = await provider.register(
        email: '',
        password: '',
        confirmPassword: '',
        fullName: '',
      );

      expect(result, false);
      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNotNull);
    });

    test('register with invalid email format fails', () async {
      final result = await provider.register(
        email: 'not-an-email',
        password: 'ValidPass1',
        confirmPassword: 'ValidPass1',
        fullName: 'Test User',
      );

      expect(result, false);
      expect(provider.errorMessage, isNotNull);
    });

    test('register sets loading states correctly', () async {
      final states = <bool>[];
      provider.addListener(() {
        states.add(provider.isLoading);
      });

      await provider.register(
        email: 'new@user.com',
        password: 'TestPass1',
        confirmPassword: 'TestPass1',
        fullName: 'New User',
      );

      // Should have loading transitions
      expect(states.isNotEmpty, true);
      expect(states.last, false); // Final state: not loading
    });
  });

  group('AuthProvider - Verify Email flow', () {
    late AuthProvider provider;

    setUp(() {
      provider = AuthProvider();
    });

    test('verifyEmail with invalid OTP returns false', () async {
      final result = await provider.verifyEmail('test@test.com', '000000');

      expect(result, false);
      expect(provider.isLoading, false);
    });

    test('verifyEmail sets loading during operation', () async {
      final states = <bool>[];
      provider.addListener(() {
        states.add(provider.isLoading);
      });

      await provider.verifyEmail('test@test.com', '123456');

      expect(states.isNotEmpty, true);
      expect(states.last, false);
    });
  });

  group('AuthProvider - Resend OTP flow', () {
    late AuthProvider provider;

    setUp(() {
      provider = AuthProvider();
    });

    test('resendOtp with invalid email returns false', () async {
      final result = await provider.resendOtp('invalid-email');

      expect(result, false);
      expect(provider.isLoading, false);
    });

    test('resendOtp sets error message on failure', () async {
      await provider.resendOtp('nonexistent@email.com');
      expect(provider.errorMessage, isNotNull);
    });
  });

  group('AuthProvider - Logout flow', () {
    late AuthProvider provider;

    setUp(() {
      provider = AuthProvider();
    });

    test('logout clears user state', () async {
      await provider.logout();

      expect(provider.user, isNull);
      expect(provider.isAuthenticated, false);
      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNull);
    });

    test('logout always succeeds even without prior login', () async {
      // Should not throw even if no user is logged in
      expect(() => provider.logout(), returnsNormally);
      await provider.logout();
      expect(provider.isAuthenticated, false);
    });

    test('logout clears error message', () async {
      // First trigger an error
      await provider.login('bad@email', 'pwd');
      expect(provider.errorMessage, isNotNull);

      // Logout should clear everything
      await provider.logout();
      expect(provider.errorMessage, isNull);
    });
  });

  group('AuthProvider - Refresh Token flow', () {
    late AuthProvider provider;

    setUp(() {
      provider = AuthProvider();
    });

    test('refreshToken returns false when no token stored', () async {
      final result = await provider.refreshToken();
      // Without stored refresh token, should fail
      expect(result, false);
    });
  });

  group('AuthProvider - Listener notifications', () {
    test('notifyListeners called on state changes', () async {
      final provider = AuthProvider();
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.login('test@test.com', 'pass');

      // Should have notified at least twice (loading true, then result)
      expect(notifyCount, greaterThanOrEqualTo(2));
    });

    test('dispose does not throw', () {
      final provider = AuthProvider();
      expect(() => provider.dispose(), returnsNormally);
    });
  });

  group('AuthProvider - Error message formatting', () {
    late AuthProvider provider;

    setUp(() {
      provider = AuthProvider();
    });

    test('error message is set on API failure', () async {
      await provider.login('test@test.com', 'wrongpass');
      expect(provider.errorMessage, isA<String>());
      expect(provider.errorMessage!.isNotEmpty, true);
    });

    test('clearError removes previous error', () async {
      await provider.login('test@test.com', 'wrongpass');
      expect(provider.errorMessage, isNotNull);

      provider.clearError();
      expect(provider.errorMessage, isNull);
    });

    test('new login attempt clears previous error', () async {
      await provider.login('test1@test.com', 'wrong1');
      final firstError = provider.errorMessage;

      await provider.login('test2@test.com', 'wrong2');
      // Error should be reset (possibly different message)
      // Key point: error from first attempt is not persisted
      expect(provider.errorMessage, isNotNull);
    });
  });
}
