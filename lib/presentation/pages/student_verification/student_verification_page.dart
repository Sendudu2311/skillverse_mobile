import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';

import '../../../data/models/student_verification_models.dart';
import '../../providers/student_verification_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../widgets/common_loading.dart';
import '../../widgets/glass_card.dart';
import '../../../core/utils/error_handler.dart';

/// Student Verification Page — 4-step flow:
///   1. Check eligibility & show current status
///   2. Submit form (school email + student card image)
///   3. OTP verification (6-digit code + resend)
///   4. Success → PENDING_REVIEW status
class StudentVerificationPage extends StatefulWidget {
  const StudentVerificationPage({super.key});

  @override
  State<StudentVerificationPage> createState() =>
      _StudentVerificationPageState();
}

class _StudentVerificationPageState extends State<StudentVerificationPage> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Timer? _otpTimer;
  int _otpSecondsLeft = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentVerificationProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _otpTimer?.cancel();
    super.dispose();
  }

  void _startOtpCountdown(int seconds) {
    _otpTimer?.cancel();
    setState(() => _otpSecondsLeft = seconds);
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpSecondsLeft <= 0) {
        timer.cancel();
      } else {
        setState(() => _otpSecondsLeft--);
      }
    });
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<StudentVerificationProvider>();

    final success =
        await provider.startVerification(_emailController.text.trim());
    if (success && mounted) {
      _startOtpCountdown(300); // 5 min
      ErrorHandler.showSuccessSnackBar(
        context,
        'OTP đã được gửi đến email trường của bạn',
      );
    } else if (mounted && provider.hasError) {
      ErrorHandler.showErrorSnackBar(
        context,
        provider.errorMessage ?? 'Lỗi gửi yêu cầu',
      );
    }
  }

  Future<void> _handleVerifyOtp() async {
    if (_otpController.text.trim().length < 4) return;
    final provider = context.read<StudentVerificationProvider>();

    final success = await provider.verifyOtp(_otpController.text.trim());
    if (success && mounted) {
      ErrorHandler.showSuccessSnackBar(
        context,
        'Xác minh thành công! Yêu cầu đang chờ Admin duyệt.',
      );
    } else if (mounted && provider.hasError) {
      ErrorHandler.showErrorSnackBar(
        context,
        provider.errorMessage ?? 'OTP không hợp lệ',
      );
    }
  }

  Future<void> _handleResendOtp() async {
    final provider = context.read<StudentVerificationProvider>();
    await provider.resendOtp();
    if (mounted && !provider.hasError) {
      _startOtpCountdown(300);
      ErrorHandler.showSuccessSnackBar(context, 'Đã gửi lại OTP');
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh'),
              onTap: () {
                Navigator.pop(ctx);
                context
                    .read<StudentVerificationProvider>()
                    .pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(ctx);
                context
                    .read<StudentVerificationProvider>()
                    .pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: SkillVerseAppBar(
        title: 'Xác minh sinh viên',
        icon: Icons.school,
        useGradientTitle: true,
        gradientColors: const [AppTheme.accentCyan, AppTheme.primaryBlueDark],
        onBack: () =>
            context.canPop() ? context.pop() : context.go('/dashboard'),
      ),
      body: Consumer<StudentVerificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.currentRequest == null) {
            return CommonLoading.center();
          }

          // If user has an existing request, show status page
          if (provider.currentRequest != null) {
            return _buildStatusView(provider, isDark);
          }

          // If user has a pending OTP request (just submitted)
          if (provider.pendingRequestId != null) {
            return _buildOtpView(provider, isDark);
          }

          // Otherwise show submit form
          return _buildSubmitForm(provider, isDark);
        },
      ),
    );
  }

  // ── Step 1: Submit Form ──────────────────────────────────────────────────

  Widget _buildSubmitForm(
    StudentVerificationProvider provider,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.verified_user,
                      color: AppTheme.accentCyan,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Xác minh sinh viên',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Xác minh bạn là sinh viên để mở khóa gói Student Premium với giá ưu đãi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // School email field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email trường học',
                hintText: 'ten@truong.edu.vn',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập email trường học';
                }
                if (!RegExp(r'^.+@.+\..+$').hasMatch(value.trim())) {
                  return 'Email không hợp lệ';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Image picker
            Text(
              'Ảnh thẻ sinh viên / CCCD',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showImageSourcePicker,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: provider.hasSelectedImage
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              provider.selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              onPressed: provider.clearImage,
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    Colors.black.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            size: 40,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Chạm để chụp hoặc chọn ảnh',
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 28),

            // Submit button
            ElevatedButton.icon(
              onPressed: provider.isLoading || !provider.hasSelectedImage
                  ? null
                  : _handleSubmit,
              icon: provider.isLoading
                  ? CommonLoading.small()
                  : const Icon(Icons.send),
              label: const Text('Gửi yêu cầu xác minh'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppTheme.accentCyan,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 2: OTP Verification ─────────────────────────────────────────────

  Widget _buildOtpView(
    StudentVerificationProvider provider,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.mark_email_read,
                    color: AppTheme.accentCyan,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nhập mã OTP',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mã xác minh đã được gửi đến email trường học của bạn.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // OTP input
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 12,
            ),
            decoration: const InputDecoration(
              hintText: '------',
              counterText: '',
            ),
          ),

          const SizedBox(height: 16),

          // Timer + resend
          Center(
            child: _otpSecondsLeft > 0
                ? Text(
                    'Gửi lại sau ${_otpSecondsLeft}s',
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  )
                : TextButton(
                    onPressed: _handleResendOtp,
                    child: const Text('Gửi lại OTP'),
                  ),
          ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: provider.isLoading ? null : _handleVerifyOtp,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: AppTheme.accentCyan,
              foregroundColor: Colors.white,
            ),
            child: provider.isLoading
                ? CommonLoading.small()
                : const Text('Xác minh', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // ── Step 3: Status View ──────────────────────────────────────────────────

  Widget _buildStatusView(
    StudentVerificationProvider provider,
    bool isDark,
  ) {
    final request = provider.currentRequest!;

    IconData statusIcon;
    Color statusColor;
    switch (request.status) {
      case StudentVerificationStatus.approved:
        statusIcon = Icons.check_circle;
        statusColor = AppTheme.successColor;
        break;
      case StudentVerificationStatus.rejected:
        statusIcon = Icons.cancel;
        statusColor = AppTheme.errorColor;
        break;
      case StudentVerificationStatus.expired:
        statusIcon = Icons.timer_off;
        statusColor = AppTheme.warningColor;
        break;
      case StudentVerificationStatus.pendingReview:
        statusIcon = Icons.hourglass_top;
        statusColor = AppTheme.accentGold;
        break;
      default:
        statusIcon = Icons.pending;
        statusColor = AppTheme.accentCyan;
    }

    return RefreshIndicator(
      onRefresh: () => provider.initialize(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status card
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      request.status.displayName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _statusMessage(request, isDark),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Detail card
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow('Email trường', request.schoolEmail ?? '-',
                        isDark),
                    _detailRow('Domain', request.schoolDomain ?? '-', isDark),
                    _detailRow(
                      'Email hợp lệ',
                      request.emailDomainValid ? 'Có ✅' : 'Không ❌',
                      isDark,
                    ),
                    if (request.reviewNote != null)
                      _detailRow('Ghi chú', request.reviewNote!, isDark),
                    if (request.rejectionReason != null)
                      _detailRow(
                        'Lý do từ chối',
                        request.rejectionReason!,
                        isDark,
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Action buttons based on status
            if (request.status == StudentVerificationStatus.rejected ||
                request.status == StudentVerificationStatus.expired)
              ElevatedButton.icon(
                onPressed: () {
                  provider.reset();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Gửi yêu cầu mới'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppTheme.accentCyan,
                  foregroundColor: Colors.white,
                ),
              ),

            if (request.status == StudentVerificationStatus.approved &&
                provider.canBuyStudentPremium)
              ElevatedButton.icon(
                onPressed: () => context.go('/premium'),
                icon: const Icon(Icons.workspace_premium),
                label: const Text('Xem gói Student Premium'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppTheme.accentGold,
                  foregroundColor: Colors.black,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusMessage(
    StudentVerificationDetailResponse request,
    bool isDark,
  ) {
    String message;
    switch (request.status) {
      case StudentVerificationStatus.pendingReview:
        message =
            'Yêu cầu đã được gửi thành công. Admin đang xem xét hồ sơ của bạn.';
        break;
      case StudentVerificationStatus.approved:
        message = 'Bạn đã được xác minh là sinh viên. Hãy mua gói Student Premium!';
        break;
      case StudentVerificationStatus.rejected:
        message =
            'Yêu cầu bị từ chối. Bạn có thể gửi lại với thông tin chính xác hơn.';
        break;
      case StudentVerificationStatus.expired:
        message = 'Yêu cầu đã hết hạn. Vui lòng gửi lại.';
        break;
      default:
        message = 'Đang xử lý...';
    }

    return Text(
      message,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
      ),
    );
  }

  Widget _detailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
