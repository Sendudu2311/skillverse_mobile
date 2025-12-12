import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'galaxy_background.dart';

/// Themed scaffold that wraps content with galaxy background in dark mode
/// Provides consistent theming across all pages
class ThemedScaffold extends StatelessWidget {
  final Widget child;
  final bool showGalaxyBackground;

  const ThemedScaffold({
    super.key,
    required this.child,
    this.showGalaxyBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    // In dark mode with galaxy enabled, wrap with GalaxyBackground
    if (isDarkMode && showGalaxyBackground) {
      return GalaxyBackground(
        child: child,
      );
    }

    // Otherwise just return child
    return child;
  }
}
