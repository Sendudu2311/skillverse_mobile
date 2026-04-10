import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/course_provider.dart';
import '../../providers/enrollment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/course_card_v3.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/common_loading.dart';
import '../../widgets/animated_list_item.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/selectable_chip_row.dart';
import '../../widgets/skeleton_loaders.dart';
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
  CourseLevel? _selectedLevel;
  String _sortBy = 'newest';

  final _sortOptions = const [
    {'value': 'newest', 'label': 'Mới nhất'},
    {'value': 'oldest', 'label': 'Cũ nhất'},
    {'value': 'price-low', 'label': 'Giá thấp → cao'},
    {'value': 'price-high', 'label': 'Giá cao → thấp'},
    {'value': 'popular', 'label': 'Phổ biến nhất'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final courseProvider = context.read<CourseProvider>();
      final enrollmentProvider = context.read<EnrollmentProvider>();

      // Only fetch from API if provider has no cached data yet
      if (courseProvider.isEmpty && !courseProvider.isInitialLoading) {
        courseProvider.loadCourses();
      }

      // Load enrollment data so cards show "Đã sở hữu" instead of price
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user != null &&
          enrollmentProvider.enrollments.isEmpty) {
        await enrollmentProvider.fetchUserEnrollments(
          userId: authProvider.user!.id,
        );
      }

      _scrollController.addPaginationListener(
        pagination: courseProvider.pagination,
        onLoadMore: () => courseProvider.loadNextPage(),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final courseProvider = context.read<CourseProvider>();
    final enrollmentProvider = context.read<EnrollmentProvider>();
    final authProvider = context.read<AuthProvider>();

    await courseProvider.refresh();
    if (authProvider.user != null) {
      await enrollmentProvider.fetchUserEnrollments(userId: authProvider.user!.id);
    }
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
              // Search Bar
              SliverToBoxAdapter(
                child: AppSearchBar(
                  controller: _searchController,
                  hintText: 'Tìm khóa học...',
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  onChanged: (_) {},
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      courseProvider.searchCourses(value);
                    } else {
                      courseProvider.loadCourses(refresh: true);
                    }
                  },
                  onClear: () => courseProvider.loadCourses(refresh: true),
                ),
              ),

              // Level Filters (always visible, horizontal scroll)
              SliverToBoxAdapter(
                child: SelectableChipRow(
                  labels: const ['Tất cả', 'Cơ bản', 'Trung cấp', 'Nâng cao'],
                  selectedIndex: _selectedLevel == null
                      ? 0
                      : CourseLevel.values.indexOf(_selectedLevel!) + 1,
                  onSelected: (i) {
                    final level = i == 0 ? null : CourseLevel.values[i - 1];
                    setState(() => _selectedLevel = level);
                    courseProvider.setLevelFilter(level);
                  },
                  gradients: const [
                    [AppTheme.themeBlueStart, AppTheme.themeBlueEnd],
                    [AppTheme.themeGreenStart, AppTheme.themeGreenEnd],
                    [AppTheme.themeBlueStart, Color(0xFF42A5F5)],
                    [AppTheme.themeOrangeStart, AppTheme.themeOrangeEnd],
                  ],
                ),
              ),

              // Results count + Sort
              SliverToBoxAdapter(child: _buildResultsBar(isDark, totalCourses)),

              // Course List / Loading / Error / Empty
              ..._buildCourseContent(courseProvider, isDark),

              // Bottom spacing
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      },
    );
  }

  // ─── Results Bar (count + sort) ────────────────────────────────
  Widget _buildResultsBar(bool isDark, int totalCourses) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Course count - prominent
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$totalCourses ',
                  style: TextStyle(
                    color: AppTheme.primaryBlueDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: 'khóa học',
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Sort dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppTheme.lightBorderColor,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortBy,
                isDense: true,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                  fontSize: 12,
                ),
                dropdownColor: isDark
                    ? AppTheme.darkCardBackground
                    : Colors.white,
                items: _sortOptions.map((opt) {
                  return DropdownMenuItem(
                    value: opt['value'],
                    child: Text(opt['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _sortBy = value);
                    // Map sort option to field + direction
                    final courseProvider = context.read<CourseProvider>();
                    switch (value) {
                      case 'newest':
                        courseProvider.setSortOrder('createdAt', 'desc');
                        break;
                      case 'oldest':
                        courseProvider.setSortOrder('createdAt', 'asc');
                        break;
                      case 'price-low':
                        courseProvider.setSortOrder('price', 'asc');
                        break;
                      case 'price-high':
                        courseProvider.setSortOrder('price', 'desc');
                        break;
                      case 'popular':
                        courseProvider.setSortOrder('enrollmentCount', 'desc');
                        break;
                    }
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Course Content (list / skeleton / error / empty) ──────────
  List<Widget> _buildCourseContent(CourseProvider courseProvider, bool isDark) {
    // Loading
    if (courseProvider.isInitialLoading ||
        courseProvider.pagination.isRefreshing) {
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, __) => const CardSkeleton(imageHeight: 120),
              childCount: 5,
            ),
          ),
        ),
      ];
    }

    // Error
    if (courseProvider.paginationError != null && courseProvider.isEmpty) {
      return [
        SliverFillRemaining(
          child: ErrorStateWidget(
            message: courseProvider.paginationError!,
            onRetry: () => courseProvider.refresh(),
          ),
        ),
      ];
    }

    // Empty
    if (courseProvider.isEmpty) {
      return [
        const SliverFillRemaining(
          child: EmptyStateWidget(
            icon: Icons.search_off_rounded,
            title: 'Không tìm thấy',
            subtitle: 'Không có khóa học nào phù hợp\nvới bộ lọc hiện tại',
            iconGradient: AppTheme.blueGradient,
          ),
        ),
      ];
    }

    // Course list
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final course = courseProvider.courses[index];
            final enrollmentProvider = context.watch<EnrollmentProvider>();
            final isEnrolled = enrollmentProvider.isEnrolled(course.id);
            return AnimatedListItem(
              index: index,
              child: CourseCardV3(
                course: course,
                isEnrolled: isEnrolled,
                onTap: () => context.push('/courses/${course.id}'),
              ),
            );
          }, childCount: courseProvider.courses.length),
        ),
      ),
      // Loading more indicator
      if (courseProvider.isLoadingMore)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CommonLoading.small(color: AppTheme.primaryBlueDark),
            ),
          ),
        ),
      // End of list
      if (!courseProvider.hasMorePages && !courseProvider.isLoadingMore)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Đã hiển thị tất cả',
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
    ];
  }
}
