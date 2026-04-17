import 'dart:async';

import 'package:flutter/material.dart';

import '../themes/app_theme.dart';
import 'learning_report/generating_steps_widget.dart';
import 'learning_report/meowl_avatar_widget.dart';

class AiGenerationLoadingView extends StatefulWidget {
  final String speech;
  final String? title;
  final String? description;
  final String? etaText;
  final String? statusText;
  final List<(String, IconData)> steps;
  final int? currentStep;
  final Duration stepDuration;
  final EdgeInsetsGeometry padding;
  final double avatarSize;
  final double topSpacing;
  final bool useSafeArea;
  final bool scrollable;

  const AiGenerationLoadingView({
    super.key,
    required this.speech,
    this.title,
    this.description,
    this.etaText,
    this.statusText,
    this.steps = const [
      ('Thu thập dữ liệu', Icons.cloud_download_outlined),
      ('Phân tích AI', Icons.psychology_outlined),
      ('Tạo nội dung', Icons.auto_awesome_outlined),
      ('Hoàn thiện', Icons.check_circle_outline),
    ],
    this.currentStep,
    this.stepDuration = const Duration(seconds: 3),
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    this.avatarSize = 120,
    this.topSpacing = 40,
    this.useSafeArea = true,
    this.scrollable = true,
  });

  @override
  State<AiGenerationLoadingView> createState() =>
      _AiGenerationLoadingViewState();
}

class _AiGenerationLoadingViewState extends State<AiGenerationLoadingView> {
  Timer? _stepTimer;
  int _autoStep = 0;

  int get _maxIndex => widget.steps.isEmpty ? 0 : widget.steps.length - 1;

  @override
  void initState() {
    super.initState();
    _syncStepSource();
  }

  @override
  void didUpdateWidget(covariant AiGenerationLoadingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep ||
        oldWidget.steps.length != widget.steps.length ||
        oldWidget.stepDuration != widget.stepDuration) {
      _syncStepSource();
    }
  }

  void _syncStepSource() {
    _stepTimer?.cancel();
    _autoStep = 0;

    if (widget.currentStep != null || widget.steps.length <= 1) {
      return;
    }

    _stepTimer = Timer.periodic(widget.stepDuration, (_) {
      if (!mounted) return;
      setState(() {
        _autoStep = (_autoStep + 1) % widget.steps.length;
      });
    });
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final step = (widget.currentStep ?? _autoStep).clamp(0, _maxIndex);
    final hasSteps = widget.steps.isNotEmpty;

    final content = Padding(
      padding: widget.padding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: widget.topSpacing),
              MeowlAvatarWidget(
                speech: widget.speech,
                animate: true,
                size: widget.avatarSize,
              ),
              if (widget.title != null) ...[
                const SizedBox(height: 28),
                Text(
                  widget.title!,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (widget.description != null) ...[
                const SizedBox(height: 10),
                Text(
                  widget.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (hasSteps) ...[
                const SizedBox(height: 28),
                GeneratingStepsWidget(
                  currentStep: step,
                  isDark: isDark,
                  steps: widget.steps,
                ),
              ],
              if (widget.etaText != null) ...[
                const SizedBox(height: 16),
                Text(
                  widget.etaText!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (widget.statusText != null &&
                  widget.statusText!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  widget.statusText!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.accentCyan,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (!widget.scrollable) {
      return widget.useSafeArea ? SafeArea(child: content) : content;
    }

    final scrollView = SingleChildScrollView(child: content);
    return widget.useSafeArea ? SafeArea(child: scrollView) : scrollView;
  }
}
