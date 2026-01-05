import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/glass_card.dart';
import '../../themes/app_theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  late AnimationController _welcomeController;
  late AnimationController _statsController;
  late AnimationController _coursesController;

  late Animation<double> _welcomeSlideAnimation;
  late Animation<double> _welcomeFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Welcome section animation
    _welcomeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _welcomeSlideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _welcomeController, curve: Curves.easeOut),
    );
    _welcomeFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _welcomeController, curve: Curves.easeIn),
    );

    // Stats section animation
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Courses section animation
    _coursesController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Start animations sequentially
    _welcomeController.forward().then((_) {
      _statsController.forward();
      _coursesController.forward();
    });
  }

  @override
  void dispose() {
    _welcomeController.dispose();
    _statsController.dispose();
    _coursesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section with gradient and animation
              AnimatedBuilder(
                animation: _welcomeController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _welcomeSlideAnimation.value),
                    child: Opacity(
                      opacity: _welcomeFadeAnimation.value,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.themeBlueStart,
                              AppTheme.themeBlueEnd,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.themeBlueStart.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Xin chào,',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: Colors.white.withValues(
                                                alpha: 0.9,
                                              ),
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user?.fullName ?? 'Learner',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.waving_hand,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Hôm nay bạn muốn học gì?',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: Colors.white.withValues(
                                              alpha: 0.95,
                                            ),
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Stats Section
              Text(
                'Thống kê học tập',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Khóa học',
                      value: '3',
                      icon: Icons.book_outlined,
                      gradientColors: const [
                        AppTheme.themeBlueStart,
                        AppTheme.themeBlueEnd,
                      ],
                      onTap: () => context.go('/courses'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Hoàn thành',
                      value: '65%',
                      icon: Icons.trending_up_outlined,
                      gradientColors: const [
                        AppTheme.themeGreenStart,
                        AppTheme.themeGreenEnd,
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Streak',
                      value: '7',
                      icon: Icons.local_fire_department_outlined,
                      gradientColors: const [
                        AppTheme.themeOrangeStart,
                        AppTheme.themeOrangeEnd,
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Điểm',
                      value: '1,250',
                      icon: Icons.star_outline,
                      gradientColors: const [
                        AppTheme.themePurpleStart,
                        AppTheme.themePurpleEnd,
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Quick Actions Section
              Text(
                'Truy cập nhanh',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      'AI Roadmap',
                      Icons.map_outlined,
                      const [
                        AppTheme.themePurpleStart,
                        AppTheme.themePurpleEnd,
                      ],
                      () => context.push('/roadmap'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      'Khóa học',
                      Icons.school_outlined,
                      const [AppTheme.themeBlueStart, AppTheme.themeBlueEnd],
                      () => context.go('/courses'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      'AI Chat',
                      Icons.chat_bubble_outline,
                      const [AppTheme.themeGreenStart, AppTheme.themeGreenEnd],
                      () => context.go('/chat'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      'Cộng đồng',
                      Icons.people_outline,
                      const [
                        AppTheme.themeOrangeStart,
                        AppTheme.themeOrangeEnd,
                      ],
                      () => context.go('/community'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Recent Courses
              Text(
                'Khóa học gần đây',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _buildCourseCard(
                context,
                'Full Stack Web Development',
                'Đang học',
                0.65,
                const [AppTheme.themeBlueStart, AppTheme.themeBlueEnd],
              ),

              const SizedBox(height: 12),

              _buildCourseCard(
                context,
                'Mobile App Development',
                'Chưa bắt đầu',
                0.0,
                const [AppTheme.themePurpleStart, AppTheme.themePurpleEnd],
              ),

              const SizedBox(height: 24),

              // Learning Goals
              Text(
                'Mục tiêu học tập',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _buildGoalCard(
                context,
                'Hoàn thành khóa React.js',
                'Còn 2 tuần',
                Icons.code,
              ),

              const SizedBox(height: 12),

              _buildGoalCard(
                context,
                'Xây dựng portfolio project',
                'Còn 1 tháng',
                Icons.build,
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    List<Color> gradientColors,
    VoidCallback onTap,
  ) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors
                  .map((c) => c.withValues(alpha: 0.1))
                  .toList(),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.first.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(
    BuildContext context,
    String title,
    String status,
    double progress,
    List<Color> gradientColors,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.first.withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            status,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
          if (progress > 0) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: gradientColors.first.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(gradientColors.first),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toInt()}% hoàn thành',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: gradientColors.first,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGoalCard(
    BuildContext context,
    String title,
    String deadline,
    IconData icon,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.themeBlueStart, AppTheme.themeBlueEnd],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.themeBlueStart.withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  deadline,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
