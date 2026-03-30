# SkillVerse Mobile

Ứng dụng di động Flutter cho nền tảng học tập AI-powered **SkillVerse** — hỗ trợ định hướng nghề nghiệp, khóa học trực tuyến, mentoring và cộng đồng học tập.

## Yêu cầu hệ thống

| Tool | Phiên bản yêu cầu |
|---|---|
| **Flutter SDK** | `3.35.5` trở lên (channel stable) |
| **Dart SDK** | `^3.9.2` |
| **Android Studio** | Bản mới nhất (kèm Android SDK, Android Emulator) |
| **Xcode** | 15+ *(chỉ macOS — nếu cần chạy trên iOS)* |
| **Java JDK** | 11+ |

> **Kiểm tra nhanh:** Chạy `flutter doctor` để xác nhận môi trường đã sẵn sàng.

## Cài đặt & Chạy ứng dụng

### 1. Clone repository

```bash
git clone <repo-url>
cd skillverse_mobile
```

### 2. Tạo file cấu hình môi trường

Tạo file `.env` tại **thư mục gốc** `skillverse_mobile/`:

```env
# Backend API Base URL
BACKEND_URL=https://<your-backend-domain>/api
API_URL=https://<your-backend-domain>/api

# API Configuration
API_TIMEOUT=30000
DEBUG_MODE=true

# Google OAuth Configuration
GOOGLE_CLIENT_ID=<your-google-client-id>
```

> ⚠️ File `.env` là **bắt buộc**. App sẽ crash nếu thiếu file này.

### 3. Cài đặt dependencies

```bash
flutter pub get
```

### 4. Generate code (JSON Serialization)

```bash
dart run build_runner build --delete-conflicting-outputs
```

> Chạy lại lệnh này mỗi khi thay đổi các file model (`*_models.dart`) có annotation `@JsonSerializable()`.

### 5. Chạy ứng dụng

```bash
# Liệt kê thiết bị khả dụng
flutter devices

# Chạy trên thiết bị mặc định (Android emulator / thiết bị thật)
flutter run

# Chạy trên iOS Simulator (chỉ macOS)
flutter run -d ios

# Chạy trên thiết bị cụ thể
flutter run -d <device-id>
```

## Build APK / IPA

```bash
# Build APK (Android)
flutter build apk --release

# Build App Bundle (Android - Google Play)
flutter build appbundle --release

# Build IPA (iOS - chỉ macOS)
flutter build ipa --release
```

File output:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- App Bundle: `build/app/outputs/bundle/release/app-release.aab`

## Cấu trúc thư mục chính

```
lib/
├── core/               # Utils, helpers, mixins, network client
│   ├── mixins/         # LoadingMixin, ProviderLoadingMixin
│   ├── network/        # ApiClient (Dio)
│   └── utils/          # ErrorHandler, ValidationHelper, NumberFormatter
├── data/
│   ├── models/         # DTOs & JSON models (khớp 1:1 với Backend)
│   └── services/       # API service layer
└── presentation/
    ├── pages/          # Các màn hình (Dashboard, Courses, Profile, ...)
    ├── providers/      # State management (Provider/ChangeNotifier)
    ├── themes/         # AppTheme, dark/light mode
    └── widgets/        # Reusable UI components
```

## Các lệnh hữu ích

```bash
# Kiểm tra môi trường
flutter doctor

# Cập nhật dependencies
flutter pub upgrade

# Phân tích code (lint)
flutter analyze

# Chạy unit tests
flutter test

# Clean build cache
flutter clean && flutter pub get
```

## Tech Stack

- **Framework:** Flutter 3.35.5 / Dart 3.9.2
- **State Management:** Provider
- **HTTP Client:** Dio
- **Navigation:** GoRouter
- **JSON Serialization:** json_serializable + build_runner
- **Local Storage:** SharedPreferences, FlutterSecureStorage
- **Authentication:** Google Sign-In, JWT Token
