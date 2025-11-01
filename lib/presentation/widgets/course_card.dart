import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/course_models.dart';

class CourseCard extends StatelessWidget {
  final CourseSummaryDto course;

  const CourseCard({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          context.push('/courses/${course.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Thumbnail
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[300],
                  image: course.thumbnailUrl != null
                      ? DecorationImage(
                          image: NetworkImage(course.thumbnailUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: course.thumbnailUrl == null
                    ? const Icon(Icons.book, size: 40, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 16),

              // Course Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      course.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Author
                    Text(
                      course.authorName ?? course.author.fullName ?? 'Unknown Author',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Rating and Enrollment
                    Row(
                      children: [
                        if (course.rating != null) ...[
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            course.rating!.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 16),
                        ],
                        const Icon(Icons.people, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${course.enrollmentCount}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Level and Price
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getLevelColor(course.level).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getLevelText(course.level),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _getLevelColor(course.level),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (course.price != null) ...[
                          Text(
                            '${course.price} ${course.currency ?? 'VNĐ'}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Miễn phí',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ],
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

  Color _getLevelColor(CourseLevel level) {
    switch (level) {
      case CourseLevel.beginner:
        return Colors.green;
      case CourseLevel.intermediate:
        return Colors.orange;
      case CourseLevel.advanced:
        return Colors.red;
    }
  }

  String _getLevelText(CourseLevel level) {
    switch (level) {
      case CourseLevel.beginner:
        return 'Cơ bản';
      case CourseLevel.intermediate:
        return 'Trung cấp';
      case CourseLevel.advanced:
        return 'Nâng cao';
    }
  }
}