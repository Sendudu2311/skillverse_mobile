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

/// Job card skeleton
class JobCardSkeleton extends StatelessWidget {
  const JobCardSkeleton({super.key});

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
            Row(
              children: [
                const ShimmerBox(width: 56, height: 56, borderRadius: 12),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ShimmerBox(
                        width: double.infinity,
                        height: 18,
                        margin: EdgeInsets.only(bottom: 6),
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
            const SizedBox(height: 12),
            Row(
              children: [
                const ShimmerBox(width: 100, height: 14),
                const SizedBox(width: 16),
                const ShimmerBox(width: 80, height: 14),
              ],
            ),
            const SizedBox(height: 12),
            ShimmerBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: 14,
              margin: const EdgeInsets.only(bottom: 4),
            ),
            ShimmerBox(
              width: MediaQuery.of(context).size.width * 0.7,
              height: 14,
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

/// Post card skeleton (for community/social feed)
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
              ],
            ),
            const SizedBox(height: 16),

            // Post content
            const ShimmerBox(
              width: double.infinity,
              height: 16,
              margin: EdgeInsets.only(bottom: 8),
            ),
            const ShimmerBox(
              width: double.infinity,
              height: 14,
              margin: EdgeInsets.only(bottom: 8),
            ),
            ShimmerBox(
              width: MediaQuery.of(context).size.width * 0.6,
              height: 14,
              margin: const EdgeInsets.only(bottom: 16),
            ),

            // Action buttons
            Row(
              children: [
                const ShimmerBox(width: 60, height: 32, borderRadius: 16),
                const SizedBox(width: 12),
                const ShimmerBox(width: 60, height: 32, borderRadius: 16),
                const SizedBox(width: 12),
                const ShimmerBox(width: 60, height: 32, borderRadius: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
