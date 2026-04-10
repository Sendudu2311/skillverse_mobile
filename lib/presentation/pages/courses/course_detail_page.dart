import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/course_models.dart';
import '../../../data/models/module_with_content_models.dart';
import '../../../data/models/payment_models.dart';
import '../../providers/enrollment_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/services/module_service.dart';
import '../../../data/services/course_service.dart';
import '../payment/payment_webview_page.dart';
import 'course_learning_page.dart';
import 'course_detail_widgets.dart';
import 'course_purchase_bottom_sheet.dart';
import '../../widgets/glass_card.dart';
import '../../themes/app_theme.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/utils/error_handler.dart';
import '../../widgets/common_loading.dart';
import '../../../data/services/enrollment_service.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../../core/utils/date_time_helper.dart';

class CourseDetailPage extends StatefulWidget {
  final String courseId;
  const CourseDetailPage({super.key, required this.courseId});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage>
    with SingleTickerProviderStateMixin {
  bool _isLoadingCourse = false;
  String? _errorMessage;
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

  Future<void> _executeAsync(
    Future<void> Function() operation, {
    required void Function(bool) setLoading,
  }) async {
    setLoading(true);
    try {
      await operation();
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = ErrorHandler.getErrorMessage(e));
      }
    } finally {
      if (mounted) setLoading(false);
    }
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

    // Load course details
    await _executeAsync(() async {
      final courseService = CourseService();
      final course = await courseService.getCourseDetail(courseId);
      if (mounted) {
        setState(() => _course = course);
        _animationController.forward();
      }
    }, setLoading: (val) => setState(() {
      _isLoadingCourse = val;
      if (val) _errorMessage = null;
    }));

    if (_course == null) return;

    // Load modules with full content
    await _executeAsync(() async {
      final fullModules = await _moduleService.listModulesWithContent(courseId: courseId);
      if (mounted) setState(() => _fullModules = fullModules);
    }, setLoading: (val) => setState(() => _isLoadingModules = val));

    // Check enrollment status and load progress
    if (authProvider.user != null) {
      await enrollmentProvider.checkEnrollmentStatus(
        courseId: courseId,
        userId: authProvider.user!.id,
      );

      // Load enrollment progress if enrolled
      if (enrollmentProvider.isEnrolled(courseId)) {
        try {
          final enrollment = await EnrollmentService().getEnrollment(
            courseId: courseId,
            userId: authProvider.user!.id,
          );
          if (mounted) {
            setState(() => _enrollmentProgress = enrollment.progressPercent);
          }
        } catch (e) {
          debugPrint('Error loading enrollment progress: $e');
        }
      }
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

      if (!mounted) return;
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
      builder: (sheetContext) => CoursePurchaseBottomSheet(
        course: _course!,
        courseId: widget.courseId,
        price: price,
        isDark: isDark,
        onWalletSuccess: () => _onPurchaseSuccess(),
        onPayOSSelected: () => _handlePayOSFlow(),
      ),
    );
  }

  void _onPurchaseSuccess() async {
    if (!mounted) return;
    final enrollmentProvider = context.read<EnrollmentProvider>();
    final courseId = int.parse(widget.courseId);

    // Refresh enrollment status (backend auto-enrolled)
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user != null) {
      await enrollmentProvider.checkEnrollmentStatus(
        courseId: courseId,
        userId: authProvider.user!.id,
      );
    }
    if (!mounted) return;

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
      builder: (context) => CommonLoading.center(),
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

    if (_isLoadingCourse && _course == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        extendBodyBehindAppBar: true,
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
          child: CommonLoading.center(),
        ),
      );
    }

    if (_errorMessage != null && _course == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        extendBodyBehindAppBar: true,
        body: Center(
          child: ErrorStateWidget(
            message: _errorMessage ?? 'Đã xảy ra lỗi',
            onRetry: () {
              setState(() => _errorMessage = null);
              _loadCourseData();
            },
          ),
        ),
      );
    }

    if (_course == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(
          child: EmptyStateWidget(
            icon: Icons.search_off,
            title: 'Trống',
            subtitle: 'Không tìm thấy khóa học',
          ),
        ),
      );
    }

    final isEnrolled = context.select<EnrollmentProvider, bool>(
      (p) => p.isEnrolled(int.parse(widget.courseId)),
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
                                    (_course!.level ?? 'BEGINNER')
                                        .toUpperCase(),
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
                              CourseStatItem(
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
                              CourseStatItem(
                                icon: Icons.auto_stories_outlined,
                                label: 'Modules',
                                value: '${(_course!.moduleCount != null && _course!.moduleCount! > 0) ? _course!.moduleCount : _fullModules.length}',
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
                                CourseStatItem(
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
                                  value: DateTime.tryParse(_course!.updatedAt!) != null 
                                      ? DateTimeHelper.formatDate(DateTime.parse(_course!.updatedAt!)) 
                                      : _course!.updatedAt!,
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
                                _course!.description ??
                                    'Chưa có mô tả chi tiết cho khóa học này.',
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
                              CourseBenefitItem(
                                icon: Icons.access_time,
                                text: 'Truy cập trọn đời',
                                color: gradientColors[0],
                                isDark: isDark,
                              ),
                              const SizedBox(height: 12),
                              CourseBenefitItem(
                                icon: Icons.card_membership,
                                text: 'Chứng chỉ hoàn thành',
                                color: gradientColors[0],
                                isDark: isDark,
                              ),
                              const SizedBox(height: 12),
                              CourseBenefitItem(
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
                                CommonLoading.center()
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
                                    return CourseModuleItem(
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
                            ? CommonLoading.small(color: Colors.white)
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
