import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  static const String _themeModeKey = 'theme_mode';

  ThemeMode get themeMode => _themeMode;

  /// Resolves isDarkMode correctly for ThemeMode.system using platform brightness.
  /// Call with context when available; falls back to false when context is null.
  bool isDarkModeResolved(BuildContext? context) {
    if (_themeMode == ThemeMode.system && context != null) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  /// Simple getter — true only when explicitly set to dark.
  /// Use isDarkModeResolved(context) in widgets for accurate system-mode support.
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeMode = prefs.getString(_themeModeKey);

      if (savedThemeMode != null) {
        _themeMode =
            savedThemeMode == 'dark' ? ThemeMode.dark : ThemeMode.light;
      }
      // Always notify so widgets re-render with correct initial theme
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme mode: $e');
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _themeModeKey,
        _themeMode == ThemeMode.dark ? 'dark' : 'light',
      );
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _themeModeKey,
        mode == ThemeMode.dark ? 'dark' : 'light',
      );
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }
}
