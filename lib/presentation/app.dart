import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
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
import 'pages/courses/my_courses_page.dart';
import 'pages/jobs/jobs_page.dart';
import 'pages/help/help_center_page.dart';
import 'pages/portfolio/portfolio_page.dart';
import 'pages/legal/privacy_policy_page.dart';
import 'pages/terms/terms_of_service_page.dart';
import 'pages/roadmap/roadmap_page.dart';
import 'pages/roadmap/roadmap_generate_page.dart';
import 'pages/roadmap/roadmap_detail_page.dart';
import 'pages/profile/profile_page.dart';
import 'pages/profile/profile_settings_page.dart';
import 'pages/chat/chat_page.dart';
import 'pages/premium/premium_plans_page.dart';
import 'pages/payment/payment_history_page.dart';
import 'pages/community/community_page.dart';
import 'pages/community/post_detail_page.dart';
import 'pages/community/post_form_page.dart';
import 'pages/mentor/mentor_list_page.dart';
import 'pages/mentor/mentor_detail_page.dart';
import 'pages/mentor/my_bookings_page.dart';
import 'pages/skin/skin_shop_page.dart';
import 'pages/task_board/task_board_page.dart';
import 'pages/expert_chat/expert_chat_landing_page.dart';
import 'pages/expert_chat/domain_selection_page.dart';
import 'pages/expert_chat/role_selection_page.dart';
import 'pages/expert_chat/expert_chat_page.dart';
import 'widgets/main_layout.dart';
import 'themes/app_theme.dart';

class SkillVerseApp extends StatefulWidget {
  const SkillVerseApp({super.key});

  @override
  State<SkillVerseApp> createState() => _SkillVerseAppState();
}

class _SkillVerseAppState extends State<SkillVerseApp> {
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Create router only once when dependencies are ready
    _router ??= _createRouter();
  }

  GoRouter _createRouter() {
    final authProvider = context.read<AuthProvider>();

    // Initialize auth on first router creation (deferred to avoid build conflicts)
    Future.microtask(() => authProvider.initialize());

    return GoRouter(
      initialLocation: '/',
      refreshListenable:
          authProvider, // Listen to auth changes for auto-redirect
      routes: [
        // Splash
        GoRoute(path: '/', builder: (context, state) => const SplashPage()),

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
          path: '/my-courses',
          builder: (context, state) => MainLayout(
            currentPath: state.matchedLocation,
            child: const MyCoursesPage(),
          ),
        ),
        GoRoute(
          path: AppConstants.profileRoute,
          builder: (context, state) => MainLayout(
            currentPath: state.matchedLocation,
            child: const ProfilePage(),
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => const ProfileSettingsPage(),
            ),

            GoRoute(
              path: 'courses/:id',
              builder: (context, state) => const ProfileSettingsPage(),
            ),
            GoRoute(
              path: 'settings',
              builder: (context, state) => Scaffold(
                appBar: AppBar(title: const Text('Cài đặt')),
                body: const Center(child: Text('Settings page - Coming soon')),
              ),
            ),
            GoRoute(
              path: 'payments',
              builder: (context, state) => const PaymentHistoryPage(),
            ),
          ],
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
          path: '/roadmap/generate',
          builder: (context, state) => const RoadmapGeneratePage(),
        ),
        GoRoute(
          path: '/roadmap/:sessionId',
          builder: (context, state) {
            final sessionId = int.parse(state.pathParameters['sessionId']!);
            return RoadmapDetailPage(sessionId: sessionId);
          },
        ),
        GoRoute(
          path: '/jobs',
          builder: (context, state) => MainLayout(
            currentPath: state.matchedLocation,
            child: const JobsPage(),
          ),
        ),

        // Community Routes
        GoRoute(
          path: '/community',
          builder: (context, state) => MainLayout(
            currentPath: state.matchedLocation,
            child: const CommunityPage(),
          ),
        ),
        GoRoute(
          path: '/community/create',
          builder: (context, state) => const PostFormPage(),
        ),
        GoRoute(
          path: '/community/:postId',
          builder: (context, state) {
            final postId = int.parse(state.pathParameters['postId']!);
            return PostDetailPage(postId: postId);
          },
        ),
        GoRoute(
          path: '/community/:postId/edit',
          builder: (context, state) {
            final postId = int.parse(state.pathParameters['postId']!);
            return PostFormPage(postId: postId);
          },
        ),

        // Mentor Routes
        GoRoute(
          path: '/mentors',
          builder: (context, state) => MainLayout(
            currentPath: state.matchedLocation,
            child: const MentorListPage(),
          ),
        ),
        GoRoute(
          path: '/mentors/:mentorId',
          builder: (context, state) {
            final mentorId = int.parse(state.pathParameters['mentorId']!);
            return MentorDetailPage(mentorId: mentorId);
          },
        ),
        GoRoute(
          path: '/my-bookings',
          builder: (context, state) => MainLayout(
            currentPath: state.matchedLocation,
            child: const MyBookingsPage(),
          ),
        ),

        // Skins Shop
        GoRoute(
          path: '/skins',
          builder: (context, state) => MainLayout(
            currentPath: state.matchedLocation,
            child: const SkinShopPage(),
          ),
        ),

        // Task Board - Mission Control
        GoRoute(
          path: '/task-board',
          builder: (context, state) => const TaskBoardPage(),
        ),

        // Expert Chat Routes
        GoRoute(
          path: '/expert-chat',
          builder: (context, state) => MainLayout(
            currentPath: state.matchedLocation,
            child: const ExpertChatLandingPage(),
          ),
        ),
        GoRoute(
          path: '/expert-chat/domains',
          builder: (context, state) => const DomainSelectionPage(),
        ),
        GoRoute(
          path: '/expert-chat/roles',
          builder: (context, state) => const RoleSelectionPage(),
        ),
        GoRoute(
          path: '/expert-chat/conversation',
          builder: (context, state) => const ExpertChatPage(),
        ),

        // Premium subscription page
        GoRoute(
          path: '/premium',
          builder: (context, state) => const PremiumPlansPage(),
        ),
        // Payment history page
        GoRoute(
          path: '/profile/payments',
          builder: (context, state) => const PaymentHistoryPage(),
        ),
      ],
      redirect: (context, state) {
        final authProvider = context.read<AuthProvider>();
        final isAuthenticated = authProvider.isAuthenticated;
        final isLoading = authProvider.isLoading;
        final isAuthRoute = [
          AppConstants.loginRoute,
          AppConstants.registerRoute,
          '/verify-email',
          '/forgot-password',
        ].contains(state.matchedLocation);

        // If loading, stay on splash
        if (isLoading && state.matchedLocation == '/') {
          return null;
        }

        // After loading finished on splash, redirect appropriately
        if (!isLoading && state.matchedLocation == '/') {
          return isAuthenticated
              ? AppConstants.dashboardRoute
              : AppConstants.loginRoute;
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
    // Show loading if router not ready yet
    if (_router == null) {
      return MaterialApp(
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
        theme: AppTheme.lightTheme,
      );
    }

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp.router(
          title: AppConstants.appName,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
