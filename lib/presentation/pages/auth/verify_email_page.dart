import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../../core/utils/error_handler.dart';
import '../../widgets/common_loading.dart';
import '../../widgets/skillverse_app_bar.dart';

class VerifyEmailPage extends StatefulWidget {
  final String email;
  
  const VerifyEmailPage({super.key, required this.email});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  Timer? _timer;
  int _countdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _canResend = false;
    _countdown = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _handleVerification() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    
    final success = await authProvider.verifyEmail(
      widget.email,
      _otpController.text.trim(),
    );

    if (success && mounted) {
      ErrorHandler.showSuccessSnackBar(context, 'Xác thực email thành công!');
      context.go('/login');
    } else if (mounted) {
      ErrorHandler.showErrorSnackBar(context, authProvider.errorMessage ?? 'Xác thực thất bại');
    }
  }

  Future<void> _handleResendOtp() async {
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.resendOtp(widget.email);

    if (success && mounted) {
      ErrorHandler.showSuccessSnackBar(context, 'OTP đã được gửi lại thành công');
      _startCountdown();
    } else if (mounted) {
      ErrorHandler.showErrorSnackBar(context, authProvider.errorMessage ?? 'Gửi lại OTP thất bại');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SkillVerseAppBar(
        title: 'Xác thực Email',
        onBack: () => context.go('/register'),
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
                          Icons.mark_email_read_outlined,
                          size: 40,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Text(
                        'Xác thực Email',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                          children: [
                            const TextSpan(text: 'Chúng tôi đã gửi mã xác thực đến\n'),
                            TextSpan(
                              text: widget.email,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // OTP Field
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    letterSpacing: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Mã xác thực',
                    hintText: '000000',
                    prefixIcon: Icon(Icons.security),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mã xác thực';
                    }
                    if (value.length != 6) {
                      return 'Mã xác thực phải có 6 chữ số';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Verify Button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _handleVerification,
                      child: authProvider.isLoading
                          ? CommonLoading.small()
                          : const Text('Xác thực'),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Resend OTP Section
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Không nhận được mã?',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      if (_canResend)
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            return TextButton(
                              onPressed: authProvider.isLoading ? null : _handleResendOtp,
                              child: const Text('Gửi lại mã'),
                            );
                          },
                        )
                      else
                        Text(
                          'Gửi lại mã sau $_countdown giây',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Change Email
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('Thay đổi địa chỉ email'),
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