import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static String get backendUrl {
    return dotenv.env['BACKEND_URL'] ?? 'http://221.132.33.141:8080/api';
  }

  static String get apiUrl {
    return dotenv.env['API_URL'] ?? dotenv.env['BACKEND_URL'] ?? 'http://221.132.33.141:8080/api';
  }

  static String get meowlApiKey {
    return dotenv.env['MEOWL_API_KEY'] ?? '';
  }

  static int get apiTimeout {
    return int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30000') ?? 30000;
  }

  static bool get isDebug {
    return kDebugMode;
  }

  static String get openaiApiUrl {
    return 'https://api.openai.com/v1/chat/completions';
  }
}