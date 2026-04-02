import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/post_provider.dart';
import '../../widgets/post_card.dart';
import '../../widgets/skeleton_loaders.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/common_loading.dart';
import '../../widgets/selectable_chip_row.dart';
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
          AppSearchBar(
            controller: _searchController,
            hintText: 'Tìm kiếm bài viết...',
            padding: const EdgeInsets.all(16),
            onSubmitted: (v) => context.read<PostProvider>().searchPosts(v),
            onClear: () => context.read<PostProvider>().searchPosts(''),
          ),

          // Filter chips
          SelectableChipRow(
            labels: const ['Tất cả', 'Thảo luận', 'Mẹo hay', 'Tin tức', 'Đã lưu'],
            icons: const [
              Icons.dashboard_outlined,
              Icons.forum_outlined,
              Icons.lightbulb_outline,
              Icons.newspaper_outlined,
              Icons.bookmark_outline,
            ],
            selectedIndex: const ['all', 'discussion', 'tips', 'news', 'saved']
                .indexOf(_selectedFilter),
            onSelected: (i) {
              const keys = ['all', 'discussion', 'tips', 'news', 'saved'];
              final value = keys[i];
              setState(() => _selectedFilter = value);
              final provider = context.read<PostProvider>();
              switch (value) {
                case 'all':
                  provider.clearFilters();
                case 'discussion':
                case 'tips':
                case 'news':
                  provider.filterByCategory(value);
                case 'saved':
                  provider.showSavedPosts();
              }
            },
          ),

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
      return ErrorStateWidget(
        message: provider.paginationError!,
        onRetry: () => provider.refresh(),
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
          return Padding(
            padding: const EdgeInsets.all(16),
            child: CommonLoading.center(),
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
