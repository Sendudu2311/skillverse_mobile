import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/course_provider.dart';
import '../../widgets/course_card_v2.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/common_loading.dart';
import '../../themes/app_theme.dart';
import '../../../data/models/course_models.dart';
import '../../../core/utils/pagination_helper.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  CourseLevel? _selectedLevel;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CourseProvider>();
      provider.reset();
      provider.loadCourses();
      _scrollController.addPaginationListener(
        pagination: provider.pagination,
        onLoadMore: () => provider.loadNextPage(),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onLevelFilterChanged(CourseLevel? level) {
    setState(() => _selectedLevel = level);
    context.read<CourseProvider>().setLevelFilter(level);
  }

  Future<void> _onRefresh() async {
    await context.read<CourseProvider>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<CourseProvider>(
      builder: (context, courseProvider, child) {
        final totalCourses = courseProvider.pagination.totalItems;

        return RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppTheme.primaryBlueDark,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Sci-Fi Header
              SliverToBoxAdapter(child: _buildHeader(isDark, totalCourses)),

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _buildSearchBar(isDark, courseProvider),
                ),
              ),

              // Level Filters
              SliverToBoxAdapter(child: _buildLevelFilters(isDark)),

              // Results count
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Text(
                        'KẾT QUẢ: ',
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                          fontSize: 12,
                          fontFamily: 'monospace',
                          letterSpacing: 1,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlueDark.withValues(
                            alpha: 0.2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppTheme.primaryBlueDark.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Text(
                          '$totalCourses KHÓA HỌC',
                          style: const TextStyle(
                            color: AppTheme.primaryBlueDark,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Course Grid/List
              _buildCourseContent(courseProvider, isDark),

              // Bottom spacing
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark, int totalCourses) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main title
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppTheme.primaryBlueDark, AppTheme.secondaryPurple],
            ).createShader(bounds),
            child: const Text(
              'KHÁM PHÁ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'THIÊN HÀ TRI THỨC',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              // Module count badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.primaryBlueDark.withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'MODULES',
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                        fontSize: 8,
                        fontFamily: 'monospace',
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '$totalCourses',
                      style: const TextStyle(
                        color: AppTheme.primaryBlueDark,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'DATA UPGRADE MODULES',
            style: TextStyle(
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
              fontSize: 10,
              fontFamily: 'monospace',
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, CourseProvider courseProvider) {
    return Row(
      children: [
        // Search bar container
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? AppTheme.primaryBlueDark.withValues(alpha: 0.3)
                    : AppTheme.lightBorderColor,
              ),
            ),
            child: Row(
              children: [
                // Scan icon
                Container(
                  padding: const EdgeInsets.all(14),
                  child: Icon(
                    Icons.radar,
                    color: AppTheme.primaryBlueDark.withValues(alpha: 0.7),
                    size: 22,
                  ),
                ),
                // Search input
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'BẮT ĐẦU QUÉT DỮ LIỆU...',
                      hintStyle: TextStyle(
                        color: isDark
                            ? AppTheme.darkTextSecondary.withValues(alpha: 0.5)
                            : AppTheme.lightTextSecondary.withValues(
                                alpha: 0.5,
                              ),
                        fontSize: 13,
                        fontFamily: 'monospace',
                        letterSpacing: 1,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        courseProvider.searchCourses(value);
                      } else {
                        courseProvider.loadCourses(refresh: true);
                      }
                    },
                    textInputAction: TextInputAction.search,
                  ),
                ),
                // Clear button
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: AppTheme.darkTextSecondary,
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                      courseProvider.loadCourses(refresh: true);
                    },
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Filter button - outside search container
        Container(
          decoration: BoxDecoration(
            color: _showFilters
                ? AppTheme.primaryBlueDark.withValues(alpha: 0.2)
                : (isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.9)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? AppTheme.primaryBlueDark.withValues(alpha: 0.3)
                  : AppTheme.lightBorderColor,
            ),
          ),
          child: IconButton(
            icon: Icon(
              Icons.tune,
              color: _showFilters
                  ? AppTheme.primaryBlueDark
                  : (isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary),
              size: 20,
            ),
            onPressed: () {
              setState(() => _showFilters = !_showFilters);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLevelFilters(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _showFilters ? 100 : 0,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CẤP ĐỘ',
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                  fontSize: 10,
                  fontFamily: 'monospace',
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 60,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip('Tất cả', Icons.grid_view_rounded, null, [
                      AppTheme.themeBlueStart,
                      AppTheme.themeBlueEnd,
                    ], isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Cơ bản',
                      Icons.rocket_launch_outlined,
                      CourseLevel.beginner,
                      [AppTheme.themeGreenStart, AppTheme.themeGreenEnd],
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Trung cấp',
                      Icons.trending_up,
                      CourseLevel.intermediate,
                      [AppTheme.themeOrangeStart, AppTheme.themeOrangeEnd],
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Nâng cao',
                      Icons.auto_awesome,
                      CourseLevel.advanced,
                      [AppTheme.themePurpleStart, AppTheme.themePurpleEnd],
                      isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    IconData icon,
    CourseLevel? level,
    List<Color> colors,
    bool isDark,
  ) {
    final isSelected = _selectedLevel == level;

    return GestureDetector(
      onTap: () => _onLevelFilterChanged(level),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(colors: colors) : null,
          color: isSelected
              ? null
              : (isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.9)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? colors.first
                : (isDark
                      ? AppTheme.primaryBlueDark.withValues(alpha: 0.3)
                      : AppTheme.lightBorderColor),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.first.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : (isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary),
            ),
            const SizedBox(width: 8),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontFamily: 'monospace',
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseContent(CourseProvider courseProvider, bool isDark) {
    // Loading state
    if (courseProvider.isInitialLoading ||
        courseProvider.pagination.isRefreshing) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => const CourseCardSkeleton(),
            childCount: 6,
          ),
        ),
      );
    }

    // Error state
    if (courseProvider.paginationError != null && courseProvider.isEmpty) {
      return SliverFillRemaining(
        child: Center(child: _buildErrorState(courseProvider, isDark)),
      );
    }

    // Empty state
    if (courseProvider.isEmpty) {
      return SliverFillRemaining(
        child: Center(child: _buildEmptyState(isDark)),
      );
    }

    // Course grid
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            // Loading more indicator
            if (index == courseProvider.courses.length) {
              if (courseProvider.isLoadingMore) {
                return Center(
                  child: CommonLoading.small(color: AppTheme.primaryBlueDark),
                );
              }
              if (!courseProvider.hasMorePages) {
                return Center(
                  child: Text(
                    'ĐÃ HIỂN THỊ TẤT CẢ',
                    style: TextStyle(
                      color: AppTheme.darkTextSecondary,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }

            final course = courseProvider.courses[index];
            return CourseCardV2(
              course: course,
              onTap: () => context.push('/courses/${course.id}'),
            );
          },
          childCount:
              courseProvider.courses.length +
              (courseProvider.isLoadingMore || !courseProvider.hasMorePages
                  ? 1
                  : 0),
        ),
      ),
    );
  }

  Widget _buildErrorState(CourseProvider courseProvider, bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.errorColor.withValues(alpha: 0.1),
            ),
            child: const Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'LỖI KẾT NỐI',
            style: TextStyle(
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            courseProvider.paginationError!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 24),
          _buildRetryButton(courseProvider),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlueDark.withValues(alpha: 0.2),
                  AppTheme.secondaryPurple.withValues(alpha: 0.2),
                ],
              ),
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppTheme.primaryBlueDark.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'KHÔNG TÌM THẤY',
            style: TextStyle(
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Không có khóa học nào phù hợp\nvới bộ lọc hiện tại',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryButton(CourseProvider courseProvider) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.themeBlueStart, AppTheme.themeBlueEnd],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppTheme.themeBlueStart.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => courseProvider.refresh(),
          borderRadius: BorderRadius.circular(10),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'THỬ LẠI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
