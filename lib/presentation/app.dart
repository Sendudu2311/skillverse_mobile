import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import 'providers/auth_provider.dart';
import 'pages/splash/splash_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/register_page.dart';
import 'pages/auth/verify_email_page.dart';
import 'pages/auth/forgot_password_page.dart';
import 'pages/home/home_page.dart';
import 'pages/dashboard/dashboard_page.dart';
import 'pages/courses/courses_page.dart';
import 'pages/courses/course_detail_page.dart';
import 'pages/courses/course_learning_page.dart';
import 'pages/jobs/jobs_page.dart';
import 'pages/help/help_center_page.dart';
import 'pages/portfolio/portfolio_page.dart';
import 'pages/legal/privacy_policy_page.dart';
import 'pages/terms/terms_of_service_page.dart';
import 'pages/roadmap/roadmap_page.dart';
import 'pages/profile/profile_page.dart';
import 'pages/chat/chat_page.dart';
import 'widgets/main_layout.dart';
import 'themes/app_theme.dart';

class SkillVerseApp extends StatefulWidget {
  const SkillVerseApp({super.key});

  @override
  State<SkillVerseApp> createState() => _SkillVerseAppState();
}

class _SkillVerseAppState extends State<SkillVerseApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _createRouter();
    
    // Initialize auth
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().initialize();
    });
  }

  GoRouter _createRouter() {
    return GoRouter(
      initialLocation: '/',
      routes: [
        // Splash
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashPage(),
        ),
        
        // Auth routes
        GoRoute(
          path: AppConstants.loginRoute,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: AppConstants.registerRoute,
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: '/verify-email',
          builder: (context, state) {
            final email = state.uri.queryParameters['email'] ?? '';
            return VerifyEmailPage(email: email);
          },
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordPage(),
        ),
        
        // Main app routes wrapped in MainLayout so pages render inside the app scaffold
        GoRoute(
          path: AppConstants.homeRoute,
          builder: (context, state) => MainLayout(
            currentPath: state.matchedLocation,
            child: const HomePage(),
          ),
        ),
        GoRoute(
          path: AppConstants.dashboardRoute,
          builder: (context, state) => MainLayout(
            currentPath: state.matchedLocation,
            child: const DashboardPage(),
          ),
        ),
        GoRoute(
          path: AppConstants.coursesRoute,
          builder: (context, state) => MainLayout(
            currentPath: state.matchedLocation,
            child: const CoursesPage(),
          ),
        ),
        GoRoute(
          path: '${AppConstants.coursesRoute}/:courseId/learning',
          builder: (context, state) {
            final courseId = state.pathParameters['courseId'] ?? '';
            return MainLayout(
              currentPath: state.matchedLocation,
              child: CourseLearningPage(courseId: courseId),
            );
          },
        ),
        GoRoute(
          path: '${AppConstants.coursesRoute}/:courseId',
          builder: (context, state) {
            final courseId = state.pathParameters['courseId'] ?? '';
            return MainLayout(
              currentPath: state.matchedLocation,
              child: CourseDetailPage(courseId: courseId),
            );
          },
        ),
        GoRoute(
          path: AppConstants.profileRoute,
          builder: (context, state) => MainLayout(
            currentPath: state.matchedLocation,
            child: const ProfilePage(),
          ),
        ),
        GoRoute(
          path: '/chat',
          builder: (context, state) => MainLayout(
            currentPath: state.matchedLocation,
              child: const ChatPage(),
          ),
        ),
        GoRoute(
          path: '/help',
          builder: (context, state) => MainLayout(
            currentPath: state.matchedLocation,
            child: const HelpCenterPage(),
          ),
        ),
        GoRoute(
          path: '/portfolio',
          builder: (context, state) => MainLayout(
            currentPath: state.matchedLocation,
            child: const PortfolioPage(),
          ),
        ),
        GoRoute(
          path: '/privacy',
          builder: (context, state) => MainLayout(
            currentPath: state.matchedLocation,
            child: const PrivacyPolicyPage(),
          ),
        ),
        GoRoute(
          path: '/terms',
          builder: (context, state) => MainLayout(
            currentPath: state.matchedLocation,
            child: const TermsOfServicePage(),
          ),
        ),
        GoRoute(
          path: '/roadmap',
          builder: (context, state) => MainLayout(
            currentPath: state.matchedLocation,
            child: const RoadmapPage(),
          ),
        ),
        GoRoute(
          path: '/jobs',
          builder: (context, state) => MainLayout(
            currentPath: state.matchedLocation,
            child: const JobsPage(),
          ),
        ),
      ],
      redirect: (context, state) {
        final authProvider = context.read<AuthProvider>();
        final isAuthenticated = authProvider.isAuthenticated;
        final isAuthRoute = [
          AppConstants.loginRoute,
          AppConstants.registerRoute,
          '/verify-email',
          '/forgot-password',
        ].contains(state.matchedLocation);

        // If loading, stay on splash
        if (authProvider.isLoading && state.matchedLocation == '/') {
          return null;
        }

        // If not authenticated and not on auth route, go to login
        if (!isAuthenticated && !isAuthRoute && state.matchedLocation != '/') {
          return AppConstants.loginRoute;
        }

        // If authenticated and on auth route, go to dashboard
        if (isAuthenticated && isAuthRoute) {
          return AppConstants.dashboardRoute;
        }

        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Always light for minimal design
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}