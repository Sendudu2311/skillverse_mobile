import 'package:flutter_test/flutter_test.dart';
import 'package:skillverse_mobile/data/models/auth_models.dart';
import 'package:skillverse_mobile/data/models/course_models.dart';
import 'package:skillverse_mobile/data/models/quiz_models.dart';
import 'package:skillverse_mobile/data/models/enrollment_models.dart';
import 'package:skillverse_mobile/core/utils/validation_helper.dart';

/// Edge Case / Stress Tests
/// Kiểm thử với dữ liệu bất thường, giá trị biên, và input sai định dạng
/// để tìm lỗi tiềm ẩn trong ứng dụng.
void main() {
  // ============================================================
  // 1. SỐ LỚN & SỐ ÂM
  // ============================================================
  group('Edge Case: Số lớn & số âm', () {
    test('UserDto - id rất lớn (int max)', () {
      final json = {'id': 2147483647, 'email': 'big@id.com'};
      final user = UserDto.fromJson(json);
      expect(user.id, 2147483647);
    });

    test('UserDto - id = 0', () {
      final json = {'id': 0, 'email': 'zero@id.com'};
      final user = UserDto.fromJson(json);
      expect(user.id, 0);
    });

    test('UserDto - id âm', () {
      final json = {'id': -1, 'email': 'neg@id.com'};
      final user = UserDto.fromJson(json);
      expect(user.id, -1); // Should still parse, business logic should validate
    });

    test('QuizAttemptDto - score = 0 (minimum)', () {
      final json = {'quizId': 1, 'userId': 1, 'score': 0, 'passed': false};
      final attempt = QuizAttemptDto.fromJson(json);
      expect(attempt.score, 0);
      expect(attempt.passed, false);
    });

    test('QuizAttemptDto - score rất lớn (999)', () {
      final json = {'quizId': 1, 'userId': 1, 'score': 999, 'passed': true};
      final attempt = QuizAttemptDto.fromJson(json);
      expect(attempt.score, 999);
    });

    test('QuizAttemptDto - score âm', () {
      final json = {'quizId': 1, 'userId': 1, 'score': -10, 'passed': false};
      final attempt = QuizAttemptDto.fromJson(json);
      expect(attempt.score, -10); // Parse OK, validation logic elsewhere
    });

    test('EnrollmentDetailDto - progressPercent vượt 100', () {
      final json = {
        'courseId': 1,
        'courseTitle': 'Test',
        'courseSlug': 'test',
        'userId': 1,
        'status': 'ENROLLED',
        'progressPercent': 150, // Bất thường: > 100%
        'completed': false,
      };
      final enrollment = EnrollmentDetailDto.fromJson(json);
      expect(enrollment.progressPercent, 150); // Model không validate range
    });

    test('EnrollmentDetailDto - progressPercent âm', () {
      final json = {
        'courseId': 1,
        'courseTitle': 'Test',
        'courseSlug': 'test',
        'userId': 1,
        'status': 'ENROLLED',
        'progressPercent': -5,
        'completed': false,
      };
      final enrollment = EnrollmentDetailDto.fromJson(json);
      expect(enrollment.progressPercent, -5);
    });

    test('CourseSummaryDto - enrollmentCount rất lớn', () {
      final json = {
        'id': 1,
        'title': 'Popular Course',
        'level': 'BEGINNER',
        'status': 'PUBLIC',
        'author': {'id': 1, 'email': 'a@b.com'},
        'enrollmentCount': 9999999,
      };
      final course = CourseSummaryDto.fromJson(json);
      expect(course.enrollmentCount, 9999999);
    });

    test('CourseSummaryDto - price = 0 (miễn phí)', () {
      final json = {
        'id': 1,
        'title': 'Free Course',
        'level': 'BEGINNER',
        'status': 'PUBLIC',
        'author': {'id': 1, 'email': 'a@b.com'},
        'enrollmentCount': 0,
        'price': 0.0,
      };
      final course = CourseSummaryDto.fromJson(json);
      expect(course.price, 0.0);
    });

    test('QuizAttemptStatusDto - maxAttempts = 0', () {
      final json = {
        'quizId': 1,
        'userId': 1,
        'attemptsUsed': 0,
        'maxAttempts': 0,
        'canRetry': false,
        'hasPassed': false,
        'bestScore': 0,
        'secondsUntilRetry': 0,
      };
      final status = QuizAttemptStatusDto.fromJson(json);
      expect(status.maxAttempts, 0);
      expect(status.canRetry, false);
    });
  });

  // ============================================================
  // 2. CHUỖI ĐẶC BIỆT & DÀI BẤT THƯỜNG
  // ============================================================
  group('Edge Case: Chuỗi đặc biệt', () {
    test('LoginRequest - email có ký tự Unicode', () {
      final json = {'email': 'tést@exämple.com', 'password': 'pass'};
      final request = LoginRequest.fromJson(json);
      expect(request.email, 'tést@exämple.com');
    });

    test('LoginRequest - password rất dài (1000 chars)', () {
      final longPassword = 'A' * 1000;
      final json = {'email': 'a@b.com', 'password': longPassword};
      final request = LoginRequest.fromJson(json);
      expect(request.password.length, 1000);
    });

    test('RegisterRequest - fullName có ký tự đặc biệt', () {
      final json = {
        'email': 'a@b.com',
        'password': 'pass',
        'confirmPassword': 'pass',
        'fullName': "Nguyễn Văn A's \"Name\" <script>alert('xss')</script>",
      };
      final request = RegisterRequest.fromJson(json);
      expect(request.fullName, contains("Nguyễn Văn A"));
      expect(
        request.fullName,
        contains("<script>"),
      ); // XSS not sanitized at model level
    });

    test('CourseSummaryDto - title rất dài (500 chars)', () {
      final longTitle = 'Khóa học ' * 50;
      final json = {
        'id': 1,
        'title': longTitle,
        'level': 'BEGINNER',
        'status': 'PUBLIC',
        'author': {'id': 1, 'email': 'a@b.com'},
        'enrollmentCount': 0,
      };
      final course = CourseSummaryDto.fromJson(json);
      expect(course.title.length, greaterThan(400));
    });

    test('QuizQuestionDetailDto - questionText rỗng', () {
      final json = {
        'id': 1,
        'questionText': '',
        'questionType': 'MULTIPLE_CHOICE',
        'score': 10,
        'orderIndex': 0,
      };
      final question = QuizQuestionDetailDto.fromJson(json);
      expect(question.questionText, '');
    });

    test('QuizOptionDto - optionText có HTML', () {
      final json = {
        'id': 1,
        'optionText': '<b>Bold answer</b> & "quotes"',
        'correct': true,
      };
      final option = QuizOptionDto.fromJson(json);
      expect(option.optionText, contains('<b>'));
    });

    test('EnrollmentDetailDto - courseSlug có ký tự lạ', () {
      final json = {
        'courseId': 1,
        'courseTitle': 'Test',
        'courseSlug': 'course-with-émojis-🎓',
        'userId': 1,
        'status': 'ENROLLED',
        'progressPercent': 0,
        'completed': false,
      };
      final enrollment = EnrollmentDetailDto.fromJson(json);
      expect(enrollment.courseSlug, contains('🎓'));
    });
  });

  // ============================================================
  // 3. SAI KIỂU DỮ LIỆU & THIẾU FIELD
  // ============================================================
  group('Edge Case: Dữ liệu sai định dạng', () {
    test('CourseSummaryDto - level không hợp lệ fallback to beginner', () {
      final json = {
        'id': 1,
        'title': 'Test',
        'level': 'SUPER_EXPERT', // Không tồn tại
        'status': 'PUBLIC',
        'author': {'id': 1, 'email': 'a@b.com'},
        'enrollmentCount': 0,
      };
      final course = CourseSummaryDto.fromJson(json);
      expect(course.level, CourseLevel.beginner); // unknownEnumValue fallback
    });

    test('CourseSummaryDto - status không hợp lệ fallback to public', () {
      final json = {
        'id': 1,
        'title': 'Test',
        'level': 'BEGINNER',
        'status': 'DELETED', // Không tồn tại
        'author': {'id': 1, 'email': 'a@b.com'},
        'enrollmentCount': 0,
      };
      final course = CourseSummaryDto.fromJson(json);
      expect(course.status, CourseStatus.public); // unknownEnumValue fallback
    });

    test('PageResponse - items=null returns null content', () {
      final json = {
        'items': null,
        'page': 0,
        'size': 10,
        'total': 0,
        'totalPages': 0,
        'first': true,
        'last': true,
        'empty': true,
      };
      final page = PageResponse<CourseSummaryDto>.fromJson(
        json,
        (obj) => CourseSummaryDto.fromJson(obj as Map<String, dynamic>),
      );
      expect(page.content, isNull);
    });

    test('AuthResponse - refreshToken = null (chỉ có accessToken)', () {
      final json = {
        'accessToken': 'token',
        'refreshToken': null,
        'user': {'id': 1, 'email': 'a@b.com'},
      };
      final response = AuthResponse.fromJson(json);
      expect(response.accessToken, 'token');
      expect(response.refreshToken, isNull);
    });

    test('QuizDetailDto - questions = empty list', () {
      final json = {
        'id': 1,
        'title': 'Empty Quiz',
        'passScore': 50,
        'questions': [],
      };
      final quiz = QuizDetailDto.fromJson(json);
      expect(quiz.questions, isEmpty);
    });

    test('QuizAttemptDto - tất cả optional fields đều null', () {
      final json = {'quizId': 1, 'userId': 1, 'score': 0, 'passed': false};
      final attempt = QuizAttemptDto.fromJson(json);
      expect(attempt.id, isNull);
      expect(attempt.quizTitle, isNull);
      expect(attempt.correctAnswers, isNull);
      expect(attempt.totalQuestions, isNull);
      expect(attempt.submittedAt, isNull);
      expect(attempt.answers, isNull);
    });
  });

  // ============================================================
  // 4. VALIDATION EDGE CASES - Giá trị biên
  // ============================================================
  group('Edge Case: Validation - Giá trị biên', () {
    test('password đúng 8 ký tự (boundary min)', () {
      expect(ValidationHelper.password('Abcdefg1'), isNull); // 8 chars - pass
    });

    test('password 7 ký tự (boundary min - 1)', () {
      expect(ValidationHelper.password('Abcdef1'), isNotNull); // 7 chars - fail
    });

    // 🐛 BUG PHÁT HIỆN: Email regex quá lỏng - cho phép dot ở đầu
    // RFC 5321 quy định local part không được bắt đầu bằng dấu chấm
    // Hiện tại regex: r'^[a-zA-Z0-9._%+-]+@...' cho phép '.' ở đầu
    test('email - dot at start of local part (BUG: regex quá lỏng)', () {
      // EXPECTED: isNotNull (reject), ACTUAL: null (accept) → BUG
      final result = ValidationHelper.email('.user@test.com');
      expect(result, isNull); // Documenting current (buggy) behavior
    });

    // 🐛 BUG PHÁT HIỆN: Email regex cho phép consecutive dots
    test('email - consecutive dots (BUG: regex quá lỏng)', () {
      // EXPECTED: isNotNull (reject), ACTUAL: null (accept) → BUG
      final result = ValidationHelper.email('user..name@test.com');
      expect(result, isNull); // Documenting current (buggy) behavior
    });

    test('email - chỉ có domain 1 ký tự TLD', () {
      expect(ValidationHelper.email('user@test.c'), isNotNull); // TLD < 2
    });

    test('phone - đúng 10 số (boundary)', () {
      expect(ValidationHelper.phoneNumber('0123456789'), isNull);
    });

    test('phone - 9 số (boundary - 1)', () {
      expect(ValidationHelper.phoneNumber('012345678'), isNotNull);
    });

    test('phone - 11 số (boundary + 1)', () {
      expect(ValidationHelper.phoneNumber('01234567890'), isNotNull);
    });

    test('numberRange - giá trị = min (boundary)', () {
      expect(ValidationHelper.numberRange('0', 0, 100), isNull);
    });

    test('numberRange - giá trị = max (boundary)', () {
      expect(ValidationHelper.numberRange('100', 0, 100), isNull);
    });

    test('numberRange - giá trị = min - 0.001 (boundary)', () {
      expect(ValidationHelper.numberRange('-0.001', 0, 100), isNotNull);
    });

    test('numberRange - giá trị = max + 0.001 (boundary)', () {
      expect(ValidationHelper.numberRange('100.001', 0, 100), isNotNull);
    });

    test('minLength đúng boundary', () {
      expect(ValidationHelper.minLength('12345', 5), isNull); // = min
      expect(ValidationHelper.minLength('1234', 5), isNotNull); // min - 1
    });

    test('maxLength đúng boundary', () {
      expect(ValidationHelper.maxLength('12345', 5), isNull); // = max
      expect(ValidationHelper.maxLength('123456', 5), isNotNull); // max + 1
    });

    test('slug - chỉ 1 ký tự', () {
      expect(ValidationHelper.slug('a'), isNull);
    });

    test('slug - chỉ số', () {
      expect(ValidationHelper.slug('123'), isNull);
    });

    test('githubUsername - đúng 1 ký tự (min)', () {
      expect(ValidationHelper.githubUsername('a'), isNull);
    });

    test('twitterUsername - đúng 15 ký tự (max)', () {
      expect(ValidationHelper.twitterUsername('a' * 15), isNull);
    });

    test('twitterUsername - 16 ký tự (max + 1)', () {
      expect(ValidationHelper.twitterUsername('a' * 16), isNotNull);
    });
  });

  // ============================================================
  // 5. SQL INJECTION & XSS INPUT
  // ============================================================
  group('Edge Case: Input độc hại', () {
    test('Validation - email với SQL injection', () {
      expect(
        ValidationHelper.email("admin'--@test.com"),
        isNotNull, // Should reject
      );
    });

    test('Validation - email với SQL UNION', () {
      expect(
        ValidationHelper.email("' UNION SELECT * FROM users--"),
        isNotNull,
      );
    });

    test('Validation - password chỉ có spaces', () {
      expect(ValidationHelper.password('        '), isNotNull);
    });

    test('Validation - required với chỉ tab/newline', () {
      expect(ValidationHelper.required('\t\n'), isNotNull);
    });

    test('LoginRequest - serialize XSS input không crash', () {
      final request = LoginRequest(
        email: '<script>alert("xss")</script>@evil.com',
        password: '"; DROP TABLE users;--',
      );
      final json = request.toJson();
      // Model layer chỉ serialize, không sanitize - đó là trách nhiệm của backend
      expect(json['email'], contains('<script>'));
      expect(json['password'], contains('DROP TABLE'));
    });

    test('Validation - URL với javascript: protocol', () {
      expect(ValidationHelper.url('javascript:alert(1)'), isNotNull);
    });

    test('Validation - URL với data: protocol', () {
      expect(ValidationHelper.url('data:text/html,<h1>hi</h1>'), isNotNull);
    });
  });

  // ============================================================
  // 6. DATE & TIME EDGE CASES
  // ============================================================
  group('Edge Case: Ngày tháng bất thường', () {
    test('dateFormat - ngày 29/02 năm nhuận', () {
      expect(
        ValidationHelper.dateFormat('2024-02-29'),
        isNull,
      ); // 2024 là năm nhuận
    });

    // 🐛 BUG PHÁT HIỆN: Dart DateTime.parse() tự điều chỉnh ngày không hợp lệ
    // thay vì throw exception. VD: '2023-02-29' → tự chuyển thành '2023-03-01'
    // Điều này khiến dateFormat() không bắt được ngày sai.
    test(
      'dateFormat - ngày 29/02 năm KHÔNG nhuận (BUG: DateTime.parse tự adjust)',
      () {
        // EXPECTED: isNotNull (reject), ACTUAL: null (accept) → BUG
        final result = ValidationHelper.dateFormat('2023-02-29');
        expect(result, isNull); // Documenting current (buggy) behavior
      },
    );

    test(
      'dateFormat - ngày 31 tháng có 30 ngày (BUG: DateTime.parse tự adjust)',
      () {
        final result = ValidationHelper.dateFormat('2024-04-31');
        expect(result, isNull); // Documenting current behavior
      },
    );

    test('dateFormat - ngày 00 (BUG: DateTime.parse tự adjust)', () {
      final result = ValidationHelper.dateFormat('2024-01-00');
      expect(result, isNull); // Documenting current behavior
    });

    test('dateFormat - tháng 00 (BUG: DateTime.parse tự adjust)', () {
      final result = ValidationHelper.dateFormat('2024-00-15');
      expect(result, isNull); // Documenting current behavior
    });

    test('dateRange - cùng ngày (start == end)', () {
      final date = DateTime(2024, 6, 15);
      expect(
        ValidationHelper.dateRange(date, date),
        isNull,
      ); // Same day should be OK
    });

    test('EnrollmentDetailDto - parse ISO 8601 date', () {
      final json = {
        'courseId': 1,
        'courseTitle': 'Test',
        'courseSlug': 'test',
        'userId': 1,
        'status': 'ENROLLED',
        'progressPercent': 0,
        'enrolledAt': '2024-02-29T23:59:59.999Z', // Leap year edge case
        'completed': false,
      };
      final enrollment = EnrollmentDetailDto.fromJson(json);
      expect(enrollment.enrolledAt, isNotNull);
      expect(enrollment.enrolledAt!.month, 2);
      expect(enrollment.enrolledAt!.day, 29);
    });
  });
}
