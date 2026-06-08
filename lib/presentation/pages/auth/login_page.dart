import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../../core/utils/error_handler.dart';
import '../../widgets/common_loading.dart';
import '../../../core/utils/validation_helper.dart';
import '../../../data/services/journey_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Show logout reason (e.g. ACCOUNT_LOGGED_ELSEWHERE) after redirect
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final reason = authProvider.logoutReason;
      if (reason != null && mounted) {
        ErrorHandler.showWarningSnackBar(context, reason);
        authProvider.clearLogoutReason();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      await _navigateAfterAuth();
    } else if (mounted) {
      final errorMsg = authProvider.errorMessage ?? 'Đăng nhập thất bại';

      // Detect EMAIL_NOT_VERIFIED from backend error message
      if (_isEmailNotVerifiedError(errorMsg)) {
        ErrorHandler.showWarningSnackBar(
          context,
          'Email chưa được xác thực. Vui lòng kiểm tra email của bạn.',
        );
        // Navigate to verify-email page with the entered email
        final email = Uri.encodeComponent(_emailController.text.trim());
        context.go('/verify-email?email=$email');
      } else {
        ErrorHandler.showErrorSnackBar(context, errorMsg);
      }
    }
  }

  /// Check if the error indicates that the user's email is not verified.
  /// Backend returns message containing 'EMAIL_NOT_VERIFIED' or 'verify your email'.
  bool _isEmailNotVerifiedError(String errorMsg) {
    final lower = errorMsg.toLowerCase();
    return lower.contains('email_not_verified') ||
        lower.contains('email not verified') ||
        lower.contains('verify your email') ||
        lower.contains('xác thực email');
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.signInWithGoogle();

    if (success && mounted) {
      await _navigateAfterAuth();
    } else if (mounted) {
      ErrorHandler.showErrorSnackBar(
        context,
        authProvider.errorMessage ?? 'Đăng nhập Google thất bại',
      );
    }
  }

  /// Check if user has any journeys. If not, redirect to /journey/create
  /// for onboarding assessment. Otherwise, go to /dashboard.
  Future<void> _navigateAfterAuth() async {
    if (!mounted) return;
    try {
      final journeys = await JourneyService().getUserJourneys(page: 0, size: 1);
      if (!mounted) return;
      if (journeys.isEmpty) {
        context.go('/journey/create');
      } else {
        context.go('/dashboard');
      }
    } catch (_) {
      // Fallback to dashboard if journey check fails
      if (mounted) context.go('/dashboard');
    }
  }

  Future<void> _quickLogin(String email, String password) async {
    _emailController.text = email;
    _passwordController.text = password;
    await _handleLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // Logo and Title
                Center(
                  child: Column(
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: Image.asset(
                          'assets/skillverse.png',
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Semantics(
                        label: 'welcome_title',
                        child: Text(
                          'Chào mừng trở lại!',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Đăng nhập để tiếp tục hành trình học tập',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Nhập địa chỉ email của bạn',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) => ValidationHelper.email(value),
                ),

                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    hintText: 'Nhập mật khẩu của bạn',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) => ValidationHelper.password(value),
                ),

                const SizedBox(height: 16),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.go('/forgot-password'),
                    child: const Text('Quên mật khẩu?'),
                  ),
                ),

                const SizedBox(height: 24),

                // Login Button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _handleLogin,
                      child: authProvider.isLoading
                          ? CommonLoading.small()
                          : const Text('Đăng nhập'),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Register Button
                OutlinedButton(
                  onPressed: () => context.go('/register'),
                  child: const Text('Tạo tài khoản mới'),
                ),


              ],
            ),
          ),
        ),
      ),
    );
  }
}
