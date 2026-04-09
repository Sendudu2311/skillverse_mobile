import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/chat_provider.dart';
import 'presentation/providers/course_provider.dart';
import 'presentation/providers/dashboard_provider.dart';
import 'presentation/providers/enrollment_provider.dart';
import 'presentation/providers/payment_provider.dart';
import 'presentation/providers/portfolio_provider.dart';
import 'presentation/providers/premium_provider.dart';
import 'presentation/providers/roadmap_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/user_provider.dart';
import 'presentation/providers/post_provider.dart';
import 'presentation/providers/comment_provider.dart';
import 'presentation/providers/mentor_provider.dart';
import 'presentation/providers/mentor_booking_provider.dart';
import 'presentation/providers/roadmap_detail_provider.dart';
import 'presentation/providers/roadmap_generate_provider.dart';
import 'presentation/providers/skin_provider.dart';

import 'presentation/providers/task_board_provider.dart';
import 'presentation/providers/expert_chat_provider.dart';
import 'presentation/providers/messaging_provider.dart';
import 'presentation/providers/job_provider.dart';
import 'presentation/providers/journey_provider.dart';
import 'presentation/providers/wallet_provider.dart';
import 'presentation/providers/notification_provider.dart';
import 'presentation/providers/learning_report_provider.dart';
import 'presentation/app.dart';
import 'core/utils/storage_helper.dart';
import 'core/utils/date_time_helper.dart';
import 'core/network/api_client.dart';
import 'core/services/firebase_push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Could not load .env file: $e');
  }

  // Initialize helpers
  await _initializeHelpers();

  // Initialize Firebase
  await _initializeFirebase();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
          create: (context) =>
              ChatProvider(Provider.of<AuthProvider>(context, listen: false)),
          update: (context, authProvider, previous) =>
              previous ?? ChatProvider(authProvider),
        ),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => EnrollmentProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => PortfolioProvider()),
        ChangeNotifierProvider(create: (_) => PremiumProvider()),
        ChangeNotifierProvider(create: (_) => RoadmapProvider()),
        ChangeNotifierProvider(create: (_) => RoadmapDetailProvider()),
        ChangeNotifierProvider(create: (_) => RoadmapGenerateProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => CommentProvider()),
        ChangeNotifierProvider(create: (_) => MentorProvider()),
        ChangeNotifierProvider(create: (_) => MentorBookingProvider()),
        ChangeNotifierProvider(create: (_) => SkinProvider()),

        ChangeNotifierProvider(create: (_) => TaskBoardProvider()),
        ChangeNotifierProvider(create: (_) => ExpertChatProvider()),
        ChangeNotifierProxyProvider<AuthProvider, MessagingProvider>(
          create: (context) =>
              MessagingProvider(Provider.of<AuthProvider>(context, listen: false)),
          update: (context, authProvider, previous) =>
              previous ?? MessagingProvider(authProvider),
        ),
        ChangeNotifierProvider(create: (_) => JobProvider()),
        ChangeNotifierProvider(create: (_) => JourneyProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => LearningReportProvider()),
      ],
      child: const SkillVerseApp(),
    ),
  );
}

/// Initialize all helper utilities
///
/// This should be called in main() before runApp()
Future<void> _initializeHelpers() async {
  try {
    // Initialize StorageHelper (SharedPreferences + FlutterSecureStorage)
    await StorageHelper.initialize();
    debugPrint('✅ StorageHelper initialized');

    // Initialize DateTimeHelper (Vietnamese locale for intl + timeago)
    await DateTimeHelper.initialize();
    debugPrint('✅ DateTimeHelper initialized');

    // Initialize ApiClient
    ApiClient().initialize();
    debugPrint('✅ ApiClient initialized');
  } catch (e) {
    debugPrint('❌ Error initializing helpers: $e');
    // Continue anyway - helpers will handle errors gracefully
  }
}

/// Initialize Firebase and push notification service.
/// NOTE: FCM token is NOT registered with backend here — that happens
/// after successful login via FirebasePushNotificationService.registerTokenAfterLogin().
Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized');

    await FirebasePushNotificationService.instance.initialize();
    debugPrint('✅ Push notification service initialized');
  } catch (e) {
    debugPrint('⚠️ Firebase init failed (push notifications disabled): $e');
    // Non-critical: app works without Firebase
  }
}
