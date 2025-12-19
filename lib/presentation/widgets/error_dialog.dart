import 'package:flutter/material.dart';
import 'package:skillverse_mobile/presentation/themes/app_theme.dart';
import 'package:skillverse_mobile/presentation/widgets/glass_card.dart';

/// Galaxy-themed error dialog with glass morphism design
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final VoidCallback? onRetry;
  final String? retryButtonText;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.onRetry,
    this.retryButtonText,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error Icon with red gradient
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFDC2626), // Red-600
                    Color(0xFFEF4444), // Red-500
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon ?? Icons.error_outline,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              message,
              style: const TextStyle(
                color: AppTheme.darkTextSecondary,
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                // Close button
                Expanded(
                  child: _buildButton(
                    context: context,
                    label: 'Đóng',
                    onPressed: () => Navigator.of(context).pop(),
                    isPrimary: false,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(width: 12),
                  // Retry button
                  Expanded(
                    child: _buildButton(
                      context: context,
                      label: retryButtonText ?? 'Thử lại',
                      onPressed: () {
                        Navigator.of(context).pop();
                        onRetry?.call();
                      },
                      isPrimary: true,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: isPrimary
            ? const LinearGradient(
                colors: [
                  Color(0xFFDC2626), // Red-600
                  Color(0xFFEF4444), // Red-500
                ],
              )
            : null,
        color: isPrimary ? null : AppTheme.darkCardBackground,
        borderRadius: BorderRadius.circular(8),
        border: isPrimary
            ? null
            : Border.all(
                color: AppTheme.darkBorderColor,
              ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : AppTheme.darkTextSecondary,
                fontSize: 16,
                fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Show error dialog with retry option
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    IconData? icon,
    VoidCallback? onRetry,
    String? retryButtonText,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        icon: icon,
        onRetry: onRetry,
        retryButtonText: retryButtonText,
      ),
    );
  }

  /// Show simple error dialog
  static Future<void> showSimple(
    BuildContext context,
    String message, {
    String? title,
  }) {
    return show(
      context: context,
      title: title ?? 'Có lỗi xảy ra',
      message: message,
    );
  }

  /// Show network error dialog with retry
  static Future<void> showNetworkError(
    BuildContext context, {
    required VoidCallback onRetry,
  }) {
    return show(
      context: context,
      title: 'Lỗi kết nối',
      message: 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra Internet và thử lại.',
      icon: Icons.wifi_off,
      onRetry: onRetry,
    );
  }

  /// Show validation error dialog
  static Future<void> showValidationError(
    BuildContext context,
    String message,
  ) {
    return show(
      context: context,
      title: 'Dữ liệu không hợp lệ',
      message: message,
      icon: Icons.warning_amber_outlined,
    );
  }
}

/// Success dialog with galaxy theme
class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onContinue;
  final String? continueButtonText;

  const SuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.onContinue,
    this.continueButtonText,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon with green gradient
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppTheme.greenGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.themeGreenStart.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              message,
              style: const TextStyle(
                color: AppTheme.darkTextSecondary,
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Continue Button
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppTheme.greenGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    onContinue?.call();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Center(
                    child: Text(
                      continueButtonText ?? 'Đồng ý',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show success dialog
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onContinue,
    String? continueButtonText,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuccessDialog(
        title: title,
        message: message,
        onContinue: onContinue,
        continueButtonText: continueButtonText,
      ),
    );
  }
}

/// Confirmation dialog with galaxy theme
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmButtonText;
  final String cancelButtonText;
  final VoidCallback onConfirm;
  final bool isDangerous;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.confirmButtonText = 'Xác nhận',
    this.cancelButtonText = 'Hủy',
    this.isDangerous = false,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = isDangerous
        ? const LinearGradient(
            colors: [Color(0xFFDC2626), Color(0xFFEF4444)], // Red gradient
          )
        : AppTheme.orangeGradient;

    final icon = isDangerous ? Icons.warning_amber : Icons.help_outline;
    final iconColor = isDangerous ? const Color(0xFFDC2626) : AppTheme.themeOrangeStart;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning/Question Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: gradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              message,
              style: const TextStyle(
                color: AppTheme.darkTextSecondary,
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.darkCardBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.darkBorderColor),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(false),
                        borderRadius: BorderRadius.circular(8),
                        child: Center(
                          child: Text(
                            cancelButtonText,
                            style: const TextStyle(
                              color: AppTheme.darkTextSecondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Confirm button
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pop(true);
                          onConfirm();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Center(
                          child: Text(
                            confirmButtonText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Show confirmation dialog
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmButtonText = 'Xác nhận',
    String cancelButtonText = 'Hủy',
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        onConfirm: onConfirm,
        confirmButtonText: confirmButtonText,
        cancelButtonText: cancelButtonText,
        isDangerous: isDangerous,
      ),
    );

    return result ?? false;
  }

  /// Show delete confirmation dialog
  static Future<bool> showDeleteConfirmation({
    required BuildContext context,
    required String itemName,
    required VoidCallback onConfirm,
  }) {
    return show(
      context: context,
      title: 'Xác nhận xóa',
      message: 'Bạn có chắc chắn muốn xóa "$itemName"? Thao tác này không thể hoàn tác.',
      onConfirm: onConfirm,
      confirmButtonText: 'Xóa',
      cancelButtonText: 'Hủy',
      isDangerous: true,
    );
  }
}
