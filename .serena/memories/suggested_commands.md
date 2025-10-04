# Development Commands and Guidelines

## Flutter Development Commands

### Project Setup
```bash
# Create new Flutter project
flutter create skillverse_mobile
cd skillverse_mobile

# Get dependencies
flutter pub get

# Generate code (for JSON serialization)
flutter packages pub run build_runner build

# Watch for changes and rebuild
flutter packages pub run build_runner watch
```

### Development Commands
```bash
# Run on Android emulator
flutter run

# Run on iOS simulator (macOS only)
flutter run

# Run with hot reload (default)
flutter run --hot

# Build APK for Android
flutter build apk

# Build iOS (macOS only)
flutter build ios

# Analyze code
flutter analyze

# Format code
flutter format .

# Run tests
flutter test
```

### Code Generation
```bash
# Generate JSON serialization code
flutter packages pub run build_runner build --delete-conflicting-outputs

# Watch mode for continuous generation
flutter packages pub run build_runner watch
```

### Debugging Commands
```bash
# Flutter doctor (check setup)
flutter doctor

# List devices
flutter devices

# Flutter logs
flutter logs

# Clean build cache
flutter clean
```

## Git Commands (Windows)
```powershell
# Basic Git operations
git status
git add .
git commit -m "message"
git push
git pull

# Create new branch
git checkout -b feature/branch-name

# View file differences
git diff
```

## Windows-specific Commands
```powershell
# List directory contents
Get-ChildItem
dir

# Create directory
New-Item -ItemType Directory -Name "folder_name"
mkdir folder_name

# Navigate directories
Set-Location "path"
cd path

# Find files
Get-ChildItem -Recurse -Filter "*.dart"
```