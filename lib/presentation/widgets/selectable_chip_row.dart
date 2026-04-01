import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

/// A horizontal-scrolling row of animated selectable chips.
///
/// Each chip shows its label with a gradient fill when selected,
/// or a subtle glass-style background when deselected.
/// Optionally renders an icon to the left of each label via [icons].
///
/// Usage (labels only):
/// ```dart
/// SelectableChipRow(
///   labels: ['Tất cả', 'Cơ bản', 'Trung cấp', 'Nâng cao'],
///   selectedIndex: _selectedIndex,
///   onSelected: (i) => setState(() => _selectedIndex = i),
/// )
/// ```
///
/// Usage (with icons):
/// ```dart
/// SelectableChipRow(
///   labels: ['Tất cả', 'Thảo luận', 'Tin tức'],
///   icons: [Icons.dashboard_outlined, Icons.forum_outlined, Icons.newspaper_outlined],
///   selectedIndex: _selectedIndex,
///   onSelected: (i) => setState(() => _selectedIndex = i),
/// )
/// ```
///
/// If [gradients] is omitted every chip uses the default blue gradient
/// when selected.
class SelectableChipRow extends StatelessWidget {
  const SelectableChipRow({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.icons,
    this.gradients,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.height = 42.0,
    this.chipSpacing = 8.0,
  })  : assert(
          gradients == null || gradients.length == labels.length,
          'gradients length must match labels length',
        ),
        assert(
          icons == null || icons.length == labels.length,
          'icons length must match labels length',
        );

  /// Display labels for each chip.
  final List<String> labels;

  /// Optional leading icon per chip. Pass `null` for chips without an icon.
  final List<IconData?>? icons;

  /// Index of the currently selected chip.
  final int selectedIndex;

  /// Called with the tapped chip index.
  final ValueChanged<int> onSelected;

  /// Optional per-chip gradient colours (two colours each).
  /// Falls back to [AppTheme.themeBlueStart]/[AppTheme.themeBlueEnd]
  /// if null or if the entry for a given index is null.
  final List<List<Color>?>? gradients;

  final EdgeInsetsGeometry padding;
  final double height;
  final double chipSpacing;

  static const _defaultGradient = [
    AppTheme.themeBlueStart,
    AppTheme.themeBlueEnd,
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: labels.length,
        separatorBuilder: (_, __) => SizedBox(width: chipSpacing),
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          final grad = (gradients != null && gradients![index] != null)
              ? gradients![index]!
              : _defaultGradient;
          final icon = icons != null ? icons![index] : null;

          final labelColor = isSelected
              ? Colors.white
              : (isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary);

          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: icon != null ? 12 : 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: grad,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected
                    ? null
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? grad.first.withValues(alpha: 0.8)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : AppTheme.lightBorderColor),
                ),
              ),
              child: icon != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 15, color: labelColor),
                        const SizedBox(width: 5),
                        Text(
                          labels[index],
                          style: TextStyle(
                            color: labelColor,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      labels[index],
                      style: TextStyle(
                        color: labelColor,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
