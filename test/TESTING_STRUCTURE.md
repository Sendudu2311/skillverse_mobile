# CẤU TRÚC KIỂM THỬ SKILLVERSE MOBILE

Tài liệu này tóm tắt cấu trúc và phân loại kiểm thử trong dự án **Skillverse Mobile** phục vụ việc quản lý và phát triển kịch bản test.

---

## 1. PHÂN LOẠI & VAI TRÒ CỦA CÁC BỘ TEST (DART ONLY)

Dự án mobile hiện tại chỉ sử dụng các kiểm thử viết bằng ngôn ngữ Dart (chạy thông qua Flutter test framework). Các file `.js` cũ (Appium/E2E) đã lỗi thời và không còn sử dụng.

| Loại Test | Vị trí thư mục | Đối tượng & Mục tiêu kiểm thử |
| :--- | :--- | :--- |
| **Unit Test** | `test/unit/` | Kiểm thử logic nghiệp vụ cô lập, xử lý dữ liệu (models, providers, flows, utils). |
| **Widget Test** | `test/widget_test.dart` | Kiểm thử giao diện ảo trên RAM (renders, layouts, forms, local validators). |

---

## 2. CHI TIẾT CÁC BỘ KIỂM THỬ DART

### 2.1. Unit Test (Kiểm thử đơn vị)
Nằm trong `test/unit/` chia theo các tầng kiến trúc:
*   **Models (`test/unit/models/`):** Đảm bảo chuyển đổi qua lại JSON <-> Object Dart khớp 1:1 với DTO từ Spring Boot Backend (Auth, Course, Job, CV, Portfolio...).
*   **Providers (`test/unit/providers/`):** Kiểm thử quản lý trạng thái UI (Loading, Success, Error states).
*   **Business Flows (`test/unit/flows/`):** Kiểm thử các nghiệp vụ logic liên kết giữa nhiều module (Mentorship, AI learning, Career...).
*   **Utils & Core (`test/unit/utils/` & `test/unit/core/`):** Kiểm thử các hàm định dạng ngày tháng, chuỗi, tiền tệ và các lớp xử lý exceptions.

### 2.2. Widget Test (Kiểm thử giao diện ảo)
Tất cả nằm trong file tập trung [widget_test.dart](file:///Users/tranduy/Desktop/CAPSTONE/skillverse_mobile/test/widget_test.dart):
*   **Authentication Forms:** Validate tính hợp lệ của email/mật khẩu, kiểm tra ẩn/hiện mật khẩu, form đăng ký, form quên mật khẩu và màn xác thực OTP.
*   **Dashboard Grid:** Xác nhận render thành công 11 Quick Actions phục vụ các usecase đã đăng ký.
*   **Course Filters:** Kiểm tra bộ lọc khóa học theo cấp độ (Cơ bản, Trung cấp, Nâng cao) và sắp xếp.
*   **Navigation & Flow Structure:** Kiểm tra sự hiện diện của các route chính (`/roadmap`, `/chat`, `/portfolio`, `/my-bookings`...).

---

## 3. CƠ CHẾ HOẠT ĐỘNG VỚI API THẬT & CREDENTIALS

Khi chạy test (`flutter test`), hệ thống nạp file `.env` chứa URL backend thực tế (`https://skillverse.vn/api`). Do đó, các hàm gọi API sẽ gửi yêu cầu thực tế lên server.

Tuy nhiên, **chúng ta không cần tài khoản thật** vì các kịch bản test được thiết kế theo cơ chế sau:

1.  **Chỉ test các luồng lỗi (Failure Paths):** 
    Các test case đăng nhập gửi các thông tin không có thật (ví dụ: `nonexistent@test.com` và `wrongpassword`). Hệ thống chỉ kiểm tra xem Provider có chuyển sang trạng thái lỗi (`errorMessage` không null) và trả về `false` một cách chính xác hay không. Luồng này tự động đúng vì server thật sẽ luôn từ chối các thông tin này.
2.  **Kiểm tra sự chuyển đổi trạng thái (State Transitions):**
    Test case kiểm tra xem trạng thái loading có chuyển từ `false` -> `true` -> `false` hay không. Việc này diễn ra bình thường bất kể request thành công hay thất bại.
3.  **Khả năng chịu lỗi (Error Resilience):**
    Các API lấy dữ liệu (như danh sách khóa học) được bọc trong các khối `try-catch`. Test case chỉ verify rằng ứng dụng vẫn hoạt động ổn định và giữ danh sách trống chứ không bị crash nếu API trả về lỗi hoặc không phản hồi.

---

## 4. LỆNH CHẠY TEST

```bash
# Chạy toàn bộ test suite (Dart)
flutter test

# Chạy riêng một file test cụ thể
flutter test test/unit/utils/date_time_helper_test.dart
```
