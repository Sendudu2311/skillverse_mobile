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
import '../pages/courses/my_courses_page.dart';
import '../pages/courses/course_learning_page.dart';
import '../pages/chat/chat_page.dart';
import '../pages/profile/profile_page.dart';
import '../pages/profile/profile_settings_page.dart';
import '../pages/portfolio/portfolio_page.dart';
import '../pages/premium/premium_plans_page.dart';
import '../pages/payment/payment_history_page.dart';
import '../pages/community/community_page.dart';
import '../pages/community/post_detail_page.dart';
import '../pages/community/post_form_page.dart';
import '../pages/roadmap/roadmap_page.dart';
import '../pages/roadmap/roadmap_generate_page.dart';
import '../pages/roadmap/roadmap_detail_page.dart';
import '../pages/mentor/mentor_list_page.dart';
import '../pages/mentor/mentor_detail_page.dart';
import '../pages/mentor/my_bookings_page.dart';
import '../pages/mentor/booking_review_page.dart';
import '../pages/profile/learning_report_page.dart';
import '../pages/skin/skin_shop_page.dart';
import '../pages/task_board/task_board_page.dart';
import '../pages/jobs/jobs_page.dart';
import '../pages/jobs/job_detail_page.dart';
import '../pages/jobs/my_applications_page.dart';
import '../pages/wallet/wallet_page.dart';
import '../pages/journey/journey_list_page.dart';
import '../pages/journey/journey_create_page.dart';
import '../pages/journey/journey_detail_page.dart';
import '../pages/expert_chat/expert_chat_landing_page.dart';
import '../pages/expert_chat/domain_selection_page.dart';
import '../pages/expert_chat/role_selection_page.dart';
import '../pages/expert_chat/expert_chat_page.dart';
import '../pages/help/help_center_page.dart';
import '../pages/legal/privacy_policy_page.dart';
import '../pages/terms/terms_of_service_page.dart';
import '../pages/splash/splash_page.dart';
import '../pages/notifications/notification_page.dart';
import '../widgets/main_layout.dart';
import '../providers/auth_provider.dart';

class AppRouter {
  static GoRouter createRouter(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    // Initialize auth on first router creation
    Future.microtask(() => authProvider.initialize());

    return GoRouter(
      debugLogDiagnostics: true,
      initialLocation: '/splash',
      refreshListenable: authProvider, // Auto-redirect on auth changes
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

        // Task Board Route
        GoRoute(
          path: '/task-board',
          name: 'task-board',
          builder: (context, state) => const TaskBoardPage(),
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
        GoRoute(
          path: '/courses/:courseId/learn',
          name: 'course-learning',
          builder: (context, state) {
            final courseId = state.pathParameters['courseId']!;
            return CourseLearningPage(courseId: courseId);
          },
        ),
        GoRoute(
          path: '/my-courses',
          name: 'my-courses',
          builder: (context, state) => const MyCoursesPage(),
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

        // Jobs Route
        GoRoute(
          path: '/jobs',
          name: 'jobs',
          builder: (context, state) => MainLayout(
            currentPath: state.matchedLocation,
            child: const JobsPage(),
          ),
        ),
        GoRoute(
          path: '/jobs/:jobId',
          name: 'job-detail',
          builder: (context, state) {
            final jobId = int.parse(state.pathParameters['jobId']!);
            final isShortTerm =
                state.uri.queryParameters['shortTerm'] == 'true';
            return JobDetailPage(jobId: jobId, isShortTerm: isShortTerm);
          },
        ),
        GoRoute(
          path: '/my-applications',
          name: 'my-applications',
          builder: (context, state) => const MyApplicationsPage(),
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

        // Journey Routes
        GoRoute(
          path: '/journey',
          name: 'journey',
          builder: (context, state) => const JourneyListPage(),
        ),
        GoRoute(
          path: '/journey/create',
          name: 'journey-create',
          builder: (context, state) => const JourneyCreatePage(),
        ),
        GoRoute(
          path: '/journey/:journeyId',
          name: 'journey-detail',
          builder: (context, state) {
            final journeyId = state.pathParameters['journeyId']!;
            return JourneyDetailPage(journeyId: journeyId);
          },
        ),

        // Roadmap Routes
        GoRoute(
          path: '/roadmap',
          name: 'roadmap',
          builder: (context, state) => const RoadmapPage(),
        ),
        GoRoute(
          path: '/roadmap/generate',
          name: 'roadmap-generate',
          builder: (context, state) => const RoadmapGeneratePage(),
        ),
        GoRoute(
          path: '/roadmap/:sessionId',
          name: 'roadmap-detail',
          builder: (context, state) {
            final sessionId = int.parse(state.pathParameters['sessionId']!);
            return RoadmapDetailPage(sessionId: sessionId);
          },
        ),

        // Mentor Routes
        GoRoute(
          path: '/mentors',
          name: 'mentors',
          builder: (context, state) => const MentorListPage(),
        ),
        GoRoute(
          path: '/mentors/:mentorId',
          name: 'mentor-detail',
          builder: (context, state) {
            final mentorId = int.parse(state.pathParameters['mentorId']!);
            return MentorDetailPage(mentorId: mentorId);
          },
        ),
        GoRoute(
          path: '/my-bookings',
          name: 'my-bookings',
          builder: (context, state) => const MyBookingsPage(),
        ),
        GoRoute(
          path: '/booking-review/:bookingId',
          name: 'booking-review',
          builder: (context, state) {
            final bookingId = int.parse(state.pathParameters['bookingId']!);
            final mentorName = state.uri.queryParameters['mentorName'];
            return BookingReviewPage(
              bookingId: bookingId,
              mentorName: mentorName,
            );
          },
        ),

        // Skin Shop Route
        GoRoute(
          path: '/skins',
          name: 'skins',
          builder: (context, state) => const SkinShopPage(),
        ),

        // Wallet Route
        GoRoute(
          path: '/wallet',
          name: 'wallet',
          builder: (context, state) => MainLayout(
            currentPath: state.matchedLocation,
            child: const WalletPage(),
          ),
        ),

        // Expert Chat Routes
        GoRoute(
          path: '/expert-chat',
          name: 'expert-chat',
          builder: (context, state) => const ExpertChatLandingPage(),
        ),
        GoRoute(
          path: '/expert-chat/domain',
          name: 'expert-chat-domain',
          builder: (context, state) => const DomainSelectionPage(),
        ),
        GoRoute(
          path: '/expert-chat/role',
          name: 'expert-chat-role',
          builder: (context, state) => const RoleSelectionPage(),
        ),
        GoRoute(
          path: '/expert-chat/chat',
          name: 'expert-chat-chat',
          builder: (context, state) => const ExpertChatPage(),
        ),

        // Help & Legal Routes
        GoRoute(
          path: '/help',
          name: 'help',
          builder: (context, state) => const HelpCenterPage(),
        ),
        GoRoute(
          path: '/privacy',
          name: 'privacy',
          builder: (context, state) => const PrivacyPolicyPage(),
        ),
        GoRoute(
          path: '/terms',
          name: 'terms',
          builder: (context, state) => const TermsOfServicePage(),
        ),

        // Premium Route
        GoRoute(
          path: '/premium',
          name: 'premium',
          builder: (context, state) => const PremiumPlansPage(),
        ),

        // Payment History Route
        GoRoute(
          path: '/payment-history',
          name: 'payment-history',
          builder: (context, state) => const PaymentHistoryPage(),
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
              path: 'learning-report',
              name: 'learning-report',
              builder: (context, state) => const LearningReportPage(),
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

        // Notifications Route
        GoRoute(
          path: '/notifications',
          name: 'notifications',
          builder: (context, state) => const NotificationPage(),
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
}
