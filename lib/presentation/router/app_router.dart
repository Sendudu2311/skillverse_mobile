import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/register_page.dart';
import '../pages/auth/verify_email_page.dart';
import '../pages/auth/forgot_password_page.dart';
import '../pages/home/home_page.dart';
import '../pages/dashboard/dashboard_page.dart';
import '../pages/courses/courses_page.dart';
import '../pages/courses/course_detail_page.dart';
import '../pages/chat/chat_page.dart';
import '../pages/profile/profile_page.dart';
import '../pages/profile/profile_settings_page.dart';
import '../pages/portfolio/portfolio_page.dart';
import '../pages/premium/premium_plans_page.dart';
import '../pages/payment/payment_history_page.dart';
import '../pages/community/community_page.dart';
import '../pages/community/post_detail_page.dart';
import '../pages/community/post_form_page.dart';
import '../pages/splash_page.dart';
import '../widgets/main_layout.dart';
import '../providers/auth_provider.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/splash',
    redirect: (context, state) {
      final authProvider = context.read<AuthProvider>();
      final isAuthenticated = authProvider.isAuthenticated;
      final isLoading = authProvider.isLoading;

      // Show splash while loading
      if (isLoading) {
        return '/splash';
      }

      // Redirect to login if not authenticated (except for auth pages)
      if (!isAuthenticated) {
        final authPages = [
          '/login',
          '/register',
          '/verify-email',
          '/forgot-password',
        ];
        if (!authPages.contains(state.matchedLocation)) {
          return '/login';
        }
      }

      // Redirect to dashboard if authenticated and on auth pages
      if (isAuthenticated) {
        final authPages = [
          '/login',
          '/register',
          '/verify-email',
          '/forgot-password',
          '/splash',
        ];
        if (authPages.contains(state.matchedLocation)) {
          return '/dashboard';
        }
      }

      return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),

      // Authentication Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/verify-email',
        name: 'verify-email',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return VerifyEmailPage(email: email);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),

      // Main App Routes
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => MainLayout(
          currentPath: state.matchedLocation,
          child: const HomePage(),
        ),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => MainLayout(
          currentPath: state.matchedLocation,
          child: const DashboardPage(),
        ),
      ),

      // Courses Routes
      GoRoute(
        path: '/courses',
        name: 'courses',
        builder: (context, state) => MainLayout(
          currentPath: state.matchedLocation,
          child: const CoursesPage(),
        ),
      ),
      GoRoute(
        path: '/courses/:courseId',
        name: 'course-detail',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          return CourseDetailPage(courseId: courseId);
        },
      ),

      // Chat Route
      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (context, state) => MainLayout(
          currentPath: state.matchedLocation,
          child: const ChatPage(),
        ),
      ),

      // Community Routes
      GoRoute(
        path: '/community',
        name: 'community',
        builder: (context, state) => MainLayout(
          currentPath: state.matchedLocation,
          child: const CommunityPage(),
        ),
      ),
      GoRoute(
        path: '/community/create',
        name: 'community-create',
        builder: (context, state) => const PostFormPage(),
      ),
      GoRoute(
        path: '/community/:postId',
        name: 'community-detail',
        builder: (context, state) {
          final postId = int.parse(state.pathParameters['postId']!);
          return PostDetailPage(postId: postId);
        },
      ),
      GoRoute(
        path: '/community/:postId/edit',
        name: 'community-edit',
        builder: (context, state) {
          final postId = int.parse(state.pathParameters['postId']!);
          return PostFormPage(postId: postId);
        },
      ),

      // Premium Route
      GoRoute(
        path: '/premium',
        name: 'premium',
        builder: (context, state) => const PremiumPlansPage(),
      ),

      // Profile Route with subroutes
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => MainLayout(
          currentPath: state.matchedLocation,
          child: const ProfilePage(),
        ),
        routes: [
          GoRoute(
            path: 'edit',
            name: 'profile-edit',
            builder: (context, state) => const ProfileSettingsPage(),
          ),
          GoRoute(
            path: 'certificates',
            name: 'profile-certificates',
            builder: (context, state) => MainLayout(
              currentPath: state.matchedLocation,
              child: Scaffold(
                appBar: AppBar(title: const Text('Chứng chỉ')),
                body: const Center(child: Text('Certificates placeholder')),
              ),
            ),
          ),
          GoRoute(
            path: 'payments',
            name: 'profile-payments',
            builder: (context, state) => const PaymentHistoryPage(),
          ),
          GoRoute(
            path: 'settings',
            name: 'profile-settings',
            builder: (context, state) => Scaffold(
              appBar: AppBar(title: const Text('Cài đặt')),
              body: const Center(child: Text('Settings page - Coming soon')),
            ),
          ),
        ],
      ),

      // Portfolio Route
      GoRoute(
        path: '/portfolio',
        name: 'portfolio',
        builder: (context, state) => MainLayout(
          currentPath: state.matchedLocation,
          child: const PortfolioPage(),
        ),
      ),
    ],

    // Error page
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Lỗi')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Trang không tìm thấy',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Đường dẫn: ${state.matchedLocation}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Về trang chủ'),
            ),
          ],
        ),
      ),
    ),
  );
}
