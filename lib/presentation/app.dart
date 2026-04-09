import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
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
        );
      },
    );
  }
}
