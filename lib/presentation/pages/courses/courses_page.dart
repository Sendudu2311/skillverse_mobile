import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/course_provider.dart';
import '../../widgets/course_card.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/shimmer_loading.dart';
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

  @override
  void initState() {
    super.initState();

    // Load courses on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CourseProvider>();
      provider.loadCourses();

      // Add pagination listener for infinite scroll
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
    setState(() {
      _selectedLevel = level;
    });
    context.read<CourseProvider>().setLevelFilter(level);
  }

  Future<void> _onRefresh() async {
    await context.read<CourseProvider>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CourseProvider>(
      builder: (context, courseProvider, child) {
        return RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppTheme.themeOrangeStart,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm khóa học...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.6),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                                courseProvider.loadCourses(refresh: true);
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                      ),
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
                const SizedBox(height: 16),

                // Level Filters
                SizedBox(
                  height: 80,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildLevelChip(
                        context,
                        'Tất cả',
                        Icons.grid_view,
                        null,
                        [AppTheme.themeBlueStart, AppTheme.themeBlueEnd],
                      ),
                      _buildLevelChip(
                        context,
                        'Cơ bản',
                        Icons.school_outlined,
                        CourseLevel.beginner,
                        [AppTheme.themeGreenStart, AppTheme.themeGreenEnd],
                      ),
                      _buildLevelChip(
                        context,
                        'Trung cấp',
                        Icons.trending_up,
                        CourseLevel.intermediate,
                        [AppTheme.themeOrangeStart, AppTheme.themeOrangeEnd],
                      ),
                      _buildLevelChip(
                        context,
                        'Nâng cao',
                        Icons.workspace_premium,
                        CourseLevel.advanced,
                        [AppTheme.themePurpleStart, AppTheme.themePurpleEnd],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Header
                Text(
                  _searchQuery.isNotEmpty ? 'Kết quả tìm kiếm' : 'Khóa học đề xuất',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Course List
                _buildCourseList(courseProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLevelChip(
    BuildContext context,
    String label,
    IconData icon,
    CourseLevel? level,
    List<Color> gradientColors,
  ) {
    final isSelected = _selectedLevel == level;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _onLevelFilterChanged(level),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 150),
          tween: Tween(begin: 1.0, end: isSelected ? 1.05 : 1.0),
          curve: Curves.easeInOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: 100,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? gradientColors.first
                        : Theme.of(context).dividerColor,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: gradientColors.first.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).iconTheme.color,
                      size: 28,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).textTheme.bodySmall?.color,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 11,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCourseList(CourseProvider courseProvider) {
    // Initial loading state
    if (courseProvider.isInitialLoading) {
      return Column(
        children: List.generate(
          3,
          (index) => const CourseCardSkeleton(),
        ),
      );
    }

    // Error state (pagination error)
    if (courseProvider.paginationError != null && courseProvider.isEmpty) {
      return Center(
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                courseProvider.paginationError!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.themeBlueStart, AppTheme.themeBlueEnd],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  onPressed: () => courseProvider.refresh(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  child: const Text(
                    'Thử lại',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (courseProvider.isEmpty) {
      return Center(
        child: GlassCard(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Không tìm thấy khóa học',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
        ),
      );
    }

    // Course list with loading more indicator
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: courseProvider.courses.length,
          itemBuilder: (context, index) {
            final course = courseProvider.courses[index];
            return CourseCard(course: course, index: index);
          },
        ),

        // Loading more indicator
        if (courseProvider.isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: AppTheme.themeOrangeStart,
              ),
            ),
          ),

        // End of list indicator
        if (!courseProvider.hasMorePages && courseProvider.courses.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Đã hiển thị tất cả khóa học',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.darkTextSecondary,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}
