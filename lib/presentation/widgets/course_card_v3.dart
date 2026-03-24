import 'package:flutter/material.dart';
import '../../data/models/course_models.dart';
import '../themes/app_theme.dart';
import '../widgets/glass_card.dart';
import '../../core/utils/number_formatter.dart';

/// Horizontal course card for list views
/// Shows thumbnail, title, author, stats, and price
class CourseCardV3 extends StatelessWidget {
  final CourseSummaryDto course;
  final VoidCallback? onTap;
  final bool isEnrolled;

  const CourseCardV3({
    super.key,
    required this.course,
    this.onTap,
    this.isEnrolled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with level badge
            _buildThumbnail(isDark),
            const SizedBox(width: 14),
            // Info section
            Expanded(child: _buildInfo(context, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(bool isDark) {
    final imageUrl = course.thumbnailUrl ?? course.thumbnail?.url;
    final levelColors = _getLevelGradient();

    return SizedBox(
      width: 120,
      height: 90,
      child: Stack(
        children: [
          // Image or gradient placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    width: 120,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _buildPlaceholder(levelColors),
                  )
                : _buildPlaceholder(levelColors),
          ),
          // Level badge overlay
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: levelColors),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: levelColors[0].withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                _getLevelText(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(List<Color> colors) {
    return Container(
      width: 120,
      height: 90,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.school_outlined, color: Colors.white70, size: 32),
      ),
    );
  }

  Widget _buildInfo(BuildContext context, bool isDark) {
    final authorName =
        course.authorName ??
        course.author.fullName ??
        '${course.author.firstName ?? ''} ${course.author.lastName ?? ''}'
            .trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Text(
          course.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 4),
        // Author
        if (authorName.isNotEmpty)
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 13,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  authorName == 'Unknown' ? 'Đang cập nhật' : authorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
        // Stats row + Price
        Row(
          children: [
            // Rating
            if (course.rating != null && course.rating! > 0) ...[
              const Icon(Icons.star, size: 14, color: Colors.amber),
              const SizedBox(width: 2),
              Text(
                course.rating!.toStringAsFixed(1),
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _statDot(isDark),
            ],
            // Enrollment count
            Icon(
              Icons.people_outline,
              size: 14,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
            const SizedBox(width: 2),
            Text(
              course.enrollmentCount == 0 ? 'Mới' : '${course.enrollmentCount}',
              style: TextStyle(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
                fontSize: 12,
              ),
            ),
            // Module count
            if (course.moduleCount != null && course.moduleCount! > 0) ...[
              _statDot(isDark),
              Icon(
                Icons.menu_book_outlined,
                size: 14,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
              const SizedBox(width: 2),
              Text(
                '${course.moduleCount}',
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                  fontSize: 12,
                ),
              ),
            ],
            const Spacer(),
            // Price badge
            _buildPriceBadge(isDark),
          ],
        ),
      ],
    );
  }

  Widget _statDot(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '•',
        style: TextStyle(
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
          fontSize: 8,
        ),
      ),
    );
  }

  Widget _buildPriceBadge(bool isDark) {
    final price = course.price ?? 0;
    final isFree = price == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isFree
            ? AppTheme.successColor.withValues(alpha: 0.15)
            : AppTheme.primaryBlueDark.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFree
              ? AppTheme.successColor.withValues(alpha: 0.3)
              : AppTheme.primaryBlueDark.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        isEnrolled
            ? 'Đã sở hữu'
            : isFree
            ? 'Miễn phí'
            : NumberFormatter.formatCurrency(price, currency: 'đ'),
        style: TextStyle(
          color: isEnrolled
              ? AppTheme.successColor
              : isFree
              ? AppTheme.successColor
              : AppTheme.primaryBlueDark,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  List<Color> _getLevelGradient() {
    switch (course.level) {
      case CourseLevel.beginner:
        return [const Color(0xFF4CAF50), const Color(0xFF66BB6A)];
      case CourseLevel.intermediate:
        return [const Color(0xFF2196F3), const Color(0xFF42A5F5)];
      case CourseLevel.advanced:
        return [const Color(0xFFFF6B35), const Color(0xFFFF8A65)];
    }
  }

  String _getLevelText() {
    switch (course.level) {
      case CourseLevel.beginner:
        return 'CƠ BẢN';
      case CourseLevel.intermediate:
        return 'TRUNG CẤP';
      case CourseLevel.advanced:
        return 'NÂNG CAO';
    }
  }
}
