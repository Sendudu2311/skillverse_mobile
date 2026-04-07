import 'package:flutter/material.dart';
import '../../widgets/skeleton_loaders.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/enrollment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/glass_card.dart';
import '../../../data/models/enrollment_models.dart';
import '../../themes/app_theme.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/animated_list_item.dart';

class MyCoursesPage extends StatefulWidget {
  const MyCoursesPage({super.key});

  @override
  State<MyCoursesPage> createState() => _MyCoursesPageState();
}

class _MyCoursesPageState extends State<MyCoursesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEnrollments();
    });
  }

  Future<void> _loadEnrollments() async {
    final authProvider = context.read<AuthProvider>();
    final enrollmentProvider = context.read<EnrollmentProvider>();

    if (authProvider.user != null) {
      await enrollmentProvider.fetchUserEnrollments(
        userId: authProvider.user!.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: SkillVerseAppBar(title: 'Khóa học của tôi', centerTitle: true),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.galaxyDarkest, AppTheme.galaxyDark],
                )
              : null,
          color: isDark ? null : AppTheme.lightBackgroundPrimary,
        ),
        child: SafeArea(
          child: Consumer<EnrollmentProvider>(
            builder: (context, enrollmentProvider, child) {
              if (enrollmentProvider.isLoading) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 3,
                  itemBuilder: (_, __) =>
                      const CardSkeleton(imageHeight: null, hasFooter: false),
                );
              }

              if (enrollmentProvider.errorMessage != null) {
                return ErrorStateWidget(
                  message: enrollmentProvider.errorMessage!,
                  onRetry: _loadEnrollments,
                );
              }

              if (enrollmentProvider.enrollments.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.school_outlined,
                  title: 'Chưa đăng ký khóa học nào',
                  subtitle: 'Khám phá và đăng ký khóa học để bắt đầu học',
                  ctaLabel: 'Khám phá khóa học',
                  onCtaPressed: () => context.go('/courses'),
                  iconGradient: AppTheme.blueGradient,
                );
              }

              return RefreshIndicator(
                onRefresh: _loadEnrollments,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: enrollmentProvider.enrollments.length,
                  itemBuilder: (context, index) {
                    final enrollment = enrollmentProvider.enrollments[index];
                    return AnimatedListItem(
                      index: index,
                      child: _buildEnrolledCourseCard(
                        context,
                        enrollment,
                        isDark,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEnrolledCourseCard(
    BuildContext context,
    EnrollmentDetailDto enrollment,
    bool isDark,
  ) {
    final progress = enrollment.progressPercent;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.zero,
      backgroundColor: isDark ? null : Colors.white,
      borderColor: isDark ? null : AppTheme.lightBorderColor,
      child: InkWell(
        onTap: () => context.push('/courses/${enrollment.courseId}/learn'),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    enrollment.courseTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: isDark
                          ? Colors.white10
                          : Colors.grey.shade200,
                      color: progress >= 100
                          ? AppTheme.successColor
                          : AppTheme.themeOrangeStart,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Progress Text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$progress% hoàn thành',
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                      if (progress >= 100)
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: AppTheme.successColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Đã hoàn thành',
                              style: TextStyle(
                                color: AppTheme.successColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
