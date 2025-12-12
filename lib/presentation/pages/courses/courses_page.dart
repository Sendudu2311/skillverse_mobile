import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/course_provider.dart';
import '../../widgets/course_card.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/shimmer_loading.dart';
import '../../themes/app_theme.dart';
import '../../../data/models/course_models.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  CourseLevel? _selectedLevel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadCourses();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onLevelFilterChanged(CourseLevel? level) {
    setState(() {
      _selectedLevel = level;
    });
    context.read<CourseProvider>().setLevelFilter(level);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CourseProvider>(
      builder: (context, courseProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
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
    if (courseProvider.isLoading && courseProvider.courses.isEmpty) {
      return Column(
        children: List.generate(
          3,
          (index) => const CourseCardSkeleton(),
        ),
      );
    } else if (courseProvider.error != null) {
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
                'Lỗi: ${courseProvider.error}',
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
    } else if (courseProvider.courses.isEmpty) {
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
    } else {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount:
            courseProvider.courses.length + (courseProvider.hasMorePages ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == courseProvider.courses.length) {
            courseProvider.loadCourses();
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final course = courseProvider.courses[index];
          return CourseCard(course: course, index: index);
        },
      );
    }
  }
}
