import 'package:flutter/material.dart';

/// Shared section header widget for forms and detail pages.
///
/// **Gradient variant** — used in portfolio forms (edit profile, projects, certificates):
/// ```dart
/// SectionHeader.gradient(
///   title: 'Kinh nghiệm',
///   icon: Icons.work,
///   gradientColors: [AppTheme.themeBlueStart, AppTheme.themeBlueEnd],
/// )
/// ```
///
/// **Simple variant** — used in settings/profile pages:
/// ```dart
/// SectionHeader(title: 'Thông tin', icon: Icons.person)
/// ```
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color>? gradientColors;
  final bool _useGradient;

  /// Simple themed section header (icon + title using theme colors).
  const SectionHeader({super.key, required this.title, required this.icon})
    : gradientColors = null,
      _useGradient = false;

  /// Gradient section header with glowing icon box and gradient title text.
  const SectionHeader.gradient({
    super.key,
    required this.title,
    required this.icon,
    required this.gradientColors,
  }) : _useGradient = true;

  @override
  Widget build(BuildContext context) {
    return _useGradient ? _buildGradient(context) : _buildSimple(context);
  }

  Widget _buildGradient(BuildContext context) {
    final colors = gradientColors!;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: colors[0].withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ShaderMask(
            shaderCallback: (bounds) =>
                LinearGradient(colors: colors).createShader(bounds),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimple(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
