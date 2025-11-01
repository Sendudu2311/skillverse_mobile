import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/chat_provider.dart';
import 'presentation/providers/course_provider.dart';
import 'presentation/providers/enrollment_provider.dart';
import 'presentation/providers/roadmap_provider.dart';
import 'presentation/providers/user_provider.dart';
import 'presentation/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Could not load .env file: $e');
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
          create: (context) => ChatProvider(Provider.of<AuthProvider>(context, listen: false)),
          update: (context, authProvider, previous) => previous ?? ChatProvider(authProvider),
        ),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => EnrollmentProvider()),
        ChangeNotifierProvider(create: (_) => RoadmapProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const SkillVerseApp(),
    ),
  );
}
