/// Example usage of centralized error handling system
///
/// This file demonstrates how to use:
/// - ErrorHandler for catching exceptions and showing errors
/// - ValidationHelper for form field validation
/// - ErrorDialog for custom error dialogs
library;

// ignore_for_file: unused_element, unused_local_variable

import 'package:flutter/material.dart';
import 'error_handler.dart';
import 'validation_helper.dart';
import '../../presentation/widgets/error_dialog.dart';

/// Example 1: Using ValidationHelper in forms
class _FormValidationExample extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _slugController = TextEditingController();

  _FormValidationExample();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Required field validation
          TextFormField(
            validator: (value) => ValidationHelper.required(
              value,
              fieldName: 'Email',
            ),
          ),

          // Email validation
          TextFormField(
            controller: _emailController,
            validator: ValidationHelper.email,
          ),

          // URL validation (optional)
          TextFormField(
            controller: _websiteController,
            validator: (value) => ValidationHelper.url(
              value,
              isRequired: false,
            ),
          ),

          // Slug validation
          TextFormField(
            controller: _slugController,
            validator: (value) => ValidationHelper.slug(
              value,
              isRequired: true,
            ),
          ),

          // Length validation
          TextFormField(
            validator: (value) => ValidationHelper.lengthRange(
              value,
              8,
              100,
              fieldName: 'Mật khẩu',
            ),
          ),

          // Combining multiple validators
          TextFormField(
            validator: ValidationHelper.combine([
              (value) => ValidationHelper.required(value, fieldName: 'Tên'),
              (value) => ValidationHelper.minLength(value, 3, fieldName: 'Tên'),
              (value) => ValidationHelper.maxLength(value, 50, fieldName: 'Tên'),
            ]),
          ),

          // GitHub repository URL validation
          TextFormField(
            validator: (value) => ValidationHelper.githubRepoUrl(
              value,
              isRequired: false,
            ),
          ),
        ],
      ),
    );
  }
}

/// Example 2: Using ErrorHandler for exceptions
class _ErrorHandlerExample {
  Future<void> saveData(BuildContext context) async {
    try {
      // Your API call here
      // await apiService.save(...);

      // Success
      ErrorHandler.showSuccessSnackBar(context, 'Lưu thành công!');
    } catch (e) {
      // Automatically converts exception to user-friendly message
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Future<void> loadDataWithWarning(BuildContext context) async {
    try {
      // Some operation
      ErrorHandler.showWarningSnackBar(
        context,
        'Dữ liệu có thể không đầy đủ',
      );
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  // Using handleAsync helper
  Future<void> saveWithHelper(BuildContext context) async {
    final result = await ErrorHandler.handleAsync(
      operation: () async {
        // Your async operation
        return await Future.value('Success');
      },
      context: context,
      successMessage: 'Lưu thành công!',
    );

    if (result != null) {
      // Handle success
    }
  }
}

/// Example 3: Using ErrorDialog
class _ErrorDialogExample {
  // Show simple error
  Future<void> showSimpleError(BuildContext context) async {
    await ErrorDialog.showSimple(
      context,
      'Không thể tải dữ liệu. Vui lòng thử lại.',
      title: 'Lỗi tải dữ liệu',
    );
  }

  // Show network error with retry
  Future<void> showNetworkError(BuildContext context) async {
    await ErrorDialog.showNetworkError(
      context,
      onRetry: () {
        // Retry logic here
        print('Retrying...');
      },
    );
  }

  // Show validation error
  Future<void> showValidationError(BuildContext context) async {
    await ErrorDialog.showValidationError(
      context,
      'Email không hợp lệ. Vui lòng kiểm tra lại.',
    );
  }

  // Show custom error with retry
  Future<void> showCustomError(BuildContext context) async {
    await ErrorDialog.show(
      context: context,
      title: 'Lỗi tải dữ liệu',
      message: 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra Internet.',
      icon: Icons.cloud_off,
      onRetry: () async {
        // Your retry logic
      },
      retryButtonText: 'Thử lại',
    );
  }
}

/// Example 4: Using SuccessDialog
class _SuccessDialogExample {
  Future<void> showSuccess(BuildContext context) async {
    await SuccessDialog.show(
      context: context,
      title: 'Thành công!',
      message: 'Dữ liệu của bạn đã được lưu thành công.',
      onContinue: () {
        // Navigate or perform action
      },
      continueButtonText: 'Tiếp tục',
    );
  }
}

/// Example 5: Using ConfirmationDialog
class _ConfirmationDialogExample {
  Future<void> showConfirmation(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Xác nhận lưu',
      message: 'Bạn có chắc chắn muốn lưu thay đổi?',
      onConfirm: () {
        // Save logic
        print('Confirmed!');
      },
      confirmButtonText: 'Lưu',
      cancelButtonText: 'Hủy',
    );

    if (confirmed) {
      // User confirmed
    }
  }

  Future<void> showDeleteConfirmation(BuildContext context) async {
    final confirmed = await ConfirmationDialog.showDeleteConfirmation(
      context: context,
      itemName: 'Dự án ABC',
      onConfirm: () {
        // Delete logic
        print('Deleted!');
      },
    );

    if (confirmed) {
      // Item deleted
    }
  }

  Future<void> showDangerousAction(BuildContext context) async {
    await ConfirmationDialog.show(
      context: context,
      title: 'Xóa tài khoản',
      message: 'Bạn có chắc chắn muốn xóa tài khoản? Hành động này không thể hoàn tác.',
      onConfirm: () {
        // Dangerous action
      },
      isDangerous: true,
      confirmButtonText: 'Xóa',
    );
  }
}

/// Example 6: Complete form with error handling
class _CompleteFormExample extends StatefulWidget {
  const _CompleteFormExample();

  @override
  State<_CompleteFormExample> createState() => _CompleteFormExampleState();
}

class _CompleteFormExampleState extends State<_CompleteFormExample> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      ErrorHandler.showWarningSnackBar(
        context,
        'Vui lòng kiểm tra lại thông tin đã nhập',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Success
      ErrorHandler.showSuccessSnackBar(context, 'Lưu thành công!');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Form Example')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tên'),
              validator: (value) => ValidationHelper.required(
                value,
                fieldName: 'Tên',
              ),
            ),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: ValidationHelper.email,
            ),
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(labelText: 'Website'),
              validator: (value) => ValidationHelper.url(
                value,
                isRequired: false,
              ),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example 7: Specialized validators
class _SpecializedValidatorsExample {
  void demonstrateValidators() {
    // Phone number (Vietnamese format)
    final phoneError = ValidationHelper.phoneNumber('0123456789');

    // GitHub repository URL
    final githubError = ValidationHelper.githubRepoUrl(
      'https://github.com/user/repo',
    );

    // LinkedIn profile URL
    final linkedInError = ValidationHelper.linkedInUrl(
      'https://linkedin.com/in/username',
    );

    // Twitter username
    final twitterError = ValidationHelper.twitterUsername('@username');

    // GitHub username
    final githubUsernameError = ValidationHelper.githubUsername('username');

    // Password strength
    final passwordError = ValidationHelper.password('MyPass123');

    // Confirm password
    final confirmError = ValidationHelper.confirmPassword(
      'MyPass123',
      'MyPass123',
    );

    // Date format
    final dateError = ValidationHelper.dateFormat('2024-01-01');

    // Number range
    final rangeError = ValidationHelper.numberRange('50', 0, 100);
  }
}
