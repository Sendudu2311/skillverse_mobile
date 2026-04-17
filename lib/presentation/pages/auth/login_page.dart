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
      ErrorHandler.showErrorSnackBar(
        context,
        authProvider.errorMessage ?? 'Đăng nhập thất bại',
      );
    }
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

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'hoặc',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 24),

                // Google Sign In Button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return OutlinedButton.icon(
                      onPressed: authProvider.isLoading
                          ? null
                          : _handleGoogleSignIn,
                      icon: authProvider.isLoading
                          ? CommonLoading.small()
                          : Image.asset(
                              'assets/google_logo.png',
                              height: 24,
                              width: 24,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.g_mobiledata, size: 24);
                              },
                            ),
                      label: const Text('Đăng nhập với Google'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Register Button
                OutlinedButton(
                  onPressed: () => context.go('/register'),
                  child: const Text('Tạo tài khoản mới'),
                ),

                const SizedBox(height: 32),

                // Demo Accounts Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.speed,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Semantics(
                            label: 'demo_accounts_header',
                            child: Text(
                              'DEMO ACCOUNTS',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          return Column(
                            children: [
                              // Demo Account 1
                              OutlinedButton.icon(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : () => _quickLogin(
                                        'phuonganh160268@gmail.com',
                                        'Duy071204@',
                                      ),
                                icon: const Icon(Icons.person, size: 16),
                                label: const Text(
                                  'phuonganh160268@gmail.com',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  minimumSize: const Size(double.infinity, 36),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Demo Account 2
                              OutlinedButton.icon(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : () => _quickLogin(
                                        'duy071204@gmail.com',
                                        'Duy071204@',
                                      ),
                                icon: const Icon(Icons.person, size: 16),
                                label: const Text(
                                  'duy071204@gmail.com',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  minimumSize: const Size(double.infinity, 36),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
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
