import 'package:flutter/material.dart';
import '../../data/models/course_models.dart';
import '../themes/app_theme.dart';

/// Modernized course card with clean Column layout
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
          color: isDark
              ? AppTheme.darkCardBackground
              : AppTheme.lightCardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? AppTheme.darkBorderColor
                : AppTheme.lightBorderColor,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail area with level badge
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildThumbnail(isDark),
                    // Level badge - top left
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildLevelBadge(),
                    ),
                    // Status dot - top right
                    if (showStatus)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _buildStatusIndicator(),
                      ),
                  ],
                ),
              ),

              // Info section below image
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Expanded(
                        child: Text(
                          course.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Author + Price row
                      Row(
                        children: [
                          // Author
                          if (course.authorName != null ||
                              course.author.fullName != null) ...[
                            Icon(
                              Icons.person_outline,
                              size: 12,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                course.authorName ??
                                    course.author.fullName ??
                                    '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 6),
                          // Price badge
                          _buildPriceBadge(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(bool isDark) {
    final thumbnailUrl = course.thumbnailUrl ?? course.thumbnail?.url;

    if (thumbnailUrl != null) {
      return Image.network(
        thumbnailUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildPlaceholder(isDark),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder(isDark);
        },
      );
    }
    return _buildPlaceholder(isDark);
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
          size: 36,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildLevelBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: _getLevelGradient()),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: _getLevelGradient().first.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getLevelIcon(), size: 10, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            _getLevelText().toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    final isPublic = course.status == CourseStatus.public;
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isPublic ? AppTheme.successColor : AppTheme.warningColor,
        boxShadow: [
          BoxShadow(
            color: (isPublic ? AppTheme.successColor : AppTheme.warningColor)
                .withValues(alpha: 0.5),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBadge() {
    if (course.price != null && course.price! > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.themeOrangeStart.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          _formatPrice(course.price!),
          style: const TextStyle(
            color: AppTheme.themeOrangeStart,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'FREE',
        style: TextStyle(
          color: AppTheme.successColor,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
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
