import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../themes/app_theme.dart';

/// Animation duration constants for consistent timing across the app.
class LearningReportAnimations {
  LearningReportAnimations._();

  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 500);
  static const page = Duration(milliseconds: 400);
  static const shimmerCycle = Duration(milliseconds: 1500);
}

/// Shimmer loading base widget for Learning Report.
class LearningShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool isDark;

  const LearningShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.grey.shade300,
      highlightColor: isDark
          ? Colors.white.withValues(alpha: 0.16)
          : Colors.grey.shade100,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Skeleton for Meowl avatar + speech bubble.
class SkeletonMeowl extends StatelessWidget {
  final bool isDark;
  final double avatarSize;

  const SkeletonMeowl({
    super.key,
    required this.isDark,
    this.avatarSize = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LearningShimmer(
          width: avatarSize,
          height: avatarSize,
          borderRadius: avatarSize / 2,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        LearningShimmer(
          width: avatarSize * 0.8,
          height: 50,
          borderRadius: 16,
          isDark: isDark,
        ),
      ],
    );
  }
}

/// Skeleton for 2x2 stats grid.
class SkeletonStatsGrid extends StatelessWidget {
  final bool isDark;

  const SkeletonStatsGrid({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.grey.shade300,
      highlightColor: isDark
          ? Colors.white.withValues(alpha: 0.16)
          : Colors.grey.shade100,
      period: const Duration(milliseconds: 1500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
          LearningShimmer(
            width: 80,
            height: 14,
            borderRadius: 4,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          // Top row
          Row(
            children: [
              Expanded(child: _buildStatCard(isDark)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(isDark)),
            ],
          ),
          const SizedBox(height: 12),
          // Bottom row
          Row(
            children: [
              Expanded(child: _buildStatCard(isDark)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(isDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.galaxyMid.withValues(alpha: 0.5)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LearningShimmer(
            width: 24,
            height: 24,
            borderRadius: 6,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          LearningShimmer(
            width: 48,
            height: 28,
            borderRadius: 6,
            isDark: isDark,
          ),
          const SizedBox(height: 4),
          LearningShimmer(
            width: 60,
            height: 12,
            borderRadius: 4,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

/// Skeleton for trend banner.
class SkeletonTrendBanner extends StatelessWidget {
  final bool isDark;

  const SkeletonTrendBanner({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.grey.shade300,
      highlightColor: isDark
          ? Colors.white.withValues(alpha: 0.16)
          : Colors.grey.shade100,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// Skeleton for section navigation chips.
class SkeletonSectionNav extends StatelessWidget {
  final bool isDark;

  const SkeletonSectionNav({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.grey.shade300,
      highlightColor: isDark
          ? Colors.white.withValues(alpha: 0.16)
          : Colors.grey.shade100,
      period: const Duration(milliseconds: 1500),
      child: Row(
        children: List.generate(5, (_) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              width: 70,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Skeleton for section card content.
class SkeletonSectionCard extends StatelessWidget {
  final bool isDark;

  const SkeletonSectionCard({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.grey.shade300,
      highlightColor: isDark
          ? Colors.white.withValues(alpha: 0.16)
          : Colors.grey.shade100,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.galaxyMid.withValues(alpha: 0.5)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LearningShimmer(
              width: 100,
              height: 16,
              borderRadius: 4,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            LearningShimmer(
              width: double.infinity,
              height: 14,
              borderRadius: 4,
              isDark: isDark,
            ),
            const SizedBox(height: 6),
            LearningShimmer(
              width: 240,
              height: 14,
              borderRadius: 4,
              isDark: isDark,
            ),
            const SizedBox(height: 6),
            LearningShimmer(
              width: 180,
              height: 14,
              borderRadius: 4,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for history item.
class SkeletonHistoryItem extends StatelessWidget {
  final bool isDark;

  const SkeletonHistoryItem({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.grey.shade300,
      highlightColor: isDark
          ? Colors.white.withValues(alpha: 0.16)
          : Colors.grey.shade100,
      period: const Duration(milliseconds: 1500),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.galaxyMid.withValues(alpha: 0.5)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              LearningShimmer(
                width: 44,
                height: 44,
                borderRadius: 10,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        LearningShimmer(
                          width: 100,
                          height: 14,
                          borderRadius: 4,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        LearningShimmer(
                          width: 50,
                          height: 20,
                          borderRadius: 6,
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LearningShimmer(
                      width: 160,
                      height: 12,
                      borderRadius: 4,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              LearningShimmer(
                width: 32,
                height: 32,
                borderRadius: 8,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full page skeleton loading state for Learning Report.
class LearningReportSkeleton extends StatelessWidget {
  final bool isDark;
  final bool includeStats;
  final bool includeSections;

  const LearningReportSkeleton({
    super.key,
    required this.isDark,
    this.includeStats = true,
    this.includeSections = true,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // Meowl + speech skeleton centered
          Center(
            child: SkeletonMeowl(isDark: isDark, avatarSize: 100),
          ),
          const SizedBox(height: 32),
          Text(
            'Đang đồng bộ dữ liệu...',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (includeStats) ...[
            const SizedBox(height: 32),
            SkeletonStatsGrid(isDark: isDark),
          ],
          if (includeSections) ...[
            const SizedBox(height: 16),
            SkeletonTrendBanner(isDark: isDark),
            const SizedBox(height: 16),
            SkeletonSectionNav(isDark: isDark),
            const SizedBox(height: 16),
            SkeletonSectionCard(isDark: isDark),
            const SizedBox(height: 12),
            SkeletonSectionCard(isDark: isDark),
          ],
        ],
      ),
    );
  }
}

/// Generating state skeleton — Meowl + steps skeleton.
class GeneratingSkeleton extends StatelessWidget {
  final bool isDark;
  final int currentStep;

  const GeneratingSkeleton({
    super.key,
    required this.isDark,
    this.currentStep = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 40),
            SkeletonMeowl(isDark: isDark, avatarSize: 120),
            const SizedBox(height: 32),
            // Steps skeleton
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(7, (index) {
                if (index.isOdd) {
                  return const SizedBox(width: 24, height: 2);
                }
                return Shimmer.fromColors(
                  baseColor: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey.shade300,
                  highlightColor: isDark
                      ? Colors.white.withValues(alpha: 0.16)
                      : Colors.grey.shade100,
                  period: const Duration(milliseconds: 1500),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey.shade300,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            LearningShimmer(
              width: 220,
              height: 14,
              borderRadius: 4,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}
