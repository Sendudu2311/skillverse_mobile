import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/roadmap_provider.dart';
import '../../widgets/ai_roadmap_card.dart';
import '../../themes/app_theme.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../widgets/animated_list_item.dart';
import 'package:go_router/go_router.dart';

class RoadmapPage extends StatefulWidget {
  const RoadmapPage({super.key});

  @override
  State<RoadmapPage> createState() => _RoadmapPageState();
}

class _RoadmapPageState extends State<RoadmapPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoadmapProvider>().loadUserRoadmaps();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: SkillVerseAppBar(
        title: 'NAVIGATION CONTROL',
        icon: Icons.satellite_alt,
        useGradientTitle: true,
        onBack: () => context.go('/dashboard'),
      ),
      body: Column(
        children: [
          // Description and Create Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? AppTheme.darkBorderColor
                      : AppTheme.lightBorderColor,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '>> ',
                  style: TextStyle(
                    color: AppTheme.primaryBlueDark,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Hệ thống định vị lộ trình học tập AI',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search & Filters
          _buildSearchAndFilters(context, isDark),

          // Roadmap List
          Expanded(
            child: Consumer<RoadmapProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return _buildLoadingState();
                }

                if (provider.errorMessage != null) {
                  return ErrorStateWidget(
                    message: provider.errorMessage!,
                    onRetry: () => provider.loadUserRoadmaps(),
                  );
                }

                final roadmaps = provider.filteredRoadmaps;

                if (roadmaps.isEmpty) {
                  return _buildEmptyState(context, isDark);
                }

                return _buildRoadmapList(context, roadmaps);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/roadmap/generate'),
        icon: const Icon(Icons.add),
        label: const Text('Tạo lộ trình mới'),
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, bool isDark) {
    return Consumer<RoadmapProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.darkCardBackground.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? AppTheme.darkBorderColor
                    : AppTheme.lightBorderColor,
              ),
              bottom: BorderSide(
                color: isDark
                    ? AppTheme.darkBorderColor
                    : AppTheme.lightBorderColor,
              ),
            ),
          ),
          child: Column(
            children: [
              // Search bar
              TextField(
                controller: _searchController,
                onChanged: (value) => provider.setSearchQuery(value),
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm lộ trình...',
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark
                        ? AppTheme.primaryBlueDark
                        : AppTheme.primaryBlue,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Filter row
              Row(
                children: [
                  // Experience filter
                  Expanded(
                    child: _buildFilterDropdown(
                      context,
                      icon: Icons.filter_list,
                      value: provider.filterExperience,
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('Tất cả cấp độ'),
                        ),
                        DropdownMenuItem(
                          value: 'beginner',
                          child: Text('Mới bắt đầu'),
                        ),
                        DropdownMenuItem(
                          value: 'intermediate',
                          child: Text('Trung cấp'),
                        ),
                        DropdownMenuItem(
                          value: 'advanced',
                          child: Text('Nâng cao'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) provider.setFilterExperience(value);
                      },
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Sort dropdown
                  Expanded(
                    child: _buildSortDropdown(context, provider, isDark),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterDropdown(
    BuildContext context, {
    required IconData icon,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? AppTheme.primaryBlueDark : AppTheme.primaryBlue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                items: items,
                onChanged: onChanged,
                isExpanded: true,
                dropdownColor: isDark ? AppTheme.galaxyMid : Colors.white,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortDropdown(
    BuildContext context,
    RoadmapProvider provider,
    bool isDark,
  ) {
    String getSortLabel(SortOption option) {
      switch (option) {
        case SortOption.newest:
          return 'Mới nhất';
        case SortOption.oldest:
          return 'Cũ nhất';
        case SortOption.progress:
          return 'Tiến độ';
        case SortOption.title:
          return 'Tiêu đề (A-Z)';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor,
        ),
      ),
      child: Row(
        children: [
          Text(
            'Sắp xếp:',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SortOption>(
                value: provider.sortBy,
                items: SortOption.values
                    .map(
                      (option) => DropdownMenuItem(
                        value: option,
                        child: Text(getSortLabel(option)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) provider.setSortBy(value);
                },
                isExpanded: true,
                dropdownColor: isDark ? AppTheme.galaxyMid : Colors.white,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      itemBuilder: (context, index) => const AiRoadmapCardSkeleton(),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final provider = context.read<RoadmapProvider>();
    final hasFilters =
        provider.searchQuery.isNotEmpty || provider.filterExperience != 'all';

    return EmptyStateWidget(
      icon: hasFilters ? Icons.search_off : Icons.map_outlined,
      title: hasFilters ? 'Không tìm thấy lộ trình' : 'Chưa có lộ trình nào',
      subtitle: hasFilters
          ? 'Thử điều chỉnh bộ lọc hoặc từ khóa tìm kiếm'
          : 'Bắt đầu hành trình học tập với lộ trình AI cá nhân hóa',
      ctaLabel: hasFilters ? 'Xóa bộ lọc' : 'Tạo lộ trình mới',
      onCtaPressed: () {
        if (hasFilters) {
          _searchController.clear();
          provider.clearFilters();
        } else {
          _navigateToGenerate(context);
        }
      },
      iconGradient: AppTheme.blueGradient,
    );
  }

  Widget _buildRoadmapList(BuildContext context, List roadmaps) {
    return RefreshIndicator(
      onRefresh: () => context.read<RoadmapProvider>().refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: roadmaps.length,
        itemBuilder: (context, index) {
          final roadmap = roadmaps[index];
          return AnimatedListItem(
            index: index,
            child: AiRoadmapCard(
              roadmap: roadmap,
              onTap: () => _navigateToDetail(context, roadmap.sessionId),
            ),
          );
        },
      ),
    );
  }

  void _navigateToGenerate(BuildContext context) {
    context.push('/roadmap/generate');
  }

  void _navigateToDetail(BuildContext context, int sessionId) {
    context.push('/roadmap/$sessionId');
  }
}
