# Code Style and Conventions

## Flutter/Dart Coding Standards

### Naming Conventions
- **Files**: snake_case (e.g., `user_profile_page.dart`)
- **Classes**: PascalCase (e.g., `UserProfilePage`)
- **Variables/Functions**: camelCase (e.g., `userName`, `getUserData()`)
- **Constants**: SCREAMING_SNAKE_CASE (e.g., `API_BASE_URL`)
- **Private members**: prefix with underscore (e.g., `_privateMethod()`)

### File Organization
```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   ├── error/
│   ├── network/
│   └── utils/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── presentation/
│   ├── pages/
│   ├── widgets/
│   └── providers/
└── shared/
    ├── widgets/
    └── themes/
```

### Code Style Guidelines
- Use explicit types when helpful for readability
- Prefer `const` constructors where possible
- Use trailing commas in parameter lists
- Keep line length under 80 characters
- Use descriptive variable names
- Add documentation comments for public APIs

### Widget Guidelines
- Prefer StatelessWidget over StatefulWidget when possible
- Extract reusable widgets into separate files
- Use proper widget composition over complex single widgets
- Implement proper dispose methods for resources

### State Management Patterns
- Use Provider/Riverpod for dependency injection
- Keep business logic separate from UI
- Use immutable data classes
- Implement proper error handling

### Import Organization
```dart
// 1. Dart imports
import 'dart:async';

// 2. Flutter imports
import 'package:flutter/material.dart';

// 3. Package imports
import 'package:provider/provider.dart';

// 4. Relative imports
import '../models/user.dart';
import 'widgets/user_tile.dart';
```