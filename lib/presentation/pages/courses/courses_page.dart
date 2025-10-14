import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/course_provider.dart';
import '../../widgets/course_card.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load initial courses after the first frame is built to ensure context is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use listen: false if you are calling this inside initState.
      // However, addPostFrameCallback defers it, so read is fine.
      context.read<CourseProvider>().loadCourses();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer to listen to changes in CourseProvider and rebuild the UI
    return Consumer<CourseProvider>(
      builder: (context, courseProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ## Search Section ##
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm khóa học...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () {
                      // TODO: Implement filter functionality
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  if (value.isNotEmpty) {
                    courseProvider.searchCourses(value);
                  } else {
                    // Load all courses again if search is cleared
                    courseProvider.loadCourses(refresh: true);
                  }
                },
              ),
              const SizedBox(height: 16),

              // ## Categories Section ##
              Text(
                'Danh mục phổ biến',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildCategoryCard(context, 'Frontend', Icons.web, Colors.blue),
                    _buildCategoryCard(context, 'Backend', Icons.storage, Colors.green),
                    _buildCategoryCard(context, 'Mobile', Icons.phone_android, Colors.purple),
                    _buildCategoryCard(context, 'UI/UX', Icons.design_services, Colors.orange),
                    _buildCategoryCard(context, 'DevOps', Icons.settings, Colors.red),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ## Courses Section ##
              Text(
                _searchQuery.isNotEmpty ? 'Kết quả tìm kiếm' : 'Khóa học đề xuất',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // ## Conditional UI for Course List ##
              _buildCourseList(courseProvider),
            ],
          ),
        );
      },
    );
  }

  /// Builds the list of courses based on the provider's state.
  Widget _buildCourseList(CourseProvider courseProvider) {
    if (courseProvider.isLoading && courseProvider.courses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    } else if (courseProvider.error != null) {
      return Center(
        child: Column(
          children: [
            Text('Lỗi: ${courseProvider.error}'),
            ElevatedButton(
              onPressed: () => courseProvider.refresh(),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    } else if (courseProvider.courses.isEmpty) {
      return const Center(child: Text('Không có khóa học nào'));
    } else {
      return ListView.builder(
        shrinkWrap: true, // Important for ListView inside SingleChildScrollView
        physics: const NeverScrollableScrollPhysics(), // Disables ListView's own scrolling
        itemCount: courseProvider.courses.length + (courseProvider.hasMorePages ? 1 : 0),
        itemBuilder: (context, index) {
          // Check if it's the last item and if there are more pages to load
          if (index == courseProvider.courses.length) {
            // Request the next page
            courseProvider.loadCourses();
            // Show a loading indicator at the bottom
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final course = courseProvider.courses[index];
          // Assuming you have a CourseCard widget defined elsewhere
          return CourseCard(course: course);
        },
      );
    }
  }

  /// Helper widget for building category cards.
  Widget _buildCategoryCard(BuildContext context, String title, IconData icon, Color color) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}