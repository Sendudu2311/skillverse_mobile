import 'package:flutter/material.dart';
import '../../../data/services/group_chat_service.dart';
import '../../../core/utils/error_handler.dart';
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
import '../../widgets/status_badge.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../../data/services/certificate_service.dart';
import 'certificate_view_page.dart';

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
                  itemBuilder: (_, __) => const CourseCardSkeleton(),
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

              // Separate completed and in-progress courses
              final inProgress = enrollmentProvider.enrollments
                  .where((e) => !e.completed)
                  .toList();
              final completed = enrollmentProvider.enrollments
                  .where((e) => e.completed)
                  .toList();

              return RefreshIndicator(
                onRefresh: _loadEnrollments,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Summary stats row
                    _buildStatsRow(enrollmentProvider.enrollments, isDark),
                    const SizedBox(height: 20),

                    // In-progress section
                    if (inProgress.isNotEmpty) ...[
                      _buildSectionHeader(
                        context,
                        icon: Icons.play_circle_outline,
                        title: 'Đang học',
                        count: inProgress.length,
                        color: AppTheme.themeBlueStart,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      ...inProgress.asMap().entries.map((entry) {
                        return AnimatedListItem(
                          index: entry.key,
                          child: _buildEnrolledCourseCard(
                            context,
                            entry.value,
                            isDark,
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                    ],

                    // Completed section
                    if (completed.isNotEmpty) ...[
                      _buildSectionHeader(
                        context,
                        icon: Icons.emoji_events_outlined,
                        title: 'Đã hoàn thành',
                        count: completed.length,
                        color: AppTheme.successColor,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      ...completed.asMap().entries.map((entry) {
                        return AnimatedListItem(
                          index: entry.key + inProgress.length,
                          child: _buildEnrolledCourseCard(
                            context,
                            entry.value,
                            isDark,
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Stats Row ──────────────────────────────────────────────────────────────

  Widget _buildStatsRow(List<EnrollmentDetailDto> enrollments, bool isDark) {
    final total = enrollments.length;
    final completedCount = enrollments.where((e) => e.completed).length;
    final inProgressCount = total - completedCount;
    final avgProgress = enrollments.isEmpty
        ? 0
        : (enrollments.fold<int>(0, (sum, e) => sum + e.progressPercent) / total)
            .round();

    return Row(
      children: [
        Expanded(
          child: _buildMiniStat(
            icon: Icons.menu_book_outlined,
            value: '$total',
            label: 'Tổng',
            colors: [AppTheme.themeBlueStart, AppTheme.themeBlueEnd],
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMiniStat(
            icon: Icons.trending_up,
            value: '$inProgressCount',
            label: 'Đang học',
            colors: [AppTheme.themeOrangeStart, AppTheme.themeOrangeEnd],
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMiniStat(
            icon: Icons.check_circle_outline,
            value: '$completedCount',
            label: 'Hoàn thành',
            colors: [AppTheme.themeGreenStart, AppTheme.themeGreenEnd],
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMiniStat(
            icon: Icons.speed,
            value: '$avgProgress%',
            label: 'TB',
            colors: [AppTheme.themePurpleStart, AppTheme.themePurpleEnd],
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String value,
    required String label,
    required List<Color> colors,
    required bool isDark,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: colors),
              boxShadow: [
                BoxShadow(
                  color: colors.first.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Header ─────────────────────────────────────────────────────────

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int count,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
  // ── Certificate Navigation ──────────────────────────────────────────────────

  Future<void> _viewCertificate(
    BuildContext context,
    EnrollmentDetailDto enrollment,
  ) async {
    final certService = CertificateService();
    final certId = await certService.getCertificateIdByCourse(
      courseId: enrollment.courseId,
      courseTitle: enrollment.courseTitle,
    );

    if (!mounted) return;

    if (certId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CertificateViewPage(certificateId: certId),
        ),
      );
    } else {
      ErrorHandler.showWarningSnackBar(
        context,
        'Chưa có chứng chỉ cho khóa học này.',
      );
    }
  }

  // ── Group Chat Navigation ──────────────────────────────────────────────────

  Future<void> _openGroupChat(BuildContext ctx, int courseId) async {
    final authProvider = ctx.read<AuthProvider>();
    if (authProvider.user == null) return;

    try {
      final courseGroup = await GroupChatService().getGroupByCourse(
        courseId,
        authProvider.user!.id,
      );

      if (!mounted) return;

      if (courseGroup != null) {
        if (!courseGroup.isMember) {
          await GroupChatService().joinGroup(courseGroup.id, authProvider.user!.id);
        }
        ctx.push('/group-chat/${courseGroup.id}');
      } else {
        ErrorHandler.showWarningSnackBar(ctx, 'Khóa học này chưa có nhóm chat');
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(ctx, 'Không thể mở nhóm chat');
    }
  }

  // ── Course Card ────────────────────────────────────────────────────────────

  Widget _buildEnrolledCourseCard(
    BuildContext context,
    EnrollmentDetailDto enrollment,
    bool isDark,
  ) {
    final progress = enrollment.progressPercent;
    final isCompleted = enrollment.completed;
    
    // Unified brand styling for all courses
    final gradientColors = [const Color(0xFF6366F1), const Color(0xFF818CF8)];
    const courseIcon = Icons.school_outlined;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.zero,
      backgroundColor: isDark ? null : Colors.white,
      borderColor: isDark ? null : AppTheme.lightBorderColor,
      onTap: () => context.push('/courses/${enrollment.courseId}/learn'),
      child: Row(
          children: [
            // Left: Gradient icon box
            Container(
              width: 90,
              height: 110,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background pattern circles
                  Positioned(
                    top: -10,
                    right: -10,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -15,
                    left: -15,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  // Main Icon
                  Icon(courseIcon, color: Colors.white, size: 36),
                  // Progress overlay at bottom
                  if (!isCompleted)
                    Positioned(
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$progress%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  // Completed checkmark
                  if (isCompleted)
                    Positioned(
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.successColor,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Right: Info section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    Text(
                      enrollment.courseTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Date + Status badge row
                    Row(
                      children: [
                        if (enrollment.enrolledAt != null) ...[
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateTimeHelper.formatShortDate(enrollment.enrolledAt!),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        StatusBadge(status: enrollment.status),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.grey.shade200,
                        color: isCompleted
                            ? AppTheme.successColor
                            : gradientColors.first,
                        minHeight: 5,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Bottom row: progress text + action buttons
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runSpacing: 8,
                        children: [
                          Text(
                            isCompleted
                                ? 'Đã hoàn thành'
                                : '$progress% hoàn thành',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w400,
                              color: isCompleted
                                  ? AppTheme.successColor
                                  : isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary,
                            ),
                          ),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              // Group Chat button
                              GestureDetector(
                                onTap: () => _openGroupChat(context, enrollment.courseId),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlueDark.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme.primaryBlueDark.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.groups_outlined,
                                        size: 12,
                                        color: AppTheme.primaryBlueDark,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Chat',
                                        style: TextStyle(
                                          color: AppTheme.primaryBlueDark,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (isCompleted)
                                GestureDetector(
                                  onTap: () => _viewCertificate(context, enrollment),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.successColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppTheme.successColor.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.workspace_premium,
                                          size: 12,
                                          color: AppTheme.successColor,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          'Chứng chỉ',
                                          style: TextStyle(
                                            color: AppTheme.successColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: gradientColors),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: gradientColors.first.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  isCompleted ? 'Xem lại' : 'Tiếp tục',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }
}
