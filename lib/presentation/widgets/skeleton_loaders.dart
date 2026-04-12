import 'package:flutter/material.dart';
import 'shimmer_loading.dart';

/// Collection of skeleton loaders for different UI components
/// Use these for loading states to provide better UX

/// List item skeleton (generic)
class ListItemSkeleton extends StatelessWidget {
  final bool hasLeading;
  final bool hasTrailing;
  final int lineCount;

  const ListItemSkeleton({
    super.key,
    this.hasLeading = true,
    this.hasTrailing = false,
    this.lineCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (hasLeading) ...[
              const ShimmerBox(width: 48, height: 48, borderRadius: 24),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(
                    width: double.infinity,
                    height: 16,
                    margin: EdgeInsets.only(bottom: 8),
                  ),
                  if (lineCount >= 2)
                    ShimmerBox(
                      width: MediaQuery.of(context).size.width * 0.6,
                      height: 14,
                    ),
                  if (lineCount >= 3) ...[
                    const SizedBox(height: 8),
                    ShimmerBox(
                      width: MediaQuery.of(context).size.width * 0.4,
                      height: 14,
                    ),
                  ],
                ],
              ),
            ),
            if (hasTrailing) ...[
              const SizedBox(width: 16),
              const ShimmerBox(width: 24, height: 24, borderRadius: 12),
            ],
          ],
        ),
      ),
    );
  }
}

/// Profile header skeleton
class ProfileHeaderSkeleton extends StatelessWidget {
  const ProfileHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        children: [
          const SizedBox(height: 24),
          const ShimmerBox(width: 100, height: 100, borderRadius: 50),
          const SizedBox(height: 16),
          ShimmerBox(
            width: MediaQuery.of(context).size.width * 0.5,
            height: 24,
            margin: const EdgeInsets.only(bottom: 8),
          ),
          ShimmerBox(
            width: MediaQuery.of(context).size.width * 0.7,
            height: 16,
            margin: const EdgeInsets.only(bottom: 16),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  const ShimmerBox(width: 60, height: 20),
                  const SizedBox(height: 4),
                  ShimmerBox(
                    width: 80,
                    height: 14,
                    margin: const EdgeInsets.all(0),
                  ),
                ],
              ),
              Column(
                children: [
                  const ShimmerBox(width: 60, height: 20),
                  const SizedBox(height: 4),
                  ShimmerBox(
                    width: 80,
                    height: 14,
                    margin: const EdgeInsets.all(0),
                  ),
                ],
              ),
              Column(
                children: [
                  const ShimmerBox(width: 60, height: 20),
                  const SizedBox(height: 4),
                  ShimmerBox(
                    width: 80,
                    height: 14,
                    margin: const EdgeInsets.all(0),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card skeleton (generic card with image)
class CardSkeleton extends StatelessWidget {
  final double? imageHeight;
  final bool hasSubtitle;
  final bool hasFooter;

  const CardSkeleton({
    super.key,
    this.imageHeight = 160,
    this.hasSubtitle = true,
    this.hasFooter = true,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageHeight != null)
              ShimmerBox(
                width: double.infinity,
                height: imageHeight,
                borderRadius: 16,
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(
                    width: double.infinity,
                    height: 20,
                    margin: EdgeInsets.only(bottom: 8),
                  ),
                  if (hasSubtitle)
                    ShimmerBox(
                      width: MediaQuery.of(context).size.width * 0.6,
                      height: 16,
                      margin: const EdgeInsets.only(bottom: 12),
                    ),
                  if (hasFooter)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const ShimmerBox(width: 80, height: 14),
                        ShimmerBox(
                          width: MediaQuery.of(context).size.width * 0.25,
                          height: 32,
                          borderRadius: 16,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Text skeleton (for paragraph loading)
class TextSkeleton extends StatelessWidget {
  final int lines;
  final double? lineHeight;
  final EdgeInsetsGeometry? padding;

  const TextSkeleton({
    super.key,
    this.lines = 3,
    this.lineHeight = 16,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(lines, (index) {
            final isLast = index == lines - 1;
            return ShimmerBox(
              width: isLast
                  ? MediaQuery.of(context).size.width * 0.7
                  : double.infinity,
              height: lineHeight,
              margin: EdgeInsets.only(bottom: index < lines - 1 ? 8 : 0),
            );
          }),
        ),
      ),
    );
  }
}

/// Grid item skeleton
class GridItemSkeleton extends StatelessWidget {
  final double aspectRatio;

  const GridItemSkeleton({super.key, this.aspectRatio = 1.0});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.2),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const ShimmerBox(
                        width: double.infinity,
                        height: 12,
                        margin: EdgeInsets.only(bottom: 4),
                      ),
                      ShimmerBox(
                        width: MediaQuery.of(context).size.width * 0.4,
                        height: 10,
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
}

/// Job card skeleton — matches _buildLongTermJobCard in jobs_page.dart
/// Layout: Header (48px avatar + title/company) → Salary row → Description
///         → Skill chips → Info chips → Footer (deadline + applicants)
class JobCardSkeleton extends StatelessWidget {
  const JobCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: avatar + title + company
            Row(
              children: [
                const ShimmerBox(width: 48, height: 48, borderRadius: 12),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ShimmerBox(
                        width: double.infinity,
                        height: 18,
                        margin: EdgeInsets.only(bottom: 4),
                      ),
                      ShimmerBox(
                        width: MediaQuery.of(context).size.width * 0.35,
                        height: 13,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Salary highlight row
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  ShimmerBox(width: 18, height: 18, borderRadius: 4),
                  SizedBox(width: 8),
                  ShimmerBox(width: 140, height: 14),
                ],
              ),
            ),
            // Description
            const SizedBox(height: 10),
            const ShimmerBox(
              width: double.infinity,
              height: 14,
              margin: EdgeInsets.only(bottom: 4),
            ),
            ShimmerBox(
              width: MediaQuery.of(context).size.width * 0.6,
              height: 14,
            ),
            // Skill chips
            const SizedBox(height: 10),
            const Row(
              children: [
                ShimmerBox(width: 60, height: 26, borderRadius: 12),
                SizedBox(width: 8),
                ShimmerBox(width: 72, height: 26, borderRadius: 12),
                SizedBox(width: 8),
                ShimmerBox(width: 56, height: 26, borderRadius: 12),
              ],
            ),
            // Info chips row
            const SizedBox(height: 12),
            const Row(
              children: [
                ShimmerBox(width: 70, height: 14),
                SizedBox(width: 12),
                ShimmerBox(width: 80, height: 14),
              ],
            ),
            // Footer: deadline + applicants
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const ShimmerBox(width: 80, height: 12),
                const ShimmerBox(width: 70, height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Comment/Message skeleton
class CommentSkeleton extends StatelessWidget {
  const CommentSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(width: 40, height: 40, borderRadius: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(
                    width: MediaQuery.of(context).size.width * 0.3,
                    height: 14,
                    margin: const EdgeInsets.only(bottom: 8),
                  ),
                  const ShimmerBox(
                    width: double.infinity,
                    height: 14,
                    margin: EdgeInsets.only(bottom: 4),
                  ),
                  ShimmerBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 14,
                    margin: const EdgeInsets.only(bottom: 4),
                  ),
                  ShimmerBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: 14,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Post card skeleton — matches PostCard in post_card.dart
/// Layout: Author header (avatar + name + time + menu) → Title → Content
///         → Action buttons (like, comment, spacer, bookmark)
class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author header
            Row(
              children: [
                const ShimmerBox(width: 40, height: 40, borderRadius: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(
                        width: MediaQuery.of(context).size.width * 0.3,
                        height: 14,
                        margin: const EdgeInsets.only(bottom: 4),
                      ),
                      ShimmerBox(
                        width: MediaQuery.of(context).size.width * 0.2,
                        height: 12,
                      ),
                    ],
                  ),
                ),
                // Menu icon placeholder
                const ShimmerBox(width: 24, height: 24, borderRadius: 12),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            ShimmerBox(
              width: MediaQuery.of(context).size.width * 0.7,
              height: 18,
              margin: const EdgeInsets.only(bottom: 8),
            ),

            // Content lines
            const ShimmerBox(
              width: double.infinity,
              height: 14,
              margin: EdgeInsets.only(bottom: 6),
            ),
            const ShimmerBox(
              width: double.infinity,
              height: 14,
              margin: EdgeInsets.only(bottom: 6),
            ),
            ShimmerBox(
              width: MediaQuery.of(context).size.width * 0.5,
              height: 14,
            ),

            const SizedBox(height: 16),

            // Action buttons: like + comment + spacer + bookmark
            const Row(
              children: [
                ShimmerBox(width: 48, height: 28, borderRadius: 14),
                SizedBox(width: 16),
                ShimmerBox(width: 48, height: 28, borderRadius: 14),
                Spacer(),
                ShimmerBox(width: 28, height: 28, borderRadius: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Mentor card skeleton — matches _buildMentorCard in mentor_list_page.dart
/// Layout: Gradient header (72px avatar + name + specialization + rating)
///         → Body (skill chips + price row + action buttons)
class MentorCardSkeleton extends StatelessWidget {
  const MentorCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            // Header with gradient tint
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.04),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Avatar
                  const ShimmerBox(width: 72, height: 72, borderRadius: 36),
                  const SizedBox(width: 16),
                  // Name + specialization + rating
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(
                          width: MediaQuery.of(context).size.width * 0.4,
                          height: 20,
                          margin: const EdgeInsets.only(bottom: 4),
                        ),
                        ShimmerBox(
                          width: MediaQuery.of(context).size.width * 0.3,
                          height: 14,
                          margin: const EdgeInsets.only(bottom: 6),
                        ),
                        const Row(
                          children: [
                            ShimmerBox(width: 16, height: 16, borderRadius: 2),
                            SizedBox(width: 4),
                            ShimmerBox(width: 30, height: 13),
                            SizedBox(width: 12),
                            ShimmerBox(width: 14, height: 14, borderRadius: 2),
                            SizedBox(width: 4),
                            ShimmerBox(width: 44, height: 12),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Favorite icon
                  const ShimmerBox(width: 24, height: 24, borderRadius: 12),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Skill chips
                  const Row(
                    children: [
                      ShimmerBox(width: 70, height: 30, borderRadius: 12),
                      SizedBox(width: 8),
                      ShimmerBox(width: 85, height: 30, borderRadius: 12),
                      SizedBox(width: 8),
                      ShimmerBox(width: 55, height: 30, borderRadius: 12),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Price + action buttons
                  Row(
                    children: [
                      // Price
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const ShimmerBox(width: 60, height: 11),
                            const SizedBox(height: 2),
                            const ShimmerBox(width: 80, height: 18),
                          ],
                        ),
                      ),
                      // Chat button
                      const ShimmerBox(width: 72, height: 36, borderRadius: 12),
                      const SizedBox(width: 8),
                      // Arrow button
                      const ShimmerBox(width: 40, height: 36, borderRadius: 12),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JourneyCardSkeleton extends StatelessWidget {
  const JourneyCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const ShimmerBox(width: 80, height: 24, borderRadius: 8),
                const Spacer(),
                const ShimmerBox(width: 70, height: 24, borderRadius: 8),
              ],
            ),
            const SizedBox(height: 10),
            const ShimmerBox(
              width: double.infinity,
              height: 18,
              margin: EdgeInsets.only(bottom: 6),
            ),
            ShimmerBox(
              width: MediaQuery.of(context).size.width * 0.65,
              height: 14,
              margin: const EdgeInsets.only(bottom: 12),
            ),
            const ShimmerBox(
              width: double.infinity,
              height: 6,
              borderRadius: 4,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const ShimmerBox(width: 80, height: 12),
                const Spacer(),
                const ShimmerBox(width: 50, height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Course card skeleton — matches CourseCard in course_card.dart
/// Layout: 160px thumbnail → Title → Author row (24px avatar + name)
///         → Stats row (rating + students + modules) → Price + CTA button
class CourseCardSkeleton extends StatelessWidget {
  const CourseCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            const ShimmerBox(
              width: double.infinity,
              height: 160,
              borderRadius: 16,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title (2 lines)
                  const ShimmerBox(
                    width: double.infinity,
                    height: 18,
                    margin: EdgeInsets.only(bottom: 8),
                  ),
                  // Author row
                  Row(
                    children: [
                      const ShimmerBox(
                        width: 24,
                        height: 24,
                        borderRadius: 12,
                        margin: EdgeInsets.only(right: 8),
                      ),
                      ShimmerBox(
                        width: MediaQuery.of(context).size.width * 0.35,
                        height: 14,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Stats row: rating + students + modules
                  const Row(
                    children: [
                      ShimmerBox(width: 16, height: 16, borderRadius: 2),
                      SizedBox(width: 4),
                      ShimmerBox(width: 24, height: 14),
                      SizedBox(width: 16),
                      ShimmerBox(width: 16, height: 16, borderRadius: 2),
                      SizedBox(width: 4),
                      ShimmerBox(width: 24, height: 14),
                      SizedBox(width: 16),
                      ShimmerBox(width: 16, height: 16, borderRadius: 2),
                      SizedBox(width: 4),
                      ShimmerBox(width: 60, height: 14),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Price + CTA button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const ShimmerBox(
                        width: 80,
                        height: 32,
                        borderRadius: 8,
                      ),
                      const Spacer(),
                      ShimmerBox(
                        width: MediaQuery.of(context).size.width * 0.3,
                        height: 38,
                        borderRadius: 8,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Course card skeleton (horizontal) — matches CourseCardV3 in course_card_v3.dart
/// Layout: Row( 120x90 thumbnail | Column(Title, Author, Stats/Price) )
class CourseCardV3Skeleton extends StatelessWidget {
  const CourseCardV3Skeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            const ShimmerBox(width: 120, height: 90, borderRadius: 12),
            const SizedBox(width: 14),
            // Info block
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title (2 lines)
                  const ShimmerBox(
                    width: double.infinity,
                    height: 15,
                    margin: EdgeInsets.only(bottom: 6),
                  ),
                  ShimmerBox(
                    width: MediaQuery.of(context).size.width * 0.35,
                    height: 15,
                    margin: const EdgeInsets.only(bottom: 8),
                  ),
                  // Author row
                  Row(
                    children: [
                      const ShimmerBox(width: 13, height: 13, borderRadius: 2),
                      const SizedBox(width: 4),
                      ShimmerBox(
                        width: MediaQuery.of(context).size.width * 0.25,
                        height: 12,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Stats row + Price badge
                  Row(
                    children: [
                      const ShimmerBox(width: 14, height: 14, borderRadius: 2),
                      const SizedBox(width: 2),
                      const ShimmerBox(width: 20, height: 12),
                      const SizedBox(width: 12),
                      const ShimmerBox(width: 14, height: 14, borderRadius: 2),
                      const SizedBox(width: 2),
                      const ShimmerBox(width: 20, height: 12),
                      const Spacer(),
                      // Price badge
                      const ShimmerBox(width: 60, height: 22, borderRadius: 8),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chat bubble skeleton (for chat message loading states)
class ChatBubbleSkeleton extends StatelessWidget {
  /// Number of message pairs to show
  final int pairCount;

  const ChatBubbleSkeleton({super.key, this.pairCount = 3});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        children: List.generate(pairCount, (pairIndex) {
          return Column(
            children: [
              // Assistant bubble (left-aligned)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerBox(width: 32, height: 32, borderRadius: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBox(
                            width: MediaQuery.of(context).size.width * 0.65,
                            height: 16,
                            margin: const EdgeInsets.only(bottom: 6),
                          ),
                          ShimmerBox(
                            width: MediaQuery.of(context).size.width * 0.5,
                            height: 16,
                            margin: const EdgeInsets.only(bottom: 6),
                          ),
                          ShimmerBox(
                            width: MediaQuery.of(context).size.width * 0.35,
                            height: 16,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              // User bubble (right-aligned)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    const Spacer(),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ShimmerBox(
                            width: MediaQuery.of(context).size.width * 0.45,
                            height: 16,
                            margin: const EdgeInsets.only(bottom: 6),
                          ),
                          ShimmerBox(
                            width: MediaQuery.of(context).size.width * 0.3,
                            height: 16,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const ShimmerBox(width: 32, height: 32, borderRadius: 16),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// Dashboard Continue-Learning skeleton — matches GradientGlassCard with
/// 48×48 icon block, title, subtitle and a thin progress bar.
class ContinueLearningSkeleton extends StatelessWidget {
  const ContinueLearningSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            // Icon block placeholder
            const ShimmerBox(width: 48, height: 48, borderRadius: 12),
            const SizedBox(width: 12),
            // Text + progress bar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(
                    width: 80,
                    height: 10,
                    margin: EdgeInsets.only(bottom: 4),
                  ),
                  ShimmerBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: 14,
                    margin: const EdgeInsets.only(bottom: 8),
                  ),
                  Row(
                    children: [
                      const Expanded(
                        child: ShimmerBox(
                          width: double.infinity,
                          height: 4,
                          borderRadius: 4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const ShimmerBox(width: 30, height: 11),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const ShimmerBox(width: 20, height: 20, borderRadius: 10),
          ],
        ),
      ),
    );
  }
}

/// Dashboard Active-Roadmap skeleton — matches compact roadmap card with
/// icon, title, percentage, progress bar and quest count text.
class ActiveRoadmapSkeleton extends StatelessWidget {
  const ActiveRoadmapSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row: icon + title + percentage + chevron
            Row(
              children: [
                const ShimmerBox(width: 18, height: 18, borderRadius: 4),
                const SizedBox(width: 8),
                Expanded(
                  child: ShimmerBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: 14,
                  ),
                ),
                const SizedBox(width: 8),
                const ShimmerBox(width: 32, height: 13),
                const SizedBox(width: 4),
                const ShimmerBox(width: 18, height: 18, borderRadius: 9),
              ],
            ),
            const SizedBox(height: 10),
            // Progress bar
            const ShimmerBox(
              width: double.infinity,
              height: 6,
              borderRadius: 4,
            ),
            const SizedBox(height: 6),
            // Quest count
            const ShimmerBox(width: 90, height: 11),
          ],
        ),
      ),
    );
  }
}

/// Dashboard Hero Card skeleton — matches the welcome card with avatar
class HeroCardSkeleton extends StatelessWidget {
  const HeroCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 8, 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification bell placeholder
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [ShimmerBox(width: 36, height: 36, borderRadius: 18)],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: greeting + name + streak
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(
                        width: MediaQuery.of(context).size.width * 0.35,
                        height: 13,
                        margin: const EdgeInsets.only(bottom: 4),
                      ),
                      ShimmerBox(
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: 27,
                        margin: const EdgeInsets.only(bottom: 10),
                      ),
                      // Streak badge + weekly dots
                      Row(
                        children: [
                          const ShimmerBox(
                            width: 80,
                            height: 24,
                            borderRadius: 20,
                          ),
                          const SizedBox(width: 10),
                          ...List.generate(
                            7,
                            (_) => const Padding(
                              padding: EdgeInsets.only(right: 5),
                              child: ShimmerBox(
                                width: 10,
                                height: 10,
                                borderRadius: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Check-in button
                      const ShimmerBox(
                        width: 110,
                        height: 30,
                        borderRadius: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Right: Meowl avatar
                const ShimmerBox(width: 92, height: 92, borderRadius: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Dashboard Quick Actions skeleton — matches 4-column GridView with 8 cells.
/// Each cell has a 36×36 rounded-rect icon box + a small text label below.
class QuickActionsSkeleton extends StatelessWidget {
  const QuickActionsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title placeholder
          const ShimmerBox(width: 100, height: 14),
          const SizedBox(height: 12),
          // 4-column grid, 2 rows = 8 cells (default visible count)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemCount: 8,
            itemBuilder: (_, __) => Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShimmerBox(width: 36, height: 36, borderRadius: 10),
                  SizedBox(height: 6),
                  ShimmerBox(width: 36, height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashboard Stats Grid skeleton — matches 2×2 stat cards with
/// 40×40 icon + value + label in a Row layout per card.
class StatsGridSkeleton extends StatelessWidget {
  const StatsGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
        ),
        itemCount: 4,
        itemBuilder: (_, __) => _buildStatCell(context),
      ),
    );
  }

  Widget _buildStatCell(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: const Row(
        children: [
          ShimmerBox(width: 40, height: 40, borderRadius: 10),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShimmerBox(width: 36, height: 22),
                SizedBox(height: 3),
                ShimmerBox(width: 60, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Notification tile skeleton — matches _NotificationTile in notification_page.dart
/// Layout: Row( 44px avatar + Column(title, message, time) + unread dot )
class NotificationSkeleton extends StatelessWidget {
  const NotificationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            const ShimmerBox(width: 44, height: 44, borderRadius: 22),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: 13,
                    margin: const EdgeInsets.only(bottom: 4),
                  ),
                  const ShimmerBox(
                    width: double.infinity,
                    height: 12,
                    margin: EdgeInsets.only(bottom: 4),
                  ),
                  ShimmerBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: 12,
                    margin: const EdgeInsets.only(bottom: 4),
                  ),
                  const ShimmerBox(width: 60, height: 11),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Unread dot
            const ShimmerBox(width: 8, height: 8, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}

/// Group card skeleton — matches _GroupCard in community_groups_page.dart
/// Layout: Row( 56px avatar + Column(name, members row) + chevron icon )
class GroupCardSkeleton extends StatelessWidget {
  const GroupCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            // Group avatar
            const ShimmerBox(width: 56, height: 56, borderRadius: 28),
            const SizedBox(width: 14),
            // Group info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(
                    width: MediaQuery.of(context).size.width * 0.45,
                    height: 15,
                    margin: const EdgeInsets.only(bottom: 6),
                  ),
                  const Row(
                    children: [
                      ShimmerBox(width: 14, height: 14, borderRadius: 2),
                      SizedBox(width: 4),
                      ShimmerBox(width: 80, height: 12),
                      SizedBox(width: 8),
                      ShimmerBox(width: 90, height: 12),
                    ],
                  ),
                ],
              ),
            ),
            // Chevron
            const ShimmerBox(width: 24, height: 24, borderRadius: 12),
          ],
        ),
      ),
    );
  }
}
