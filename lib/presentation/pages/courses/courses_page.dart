import 'package:flutter/material.dart';

class CoursesPage extends StatelessWidget {
  const CoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Section
          TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm khóa học...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  // TODO: Implement filter
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Categories Section
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
            
            // Recommended Courses
            Text(
              'Khóa học đề xuất',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            _buildCourseCard(
              context,
              'Full Stack Web Development với React & Node.js',
              'John Smith',
              4.8,
              120,
              '2,999,000 VNĐ',
              'Intermediate',
            ),
            
            const SizedBox(height: 16),
            
            _buildCourseCard(
              context,
              'Flutter Mobile App Development',
              'Sarah Johnson',
              4.9,
              85,
              '1,999,000 VNĐ',
              'Beginner',
            ),
            
            const SizedBox(height: 16),
            
            _buildCourseCard(
              context,
              'UI/UX Design với Figma',
              'Mike Chen',
              4.7,
              95,
              '1,499,000 VNĐ',
              'Beginner',
            ),
          ],
        ),
      );
    }

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

  Widget _buildCourseCard(
    BuildContext context,
    String title,
    String instructor,
    double rating,
    int students,
    String price,
    String level,
  ) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Image
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Icon(
              Icons.image,
              size: 64,
              color: Colors.grey,
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course Title
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 8),
                
                // Instructor
                Text(
                  'Giảng viên: $instructor',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Rating and Students
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.people, color: Colors.grey[600], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$students học viên',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Level and Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getLevelColor(level).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        level,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getLevelColor(level),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      price,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class CourseDetailPlaceholder extends StatelessWidget {
  final String courseId;

  const CourseDetailPlaceholder({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết khóa học $courseId'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.book, size: 64),
            const SizedBox(height: 16),
            Text('Chi tiết khóa học $courseId'),
            const Text('Coming Soon...'),
          ],
        ),
      ),
    );
  }
}