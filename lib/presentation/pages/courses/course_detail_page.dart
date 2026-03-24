import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/course_models.dart';
import '../../../data/models/module_with_content_models.dart';
import '../../../data/models/lesson_models.dart';
import '../../../data/models/payment_models.dart';
import '../../providers/enrollment_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/services/module_service.dart';
import '../../../data/services/wallet_service.dart';
import '../../../data/services/course_service.dart';
import '../payment/payment_webview_page.dart';
import 'course_learning_page.dart';
import '../../widgets/glass_card.dart';
import '../../themes/app_theme.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/mixins/loading_mixin.dart';
import '../../../core/network/api_client.dart';

class CourseDetailPage extends StatefulWidget {
  final String courseId;
  const CourseDetailPage({super.key, required this.courseId});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage>
    with SingleTickerProviderStateMixin, LoadingStateMixin {
  bool isWishlisted = false;
  String activeTab = 'overview';
  int? expandedModule;

  CourseDetailDto? _course;
  List<ModuleWithContentDto> _fullModules = [];
  bool _isLoadingModules = true;
  bool _isEnrolling = false;
  int _enrollmentProgress = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final ModuleService _moduleService = ModuleService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _loadCourseData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCourseData() async {
    final courseId = int.tryParse(widget.courseId);
    if (courseId == null) {
      ErrorHandler.showErrorSnackBar(context, 'ID khóa học không hợp lệ');
      return;
    }

    final enrollmentProvider = context.read<EnrollmentProvider>();
    final authProvider = context.read<AuthProvider>();

    // Load course details using LoadingStateMixin
    await executeAsync(
      () async {
        final courseService = CourseService();
        final course = await courseService.getCourseDetail(courseId);
        if (mounted) {
          setState(() {
            _course = course;
          });
          _animationController.forward();
        }
      },
      errorMessageBuilder: (e) {
        if (e.toString().contains('404')) {
          return 'Không tìm thấy khóa học';
        } else if (e.toString().contains('timeout')) {
          return 'Không có kết nối Internet';
        }
        return 'Lỗi tải khóa học: ${e.toString()}';
      },
    );

    // Load modules with full content (lessons, quizzes, assignments)
    setState(() => _isLoadingModules = true);
    try {
      final fullModules = await _moduleService.listModulesWithContent(
        courseId: courseId,
      );
      setState(() {
        _fullModules = fullModules;
        _isLoadingModules = false;
      });
    } catch (e) {
      setState(() => _isLoadingModules = false);
      debugPrint('Error loading modules: $e');
    }

    // Check enrollment status and load progress
    if (authProvider.user != null) {
      await enrollmentProvider.checkEnrollmentStatus(
        courseId: courseId,
        userId: authProvider.user!.id,
      );

      // Load enrollment progress if enrolled
      if (enrollmentProvider.isEnrolled(courseId)) {
        try {
          final dio = ApiClient().dio;
          final response = await dio.get(
            '/enrollments/course/$courseId/user/${authProvider.user!.id}',
          );
          if (response.data != null &&
              response.data['progressPercent'] != null) {
            setState(() {
              _enrollmentProgress = response.data['progressPercent'] as int;
            });
          }
        } catch (e) {
          debugPrint('Error loading enrollment progress: $e');
        }
      }
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildQuickInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackgroundSecondary : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void toggleWishlist() => setState(() => isWishlisted = !isWishlisted);

  void toggleModule(int id) =>
      setState(() => expandedModule = expandedModule == id ? null : id);

  Future<void> _handleEnroll() async {
    if (_course == null) return;

    final authProvider = context.read<AuthProvider>();
    final enrollmentProvider = context.read<EnrollmentProvider>();

    if (authProvider.user == null) {
      ErrorHandler.showWarningSnackBar(
        context,
        'Vui lòng đăng nhập để đăng ký khóa học',
      );
      return;
    }

    final courseId = int.parse(widget.courseId);

    // Check if this is a free course (price is null or 0)
    if (_course!.price == null || _course!.price == 0) {
      // Free course - enroll directly
      setState(() => _isEnrolling = true);

      final enrolled = await enrollmentProvider.enrollInCourse(
        courseId: courseId,
        userId: authProvider.user!.id,
      );

      setState(() => _isEnrolling = false);

      if (enrolled && mounted) {
        ErrorHandler.showSuccessSnackBar(context, 'Đăng ký thành công!');
      } else if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          enrollmentProvider.errorMessage ?? 'Đăng ký thất bại',
        );
      }
    } else {
      // Paid course - show payment dialog and process
      await _handlePaidCourseEnroll();
    }
  }

  Future<void> _handlePaidCourseEnroll() async {
    if (_course == null) return;

    final price = _course!.price!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show purchase bottom sheet
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _PurchaseBottomSheet(
        course: _course!,
        courseId: widget.courseId,
        price: price,
        isDark: isDark,
        onWalletSuccess: () => _onPurchaseSuccess(),
        onPayOSSelected: () => _handlePayOSFlow(),
      ),
    );
  }

  void _onPurchaseSuccess() {
    if (!mounted) return;
    final enrollmentProvider = context.read<EnrollmentProvider>();
    final courseId = int.parse(widget.courseId);

    // Refresh enrollment status (backend auto-enrolled)
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user != null) {
      enrollmentProvider.checkEnrollmentStatus(
        courseId: courseId,
        userId: authProvider.user!.id,
      );
    }

    // Show success dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
        title: const Text('Mua khóa học thành công!'),
        content: Text(
          'Bạn đã mua thành công khóa học "${_course!.title}".\n'
          'Bắt đầu học ngay bây giờ!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Để sau'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CourseLearningPage(courseId: widget.courseId),
                ),
              );
            },
            child: const Text('Học ngay'),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePayOSFlow() async {
    if (_course == null) return;

    final price = _course!.price!;
    final paymentProvider = context.read<PaymentProvider>();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final paymentResponse = await paymentProvider.createPayment(
      amount: price,
      type: PaymentType.coursePurchase,
      paymentMethod: PaymentMethod.payos,
      description: 'Mua khóa học: ${_course!.title}',
      courseId: int.parse(widget.courseId),
      successUrl: 'https://skillverse.app/payment/success',
      cancelUrl: 'https://skillverse.app/payment/cancel',
    );

    if (mounted) Navigator.pop(context); // close loading

    if (paymentResponse == null) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          paymentProvider.errorMessage ?? 'Lỗi tạo thanh toán',
        );
      }
      return;
    }

    if (!mounted) return;
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PaymentWebViewPage(checkoutUrl: paymentResponse.checkoutUrl),
      ),
    );

    if (result != null && result['success'] == true && mounted) {
      _onPurchaseSuccess();
    } else if (result != null && result['cancelled'] == true) {
      if (mounted) {
        ErrorHandler.showWarningSnackBar(context, 'Thanh toán đã bị hủy');
      }
      if (paymentResponse.transactionReference.isNotEmpty) {
        await paymentProvider.cancelPayment(
          paymentResponse.transactionReference,
          reason: 'Người dùng hủy thanh toán',
        );
      }
    } else {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          'Thanh toán không thành công. Vui lòng thử lại.',
        );
      }
    }
  }

  List<Color> _getLevelGradient(String? level) {
    switch (level?.toUpperCase()) {
      case 'BEGINNER':
        return [AppTheme.themeGreenStart, AppTheme.themeGreenEnd];
      case 'INTERMEDIATE':
        return [AppTheme.themeOrangeStart, AppTheme.themeOrangeEnd];
      case 'ADVANCED':
        return [AppTheme.themePurpleStart, AppTheme.themePurpleEnd];
      default:
        return [AppTheme.themeGreenStart, AppTheme.themeGreenEnd];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [AppTheme.galaxyDarkest, AppTheme.galaxyDark]
                  : [Colors.grey.shade100, Colors.white],
            ),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (hasError) {
      return Scaffold(
        body: Center(
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  errorMessage ?? 'Đã xảy ra lỗi',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    clearError();
                    _loadCourseData();
                  },
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_course == null) {
      return Scaffold(
        body: const Center(child: Text('Không tìm thấy khóa học')),
      );
    }

    final enrollmentProvider = context.watch<EnrollmentProvider>();
    final isEnrolled = enrollmentProvider.isEnrolled(
      int.parse(widget.courseId),
    );
    final gradientColors = _getLevelGradient(_course!.level);

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Gradient Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [AppTheme.galaxyDarkest, AppTheme.galaxyDark]
                      : [Colors.grey.shade50, Colors.white],
                ),
              ),
            ),
            // Content
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Image with Gradient Overlay
                  Stack(
                    children: [
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: gradientColors,
                          ),
                        ),
                        child: _course!.thumbnailUrl != null
                            ? Image.network(
                                _course!.thumbnailUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                      child: Icon(
                                        Icons.play_circle_fill,
                                        size: 72,
                                        color: Colors.white,
                                      ),
                                    ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.play_circle_fill,
                                  size: 72,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                      // Gradient Overlay - only at bottom
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          height: 150,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                isDark
                                    ? AppTheme.galaxyDarkest.withValues(
                                        alpha: 0.9,
                                      )
                                    : Colors.grey.shade50.withValues(
                                        alpha: 0.9,
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Back button
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                      // Save & Share buttons
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        right: 16,
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  isWishlisted
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  color: isWishlisted
                                      ? AppTheme.themeOrangeStart
                                      : Colors.white,
                                ),
                                onPressed: toggleWishlist,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.share,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  // TODO: Implement share functionality
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Level Badge and Price Badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: gradientColors,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: gradientColors[0].withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.school,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _course!.level.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Only show MIỄN PHÍ badge for free courses
                            if (_course!.price == null ||
                                _course!.price == 0) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppTheme.themeGreenStart,
                                      AppTheme.themeGreenEnd,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.themeGreenStart
                                          .withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.card_giftcard,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'MIỄN PHÍ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          _course!.title,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppTheme.lightTextPrimary,
                              ),
                        ),
                        const SizedBox(height: 8),

                        // Author
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: gradientColors[0],
                              child: const Icon(
                                Icons.person,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _course!.authorName ?? 'Unknown',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: isDark
                                        ? AppTheme.darkTextSecondary
                                        : AppTheme.lightTextSecondary,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Stats
                        GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _StatItem(
                                icon: Icons.people_outline,
                                label: 'Học viên',
                                value: '${_course!.enrollmentCount}',
                                color: AppTheme.themeBlueStart,
                                isDark: isDark,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: isDark
                                    ? AppTheme.darkBorderColor
                                    : AppTheme.lightBorderColor,
                              ),
                              _StatItem(
                                icon: Icons.auto_stories_outlined,
                                label: 'Modules',
                                value: '${_course!.moduleCount ?? 0}',
                                color: AppTheme.themePurpleStart,
                                isDark: isDark,
                              ),
                              if (_course!.rating != null) ...[
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: isDark
                                      ? AppTheme.darkBorderColor
                                      : AppTheme.lightBorderColor,
                                ),
                                _StatItem(
                                  icon: Icons.star_outline,
                                  label: 'Đánh giá',
                                  value: NumberFormatter.formatRating(
                                    _course!.rating!,
                                  ),
                                  color: Colors.amber,
                                  isDark: isDark,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Quick Info Grid
                        GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: gradientColors[0],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Thông tin chung',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: isDark
                                              ? Colors.white
                                              : AppTheme.lightTextPrimary,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildQuickInfoChip(
                                      context,
                                      icon: Icons.category_outlined,
                                      label: 'Danh mục',
                                      value:
                                          _course!.category ?? 'Chưa cập nhật',
                                      isDark: isDark,
                                      color: gradientColors[0],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildQuickInfoChip(
                                      context,
                                      icon: Icons.language_outlined,
                                      label: 'Ngôn ngữ',
                                      value:
                                          _course!.language ?? 'Chưa cập nhật',
                                      isDark: isDark,
                                      color: gradientColors[0],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildQuickInfoChip(
                                      context,
                                      icon: Icons.timer_outlined,
                                      label: 'Thời lượng',
                                      value:
                                          _course!.estimatedDurationHours !=
                                              null
                                          ? '${_course!.estimatedDurationHours} giờ'
                                          : 'Chưa cập nhật',
                                      isDark: isDark,
                                      color: gradientColors[0],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildQuickInfoChip(
                                      context,
                                      icon: Icons.book_outlined,
                                      label: 'Bài học',
                                      value:
                                          '${_fullModules.fold<int>(0, (sum, m) => sum + m.lessons.length)}',
                                      isDark: isDark,
                                      color: gradientColors[0],
                                    ),
                                  ),
                                ],
                              ),
                              if (_course!.updatedAt != null) ...[
                                const SizedBox(height: 12),
                                _buildQuickInfoChip(
                                  context,
                                  icon: Icons.update_outlined,
                                  label: 'Cập nhật',
                                  value: _formatDate(_course!.updatedAt!),
                                  isDark: isDark,
                                  color: gradientColors[0],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Enrollment Progress (for enrolled users)
                        if (isEnrolled)
                          GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.trending_up,
                                      color: AppTheme.themeGreenStart,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Tiến độ học tập',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: isDark
                                                ? Colors.white
                                                : AppTheme.lightTextPrimary,
                                          ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '$_enrollmentProgress%',
                                      style: TextStyle(
                                        color: AppTheme.themeGreenStart,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: _enrollmentProgress / 100.0,
                                    backgroundColor: isDark
                                        ? AppTheme.darkBackgroundSecondary
                                        : Colors.grey.shade200,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          AppTheme.themeGreenStart,
                                        ),
                                    minHeight: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (isEnrolled) const SizedBox(height: 20),

                        // Price Section (only for paid courses not yet purchased)
                        if (!isEnrolled &&
                            _course!.price != null &&
                            _course!.price! > 0)
                          GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Giá khóa học',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: isDark
                                                ? AppTheme.darkTextSecondary
                                                : AppTheme.lightTextSecondary,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    ShaderMask(
                                      shaderCallback: (bounds) =>
                                          LinearGradient(
                                            colors: gradientColors,
                                          ).createShader(bounds),
                                      child: Text(
                                        NumberFormatter.formatCurrency(
                                          _course!.price!,
                                          currency: _course!.currency ?? 'VND',
                                        ),
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),

                        // Description Section
                        GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.description_outlined,
                                    color: gradientColors[0],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Mô tả',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: isDark
                                              ? Colors.white
                                              : AppTheme.lightTextPrimary,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _course!.description,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: isDark
                                          ? AppTheme.darkTextSecondary
                                          : AppTheme.lightTextSecondary,
                                      height: 1.6,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Learning Objectives
                        if (_course!.learningObjectives != null &&
                            _course!.learningObjectives!.isNotEmpty)
                          GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      color: gradientColors[0],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Bạn sẽ học được',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: isDark
                                                ? Colors.white
                                                : AppTheme.lightTextPrimary,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ..._course!.learningObjectives!.map(
                                  (objective) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: AppTheme.themeGreenStart,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            objective,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: isDark
                                                      ? AppTheme
                                                            .darkTextSecondary
                                                      : AppTheme
                                                            .lightTextSecondary,
                                                  height: 1.5,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_course!.learningObjectives != null &&
                            _course!.learningObjectives!.isNotEmpty)
                          const SizedBox(height: 20),

                        // Requirements
                        if (_course!.requirements != null &&
                            _course!.requirements!.isNotEmpty)
                          GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.rule_outlined,
                                      color: gradientColors[0],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Yêu cầu',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: isDark
                                                ? Colors.white
                                                : AppTheme.lightTextPrimary,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ..._course!.requirements!.map(
                                  (req) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.arrow_right,
                                          color: gradientColors[0],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            req,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: isDark
                                                      ? AppTheme
                                                            .darkTextSecondary
                                                      : AppTheme
                                                            .lightTextSecondary,
                                                  height: 1.5,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_course!.requirements != null &&
                            _course!.requirements!.isNotEmpty)
                          const SizedBox(height: 20),

                        // Benefits Section
                        GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.verified_outlined,
                                    color: gradientColors[0],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Khóa học bao gồm:',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: isDark
                                              ? Colors.white
                                              : AppTheme.lightTextPrimary,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _BenefitItem(
                                icon: Icons.access_time,
                                text: 'Truy cập trọn đời',
                                color: gradientColors[0],
                                isDark: isDark,
                              ),
                              const SizedBox(height: 12),
                              _BenefitItem(
                                icon: Icons.card_membership,
                                text: 'Chứng chỉ hoàn thành',
                                color: gradientColors[0],
                                isDark: isDark,
                              ),
                              const SizedBox(height: 12),
                              _BenefitItem(
                                icon: Icons.support_agent,
                                text: 'Hỗ trợ giảng viên',
                                color: gradientColors[0],
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Curriculum Section
                        GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.list_alt,
                                    color: gradientColors[0],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Nội dung khóa học',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: isDark
                                              ? Colors.white
                                              : AppTheme.lightTextPrimary,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (_isLoadingModules)
                                const Center(child: CircularProgressIndicator())
                              else if (_fullModules.isEmpty)
                                Text(
                                  'Chưa có nội dung khóa học',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppTheme.darkTextSecondary
                                        : AppTheme.lightTextSecondary,
                                  ),
                                )
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _fullModules.length,
                                  itemBuilder: (context, index) {
                                    final module = _fullModules[index];
                                    final isExpanded =
                                        expandedModule == module.id;
                                    return _ModuleItem(
                                      module: module,
                                      isExpanded: isExpanded,
                                      onTap: () => toggleModule(module.id),
                                      gradientColors: gradientColors,
                                      isDark: isDark,
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 100), // Space for bottom button
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCardBackground : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? AppTheme.darkBorderColor
                  : AppTheme.lightBorderColor,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: isEnrolled
              ? Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CourseLearningPage(courseId: widget.courseId),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_circle_filled, color: Colors.white),
                            SizedBox(width: 12),
                            Text(
                              'Tiếp tục học',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isEnrolling ? null : _handleEnroll,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: _isEnrolling
                            ? const Center(
                                child: SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _course!.price == null ||
                                            _course!.price == 0
                                        ? 'Đăng ký ngay'
                                        : 'Mua khóa học',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool isDark;

  const _BenefitItem({
    required this.icon,
    required this.text,
    required this.color,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
              fontSize: 14,
            ),
          ),
        ),
        const Icon(
          Icons.check_circle,
          color: AppTheme.themeGreenStart,
          size: 20,
        ),
      ],
    );
  }
}

class _ModuleItem extends StatelessWidget {
  final ModuleWithContentDto module;
  final bool isExpanded;
  final VoidCallback onTap;
  final List<Color> gradientColors;
  final bool isDark;

  const _ModuleItem({
    required this.module,
    required this.isExpanded,
    required this.onTap,
    required this.gradientColors,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final totalItems =
        module.lessons.length +
        module.quizzes.length +
        module.assignments.length;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isExpanded
                    ? (isDark
                          ? gradientColors[0].withValues(alpha: 0.12)
                          : gradientColors[0].withValues(alpha: 0.06))
                    : (isDark
                          ? AppTheme.darkBackgroundSecondary.withValues(
                              alpha: 0.6,
                            )
                          : Colors.grey.shade50),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isExpanded
                      ? gradientColors[0].withValues(alpha: 0.4)
                      : (isDark
                            ? AppTheme.darkBorderColor.withValues(alpha: 0.3)
                            : Colors.grey.shade200),
                  width: isExpanded ? 1.5 : 1,
                ),
                boxShadow: isExpanded
                    ? [
                        BoxShadow(
                          color: gradientColors[0].withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  // Number Badge with gradient
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradientColors,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: gradientColors[0].withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${module.orderIndex + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Title & Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          module.title,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : AppTheme.lightTextPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            height: 1.3,
                          ),
                        ),
                        if (totalItems > 0) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              if (module.lessons.isNotEmpty)
                                _buildModuleCountChip(
                                  Icons.play_circle_outline,
                                  '${module.lessons.length} bài học',
                                  gradientColors[0],
                                ),
                              if (module.quizzes.isNotEmpty)
                                _buildModuleCountChip(
                                  Icons.quiz_outlined,
                                  '${module.quizzes.length} quiz',
                                  Colors.amber,
                                ),
                              if (module.assignments.isNotEmpty)
                                _buildModuleCountChip(
                                  Icons.assignment_outlined,
                                  '${module.assignments.length} bài tập',
                                  AppTheme.themeOrangeStart,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Animated Chevron
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 250),
                    turns: isExpanded ? 0.5 : 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: gradientColors[0].withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: gradientColors[0],
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isExpanded) ...[
          if (module.description != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkBackgroundSecondary
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                module.description!,
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          // Lessons
          ...module.lessons.asMap().entries.map((entry) {
            final lesson = entry.value;
            final isReading = lesson.type == LessonType.reading;
            return _buildContentItem(
              icon: isReading
                  ? Icons.menu_book_outlined
                  : Icons.play_circle_outline,
              typeLabel: 'BÀI HỌC ${entry.key + 1}',
              title: lesson.title,
              meta: isReading ? 'Bài đọc' : null,
              color: gradientColors[0],
            );
          }),
          // Quizzes
          ...module.quizzes.map((quiz) {
            return _buildContentItem(
              icon: Icons.quiz_outlined,
              typeLabel: 'BÀI KIỂM TRA',
              title: quiz.title ?? 'Bài kiểm tra',
              meta: '${quiz.questionCount} câu hỏi',
              color: Colors.amber,
            );
          }),
          // Assignments
          ...module.assignments.map((assignment) {
            return _buildContentItem(
              icon: Icons.assignment_outlined,
              typeLabel: 'BÀI TẬP',
              title: assignment.title ?? 'Bài tập',
              meta: '${assignment.maxScore} điểm',
              color: AppTheme.themeOrangeStart,
            );
          }),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildContentItem({
    required IconData icon,
    required String typeLabel,
    required String title,
    String? meta,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 16, top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkBackgroundSecondary.withValues(alpha: 0.5)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: color.withValues(alpha: 0.5), width: 3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (meta != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                meta,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModuleCountChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// PURCHASE BOTTOM SHEET
// =============================================================================

class _PurchaseBottomSheet extends StatefulWidget {
  final CourseDetailDto course;
  final String courseId;
  final double price;
  final bool isDark;
  final VoidCallback onWalletSuccess;
  final VoidCallback onPayOSSelected;

  const _PurchaseBottomSheet({
    required this.course,
    required this.courseId,
    required this.price,
    required this.isDark,
    required this.onWalletSuccess,
    required this.onPayOSSelected,
  });

  @override
  State<_PurchaseBottomSheet> createState() => _PurchaseBottomSheetState();
}

class _PurchaseBottomSheetState extends State<_PurchaseBottomSheet> {
  final WalletService _walletService = WalletService();
  final CourseService _courseService = CourseService();

  bool _isLoadingWallet = true;
  bool _isPurchasing = false;
  int _walletBalance = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    try {
      final wallet = await _walletService.getMyWallet();
      if (mounted) {
        setState(() {
          _walletBalance = wallet.cashBalance;
          _isLoadingWallet = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingWallet = false;
          _error = 'Không thể tải số dư ví';
        });
      }
    }
  }

  Future<void> _handleWalletPurchase() async {
    setState(() {
      _isPurchasing = true;
      _error = null;
    });

    try {
      await _courseService.purchaseCourseWithWallet(
        courseId: int.parse(widget.courseId),
      );

      if (mounted) {
        Navigator.pop(context); // close bottom sheet
        widget.onWalletSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAfford = _walletBalance >= widget.price.toInt();
    final remaining = _walletBalance - widget.price.toInt();

    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? AppTheme.darkCardBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: widget.isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mua khóa học',
                    style: TextStyle(
                      color: widget.isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Course info
              _buildCourseInfo(),
              const SizedBox(height: 16),

              // Wallet section
              _buildWalletSection(canAfford, remaining),
              const SizedBox(height: 12),

              // Error
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.errorColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppTheme.errorColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: AppTheme.errorColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Wallet payment button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoadingWallet || _isPurchasing || !canAfford
                      ? null
                      : _handleWalletPurchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canAfford
                        ? AppTheme.successColor
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: canAfford ? 4 : 0,
                  ),
                  child: _isPurchasing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              canAfford
                                  ? Icons.account_balance_wallet
                                  : Icons.warning_amber_rounded,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              canAfford
                                  ? 'Thanh toán bằng Ví'
                                  : 'Số dư không đủ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 10),

              // PayOS button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: _isPurchasing
                      ? null
                      : () {
                          Navigator.pop(context); // close bottom sheet
                          widget.onPayOSSelected();
                        },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppTheme.primaryBlueDark.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.credit_card,
                        size: 18,
                        color: AppTheme.primaryBlueDark,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Thanh toán qua PayOS',
                        style: TextStyle(
                          color: AppTheme.primaryBlueDark,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Hint when insufficient
              if (!_isLoadingWallet && !canAfford) ...[
                const SizedBox(height: 10),
                Text(
                  'Vui lòng nạp thêm tiền vào ví hoặc dùng PayOS.',
                  style: TextStyle(
                    color: widget.isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseInfo() {
    final imageUrl = widget.course.thumbnailUrl ?? widget.course.thumbnail?.url;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    width: 60,
                    height: 45,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 60,
                      height: 45,
                      color: AppTheme.primaryBlueDark.withValues(alpha: 0.2),
                      child: const Icon(
                        Icons.school,
                        color: Colors.white54,
                        size: 20,
                      ),
                    ),
                  )
                : Container(
                    width: 60,
                    height: 45,
                    color: AppTheme.primaryBlueDark.withValues(alpha: 0.2),
                    child: const Icon(
                      Icons.school,
                      color: Colors.white54,
                      size: 20,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.course.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: widget.isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  NumberFormatter.formatCurrency(widget.price, currency: 'đ'),
                  style: TextStyle(
                    color: AppTheme.primaryBlueDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletSection(bool canAfford, int remaining) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canAfford
              ? AppTheme.successColor.withValues(alpha: 0.3)
              : AppTheme.errorColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Wallet header
          Row(
            children: [
              Text(
                'Số dư ví',
                style: TextStyle(
                  color: widget.isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 18,
                color: widget.isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Balance
          if (_isLoadingWallet)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                NumberFormatter.formatCurrency(
                  _walletBalance.toDouble(),
                  currency: 'đ',
                ),
                style: TextStyle(
                  color: canAfford
                      ? (widget.isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary)
                      : AppTheme.errorColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Summary
            _summaryRow(
              'Giá khóa học',
              NumberFormatter.formatCurrency(widget.price, currency: 'đ'),
            ),
            const SizedBox(height: 4),
            Divider(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 4),
            _summaryRow(
              'Số dư còn lại',
              NumberFormatter.formatCurrency(
                remaining.toDouble(),
                currency: 'đ',
              ),
              isBold: true,
              valueColor: remaining >= 0
                  ? AppTheme.successColor
                  : AppTheme.errorColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: widget.isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color:
                valueColor ??
                (widget.isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary),
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
