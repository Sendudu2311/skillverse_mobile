import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/error_handler.dart';
import '../../widgets/common_loading.dart';
import '../../widgets/skillverse_app_bar.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement forgot password API call
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      setState(() {
        _emailSent = true;
        _isLoading = false;
      });

      if (mounted) {
        ErrorHandler.showSuccessSnackBar(context, 'Hướng dẫn đặt lại mật khẩu đã được gửi đến email của bạn');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, 'Có lỗi xảy ra: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SkillVerseAppBar(
        title: 'Quên mật khẩu',
        onBack: () => context.go('/login'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                
                // Icon and Title
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _emailSent ? Icons.check_circle_outline : Icons.lock_reset,
                          size: 40,
                          color: _emailSent 
                              ? Colors.green 
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Text(
                        _emailSent ? 'Email đã được gửi!' : 'Quên mật khẩu?',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Text(
                        _emailSent
                            ? 'Vui lòng kiểm tra email và làm theo hướng dẫn để đặt lại mật khẩu.'
                            : 'Nhập địa chỉ email của bạn và chúng tôi sẽ gửi hướng dẫn đặt lại mật khẩu.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),
                
                if (!_emailSent) ...[
                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Nhập địa chỉ email của bạn',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Email không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Reset Password Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleResetPassword,
                    child: _isLoading
                        ? CommonLoading.small()
                        : const Text('Gửi hướng dẫn'),
                  ),
                ] else ...[
                  // Success Actions
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Quay lại đăng nhập'),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _emailSent = false;
                        _emailController.clear();
                      });
                    },
                    child: const Text('Gửi lại email'),
                  ),
                ],
                
                const SizedBox(height: 32),
                
                // Back to Login
                if (!_emailSent)
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Quay lại đăng nhập'),
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Help Text
                Center(
                  child: Text(
                    'Cần hỗ trợ? Liên hệ support@skillverse.com',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}