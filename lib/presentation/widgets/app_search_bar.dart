import 'package:flutter/material.dart';
import 'glass_card.dart';

/// Reusable search bar used across listing pages.
///
/// Wraps a [TextField] inside a [GlassCard] so it automatically
/// adapts to dark/light theme. Shows a clear button when the
/// controller has text.
///
/// Usage:
/// ```dart
/// AppSearchBar(
///   controller: _searchController,
///   hintText: 'Tìm kiếm khóa học...',
///   onChanged: (q) => provider.search(q),
///   onSubmitted: (q) => provider.search(q),
/// )
/// ```
class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
    this.textInputAction = TextInputAction.search,
    this.padding,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Called after clear button is tapped (after controller.clear()).
  /// If null, only clears the controller without extra callback.
  final VoidCallback? onClear;

  final bool autofocus;
  final TextInputAction textInputAction;

  /// Outer padding around the GlassCard. Defaults to zero.
  final EdgeInsetsGeometry? padding;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChange);
    _hasText = widget.controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    super.dispose();
  }

  void _onControllerChange() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _handleClear() {
    widget.controller.clear();
    widget.onClear?.call();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget child = GlassCard(
      showBorder: false,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextField(
        controller: widget.controller,
        autofocus: widget.autofocus,
        textInputAction: widget.textInputAction,
        style: textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.45),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: colorScheme.onSurface.withValues(alpha: 0.55),
          ),
          suffixIcon: _hasText
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                  onPressed: _handleClear,
                )
              : null,
        ),
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
      ),
    );

    if (widget.padding != null) {
      child = Padding(padding: widget.padding!, child: child);
    }

    return child;
  }
}
