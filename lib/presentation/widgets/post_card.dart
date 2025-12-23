import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/post_models.dart';
import '../themes/app_theme.dart';
import '../../core/utils/date_time_helper.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onLike;
  final VoidCallback? onSave;
  final VoidCallback? onComment;
  final VoidCallback? onDelete;

  const PostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onSave,
    this.onComment,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.push('/community/${post.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author header
              _buildAuthorHeader(context),

              const SizedBox(height: 12),

              // Post title (if available)
              if (post.title != null && post.title!.isNotEmpty) ...[
                Text(
                  post.title!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],

              // Post content preview
              Text(
                post.content,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),

              // Thumbnail
              if (post.thumbnailUrl != null &&
                  post.thumbnailUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    post.thumbnailUrl!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ],

              // Tags
              if (post.tags != null && post.tags!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: post.tags!
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '#$tag',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],

              const SizedBox(height: 16),

              // Action buttons
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthorHeader(BuildContext context) {
    return Row(
      children: [
        // Author avatar
        CircleAvatar(
          radius: 20,
          backgroundColor: AppTheme.themeOrangeStart,
          child: post.authorAvatar != null
              ? ClipOval(
                  child: Image.network(
                    post.authorAvatar!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                  ),
                )
              : _buildDefaultAvatar(),
        ),

        const SizedBox(width: 12),

        // Author info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.authorName ?? 'Unknown',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                DateTimeHelper.formatRelativeTime(post.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
        ),

        // More options menu
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete' && onDelete != null) {
              onDelete!();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.flag_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Báo cáo'),
                ],
              ),
            ),
            if (onDelete != null)
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: AppTheme.errorColor,
                    ),
                    SizedBox(width: 12),
                    Text('Xóa', style: TextStyle(color: AppTheme.errorColor)),
                  ],
                ),
              ),
          ],
          icon: const Icon(Icons.more_vert),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Text(
      post.authorName?.isNotEmpty == true
          ? post.authorName![0].toUpperCase()
          : 'U',
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Like button
        _buildActionButton(
          context,
          icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
          label: _formatCount(post.likeCount),
          color: post.isLiked ? Colors.red : null,
          onTap: onLike,
        ),

        const SizedBox(width: 16),

        // Comment button
        _buildActionButton(
          context,
          icon: Icons.chat_bubble_outline,
          label: _formatCount(post.commentCount),
          onTap: onComment ?? () => context.push('/community/${post.id}'),
        ),

        const Spacer(),

        // Save button
        _buildActionButton(
          context,
          icon: post.isSaved ? Icons.bookmark : Icons.bookmark_border,
          label: '',
          color: post.isSaved ? AppTheme.themeOrangeStart : null,
          onTap: onSave,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: color ?? Theme.of(context).iconTheme.color,
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: color),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count == 0) return '';
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}
