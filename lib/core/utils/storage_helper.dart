import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Storage keys enum for type safety
///
/// Best practice: Use enums instead of string constants
/// - Compile-time safety
/// - No typos
/// - Easy refactoring
enum StorageKey {
  // Auth keys (Secure Storage)
  accessToken,
  refreshToken,
  userData,

  // Preferences keys (SharedPreferences)
  themeMode,
  language,
  notificationsEnabled,
  autoPlayVideos,

  // Cache keys (SharedPreferences)
  lastSyncTime,
  cachedCourses,
  cachedUserProfile,
  showOnboardingPrompt,
}

/// Extension to get string value from enum
extension StorageKeyExtension on StorageKey {
  String get key {
    switch (this) {
      // Auth
      case StorageKey.accessToken:
        return 'auth_token';
      case StorageKey.refreshToken:
        return 'refresh_token';
      case StorageKey.userData:
        return 'user_data';

      // Preferences
      case StorageKey.themeMode:
        return 'theme_mode';
      case StorageKey.language:
        return 'language';
      case StorageKey.notificationsEnabled:
        return 'notifications_enabled';
      case StorageKey.autoPlayVideos:
        return 'auto_play_videos';

      // Cache
      case StorageKey.lastSyncTime:
        return 'last_sync_time';
      case StorageKey.cachedCourses:
        return 'cached_courses';
      case StorageKey.cachedUserProfile:
        return 'cached_user_profile';
      case StorageKey.showOnboardingPrompt:
        return 'show_onboarding_prompt';
    }
  }
}

/// StorageHelper - Production-ready storage abstraction
///
/// Architecture:
/// - Singleton pattern for app-wide access
/// - FlutterSecureStorage for sensitive data (tokens, user data)
/// - SharedPreferences for non-sensitive data (preferences, cache)
/// - Initialize once at app startup
/// - Synchronous reads after initialization
///
/// Best practices:
/// - Type-safe keys using enums
/// - Graceful error handling
/// - Null safety
/// - JSON serialization helpers
class StorageHelper {
  // Singleton instance
  static StorageHelper? _instance;
  
  static StorageHelper get instance {
    if (_instance == null) {
      throw StateError(
        'StorageHelper not initialized. Call StorageHelper.initialize() first.',
      );
    }
    return _instance!;
  }

  // Storage instances
  late final SharedPreferences _prefs;
  late final FlutterSecureStorage _secureStorage;

  // Private constructor
  StorageHelper._({
    required SharedPreferences prefs,
    required FlutterSecureStorage secureStorage,
  })  : _prefs = prefs,
        _secureStorage = secureStorage;

  /// Initialize storage - Call this in main() before runApp()
  ///
  /// Example:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await StorageHelper.initialize();
  ///   runApp(MyApp());
  /// }
  /// ```
  static Future<void> initialize() async {
    if (_instance != null) return; // Already initialized

    final prefs = await SharedPreferences.getInstance();
    const secureStorage = FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
    );

    _instance = StorageHelper._(
      prefs: prefs,
      secureStorage: secureStorage,
    );
  }

  // === SECURE STORAGE (for sensitive data) ===

  /// Write to secure storage
  Future<void> writeSecure(StorageKey key, String value) async {
    try {
      await _secureStorage.write(key: key.key, value: value);
    } catch (e) {
      // Log error but don't throw - graceful degradation
      debugPrint('Error writing to secure storage: $e');
    }
  }

  /// Read from secure storage
  Future<String?> readSecure(StorageKey key) async {
    try {
      return await _secureStorage.read(key: key.key);
    } catch (e) {
      debugPrint('Error reading from secure storage: $e');
      return null;
    }
  }

  /// Delete from secure storage
  Future<void> deleteSecure(StorageKey key) async {
    try {
      await _secureStorage.delete(key: key.key);
    } catch (e) {
      debugPrint('Error deleting from secure storage: $e');
    }
  }

  /// Clear all secure storage
  Future<void> clearSecureStorage() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      debugPrint('Error clearing secure storage: $e');
    }
  }

  // === SHARED PREFERENCES (for non-sensitive data) ===

  /// Write string to SharedPreferences
  Future<bool> writeString(StorageKey key, String value) async {
    try {
      return await _prefs.setString(key.key, value);
    } catch (e) {
      debugPrint('Error writing string: $e');
      return false;
    }
  }

  /// Read string from SharedPreferences (synchronous after init)
  String? readString(StorageKey key) {
    try {
      return _prefs.getString(key.key);
    } catch (e) {
      debugPrint('Error reading string: $e');
      return null;
    }
  }

  /// Write int to SharedPreferences
  Future<bool> writeInt(StorageKey key, int value) async {
    try {
      return await _prefs.setInt(key.key, value);
    } catch (e) {
      debugPrint('Error writing int: $e');
      return false;
    }
  }

  /// Read int from SharedPreferences
  int? readInt(StorageKey key) {
    try {
      return _prefs.getInt(key.key);
    } catch (e) {
      debugPrint('Error reading int: $e');
      return null;
    }
  }

  /// Write bool to SharedPreferences
  Future<bool> writeBool(StorageKey key, bool value) async {
    try {
      return await _prefs.setBool(key.key, value);
    } catch (e) {
      debugPrint('Error writing bool: $e');
      return false;
    }
  }

  /// Read bool from SharedPreferences
  bool? readBool(StorageKey key) {
    try {
      return _prefs.getBool(key.key);
    } catch (e) {
      debugPrint('Error reading bool: $e');
      return null;
    }
  }

  /// Write double to SharedPreferences
  Future<bool> writeDouble(StorageKey key, double value) async {
    try {
      return await _prefs.setDouble(key.key, value);
    } catch (e) {
      debugPrint('Error writing double: $e');
      return false;
    }
  }

  /// Read double from SharedPreferences
  double? readDouble(StorageKey key) {
    try {
      return _prefs.getDouble(key.key);
    } catch (e) {
      debugPrint('Error reading double: $e');
      return null;
    }
  }

  /// Write list of strings to SharedPreferences
  Future<bool> writeStringList(StorageKey key, List<String> value) async {
    try {
      return await _prefs.setStringList(key.key, value);
    } catch (e) {
      debugPrint('Error writing string list: $e');
      return false;
    }
  }

  /// Read list of strings from SharedPreferences
  List<String>? readStringList(StorageKey key) {
    try {
      return _prefs.getStringList(key.key);
    } catch (e) {
      debugPrint('Error reading string list: $e');
      return null;
    }
  }

  /// Delete key from SharedPreferences
  Future<bool> delete(StorageKey key) async {
    try {
      return await _prefs.remove(key.key);
    } catch (e) {
      debugPrint('Error deleting key: $e');
      return false;
    }
  }

  /// Clear all SharedPreferences
  Future<bool> clearPreferences() async {
    try {
      return await _prefs.clear();
    } catch (e) {
      debugPrint('Error clearing preferences: $e');
      return false;
    }
  }

  /// Check if key exists in SharedPreferences
  bool containsKey(StorageKey key) {
    return _prefs.containsKey(key.key);
  }

  // === JSON HELPERS ===

  /// Write JSON object to SharedPreferences
  Future<bool> writeJson(StorageKey key, Map<String, dynamic> json) async {
    try {
      final jsonString = jsonEncode(json);
      return await writeString(key, jsonString);
    } catch (e) {
      debugPrint('Error writing JSON: $e');
      return false;
    }
  }

  /// Read JSON object from SharedPreferences
  Map<String, dynamic>? readJson(StorageKey key) {
    try {
      final jsonString = readString(key);
      if (jsonString == null) return null;
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error reading JSON: $e');
      return null;
    }
  }

  /// Write JSON object to secure storage
  Future<void> writeSecureJson(StorageKey key, Map<String, dynamic> json) async {
    try {
      final jsonString = jsonEncode(json);
      await writeSecure(key, jsonString);
    } catch (e) {
      debugPrint('Error writing secure JSON: $e');
    }
  }

  /// Read JSON object from secure storage
  Future<Map<String, dynamic>?> readSecureJson(StorageKey key) async {
    try {
      final jsonString = await readSecure(key);
      if (jsonString == null) return null;
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error reading secure JSON: $e');
      return null;
    }
  }

  // === CONVENIENCE METHODS ===

  /// Clear all storage (both secure and preferences)
  Future<void> clearAll() async {
    await Future.wait([
      clearSecureStorage(),
      clearPreferences(),
    ]);
  }

  /// Get all keys from SharedPreferences
  Set<String> getAllKeys() {
    return _prefs.getKeys();
  }

  /// Reload SharedPreferences from disk
  Future<void> reload() async {
    await _prefs.reload();
  }
}

/// Extension methods for easier storage access
extension StorageExtensions on StorageHelper {
  /// Quick access to theme mode
  String get themeMode => readString(StorageKey.themeMode) ?? 'system';
  set themeMode(String value) => writeString(StorageKey.themeMode, value);

  /// Quick access to language
  String get language => readString(StorageKey.language) ?? 'vi';
  set language(String value) => writeString(StorageKey.language, value);

  /// Quick access to notifications enabled
  bool get notificationsEnabled => readBool(StorageKey.notificationsEnabled) ?? true;
  set notificationsEnabled(bool value) => writeBool(StorageKey.notificationsEnabled, value);

  /// Quick access to auto play videos
  bool get autoPlayVideos => readBool(StorageKey.autoPlayVideos) ?? true;
  set autoPlayVideos(bool value) => writeBool(StorageKey.autoPlayVideos, value);
}

/// Auth-specific storage extension
extension AuthStorage on StorageHelper {
  /// Get access token from secure storage
  Future<String?> get accessToken => readSecure(StorageKey.accessToken);

  /// Save access token to secure storage
  Future<void> saveAccessToken(String token) => writeSecure(StorageKey.accessToken, token);

  /// Get refresh token from secure storage
  Future<String?> get refreshToken => readSecure(StorageKey.refreshToken);

  /// Save refresh token to secure storage
  Future<void> saveRefreshToken(String token) => writeSecure(StorageKey.refreshToken, token);

  /// Get user data from secure storage
  Future<Map<String, dynamic>?> get userData => readSecureJson(StorageKey.userData);

  /// Save user data to secure storage
  Future<void> saveUserData(Map<String, dynamic> data) => writeSecureJson(StorageKey.userData, data);

  /// Clear all auth data
  Future<void> clearAuthData() async {
    await Future.wait([
      deleteSecure(StorageKey.accessToken),
      deleteSecure(StorageKey.refreshToken),
      deleteSecure(StorageKey.userData),
    ]);
  }
}
