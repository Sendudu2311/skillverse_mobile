import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/post_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/post_card.dart';
import '../../widgets/skeleton_loaders.dart';
import '../../widgets/empty_state_widget.dart';
import 'widgets/community_stats_widget.dart';
import '../../themes/app_theme.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // all, my_posts, saved

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PostProvider>();
      provider.reset();
      provider.loadPosts();
      provider.fetchStatsAndTrends(); // Fetch stats and trends on init

      // Add pagination listener
      _scrollController.addListener(() {
        if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
          if (!provider.isLoadingMore && provider.hasMorePages) {
            provider.loadNextPage();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(),

          // Filter chips
          _buildFilterChips(),

          // Post list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                final provider = context.read<PostProvider>();
                await provider.refresh();
              },
              child: Consumer<PostProvider>(
                builder: (context, provider, child) {
                  return _buildPostList(provider);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/community/create'),
        backgroundColor: AppTheme.themeOrangeStart,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm bài viết...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<PostProvider>().searchPosts('');
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
        onSubmitted: (value) {
          context.read<PostProvider>().searchPosts(value);
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'Tất cả',
            value: 'all',
            icon: Icons.dashboard_outlined,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Thảo luận',
            value: 'discussion',
            icon: Icons.forum_outlined,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Mẹo hay',
            value: 'tips',
            icon: Icons.lightbulb_outline,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Tin tức',
            value: 'news',
            icon: Icons.newspaper_outlined,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Đã lưu',
            value: 'saved',
            icon: Icons.bookmark_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _selectedFilter == value;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 4), Text(label)],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });

        final provider = context.read<PostProvider>();
        switch (value) {
          case 'all':
            provider.clearFilters();
            break;
          case 'discussion':
          case 'tips':
          case 'news':
            provider.filterByCategory(value);
            break;
          case 'saved':
            provider.showSavedPosts();
            break;
        }
      },
      selectedColor: AppTheme.themeOrangeStart.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.themeOrangeStart,
    );
  }

  Widget _buildPostList(PostProvider provider) {
    // Show skeleton during initial load or refresh
    if (provider.isInitialLoading || provider.pagination.isRefreshing) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => const PostCardSkeleton(),
      );
    }

    // Error state
    if (provider.paginationError != null && provider.isEmpty) {
      return Center(
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                provider.paginationError!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => provider.refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (provider.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.forum_outlined,
        title: 'Chưa có bài viết nào',
        subtitle: 'Hãy tạo bài viết đầu tiên!',
        iconGradient: AppTheme.blueGradient,
      );
    }

    // Post list with loading more indicator
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 80), // Padding for FAB
      itemCount: provider.posts.length + (provider.isLoadingMore ? 1 : 0) + 1,
      itemBuilder: (context, index) {
        // Header (Stats & Trends)
        if (index == 0) {
          return CommunityStatsWidget(
            stats: provider.stats,
            trends: provider.trends,
            isLoading: provider.isLoadingStats,
          );
        }

        final postIndex = index - 1;

        // Loading more indicator
        if (postIndex == provider.posts.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final post = provider.posts[postIndex];
        return PostCard(
          post: post,
          onLike: () => provider.toggleLike(post.id),
          onSave: () => provider.toggleSave(post.id),
          onComment: () => context.push('/community/${post.id}'),
          // Show delete option only for own posts (TODO: check auth)
          // onDelete: post.authorId == currentUserId
          //     ? () => _showDeleteDialog(provider, post.id)
          //     : null,
        );
      },
    );
  }
}
