import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'router/app_router.dart';
import 'themes/app_theme.dart';
import '../core/constants/app_constants.dart';

class SkillVerseApp extends StatefulWidget {
  const SkillVerseApp({super.key});

  @override
  State<SkillVerseApp> createState() => _SkillVerseAppState();
}

class _SkillVerseAppState extends State<SkillVerseApp> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp.router(
          title: AppConstants.appName,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          routerConfig: AppRouter.createRouter(context),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
