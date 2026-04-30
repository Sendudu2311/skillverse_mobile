import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/ai_grading_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_dispute_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/comment_provider.dart';
import 'providers/contract_provider.dart';
import 'providers/course_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/enrollment_provider.dart';
import 'providers/expert_chat_provider.dart';
import 'providers/group_chat_provider.dart';
import 'providers/interview_provider.dart';
import 'providers/job_provider.dart';
import 'providers/journey_provider.dart';
import 'providers/learning_report_provider.dart';
import 'providers/mentor_booking_provider.dart';
import 'providers/mentor_provider.dart';
import 'providers/messaging_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/portfolio_provider.dart';
import 'providers/post_provider.dart';
import 'providers/premium_provider.dart';
import 'providers/recruitment_chat_provider.dart';
import 'providers/roadmap_detail_provider.dart';
import 'providers/roadmap_generate_provider.dart';
import 'providers/roadmap_provider.dart';
import 'providers/skin_provider.dart';
import 'providers/student_verification_provider.dart';
import 'providers/student_skill_verification_provider.dart';
import 'providers/task_board_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'providers/wallet_provider.dart';
import 'router/app_router.dart';
import 'themes/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../core/services/firebase_push_notification_service.dart';

class SkillVerseApp extends StatefulWidget {
  const SkillVerseApp({super.key});

  @override
  State<SkillVerseApp> createState() => _SkillVerseAppState();
}

class _SkillVerseAppState extends State<SkillVerseApp> {
  late final GoRouter _router;
  AuthProvider? _authProvider;
  bool _prevAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.createRouter(context);

    // P5.3: Wire FCM foreground notification tap → GoRouter navigation
    FirebasePushNotificationService.instance.onNotificationTapNavigate =
        (String route) {
          if (mounted) {
            _router.go(route);
          }
        };

    // Wire centralized logout cleanup: when auth transitions true→false,
    // call clearOnLogout() on every data-holding provider so no user data
    // persists across sessions (prevents cross-user data leakage).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _authProvider = context.read<AuthProvider>();
      _prevAuthenticated = _authProvider!.isAuthenticated;
      _authProvider!.addListener(_onAuthChanged);
    });
  }

  void _onAuthChanged() {
    if (!mounted) return;
    final isNowAuth = _authProvider?.isAuthenticated ?? false;
    if (_prevAuthenticated && !isNowAuth) {
      _clearAllOnLogout();
    }
    _prevAuthenticated = isNowAuth;
  }

  void _clearAllOnLogout() {
    final ctx = context;
    ctx.read<UserProvider>().clearOnLogout();
    ctx.read<DashboardProvider>().clearOnLogout();
    ctx.read<EnrollmentProvider>().clearOnLogout();
    ctx.read<WalletProvider>().clearOnLogout();
    ctx.read<PaymentProvider>().clearOnLogout();
    ctx.read<PremiumProvider>().clearOnLogout();
    ctx.read<CourseProvider>().clearOnLogout();
    ctx.read<PostProvider>().clearOnLogout();
    ctx.read<JobProvider>().clearOnLogout();
    ctx.read<MentorProvider>().clearOnLogout();
    ctx.read<MentorBookingProvider>().clearOnLogout();
    ctx.read<TaskBoardProvider>().clearOnLogout();
    ctx.read<PortfolioProvider>().clearOnLogout();
    ctx.read<ChatProvider>().clearOnLogout();
    ctx.read<ExpertChatProvider>().clearOnLogout();
    ctx.read<MessagingProvider>().clearOnLogout();
    ctx.read<NotificationProvider>().clearOnLogout();
    ctx.read<GroupChatProvider>().clearOnLogout();
    ctx.read<RecruitmentChatProvider>().clearOnLogout();
    ctx.read<SkinProvider>().clearOnLogout();
    ctx.read<LearningReportProvider>().clearOnLogout();
    ctx.read<RoadmapProvider>().clearOnLogout();
    ctx.read<RoadmapDetailProvider>().clearOnLogout();
    ctx.read<RoadmapGenerateProvider>().clearOnLogout();
    ctx.read<CommentProvider>().clearOnLogout();
    ctx.read<AiGradingProvider>().clearOnLogout();
    ctx.read<BookingDisputeProvider>().clearOnLogout();
    ctx.read<ContractProvider>().clearOnLogout();
    ctx.read<InterviewProvider>().clearOnLogout();
    ctx.read<JourneyProvider>().clearOnLogout();
    ctx.read<StudentVerificationProvider>().clearOnLogout();
    ctx.read<StudentSkillVerificationProvider>().clearOnLogout();
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp.router(
          title: AppConstants.appName,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: const [Locale('vi'), Locale('en')],
        );
      },
    );
  }
}
