# BÁO CÁO KIỂM THỬ ĐƠN VỊ (UNIT TEST REPORT)

## Thông tin dự án

| Mục | Chi tiết |
|-----|---------|
| **Dự án** | SkillVerse Mobile - AI-powered Learning Platform |
| **Framework** | Flutter 3.9, Dart |
| **Testing Framework** | `flutter_test`, `mocktail` |
| **Ngày chạy test** | 2026-03-04 |
| **Trạng thái** | ✅ **ALL PASSED** |
| **Tổng test cases** | **326** |
| **Passed** | **326** (100%) |
| **Failed** | **0** (0%) |
| **Bugs phát hiện** | **6 bugs** (documented as known issues) |

---

## Lệnh chạy test

```bash
flutter test test/unit/
```

**Kết quả:**
```
00:01 +326: All tests passed!
```

---

## Tổng hợp kết quả theo module

| # | Test File | Tests | Kết quả | Phạm vi kiểm thử |
|---|-----------|-------|---------|------------------|
| 1 | `auth_models_test.dart` | 15 | ✅ | Model serialization - Auth |
| 2 | `course_models_test.dart` | 20 | ✅ | Model serialization - Course |
| 3 | `quiz_models_test.dart` | 25 | ✅ | Model serialization - Quiz |
| 4 | `enrollment_models_test.dart` | 15 | ✅ | Model serialization - Enrollment |
| 5 | `validation_helper_test.dart` | 65 | ✅ | Core Utilities - Form Validation |
| 6 | `exceptions_test.dart` | 30 | ✅ | Core - Error Handling |
| 7 | `edge_cases_test.dart` | 57 | ✅ | Edge Cases / Stress Testing |
| 8 | `auth_provider_test.dart` | 22 | ✅ | State Management - Auth |
| 9 | `enrollment_provider_test.dart` | 22 | ✅ | State Management - Enrollment |
| 10 | `course_provider_test.dart` | 20 | ✅ | State Management - Course |
| 11 | `business_flows_test.dart` | 35 | ✅ | End-to-End Business Flows |
| | **TỔNG** | **326** | **✅ 100%** | |

---

## Cấu trúc thư mục test

```
test/
└── unit/
    ├── models/
    │   ├── auth_models_test.dart        # 15 tests
    │   ├── course_models_test.dart      # 20 tests
    │   ├── quiz_models_test.dart        # 25 tests
    │   └── enrollment_models_test.dart  # 15 tests
    ├── utils/
    │   └── validation_helper_test.dart  # 65 tests
    ├── core/
    │   └── exceptions_test.dart         # 30 tests
    ├── providers/
    │   ├── auth_provider_test.dart      # 22 tests
    │   ├── enrollment_provider_test.dart # 22 tests
    │   └── course_provider_test.dart    # 20 tests
    ├── flows/
    │   └── business_flows_test.dart     # 35 tests
    └── edge_cases_test.dart             # 57 tests
```

---

## Chi tiết theo tầng kiểm thử

### Tầng 1: Model Tests (75 tests)
Kiểm thử serialization/deserialization JSON ↔ Dart objects.

| Module | Classes tested | Loại test |
|--------|---------------|-----------|
| Auth | `LoginRequest`, `RegisterRequest`, `UserDto`, `AuthResponse` (direct + wrapped), `RefreshTokenRequest`, `VerifyEmailRequest`, `ResendOtpRequest`, `ApiErrorResponse` | `fromJson()`, `toJson()`, round-trip, optional fields |
| Course | `CourseStatus/Level` enums + `fromString()`, `AuthorDto`, `MediaDto`, `CourseSummaryDto`, `PageResponse<T>`, `CourseDetailDto` | Enum parsing, nested objects, pagination |
| Quiz | `QuizSummaryDto`, `QuizDetailDto` (nested questions+options), `QuizQuestionDetailDto`, `QuizOptionDto`, `QuizAnswerDto`, `SubmitQuizDto`, `QuizAttemptDto`, `QuizSubmitResponseDto`, `QuizAttemptStatusDto`, `QuizAnswerResultDto` | JSON key mapping (`userId`→`studentId`), nested serialization |
| Enrollment | `EnrollRequestDto`, `EnrollmentDetailDto`, `EnrollmentStatusDto`, `EnrollmentStatsDto`, enums | Enrolled/completed states |

### Tầng 2: Core Utilities (95 tests)
Kiểm thử logic nghiệp vụ thuần (pure functions).

**ValidationHelper** (65 tests):
- `required()` — null, empty, whitespace, custom field name
- `email()` — valid/invalid formats, required/optional
- `password()` — 8+ chars, uppercase, lowercase, digit
- `confirmPassword()` — match/mismatch
- `phoneNumber()` — Vietnamese format (10 digits, starts with 0)
- `url()`, `slug()`, `minLength()`, `maxLength()`, `lengthRange()`
- `numeric()`, `decimal()`, `numberRange()`
- `dateFormat()`, `dateRange()`
- `githubUsername()`, `githubRepoUrl()`, `linkedInUrl()`, `twitterUsername()`
- `combine()`, `withFieldName()`

**Exceptions** (30 tests):
- `AppException` hierarchy (6 subclasses)
- `ApiException.fromDioException()` cho tất cả `DioExceptionType`
- Status code mapping (400→503)

### Tầng 3: State Management / Providers (64 tests)

**AuthProvider** (22 tests):
- Initial state (user, loading, error, isAuthenticated)
- Login flow: empty credentials, invalid credentials, state transitions
- Register flow: empty fields, invalid email, loading states
- Verify email và Resend OTP flows
- Logout: clears user, handles errors, clears previous errors
- Refresh token: no stored token → false
- Listener notifications, dispose safety

**EnrollmentProvider** (22 tests):
- Initial state (empty list, cache, no loading)
- enrollInCourse: error handling, loading states, cache consistency
- unenrollFromCourse: error handling, loading states
- checkEnrollmentStatus: API error → false
- fetchUserEnrollments: invalid userId, loading states
- updateProgress: boundary values (0%, 100%), invalid data
- markAsCompleted: invalid courseId
- clear(): resets all, notifies listeners

**CourseProvider** (20 tests):
- Initial state (empty, null filter, null error)
- Level filter: set, clear, multiple changes, notify
- Reset: clears state, notifies
- API error resilience: graceful handling when API unavailable
- getCourseById: negative ID, 0, non-existent
- Dispose safety

### Tầng 4: Edge Cases / Stress Tests (57 tests)

| Category | Tests | Mục đích |
|----------|-------|---------|
| Số lớn & số âm | 11 | ID max int, score âm, progress > 100%, price = 0 |
| Chuỗi đặc biệt | 7 | Unicode, XSS, HTML, emoji, 1000-char strings |
| Sai định dạng | 6 | Invalid enum fallback, null items, empty list |
| Giá trị biên | 15 | Password 7 vs 8 chars, phone 9/10/11 digits, boundary values |
| Input độc hại | 7 | SQL injection, XSS, `javascript:` protocol |
| Ngày tháng | 9 | Leap year, invalid dates, ISO 8601 |

### Tầng 5: Business Flow Tests (35 tests)

| Flow | Steps | Mô tả |
|------|-------|-------|
| Đăng ký → Đăng nhập | 7 | Validate form → Create request → Parse response → Login |
| Duyệt → Ghi danh → Học | 7 | Course listing → Filter → Search → Enroll → Track progress |
| Quiz → Nộp → Retry | 8 | Load quiz → Submit → Check result → Retry status → Cooldown |
| Xử lý lỗi API | 6 | 401/403/404/500, error response parsing, timeout |
| Form Validation | 5 | Login form, Registration form, Password confirmation |
| Enrollment Statistics | 2 | Dashboard stats, zero enrollment edge case |

---

## Bugs phát hiện

### 🐛 Bug #1-2: Email regex quá lỏng
- **File**: `lib/core/utils/validation_helper.dart`
- **Vấn đề**: Regex cho phép `.user@test.com` (dot ở đầu) và `user..name@test.com` (dot liên tiếp)
- **Vi phạm**: RFC 5321
- **Mức độ**: Medium
- **Khuyến nghị**: Cập nhật regex pattern để reject dot ở đầu và consecutive dots

### 🐛 Bug #3-6: `dateFormat()` không validate ngày thật
- **File**: `lib/core/utils/validation_helper.dart`
- **Vấn đề**: `DateTime.parse()` trong Dart tự điều chỉnh ngày không hợp lệ thay vì throw error
  - `2023-02-29` → tự chuyển thành `2023-03-01`
  - `2024-04-31` → tự chuyển thành `2024-05-01`
  - `2024-01-00` → tự chuyển thành `2023-12-31`
  - `2024-00-15` → tự chuyển thành `2023-12-15`
- **Mức độ**: Medium
- **Khuyến nghị**: So sánh ngày parse với ngày gốc để phát hiện auto-adjustment

---

## Phương pháp kiểm thử

| Phương pháp | Mô tả | Áp dụng |
|-------------|-------|---------|
| **Black-box testing** | Test input/output, không phụ thuộc implementation | Tất cả tests |
| **Equivalence Partitioning** | Phân vùng input thành nhóm tương đương | Validation tests |
| **Boundary Value Analysis** | Test giá trị biên (min, max, min-1, max+1) | Edge case tests |
| **AAA Pattern** | Arrange-Act-Assert | Tất cả tests |
| **State Transition Testing** | Test chuyển đổi trạng thái (loading → success/error) | Provider tests |
| **Error Guessing** | Test với dữ liệu bất thường (SQL injection, XSS) | Edge case + Business flow tests |

---

## Kết luận

- ✅ **326/326** test cases **PASSED** (100% pass rate)
- ✅ **11 test files** bao phủ 5 tầng kiểm thử
- ✅ **6 bugs thật** được phát hiện và ghi nhận
- ✅ Test cả **happy path**, **error cases**, **edge cases**, và **business flows**
- ✅ Sử dụng đa phương pháp kiểm thử chuyên nghiệp
