import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

/// Shared AppBar for sub-pages (Pattern 2: Title + Back).
///
/// Replaces direct `AppBar(...)` usage with consistent styling:
/// transparent background, no elevation, optional gradient title & icon.
class SkillVerseAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData? icon;
  final bool useGradientTitle;
  final List<Color>? gradientColors;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final bool centerTitle;

  const SkillVerseAppBar({
    super.key,
    required this.title,
    this.icon,
    this.useGradientTitle = false,
    this.gradientColors,
    this.actions,
    this.onBack,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: onBack != null
          ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack)
          : null,
      title: _buildTitle(context),
      centerTitle: centerTitle,
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: actions,
    );
  }

  Widget _buildTitle(BuildContext context) {
    if (useGradientTitle) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppTheme.primaryBlueDark, size: 28),
            const SizedBox(width: 8),
          ],
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors:
                  gradientColors ??
                  const [AppTheme.primaryBlueDark, AppTheme.accentCyan],
            ).createShader(bounds),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      );
    }

    // Simple title
    return Text(title);
  }
}
