# Environment Configuration for Flutter

## Environment Variables Setup

### 1. Create environment config files
```
lib/
├── config/
│   ├── environment.dart
│   └── api_endpoints.dart
├── .env
├── .env.development
└── .env.production
```

### 2. Environment Configuration
```dart
// lib/config/environment.dart
class Environment {
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:3000/api',
  );
  
  static const String meowlApiKey = String.fromEnvironment(
    'MEOWL_API_KEY',
    defaultValue: '',
  );
  
  static const String openaiApiUrl = 'https://api.openai.com/v1/chat/completions';
  
  // Debug flags
  static const bool isDebug = kDebugMode;
  static const bool enableLogging = true;
}
```

### 3. Flutter Dotenv Package
```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

```dart
// main.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

// Usage
final backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://localhost:3000/api';
final meowlApiKey = dotenv.env['MEOWL_API_KEY'] ?? '';
```

### 4. .env files structure
```env
# .env.development
BACKEND_URL=http://localhost:3000/api
MEOWL_API_KEY=your_development_openai_key
API_TIMEOUT=30000

# .env.production  
BACKEND_URL=https://api.skillverse.com/api
MEOWL_API_KEY=your_production_openai_key
API_TIMEOUT=10000
```

### 5. Build Configuration
```bash
# Development build
flutter run --dart-define=BACKEND_URL=http://localhost:3000/api --dart-define=MEOWL_API_KEY=your_key

# Production build
flutter build apk --dart-define=BACKEND_URL=https://api.skillverse.com/api --dart-define=MEOWL_API_KEY=your_prod_key
```

### 6. Security Notes
- Add .env files to .gitignore
- Use different keys for dev/prod
- Store production keys securely
- Consider using Flutter secure storage for sensitive data