import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/validation_helper.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/exceptions/api_exception.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common_loading.dart';
import '../../widgets/glass_card.dart';

/// Bottom sheet cho phép người dùng đã đăng nhập đổi mật khẩu.
/// Được mở từ ProfileSettingsPage hoặc trang Settings.
class ChangePasswordSheet extends StatefulWidget {
  const ChangePasswordSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ChangePasswordSheet(),
    );
  }

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _currentFocus = FocusNode();
  final _newFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _isSaving = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _authService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ErrorHandler.showSuccessSnackBar(
        context,
        'Đổi mật khẩu thành công!',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(
        context,
        e.message.isNotEmpty ? e.message : 'Mật khẩu hiện tại không đúng.',
      );
    } catch (_) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, 'Đã có lỗi xảy ra. Thử lại sau.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCardBackground : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Đổi mật khẩu',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Current password
                  _buildPasswordField(
                    controller: _currentPasswordController,
                    focusNode: _currentFocus,
                    label: 'Mật khẩu hiện tại',
                    showPassword: _showCurrentPassword,
                    onToggle: () => setState(
                      () => _showCurrentPassword = !_showCurrentPassword,
                    ),
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _newFocus.requestFocus(),
                    validator: (v) =>
                        ValidationHelper.required(v, fieldName: 'Mật khẩu hiện tại'),
                  ),
                  const SizedBox(height: 12),

                  // New password
                  _buildPasswordField(
                    controller: _newPasswordController,
                    focusNode: _newFocus,
                    label: 'Mật khẩu mới',
                    showPassword: _showNewPassword,
                    onToggle: () => setState(
                      () => _showNewPassword = !_showNewPassword,
                    ),
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
                    validator: (v) => ValidationHelper.password(v),
                  ),
                  const SizedBox(height: 12),

                  // Confirm password
                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    focusNode: _confirmFocus,
                    label: 'Xác nhận mật khẩu mới',
                    showPassword: _showConfirmPassword,
                    onToggle: () => setState(
                      () => _showConfirmPassword = !_showConfirmPassword,
                    ),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Vui lòng xác nhận mật khẩu mới';
                      }
                      if (v != _newPasswordController.text) {
                        return 'Mật khẩu xác nhận không khớp';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 8),

                  // Password strength hint
                  Text(
                    '• Tối thiểu 8 ký tự, 1 chữ hoa, 1 chữ thường, 1 chữ số',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? CommonLoading.small()
                          : const Text(
                              'Đổi mật khẩu',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required bool showPassword,
    required VoidCallback onToggle,
    required TextInputAction textInputAction,
    required void Function(String) onFieldSubmitted,
    required String? Function(String?) validator,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(4),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: !showPassword,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(
              showPassword ? Icons.visibility_off : Icons.visibility,
              size: 20,
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        validator: validator,
        inputFormatters: [
          FilteringTextInputFormatter.deny(RegExp(r'\s')),
        ],
      ),
    );
  }
}
