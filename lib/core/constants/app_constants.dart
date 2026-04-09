class AppConstants {
  // App Info
  static const String appName = 'SkillVerse';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String accessTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String deviceSessionIdKey = 'device_session_id';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';

  // Default Values
  static const String defaultLanguage = 'vi';
  static const int defaultPageSize = 20;
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Routes
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String homeRoute = '/home';
  static const String dashboardRoute = '/dashboard';
  static const String coursesRoute = '/courses';
  static const String chatRoute = '/chat';
  static const String profileRoute = '/profile';

  // Error Messages
  static const String networkError = 'Lỗi kết nối mạng';
  static const String unknownError = 'Đã có lỗi xảy ra';
  static const String authError = 'Lỗi xác thực';
  static const String timeoutError = 'Kết nối quá thời gian';
}
