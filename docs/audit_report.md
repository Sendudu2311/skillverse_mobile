# 🔍 Audit Report: Helper & Theme Consistency

## Tóm tắt chung

> [!WARNING]
> Hầu hết các helper đã xây dựng **đều bị under-utilized**. Nhiều feature tự viết logic riêng thay vì dùng helper có sẵn, dẫn đến code không đồng nhất và khó maintain.

---

## 1. 🎨 Theme — Hardcoded Colors

**Mức nghiêm trọng: 🔴 CAO**

### Vấn đề
50+ chỗ dùng `Color(0x...)` hardcoded trong pages/widgets thay vì dùng `AppTheme.*` constants.

### Các màu lặp lại nhiều nhất (chưa có trong AppTheme)

| Màu | Hex | Số lần | Xuất hiện tại |
|-----|-----|--------|---------------|
| Cyan | `0xFF00D4FF` | ~15 lần | expert_chat (7), profile (5), dashboard, formatted_ai_response |
| Orange | `0xFFFFA500` | ~12 lần | task_board (5), ai_study_planner_dialog (8) |
| Gold | `0xFFFFD700` | ~4 lần | wallet, profile |
| Silver | `0xFFC0C0C0` | 1 lần | profile |
| Indigo Dark | `0xFF1E1B4B` | 2 lần | mentor_detail |

### 📋 Đề xuất
Bổ sung vào [AppTheme](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/core/constants/app_theme.dart#3-215):
```dart
static const Color accentCyan = Color(0xFF00D4FF);
static const Color accentOrange = Color(0xFFFFA500);
static const Color accentGold = Color(0xFFFFD700);
static const Color accentSilver = Color(0xFFC0C0C0);
```

### Các file cần sửa

| Feature | Files |
|---------|-------|
| Expert Chat | [expert_chat_page.dart](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/presentation/pages/expert_chat/expert_chat_page.dart), [expert_chat_landing_page.dart](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/presentation/pages/expert_chat/expert_chat_landing_page.dart) |
| Task Board | [task_board_page.dart](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/presentation/pages/task_board/task_board_page.dart), [ai_study_planner_dialog.dart](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/presentation/pages/task_board/widgets/ai_study_planner_dialog.dart), [create_task_dialog.dart](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/presentation/pages/task_board/widgets/create_task_dialog.dart) |
| Profile | [profile_page.dart](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/presentation/pages/profile/profile_page.dart) |
| Dashboard | [dashboard_page.dart](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/presentation/pages/dashboard/dashboard_page.dart) |
| Wallet | [wallet_page.dart](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/presentation/pages/wallet/wallet_page.dart) |
| Widgets | [formatted_ai_response.dart](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/presentation/widgets/formatted_ai_response.dart), [main_layout.dart](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/presentation/widgets/main_layout.dart) |
| Community | [community_stats_widget.dart](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/presentation/pages/community/widgets/community_stats_widget.dart) (nhiều gradient tùy ý) |
| Splash | [splash_page.dart](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/presentation/pages/splash_page.dart) (`0xFF4F46E5` = `AppTheme.primaryBlue` nhưng hardcode) |

---

## 2. ⚠️ ErrorHandler

**Mức nghiêm trọng: 🟡 TRUNG BÌNH**

### Hiện trạng

| Metric | Số lượng |
|--------|----------|
| Files dùng [ErrorHandler](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/core/utils/error_handler.dart#7-285) | ~10 (3 providers + 7 pages) |
| Files dùng raw `ScaffoldMessenger` | **17 pages** |
| Files cần nhưng chưa dùng | ~10 |

### ✅ Files đã dùng đúng
`premium_provider`, `user_provider`, `portfolio_provider`, `skin_provider`, `post_form_page`, `post_detail_page`, `edit_extended_profile_page`, `edit_project_page`, `add_certificate_page`, `course_detail_page`

### ❌ Files dùng `ScaffoldMessenger` trực tiếp (nên chuyển sang [ErrorHandler](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/core/utils/error_handler.dart#7-285))
`login_page`, `register_page`, `forgot_password_page`, `verify_email_page`, `premium_plans_page`, `create_task_dialog`, `ai_study_planner_dialog`, `certificate_form_page`, `cv_builder_page`, `project_form_page`, `extended_profile_form_page`, `mentor_booking_sheet`, `my_bookings_page`, `profile_settings_page`, `course_learning_page`, `roadmap_generate_page`, `roadmap_detail_page`

---

## 3. 🗄️ StorageHelper

**Mức nghiêm trọng: 🟡 TRUNG BÌNH**

### Hiện trạng
- `StorageHelper.initialize()` gọi trong [main.dart](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/main.dart) ✅
- **[auth_service.dart](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/data/services/auth_service.dart)**: dùng `FlutterSecureStorage` trực tiếp thay vì [StorageHelper](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/core/utils/storage_helper.dart#76-362) ❌
- **[chat_service.dart](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/data/services/chat_service.dart)**: dùng `FlutterSecureStorage` trực tiếp ❌
- **Các provider khác**: không dùng [StorageHelper](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/core/utils/storage_helper.dart#76-362) cho token/preferences ❌

### 📋 Đề xuất
- [auth_service.dart](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/data/services/auth_service.dart) và [chat_service.dart](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/data/services/chat_service.dart) nên dùng `StorageHelper.instance` thay vì tạo `FlutterSecureStorage` riêng
- Đảm bảo tất cả truy xuất token qua `StorageHelper.instance.accessToken`

---

## 4. ✏️ ValidationHelper

**Mức nghiêm trọng: 🔴 CAO**

### Hiện trạng

| Metric | Số lượng |
|--------|----------|
| Files dùng [ValidationHelper](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/core/utils/validation_helper.dart#2-360) | **4** (portfolio/profile pages) |
| Files có `validator:` inline | **8** (toàn bộ auth pages) |

### ❌ Auth Pages tự viết validation riêng
- [login_page.dart](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/presentation/pages/auth/login_page.dart): 2 validators (email, password) — inline lambda
- [register_page.dart](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/presentation/pages/auth/register_page.dart): 4 validators (name, email, password, confirm) — inline lambda
- [forgot_password_page.dart](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/presentation/pages/auth/forgot_password_page.dart): 1 validator (email) — inline lambda
- [verify_email_page.dart](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/presentation/pages/auth/verify_email_page.dart): 1 validator (OTP) — inline lambda

### ✅ Files đã dùng đúng
`edit_extended_profile_page`, `add_certificate_page`, `profile_settings_page`, `edit_project_page`

### 📋 Đề xuất
Tất cả auth forms nên dùng `ValidationHelper.email()`, `ValidationHelper.password()`, `ValidationHelper.confirmPassword()`, `ValidationHelper.required()`.

---

## 5. 📅 DateTimeHelper

**Mức nghiêm trọng: 🟡 TRUNG BÌNH**

### Hiện trạng

| Metric | Số lượng |
|--------|----------|
| Files dùng [DateTimeHelper](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/core/utils/date_time_helper.dart#11-291) | **3** (ai_roadmap_card, post_card, post_detail) |
| Files dùng raw `DateFormat()` | **3** (timeline_view, edit_project_page, add_certificate_page) |

### 📋 Đề xuất
[timeline_view.dart](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/presentation/pages/task_board/widgets/timeline_view.dart), [edit_project_page.dart](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/presentation/pages/portfolio/edit_project_page.dart), [add_certificate_page.dart](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/presentation/pages/portfolio/add_certificate_page.dart) nên import [DateTimeHelper](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/core/utils/date_time_helper.dart#11-291) thay vì tạo `DateFormat()` riêng.

---

## 6. 🔢 NumberFormatter

**Mức nghiêm trọng: 🟡 TRUNG BÌNH**

### Hiện trạng
- Chỉ dùng trong **1 file**: [course_detail_page.dart](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/presentation/pages/courses/course_detail_page.dart)
- Các trang như `wallet_page`, `premium_plans_page`, `payment_history_page`, `dashboard_page` có hiển thị số tiền/số lượng nhưng **không dùng** [NumberFormatter](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/core/utils/number_formatter.dart#4-71)

---

## 7. 📄 PaginationHelper

**Mức nghiêm trọng: 🟢 THẤP**

### Hiện trạng
- Dùng trong **3 providers**: `comment_provider`, `course_provider`, `post_provider` ✅
- Phạm vi hợp lý — không phải mọi danh sách đều cần pagination

---

## 8. ⏳ Loading Mixins

**Mức nghiêm trọng: 🔴 CAO**

### Hiện trạng

| Metric | Số lượng |
|--------|----------|
| Providers dùng [LoadingProviderMixin](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/core/mixins/provider_loading_mixin.dart#28-122) | **0** |
| Providers tự quản lý `_isLoading` | **11** |
| Pages dùng [LoadingMixin](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/core/mixins/loading_mixin.dart#32-146) | **0** |

### ❌ Providers tự quản lý loading (nên dùng mixin)
`expert_chat_provider`, `task_board_provider`, `payment_provider`, `mentor_provider`, `auth_provider`, `dashboard_provider`, `enrollment_provider`, `post_provider`, `subscription_provider`, `chat_provider`, `skin_provider`

### 📋 Đề xuất
Tất cả 11 providers nên `with LoadingProviderMixin` hoặc [LoadingStateProviderMixin](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/core/mixins/provider_loading_mixin.dart#150-229) thay vì tự quản lý `_isLoading`.

---

## 9. 🌀 Loading UI (Shimmer/Skeleton)

**Mức nghiêm trọng: 🟡 TRUNG BÌNH**

### Hiện trạng

| Metric | Số lượng |
|--------|----------|
| `ShimmerLoading` widget | **Tồn tại** nhưng **0 page dùng** |
| `SkeletonLoader` widget | **Tồn tại** nhưng **0 page dùng** |
| Pages dùng raw `CircularProgressIndicator` | **43 pages** |

### 📋 Đề xuất
Thay thế `CircularProgressIndicator()` bằng `ShimmerLoading` hoặc các bộ `SkeletonLoader` tương ứng tại ít nhất các trang chính (courses, dashboard, mentor, community, profile).

---

## 10. 📝 HtmlHelper & MeowlGuard

**Mức nghiêm trọng: 🟢 THẤP** — Phạm vi đúng

- [HtmlHelper](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/lib/core/utils/html_helper.dart#3-60): dùng trong 2 files (`post_card`, `post_detail`) — ✅ hợp lý, chỉ post có HTML content
- `MeowlGuard`: dùng trong 2 files (`meowl_chat_widget`, `chat_page`) — ✅ hợp lý, chỉ AI chat cần guard

---

## 📊 Bảng tổng hợp

| Helper | Đã có | Nơi dùng | Nơi nên dùng thêm | Mức độ |
|--------|-------|----------|-------------------|--------|
| **AppTheme colors** | ✅ | Một phần | 50+ chỗ hardcode | 🔴 CAO |
| **ErrorHandler** | ✅ | ~10 files | 17 files dùng raw SM | 🟡 TB |
| **StorageHelper** | ✅ | 1 file | auth_service, chat_service | 🟡 TB |
| **ValidationHelper** | ✅ | 4 files | 8 auth form validators | 🔴 CAO |
| **DateTimeHelper** | ✅ | 3 files | 3 files dùng raw DF | 🟡 TB |
| **NumberFormatter** | ✅ | 1 file | wallet, premium, payment, dashboard | 🟡 TB |
| **PaginationHelper** | ✅ | 3 providers | ✅ đủ | 🟢 THẤP |
| **Loading Mixins** | ✅ | **0** | 11 providers manual _isLoading | 🔴 CAO |
| **Shimmer/Skeleton** | ✅ | **0** | 43 raw CPI pages | 🟡 TB |
| **HtmlHelper** | ✅ | 2 files | ✅ đủ | 🟢 THẤP |
| **MeowlGuard** | ✅ | 2 files | ✅ đủ | 🟢 THẤP |

---

## 🎯 Ưu tiên fix (Top → Bottom)

1. **Loading Mixins** → Refactor 11 providers dùng mixin (ảnh hưởng rộng nhất, cải thiện code quality)
2. **AppTheme colors** → Thêm constants mới + replace hardcoded colors (50+ chỗ sửa)
3. **ValidationHelper** → Refactor 8 auth form validators (trải nghiệm validation đồng nhất)
4. **ErrorHandler** → Refactor 17 pages dùng raw ScaffoldMessenger (UX SnackBar đồng nhất)
5. **Shimmer/Skeleton** → Thay CPI ở ít nhất 5 trang chính (UX loading tốt hơn)
6. **StorageHelper** → Refactor auth_service + chat_service (bảo mật và consistency)
7. **DateTimeHelper & NumberFormatter** → Thay raw formatting (6 files nhỏ)
