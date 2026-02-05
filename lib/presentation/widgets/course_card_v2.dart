import 'package:flutter/material.dart';
import '../../data/models/course_models.dart';
import '../themes/app_theme.dart';

/// Modernized course card matching Skillverse web sci-fi design
class CourseCardV2 extends StatelessWidget {
  final CourseSummaryDto course;
  final VoidCallback? onTap;
  final bool showStatus;

  const CourseCardV2({
    super.key,
    required this.course,
    this.onTap,
    this.showStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppTheme.primaryBlueDark.withValues(alpha: 0.3)
                : AppTheme.lightBorderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? AppTheme.primaryBlueDark.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background with thumbnail
              _buildThumbnail(isDark),

              // Level badge overlay
              Positioned(top: 12, left: 12, child: _buildLevelBadge(isDark)),

              // Status indicator
              if (showStatus)
                Positioned(top: 12, right: 12, child: _buildStatusIndicator()),

              // Course ID badge
              Positioned(
                top: 12,
                right: showStatus ? 36 : 12,
                child: _buildIdBadge(isDark),
              ),

              // Bottom title overlay
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildTitleOverlay(context, isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(bool isDark) {
    final thumbnailUrl = course.thumbnailUrl ?? course.thumbnail?.url;

    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppTheme.galaxyDark, AppTheme.galaxyMid]
                : [
                    AppTheme.lightBackgroundSecondary,
                    AppTheme.lightBackgroundPrimary,
                  ],
          ),
        ),
        child: thumbnailUrl != null
            ? Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholder(isDark),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildPlaceholder(isDark);
                },
              )
            : _buildPlaceholder(isDark),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getLevelGradient(),
        ),
      ),
      child: Center(
        child: Icon(
          Icons.school_rounded,
          size: 48,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildLevelBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: _getLevelGradient()),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: _getLevelGradient().first.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getLevelIcon(), size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            _getLevelText().toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    final isPublic = course.status == CourseStatus.public;
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isPublic ? AppTheme.successColor : AppTheme.warningColor,
        boxShadow: [
          BoxShadow(
            color: (isPublic ? AppTheme.successColor : AppTheme.warningColor)
                .withValues(alpha: 0.5),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildIdBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark
              ? AppTheme.primaryBlueDark.withValues(alpha: 0.3)
              : AppTheme.lightBorderColor,
        ),
      ),
      child: Text(
        '#${course.id}',
        style: TextStyle(
          color: isDark ? AppTheme.primaryBlueDark : AppTheme.primaryBlue,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildTitleOverlay(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            (isDark ? Colors.black : Colors.white).withValues(alpha: 0.7),
            (isDark ? Colors.black : Colors.white).withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            course.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          // Meta info row
          Row(
            children: [
              // Author - use Flexible to prevent overflow
              if (course.authorName != null ||
                  course.author.fullName != null) ...[
                Icon(
                  Icons.person_outline,
                  size: 12,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    course.authorName ?? course.author.fullName ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
              // Price badge
              const SizedBox(width: 6),
              if (course.price != null && course.price! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.themeOrangeStart.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatPrice(course.price!),
                    style: const TextStyle(
                      color: AppTheme.themeOrangeStart,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'FREE',
                    style: TextStyle(
                      color: AppTheme.successColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<Color> _getLevelGradient() {
    switch (course.level) {
      case CourseLevel.beginner:
        return [AppTheme.themeGreenStart, AppTheme.themeGreenEnd];
      case CourseLevel.intermediate:
        return [AppTheme.themeBlueStart, AppTheme.themeBlueEnd];
      case CourseLevel.advanced:
        return [AppTheme.themePurpleStart, AppTheme.themePurpleEnd];
    }
  }

  IconData _getLevelIcon() {
    switch (course.level) {
      case CourseLevel.beginner:
        return Icons.rocket_launch_outlined;
      case CourseLevel.intermediate:
        return Icons.trending_up;
      case CourseLevel.advanced:
        return Icons.auto_awesome;
    }
  }

  String _getLevelText() {
    switch (course.level) {
      case CourseLevel.beginner:
        return 'Cơ bản';
      case CourseLevel.intermediate:
        return 'Trung cấp';
      case CourseLevel.advanced:
        return 'Nâng cao';
    }
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toStringAsFixed(0);
  }
}
