import 'package:flutter/material.dart';

class AppTheme {
  // Galaxy Theme Colors (matching web galaxy background)
  static const Color galaxyDarkest = Color(0xFF050510); // Deep space
  static const Color galaxyDark = Color(0xFF0A0A14); // Dark nebula
  static const Color galaxyMid = Color(0xFF141423); // Mid nebula

  // Light Theme Colors (matching web :root)
  static const Color lightBackgroundPrimary = Color(0xFFF8FAFC); // #f8fafc
  static const Color lightBackgroundSecondary = Color(0xFFE2E8F0); // #e2e8f0
  static const Color lightTextPrimary = Color(0xFF1E293B); // #1e293b
  static const Color lightTextSecondary = Color(0xFF64748B); // #64748b
  static const Color lightBorderColor = Color(
    0x3394A3B8,
  ); // rgba(148, 163, 184, 0.2)
  static const Color lightCardBackground = Color(
    0xDDFFFFFF,
  ); // rgba(255, 255, 255, 0.87) - more opaque for galaxy

  // Dark/Galaxy Theme Colors (matching web [data-theme="dark"] + galaxy)
  static const Color darkBackgroundPrimary =
      galaxyDarkest; // Deep space background
  static const Color darkBackgroundSecondary = galaxyDark; // #0f172a
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // #f8fafc
  static const Color darkTextSecondary = Color(0xFF94A3B8); // #94a3b8
  static const Color darkBorderColor = Color(
    0x2694A3B8,
  ); // rgba(148, 163, 184, 0.15) - slightly more visible
  static const Color darkCardBackground = Color(
    0xDD1E293B,
  ); // rgba(30, 41, 59, 0.87) - more opaque for better readability

  // Primary Colors (from index.css)
  static const Color primaryBlue = Color(0xFF4F46E5); // #4f46e5 (light)
  static const Color primaryBlueDark = Color(0xFF6366F1); // #6366f1 (dark)
  static const Color secondaryPurple = Color(0xFF8B5CF6); // #8b5cf6

  // Theme Colors from App.css
  static const Color themeBlueStart = Color(0xFF3B82F6); // #3b82f6
  static const Color themeBlueEnd = Color(0xFF2563EB); // #2563eb
  static const Color themeGreenStart = Color(0xFF10B981); // #10b981
  static const Color themeGreenEnd = Color(0xFF059669); // #059669
  static const Color themePurpleStart = Color(0xFF8B5CF6); // #8b5cf6
  static const Color themePurpleEnd = Color(0xFF6D28D9); // #6d28d9
  static const Color themeOrangeStart = Color(0xFFF59E0B); // #f59e0b
  static const Color themeOrangeEnd = Color(0xFFD97706); // #d97706

  // Additional Utility Colors
  static const Color errorColor = Color(0xFFDC2626);
  static const Color successColor = themeGreenStart;
  static const Color warningColor = themeOrangeStart;
  static const Color infoColor = themeBlueStart;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: secondaryPurple,
        surface: lightCardBackground,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightTextPrimary,
        onError: Colors.white,
        outline: lightBorderColor,
      ),

      // Scaffold
      scaffoldBackgroundColor: lightBackgroundPrimary,

      // AppBar - Glass effect matching web
      appBarTheme: AppBarTheme(
        backgroundColor: lightCardBackground,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        centerTitle: false,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: '-apple-system',
        ),
        iconTheme: const IconThemeData(color: lightTextPrimary),
      ),

      // Text theme - matching web font stack
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: lightTextPrimary,
          fontFamily: 'monospace',
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: lightTextPrimary,
          fontFamily: 'monospace',
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
          fontFamily: 'monospace',
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
          fontFamily: 'monospace',
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: lightTextPrimary,
          fontFamily: 'monospace',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: lightTextPrimary,
          fontFamily: 'monospace',
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: lightTextSecondary,
          fontFamily: 'monospace',
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: lightTextSecondary,
          fontFamily: 'monospace',
          height: 1.5,
        ),
      ),

      // Elevated Button - HUD style with border
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: primaryBlue.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'monospace',
          ),
        ),
      ),

      // Outlined Button - matching "Quay lại" button style
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          backgroundColor: Colors.transparent,
          side: BorderSide(color: primaryBlue.withValues(alpha: 0.3), width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'monospace',
          ),
        ),
      ),

      // Input Decoration - glass effect
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightCardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: const TextStyle(
          color: lightTextSecondary,
          fontFamily: '-apple-system',
        ),
      ),

      // Card - glass effect matching web
      cardTheme: CardThemeData(
        color: lightCardBackground,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: lightBorderColor, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightCardBackground,
        selectedItemColor: primaryBlue,
        unselectedItemColor: lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: '-apple-system',
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          fontFamily: '-apple-system',
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: lightBorderColor,
        thickness: 1,
        space: 1,
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: lightCardBackground,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: lightBorderColor),
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: lightBackgroundSecondary,
        selectedColor: primaryBlue,
        labelStyle: const TextStyle(
          color: lightTextPrimary,
          fontFamily: 'monospace',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: primaryBlueDark,
        secondary: secondaryPurple,
        surface: darkCardBackground,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkTextPrimary,
        onError: Colors.white,
        outline: darkBorderColor,
      ),

      // Scaffold
      scaffoldBackgroundColor: darkBackgroundPrimary,

      // AppBar - Glass effect matching web dark theme
      appBarTheme: AppBarTheme(
        backgroundColor: darkCardBackground,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
        iconTheme: const IconThemeData(color: darkTextPrimary),
      ),

      // Text theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
          fontFamily: 'monospace',
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
          fontFamily: 'monospace',
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
          fontFamily: 'monospace',
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
          fontFamily: 'monospace',
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
          fontFamily: 'monospace',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: darkTextPrimary,
          fontFamily: 'monospace',
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: darkTextSecondary,
          fontFamily: 'monospace',
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: darkTextSecondary,
          fontFamily: 'monospace',
          height: 1.5,
        ),
      ),

      // Elevated Button - HUD style with border
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlueDark,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: primaryBlueDark.withValues(alpha: 0.7),
              width: 1,
            ),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlueDark,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'monospace',
          ),
        ),
      ),

      // Outlined Button - matching "Quay lại" button style
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlueDark,
          backgroundColor: Colors.transparent,
          side: BorderSide(
            color: primaryBlueDark.withValues(alpha: 0.5),
            width: 1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'monospace',
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryBlueDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: const TextStyle(
          color: darkTextSecondary,
          fontFamily: '-apple-system',
        ),
      ),

      // Card - glass effect
      cardTheme: CardThemeData(
        color: darkCardBackground,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: darkBorderColor, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkCardBackground,
        selectedItemColor: primaryBlueDark,
        unselectedItemColor: darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: '-apple-system',
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          fontFamily: '-apple-system',
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: darkBorderColor,
        thickness: 1,
        space: 1,
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryBlueDark,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: darkCardBackground,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: darkBorderColor),
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: darkBackgroundSecondary,
        selectedColor: primaryBlueDark,
        labelStyle: const TextStyle(
          color: darkTextPrimary,
          fontFamily: '-apple-system',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Gradient Helpers (matching web theme gradients)
  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [themeBlueStart, themeBlueEnd],
  );

  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [themeGreenStart, themeGreenEnd],
  );

  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [themePurpleStart, themePurpleEnd],
  );

  static const LinearGradient orangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [themeOrangeStart, themeOrangeEnd],
  );
}
