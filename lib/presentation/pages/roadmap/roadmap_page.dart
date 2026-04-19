import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/roadmap_provider.dart';
import '../../widgets/ai_roadmap_card.dart';
import '../../themes/app_theme.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../widgets/animated_list_item.dart';
import '../../../core/utils/error_handler.dart';
import 'package:go_router/go_router.dart';

class RoadmapPage extends StatefulWidget {
  const RoadmapPage({super.key});

  @override
  State<RoadmapPage> createState() => _RoadmapPageState();
}

class _RoadmapPageState extends State<RoadmapPage> {
  final TextEditingController _searchController = TextEditingController();
  int _listScope = 0; // 0 = learning, 1 = deleted

  @override
  void initState() {
    super.initState();

    // Reset filters and load fresh data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RoadmapProvider>();
      provider.clearFilters();
      _searchController.clear();
      provider.loadUserRoadmaps();
      provider.loadStatusCounts();
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

          // Scope tabs: Learning | Deleted
          _buildScopeTabs(context, isDark),

          // Search & Filters
          _buildSearchAndFilters(context, isDark),

          // Roadmap List
          Expanded(
            child: Consumer<RoadmapProvider>(
              builder: (context, provider, child) {
                // DELETED scope
                if (_listScope == 1) {
                  return _buildDeletedScopeContent(context, provider, isDark);
                }

                // LEARNING scope (default)
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
      floatingActionButton: _listScope == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/roadmap/generate'),
              icon: const Icon(Icons.add),
              label: const Text('Tạo lộ trình mới'),
            )
          : null,
    );
  }

  Widget _buildScopeTabs(BuildContext context, bool isDark) {
    return Consumer<RoadmapProvider>(
      builder: (context, provider, child) {
        final learningCount =
            (provider.statusCounts['active'] ?? 0) +
            (provider.statusCounts['paused'] ?? 0);
        final deletedCount = provider.statusCounts['deleted'] ?? 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.galaxyDark.withValues(alpha: 0.5)
                : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? AppTheme.darkBorderColor.withValues(alpha: 0.5)
                    : AppTheme.lightBorderColor,
              ),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppTheme.darkBorderColor : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildScopeItem(
                    0,
                    'Đang học',
                    learningCount,
                    Icons.school,
                    isDark,
                    provider,
                  ),
                ),
                Expanded(
                  child: _buildScopeItem(
                    1,
                    'Thùng rác',
                    deletedCount,
                    Icons.delete_sweep,
                    isDark,
                    provider,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScopeItem(
    int index,
    String label,
    int count,
    IconData icon,
    bool isDark,
    RoadmapProvider provider,
  ) {
    final isSelected = _listScope == index;

    return GestureDetector(
      onTap: () {
        setState(() => _listScope = index);
        if (index == 1) {
          provider.loadDeletedRoadmaps(force: true);
        }
        provider.loadStatusCounts();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? AppTheme.primaryBlue.withValues(alpha: 0.2)
                    : AppTheme.primaryBlue)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected && isDark
              ? Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.5),
                  width: 1.5,
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? (isDark ? AppTheme.primaryBlue : Colors.white)
                  : (isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? (isDark ? AppTheme.darkTextPrimary : Colors.white)
                    : (isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                            ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.3))
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.grey[300]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? (isDark ? AppTheme.primaryBlue : Colors.white)
                        : (isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeletedScopeContent(
    BuildContext context,
    RoadmapProvider provider,
    bool isDark,
  ) {
    if (provider.isLoadingDeleted) {
      return _buildLoadingState();
    }

    final deletedRoadmaps = provider.filteredDeletedRoadmaps;

    if (deletedRoadmaps.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.delete_sweep_outlined,
        title: 'Thùng rác trống',
        subtitle: 'Khi bạn xóa lộ trình, chúng sẽ xuất hiện tại đây',
        ctaLabel: 'Quay lại danh sách',
        onCtaPressed: () => setState(() => _listScope = 0),
        iconGradient: AppTheme.blueGradient,
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadDeletedRoadmaps(force: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: deletedRoadmaps.length,
        itemBuilder: (context, index) {
          final roadmap = deletedRoadmaps[index];
          return AnimatedListItem(
            index: index,
            child: AiRoadmapCard(
              roadmap: roadmap,
              isDeletedScope: true,
              onLifecycleAction: (action) =>
                  _handleDeletedScopeAction(context, action, roadmap.sessionId),
            ),
          );
        },
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
              AppSearchBar(
                controller: _searchController,
                hintText: 'Tìm kiếm lộ trình...',
                onChanged: provider.setSearchQuery,
                onClear: () => provider.setSearchQuery(''),
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
              onLifecycleAction: (action) =>
                  _handleLifecycleAction(context, action, roadmap.sessionId),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleLifecycleAction(
    BuildContext context,
    String action,
    int sessionId,
  ) async {
    final provider = context.read<RoadmapProvider>();
    bool success = false;
    String message = '';

    switch (action) {
      case 'activate':
        success = await provider.activateRoadmap(sessionId);
        message = success ? 'Đã kích hoạt lộ trình' : 'Lỗi kích hoạt lộ trình';
        break;
      case 'pause':
        success = await provider.pauseRoadmap(sessionId);
        message = success ? 'Đã tạm dừng lộ trình' : 'Lỗi tạm dừng lộ trình';
        break;
      case 'delete':
        success = await provider.softDeleteRoadmap(sessionId);
        message = success ? 'Đã xoá lộ trình' : 'Lỗi xoá lộ trình';
        break;
    }

    if (mounted) {
      if (success) {
        ErrorHandler.showSuccessSnackBar(context, message);
      } else {
        ErrorHandler.showErrorSnackBar(context, message);
      }
    }
  }

  void _navigateToGenerate(BuildContext context) {
    context.push('/roadmap/generate');
  }

  void _navigateToDetail(BuildContext context, int sessionId) {
    context.push('/roadmap/$sessionId');
  }

  Future<void> _handleDeletedScopeAction(
    BuildContext context,
    String action,
    int sessionId,
  ) async {
    final provider = context.read<RoadmapProvider>();
    final messenger = ScaffoldMessenger.of(context);

    switch (action) {
      case 'restore':
        final success = await provider.restoreRoadmap(sessionId);
        if (mounted) {
          if (success) {
            messenger.showSnackBar(SnackBar(
              content: const Text('Đã khôi phục lộ trình'),
              backgroundColor: Colors.green,
            ));
          } else {
            messenger.showSnackBar(SnackBar(
              content: const Text('Lỗi khôi phục lộ trình'),
              backgroundColor: Colors.red,
            ));
          }
        }
        break;
      case 'permanent_delete':
        _showPermanentDeleteDialog(context, sessionId);
        break;
    }
  }

  void _showPermanentDeleteDialog(BuildContext context, int sessionId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppTheme.galaxyMid : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.red,
          size: 40,
        ),
        title: Text(
          'Xóa vĩnh viễn?',
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Hành động này không thể hoàn tác. Toàn bộ dữ liệu liên quan sẽ bị xóa khỏi hệ thống.',
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Hủy',
              style: TextStyle(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final provider = context.read<RoadmapProvider>();
              final success = await provider.permanentDeleteRoadmap(sessionId);
              if (mounted) {
                if (success) {
                  ErrorHandler.showSuccessSnackBar(
                    context,
                    'Đã xóa vĩnh viễn lộ trình',
                  );
                } else {
                  ErrorHandler.showErrorSnackBar(context, 'Lỗi xóa vĩnh viễn');
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );
  }
}
