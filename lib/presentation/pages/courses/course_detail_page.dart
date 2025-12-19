import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/course_models.dart';
import '../../../data/models/module_models.dart';
import '../../../data/models/payment_models.dart';
import '../../providers/course_provider.dart';
import '../../providers/enrollment_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/services/module_service.dart';
import '../payment/payment_webview_page.dart';
import 'course_learning_page.dart';
import '../../widgets/glass_card.dart';
import '../../themes/app_theme.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/mixins/loading_mixin.dart';

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

  CourseSummaryDto? _course;
  List<ModuleSummaryDto> _modules = [];
  bool _isLoadingModules = true;
  bool _isEnrolling = false;

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
      ErrorHandler.showErrorSnackBar(
        context,
        'ID khóa học không hợp lệ',
      );
      return;
    }

    final courseProvider = context.read<CourseProvider>();
    final enrollmentProvider = context.read<EnrollmentProvider>();
    final authProvider = context.read<AuthProvider>();

    // Load course details using LoadingStateMixin
    await executeAsync(
      () async {
        final course = await courseProvider.getCourseById(courseId);
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

    // Load modules
    setState(() => _isLoadingModules = true);
    try {
      final modules = await _moduleService.listModules(courseId: courseId);
      setState(() {
        _modules = modules;
        _isLoadingModules = false;
      });
    } catch (e) {
      setState(() => _isLoadingModules = false);
      debugPrint('Error loading modules: $e');
    }

    // Check enrollment status
    if (authProvider.user != null) {
      await enrollmentProvider.checkEnrollmentStatus(
        courseId: courseId,
        userId: authProvider.user!.id,
      );
    }
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
        ErrorHandler.showSuccessSnackBar(
          context,
          'Đăng ký thành công!',
        );
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
    final currency = _course!.currency ?? 'VND';

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận mua khóa học'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _course!.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Giá: ${NumberFormatter.formatCurrency(price, currency: currency)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Bạn sẽ được:'),
            const SizedBox(height: 8),
            const Text('• Truy cập trọn đời vào khóa học'),
            const Text('• Chứng chỉ hoàn thành'),
            const Text('• Hỗ trợ từ giảng viên'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Thanh toán'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final paymentProvider = context.read<PaymentProvider>();

    // Create payment for course purchase
    final paymentResponse = await paymentProvider.createPayment(
      amount: price,
      type: PaymentType.coursePurchase,
      paymentMethod: PaymentMethod.payos,
      description: 'Mua khóa học: ${_course!.title}',
      courseId: int.parse(widget.courseId),
      successUrl: 'https://skillverse.app/payment/success',
      cancelUrl: 'https://skillverse.app/payment/cancel',
    );

    // Close loading dialog
    if (mounted) Navigator.pop(context);

    if (paymentResponse == null) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          paymentProvider.errorMessage ?? 'Lỗi tạo thanh toán',
        );
      }
      return;
    }

    // Navigate to payment webview
    if (!mounted) return;
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentWebViewPage(
          checkoutUrl: paymentResponse.checkoutUrl,
        ),
      ),
    );

    // Handle payment result
    final authProvider = context.read<AuthProvider>();
    final enrollmentProvider = context.read<EnrollmentProvider>();
    final courseId = int.parse(widget.courseId);

    if (result != null && result['success'] == true && mounted) {
      ErrorHandler.showSuccessSnackBar(
        context,
        'Thanh toán thành công!',
      );

      // Auto-enroll user after successful payment
      final enrolled = await enrollmentProvider.enrollInCourse(
        courseId: courseId,
        userId: authProvider.user!.id,
      );

      if (enrolled && mounted) {
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
                  // Navigate to course learning page
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
    } else if (result != null && result['cancelled'] == true) {
      // Payment cancelled by user
      if (mounted) {
        ErrorHandler.showWarningSnackBar(
          context,
          'Thanh toán đã bị hủy',
        );
      }

      // Cancel the payment on backend
      if (paymentResponse.transactionReference.isNotEmpty) {
        await paymentProvider.cancelPayment(
          paymentResponse.transactionReference,
          reason: 'Người dùng hủy thanh toán',
        );
      }
    } else {
      // Payment failed or unknown result
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          'Thanh toán không thành công. Vui lòng thử lại.',
        );
      }
    }
  }

  List<Color> _getLevelGradient(CourseLevel level) {
    switch (level) {
      case CourseLevel.beginner:
        return [AppTheme.themeGreenStart, AppTheme.themeGreenEnd];
      case CourseLevel.intermediate:
        return [AppTheme.themeOrangeStart, AppTheme.themeOrangeEnd];
      case CourseLevel.advanced:
        return [AppTheme.themePurpleStart, AppTheme.themePurpleEnd];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.galaxyDarkest, AppTheme.galaxyDark],
            ),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (hasError) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
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
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: const Center(child: Text('Không tìm thấy khóa học')),
      );
    }

    final enrollmentProvider = context.watch<EnrollmentProvider>();
    final isEnrolled =
        enrollmentProvider.isEnrolled(int.parse(widget.courseId));
    final gradientColors = _getLevelGradient(_course!.level);

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Gradient Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.galaxyDarkest, AppTheme.galaxyDark],
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
                                  child: Icon(Icons.play_circle_fill,
                                      size: 72, color: Colors.white),
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.play_circle_fill,
                                    size: 72, color: Colors.white),
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
                                AppTheme.galaxyDarkest.withValues(alpha: 0.9),
                              ],
                            ),
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
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: gradientColors),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: gradientColors[0].withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.school,
                                      color: Colors.white, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    _course!.level.name.toUpperCase(),
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
                            if (_course!.price == null || _course!.price == 0) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppTheme.themeGreenStart,
                                      AppTheme.themeGreenEnd
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
                                    Icon(Icons.card_giftcard,
                                        color: Colors.white, size: 16),
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
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 8),

                        // Author
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: gradientColors[0],
                              child: const Icon(Icons.person,
                                  size: 18, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _course!.authorName ?? 'Unknown',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.darkTextSecondary,
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
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: AppTheme.darkBorderColor,
                              ),
                              _StatItem(
                                icon: Icons.auto_stories_outlined,
                                label: 'Modules',
                                value: '${_course!.moduleCount ?? 0}',
                                color: AppTheme.themePurpleStart,
                              ),
                              if (_course!.rating != null) ...[
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: AppTheme.darkBorderColor,
                                ),
                                _StatItem(
                                  icon: Icons.star_outline,
                                  label: 'Đánh giá',
                                  value: NumberFormatter.formatRating(_course!.rating!),
                                  color: Colors.amber,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Price Section (only for paid courses)
                        if (_course!.price != null && _course!.price! > 0)
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
                                            color: AppTheme.darkTextSecondary,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    ShaderMask(
                                      shaderCallback: (bounds) =>
                                          LinearGradient(
                                        colors: gradientColors,
                                      ).createShader(bounds),
                                      child: Text(
                                        NumberFormatter.formatCurrency(_course!.price!, currency: _course!.currency ?? 'VND'),
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
                                  Icon(Icons.description_outlined,
                                      color: gradientColors[0], size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Mô tả',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(color: Colors.white),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _course!.description ?? 'Không có mô tả',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppTheme.darkTextSecondary,
                                      height: 1.6,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Benefits Section
                        GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.verified_outlined,
                                      color: gradientColors[0], size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Khóa học bao gồm:',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(color: Colors.white),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _BenefitItem(
                                icon: Icons.access_time,
                                text: 'Truy cập trọn đời',
                                color: gradientColors[0],
                              ),
                              const SizedBox(height: 12),
                              _BenefitItem(
                                icon: Icons.card_membership,
                                text: 'Chứng chỉ hoàn thành',
                                color: gradientColors[0],
                              ),
                              const SizedBox(height: 12),
                              _BenefitItem(
                                icon: Icons.support_agent,
                                text: 'Hỗ trợ giảng viên',
                                color: gradientColors[0],
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
                                  Icon(Icons.list_alt,
                                      color: gradientColors[0], size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Nội dung khóa học',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(color: Colors.white),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (_isLoadingModules)
                                const Center(child: CircularProgressIndicator())
                              else if (_modules.isEmpty)
                                const Text(
                                  'Chưa có nội dung khóa học',
                                  style: TextStyle(
                                      color: AppTheme.darkTextSecondary),
                                )
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _modules.length,
                                  itemBuilder: (context, index) {
                                    final module = _modules[index];
                                    final isExpanded =
                                        expandedModule == module.id;
                                    return _ModuleItem(
                                      module: module,
                                      isExpanded: isExpanded,
                                      onTap: () => toggleModule(module.id),
                                      gradientColors: gradientColors,
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
          color: AppTheme.darkCardBackground,
          border: Border(
            top: BorderSide(
              color: AppTheme.darkBorderColor,
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
                            Icon(Icons.play_circle_filled,
                                color: Colors.white),
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
                                  const Icon(Icons.add_circle_outline,
                                      color: Colors.white),
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

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.darkTextSecondary,
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

  const _BenefitItem({
    required this.icon,
    required this.text,
    required this.color,
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
            style: const TextStyle(
              color: AppTheme.darkTextPrimary,
              fontSize: 14,
            ),
          ),
        ),
        const Icon(Icons.check_circle, color: AppTheme.themeGreenStart, size: 20),
      ],
    );
  }
}

class _ModuleItem extends StatelessWidget {
  final ModuleSummaryDto module;
  final bool isExpanded;
  final VoidCallback onTap;
  final List<Color> gradientColors;

  const _ModuleItem({
    required this.module,
    required this.isExpanded,
    required this.onTap,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isExpanded
                    ? gradientColors[0].withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isExpanded
                      ? gradientColors[0].withValues(alpha: 0.3)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradientColors),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${module.orderIndex}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          module.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: gradientColors[0],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isExpanded && module.description != null)
          Container(
            margin: const EdgeInsets.only(left: 56, top: 8, bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.darkBackgroundSecondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              module.description!,
              style: const TextStyle(
                color: AppTheme.darkTextSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}
