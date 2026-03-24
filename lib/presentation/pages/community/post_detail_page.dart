import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/post_provider.dart';
import '../../providers/comment_provider.dart';

import '../../widgets/skeleton_loaders.dart';
import '../../widgets/glass_card.dart';
import '../../../data/models/post_models.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/html_helper.dart';
import '../../themes/app_theme.dart';
import '../../widgets/skillverse_app_bar.dart';

class PostDetailPage extends StatefulWidget {
  final int postId;

  const PostDetailPage({super.key, required this.postId});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Post? _post;
  bool _isLoadingPost = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPost();
      final commentProvider = context.read<CommentProvider>();
      commentProvider.loadComments(widget.postId);

      // Pagination for comments
      _scrollController.addListener(() {
        if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
          if (!commentProvider.isLoadingMore && commentProvider.hasMorePages) {
            commentProvider.loadNextPage();
          }
        }
      });
    });
  }

  Future<void> _loadPost() async {
    setState(() => _isLoadingPost = true);
    try {
      final postProvider = context.read<PostProvider>();
      // Get from list if available, otherwise fetch from API
      final post = postProvider.posts.firstWhere(
        (p) => p.id == widget.postId,
        orElse: () => Post(
          id: widget.postId,
          content: '',
          status: PostStatus.published,
          authorId: 0,
          createdAt: DateTime.now(),
        ),
      );
      setState(() {
        _post = post;
        _isLoadingPost = false;
      });
    } catch (e) {
      setState(() => _isLoadingPost = false);
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SkillVerseAppBar(
        title: 'Chi tiết bài viết',
        actions: [
          if (_post != null)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  context.push('/community/${widget.postId}/edit');
                } else if (value == 'delete') {
                  _showDeleteDialog();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('Chỉnh sửa'),
                    ],
                  ),
                ),
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
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadPost();
          await context.read<CommentProvider>().refresh();
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post content
              _buildPostContent(),

              const SizedBox(height: 24),

              // Comments section
              _buildCommentsSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildCommentInput(),
    );
  }

  Widget _buildPostContent() {
    if (_isLoadingPost) {
      return const PostCardSkeleton();
    }

    if (_post == null) {
      return const GlassCard(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('Không tìm thấy bài viết')),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author info
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.themeOrangeStart,
                child: _post!.authorAvatar != null
                    ? ClipOval(
                        child: Image.network(
                          _post!.authorAvatar!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                        ),
                      )
                    : _buildDefaultAvatar(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _post!.authorName ?? 'Unknown',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      DateTimeHelper.formatSmart(_post!.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Title
          if (_post!.title != null && _post!.title!.isNotEmpty) ...[
            Text(
              HtmlHelper.cleanHtml(_post!.title!),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
          ],

          // Content
          Text(
            HtmlHelper.cleanHtml(_post!.content),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),

          // Action buttons
          Consumer<PostProvider>(
            builder: (context, provider, child) {
              final post = provider.posts.firstWhere(
                (p) => p.id == widget.postId,
                orElse: () => _post!,
              );

              return Row(
                children: [
                  _buildActionButton(
                    icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                    label: _formatCount(post.likeCount),
                    color: post.isLiked ? Colors.red : null,
                    onTap: () => provider.toggleLike(widget.postId),
                  ),
                  const SizedBox(width: 20),
                  _buildActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: _formatCount(post.commentCount),
                  ),
                  const Spacer(),
                  _buildActionButton(
                    icon: post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                    label: '',
                    color: post.isSaved ? AppTheme.themeOrangeStart : null,
                    onTap: () => provider.toggleSave(widget.postId),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Text(
      _post?.authorName?.isNotEmpty == true
          ? _post!.authorName![0].toUpperCase()
          : 'U',
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bình luận',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        Consumer<CommentProvider>(
          builder: (context, provider, child) {
            if (provider.isInitialLoading) {
              return Column(
                children: List.generate(3, (index) => const CommentSkeleton()),
              );
            }

            if (provider.paginationError != null && provider.isEmpty) {
              return GlassCard(
                padding: const EdgeInsets.all(16),
                child: Text(
                  provider.paginationError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              );
            }

            if (provider.isEmpty) {
              return const GlassCard(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('Chưa có bình luận nào. Hãy là người đầu tiên!'),
                ),
              );
            }

            return Column(
              children: [
                ...provider.comments.map(
                  (comment) => _buildCommentCard(comment),
                ),
                if (provider.isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCommentCard(Comment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.themeOrangeStart,
            child: comment.authorAvatar != null
                ? ClipOval(
                    child: Image.network(
                      comment.authorAvatar!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Text(
                        comment.authorName?.isNotEmpty == true
                            ? comment.authorName![0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : Text(
                    comment.authorName?.isNotEmpty == true
                        ? comment.authorName![0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          comment.authorName ?? 'Unknown',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateTimeHelper.formatRelativeTime(comment.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    comment.content,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Viết bình luận...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submitComment(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _submitComment,
              icon: const Icon(Icons.send),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.themeOrangeStart,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final provider = context.read<CommentProvider>();
    _commentController.clear();

    try {
      await provider.addComment(widget.postId, content);
      // Update comment count in post
      final postProvider = context.read<PostProvider>();
      final postIndex = postProvider.posts.indexWhere(
        (p) => p.id == widget.postId,
      );
      if (postIndex != -1) {
        final post = postProvider.posts[postIndex];
        postProvider.posts[postIndex] = post.copyWith(
          commentCount: post.commentCount + 1,
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bài viết'),
        content: const Text('Bạn có chắc chắn muốn xóa bài viết này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<PostProvider>().deletePost(widget.postId);
                if (mounted) {
                  context.pop();
                  ErrorHandler.showSuccessSnackBar(context, 'Đã xóa bài viết');
                }
              } catch (e) {
                if (mounted) {
                  ErrorHandler.showErrorSnackBar(context, e);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
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
            Icon(icon, size: 20, color: color),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: color)),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count == 0) return '0';
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}
