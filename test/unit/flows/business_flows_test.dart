import 'package:flutter_test/flutter_test.dart';
import 'package:skillverse_mobile/core/utils/validation_helper.dart';
import 'package:skillverse_mobile/data/models/auth_models.dart';
import 'package:skillverse_mobile/data/models/course_models.dart';
import 'package:skillverse_mobile/data/models/quiz_models.dart';
import 'package:skillverse_mobile/data/models/enrollment_models.dart';
import 'package:skillverse_mobile/core/exceptions/api_exception.dart';

/// ============================================================
/// BUSINESS FLOW TESTS
/// Kiểm thử các luồng nghiệp vụ end-to-end ở mức unit
/// Mô phỏng dữ liệu qua JSON → Model → Validate → Serialize
/// ============================================================

void main() {
  // ============================================================
  // FLOW 1: ĐĂNG KÝ → XÁC THỰC → ĐĂNG NHẬP
  // ============================================================
  group('Flow: Registration → Login', () {
    test('1. Validate registration form', () {
      const email = 'newuser@skillverse.vn';
      const password = 'MyPassword1';
      const fullName = 'Nguyen Van A';

      expect(ValidationHelper.email(email), isNull);
      expect(ValidationHelper.password(password), isNull);
      expect(ValidationHelper.required(fullName), isNull);
    });

    test('2. Create register request → serialize to JSON', () {
      final request = RegisterRequest(
        email: 'newuser@skillverse.vn',
        password: 'MyPassword1',
        confirmPassword: 'MyPassword1',
        fullName: 'Nguyen Van A',
        phoneNumber: '0901234567',
      );
      final json = request.toJson();

      expect(json['email'], 'newuser@skillverse.vn');
      expect(json['password'], 'MyPassword1');
      expect(json['fullName'], 'Nguyen Van A');
      expect(json['phoneNumber'], '0901234567');
    });

    test('3. Parse registration response (simulated API)', () {
      final apiResponse = {
        'accessToken': 'eyJhbGciOiJIUzI1NiJ9.new_user_token',
        'refreshToken': 'refresh_new_user',
        'user': {
          'id': 100,
          'email': 'newuser@skillverse.vn',
          'fullName': 'Nguyen Van A',
          'roles': ['STUDENT'],
        },
      };

      final response = AuthResponse.fromJson(apiResponse);
      expect(response.accessToken, contains('new_user_token'));
      expect(response.user.id, 100);
      expect(response.user.email, 'newuser@skillverse.vn');
      expect(response.user.roles, contains('STUDENT'));
    });

    test('4. Subsequent login with same credentials', () {
      final loginRequest = LoginRequest(
        email: 'newuser@skillverse.vn',
        password: 'MyPassword1',
      );
      final json = loginRequest.toJson();

      expect(json['email'], 'newuser@skillverse.vn');
      expect(json['password'], 'MyPassword1');
    });

    test('5. Registration with weak password is caught by validation', () {
      expect(ValidationHelper.password('weak'), isNotNull);
      expect(ValidationHelper.password('nouppercase1'), isNotNull);
      expect(ValidationHelper.password('NOLOWERCASE1'), isNotNull);
      expect(ValidationHelper.password('NoDigitsHere'), isNotNull);
    });

    test('6. Registration with invalid email is caught by validation', () {
      expect(ValidationHelper.email('not-email'), isNotNull);
      expect(ValidationHelper.email(''), isNotNull);
    });

    test('7. Verify email with OTP', () {
      final request = VerifyEmailRequest(
        email: 'newuser@skillverse.vn',
        otp: '123456',
      );
      final json = request.toJson();

      expect(json['email'], 'newuser@skillverse.vn');
      expect(json['otp'], '123456');
    });
  });

  // ============================================================
  // FLOW 2: DUYỆT KHÓA HỌC → GHI DANH → HỌC
  // ============================================================
  group('Flow: Browse → Enroll → Learn', () {
    test('1. Parse course listing page response', () {
      final apiResponse = {
        'items': [
          {
            'id': 1,
            'title': 'Flutter Development Masterclass',
            'description': 'Comprehensive Flutter course',
            'level': 'BEGINNER',
            'status': 'PUBLIC',
            'author': {
              'id': 10,
              'email': 'instructor@sv.vn',
              'fullName': 'Mr. Teacher',
            },
            'enrollmentCount': 250,
            'moduleCount': 12,
            'lessonCount': 60,
            'price': 499000.0,
            'currency': 'VND',
            'rating': 4.8,
            'reviewCount': 45,
          },
          {
            'id': 2,
            'title': 'Advanced Dart Programming',
            'level': 'ADVANCED',
            'status': 'PUBLIC',
            'author': {'id': 10, 'email': 'instructor@sv.vn'},
            'enrollmentCount': 100,
            'price': 299000.0,
          },
        ],
        'page': 0,
        'size': 10,
        'total': 2,
        'totalPages': 1,
        'first': true,
        'last': true,
        'empty': false,
      };

      final page = PageResponse<CourseSummaryDto>.fromJson(
        apiResponse,
        (json) => CourseSummaryDto.fromJson(json as Map<String, dynamic>),
      );

      expect(page.content!.length, 2);
      expect(page.first, true);
      expect(page.last, true);
      expect(page.content![0].title, 'Flutter Development Masterclass');
      expect(page.content![0].price, 499000.0);
      expect(page.content![1].level, CourseLevel.advanced);
    });

    test('2. Filter courses by level (client-side)', () {
      final courses = [
        CourseSummaryDto.fromJson({
          'id': 1,
          'title': 'Beginner',
          'level': 'BEGINNER',
          'status': 'PUBLIC',
          'author': {'id': 1, 'email': 'a@b.com'},
          'enrollmentCount': 0,
        }),
        CourseSummaryDto.fromJson({
          'id': 2,
          'title': 'Advanced',
          'level': 'ADVANCED',
          'status': 'PUBLIC',
          'author': {'id': 1, 'email': 'a@b.com'},
          'enrollmentCount': 0,
        }),
        CourseSummaryDto.fromJson({
          'id': 3,
          'title': 'Intermediate',
          'level': 'INTERMEDIATE',
          'status': 'PUBLIC',
          'author': {'id': 1, 'email': 'a@b.com'},
          'enrollmentCount': 0,
        }),
      ];

      final beginnerOnly = courses
          .where((c) => c.level == CourseLevel.beginner)
          .toList();
      expect(beginnerOnly.length, 1);
      expect(beginnerOnly[0].title, 'Beginner');

      final advancedOnly = courses
          .where((c) => c.level == CourseLevel.advanced)
          .toList();
      expect(advancedOnly.length, 1);
      expect(advancedOnly[0].title, 'Advanced');
    });

    test('3. Search courses filters results', () {
      final courses = [
        CourseSummaryDto.fromJson({
          'id': 1,
          'title': 'Flutter Basics',
          'level': 'BEGINNER',
          'status': 'PUBLIC',
          'author': {'id': 1, 'email': 'a@b.com'},
          'enrollmentCount': 0,
        }),
        CourseSummaryDto.fromJson({
          'id': 2,
          'title': 'React Native',
          'level': 'BEGINNER',
          'status': 'PUBLIC',
          'author': {'id': 1, 'email': 'a@b.com'},
          'enrollmentCount': 0,
        }),
      ];

      final searchResults = courses
          .where((c) => c.title.toLowerCase().contains('flutter'))
          .toList();
      expect(searchResults.length, 1);
      expect(searchResults[0].title, 'Flutter Basics');
    });

    test('4. Create enrollment request', () {
      const request = EnrollRequestDto(courseId: 1);
      final json = request.toJson();
      expect(json['courseId'], 1);
    });

    test('5. Parse enrollment response', () {
      final apiResponse = {
        'id': 500,
        'courseId': 1,
        'courseTitle': 'Flutter Development Masterclass',
        'courseSlug': 'flutter-development-masterclass',
        'userId': 100,
        'status': 'ENROLLED',
        'progressPercent': 0,
        'entitlementSource': 'PURCHASE',
        'entitlementRef': 'TXN_20240301_001',
        'enrolledAt': '2024-03-01T10:00:00.000Z',
        'completedAt': null,
        'completed': false,
      };

      final enrollment = EnrollmentDetailDto.fromJson(apiResponse);
      expect(enrollment.courseId, 1);
      expect(enrollment.status, 'ENROLLED');
      expect(enrollment.progressPercent, 0);
      expect(enrollment.completed, false);
      expect(enrollment.enrolledAt, isNotNull);
    });

    test('6. Track learning progress (0% → 50% → 100%)', () {
      final progressSteps = [0, 25, 50, 75, 100];

      for (final progress in progressSteps) {
        final enrollment = EnrollmentDetailDto(
          courseId: 1,
          courseTitle: 'Test',
          courseSlug: 'test',
          userId: 100,
          status: progress == 100 ? 'COMPLETED' : 'ENROLLED',
          progressPercent: progress,
          completed: progress == 100,
        );

        expect(enrollment.progressPercent, progress);
        if (progress == 100) {
          expect(enrollment.completed, true);
          expect(enrollment.status, 'COMPLETED');
        }
      }
    });

    test('7. Check enrollment status', () {
      final enrolled = EnrollmentStatusDto.fromJson({'enrolled': true});
      final notEnrolled = EnrollmentStatusDto.fromJson({'enrolled': false});

      expect(enrolled.enrolled, true);
      expect(notEnrolled.enrolled, false);
    });
  });

  // ============================================================
  // FLOW 3: LÀM QUIZ → NỘP BÀI → XEM KẾT QUẢ → THỬ LẠI
  // ============================================================
  group('Flow: Quiz Attempt → Submit → Result → Retry', () {
    test('1. Load quiz with questions and options', () {
      final quizJson = {
        'id': 1,
        'title': 'Flutter Basics Quiz',
        'description': 'Test your Flutter knowledge',
        'passScore': 70,
        'moduleId': 5,
        'questions': [
          {
            'id': 1,
            'questionText': 'What is Flutter?',
            'questionType': 'MULTIPLE_CHOICE',
            'score': 25,
            'orderIndex': 0,
            'options': [
              {
                'id': 1,
                'optionText': 'A UI toolkit',
                'correct': true,
                'feedback': 'Correct!',
                'orderIndex': 0,
              },
              {
                'id': 2,
                'optionText': 'A database',
                'correct': false,
                'feedback': 'Wrong',
                'orderIndex': 1,
              },
              {
                'id': 3,
                'optionText': 'A backend framework',
                'correct': false,
                'orderIndex': 2,
              },
              {
                'id': 4,
                'optionText': 'An OS',
                'correct': false,
                'orderIndex': 3,
              },
            ],
          },
          {
            'id': 2,
            'questionText': 'Dart is statically typed',
            'questionType': 'TRUE_FALSE',
            'score': 25,
            'orderIndex': 1,
            'options': [
              {'id': 5, 'optionText': 'True', 'correct': true, 'orderIndex': 0},
              {
                'id': 6,
                'optionText': 'False',
                'correct': false,
                'orderIndex': 1,
              },
            ],
          },
          {
            'id': 3,
            'questionText': 'What command creates a new Flutter project?',
            'questionType': 'SHORT_ANSWER',
            'score': 25,
            'orderIndex': 2,
          },
          {
            'id': 4,
            'questionText': 'Explain the Widget tree in Flutter',
            'questionType': 'SHORT_ANSWER',
            'score': 25,
            'orderIndex': 3,
          },
        ],
      };

      final quiz = QuizDetailDto.fromJson(quizJson);
      expect(quiz.title, 'Flutter Basics Quiz');
      expect(quiz.passScore, 70);
      expect(quiz.questions!.length, 4);

      // Question types
      expect(quiz.questions![0].questionType, QuestionType.multipleChoice);
      expect(quiz.questions![1].questionType, QuestionType.trueFalse);
      expect(quiz.questions![2].questionType, QuestionType.shortAnswer);

      // Options
      expect(quiz.questions![0].options!.length, 4);
      expect(quiz.questions![0].options!.where((o) => o.correct).length, 1);
    });

    test('2. Submit quiz answers (all correct)', () {
      final submission = SubmitQuizDto(
        quizId: 1,
        answers: [
          QuizAnswerDto(questionId: 1, selectedOptionIds: [1]),
          QuizAnswerDto(questionId: 2, selectedOptionIds: [5]),
          QuizAnswerDto(questionId: 3, textAnswer: 'flutter create'),
          QuizAnswerDto(
            questionId: 4,
            textAnswer: 'Widget tree is hierarchical',
          ),
        ],
      );
      final json = submission.toJson();

      expect(json['quizId'], 1);
      expect((json['answers'] as List).length, 4);
    });

    test('3. Parse quiz result - PASSED', () {
      final resultJson = {
        'score': 100,
        'passed': true,
        'attempt': {
          'id': 1,
          'quizId': 1,
          'userId': 100,
          'score': 100,
          'passed': true,
          'correctAnswers': 4,
          'totalQuestions': 4,
          'submittedAt': '2024-03-01T11:00:00.000Z',
        },
      };

      final result = QuizSubmitResponseDto.fromJson(resultJson);
      expect(result.passed, true);
      expect(result.score, 100);
      expect(result.attempt.correctAnswers, 4);
      expect(result.attempt.totalQuestions, 4);
    });

    test('4. Parse quiz result - FAILED', () {
      final resultJson = {
        'score': 50,
        'passed': false,
        'attempt': {
          'id': 2,
          'quizId': 1,
          'userId': 100,
          'score': 50,
          'passed': false,
          'correctAnswers': 2,
          'totalQuestions': 4,
        },
      };

      final result = QuizSubmitResponseDto.fromJson(resultJson);
      expect(result.passed, false);
      expect(result.score, 50);
      expect(result.attempt.correctAnswers, 2);
    });

    test('5. Check retry status - can retry', () {
      final statusJson = {
        'quizId': 1,
        'userId': 100,
        'attemptsUsed': 1,
        'maxAttempts': 3,
        'canRetry': true,
        'hasPassed': false,
        'bestScore': 50,
        'secondsUntilRetry': 0,
        'recentAttempts': [
          {'id': 2, 'quizId': 1, 'userId': 100, 'score': 50, 'passed': false},
        ],
      };

      final status = QuizAttemptStatusDto.fromJson(statusJson);
      expect(status.canRetry, true);
      expect(status.attemptsUsed, lessThan(status.maxAttempts));
      expect(status.hasPassed, false);
      expect(status.recentAttempts!.length, 1);
    });

    test('6. Check retry status - max attempts reached', () {
      final statusJson = {
        'quizId': 1,
        'userId': 100,
        'attemptsUsed': 3,
        'maxAttempts': 3,
        'canRetry': false,
        'hasPassed': false,
        'bestScore': 60,
        'secondsUntilRetry': 0,
      };

      final status = QuizAttemptStatusDto.fromJson(statusJson);
      expect(status.canRetry, false);
      expect(status.attemptsUsed, equals(status.maxAttempts));
    });

    test('7. Check retry status - cooldown active', () {
      final statusJson = {
        'quizId': 1,
        'userId': 100,
        'attemptsUsed': 2,
        'maxAttempts': 3,
        'canRetry': false,
        'hasPassed': false,
        'bestScore': 60,
        'secondsUntilRetry': 3600, // 1 hour cooldown
        'nextRetryAt': '2024-03-01T12:00:00.000Z',
      };

      final status = QuizAttemptStatusDto.fromJson(statusJson);
      expect(status.canRetry, false);
      expect(status.secondsUntilRetry, greaterThan(0));
      expect(status.nextRetryAt, isNotNull);
    });

    test('8. View answer results after attempt', () {
      final answers = [
        QuizAnswerResultDto.fromJson({
          'questionId': 1,
          'selectedOptionIds': [1],
          'isCorrect': true,
          'scoreEarned': 25,
        }),
        QuizAnswerResultDto.fromJson({
          'questionId': 2,
          'selectedOptionIds': [6],
          'isCorrect': false,
          'scoreEarned': 0,
        }),
      ];

      expect(answers[0].isCorrect, true);
      expect(answers[0].scoreEarned, 25);
      expect(answers[1].isCorrect, false);
      expect(answers[1].scoreEarned, 0);

      final totalScore = answers.fold<int>(0, (sum, a) => sum + a.scoreEarned);
      expect(totalScore, 25);
    });
  });

  // ============================================================
  // FLOW 4: XỬ LÝ LỖI API
  // ============================================================
  group('Flow: API Error Handling', () {
    test('401 Unauthorized → redirect to login', () {
      const error = ApiException('Unauthorized', 401);
      expect(error.statusCode, 401);
      expect(error.message.toLowerCase(), contains('unauthorized'));
    });

    test('403 Forbidden → access denied', () {
      const error = ApiException('Forbidden', 403);
      expect(error.statusCode, 403);
    });

    test('404 Not Found → resource missing', () {
      const error = ApiException('Not Found', 404);
      expect(error.statusCode, 404);
    });

    test('500 Internal Server Error → server error', () {
      const error = ApiException('Internal Server Error', 500);
      expect(error.statusCode, 500);
    });

    test('API error response parsing', () {
      final errorJson = {
        'message': 'Email already exists',
        'code': 'DUPLICATE_EMAIL',
        'details': {'field': 'email', 'value': 'existing@test.com'},
      };

      final error = ApiErrorResponse.fromJson(errorJson);
      expect(error.message, 'Email already exists');
      expect(error.code, 'DUPLICATE_EMAIL');
      expect(error.details?['field'], 'email');
    });

    test('Network timeout creates appropriate exception', () {
      const error = ApiException('Connection timeout', 0);
      expect(error.message, contains('timeout'));
    });
  });

  // ============================================================
  // FLOW 5: FORM VALIDATION - Complete form flows
  // ============================================================
  group('Flow: Login Form Validation', () {
    test('empty form → all fields show errors', () {
      expect(ValidationHelper.email(''), isNotNull);
      expect(ValidationHelper.password(''), isNotNull);
    });

    test('valid form → no errors', () {
      expect(ValidationHelper.email('user@skillverse.vn'), isNull);
      expect(ValidationHelper.password('StrongP@ss1'), isNull);
    });

    test('partial form → specific errors', () {
      expect(ValidationHelper.email('user@skillverse.vn'), isNull);
      expect(ValidationHelper.password(''), isNotNull); // Only password empty
    });
  });

  group('Flow: Registration Form Validation', () {
    test('combined validator for full name', () {
      final nameValidator = ValidationHelper.combine([
        (v) => ValidationHelper.required(v, fieldName: 'Họ và tên'),
        (v) => ValidationHelper.minLength(v, 2, fieldName: 'Họ và tên'),
        (v) => ValidationHelper.maxLength(v, 100, fieldName: 'Họ và tên'),
      ]);

      expect(nameValidator(''), isNotNull); // empty
      expect(nameValidator('A'), isNotNull); // too short
      expect(nameValidator('Nguyen Van A'), isNull); // valid
    });

    test('combined validator for phone number', () {
      final phoneValidator = ValidationHelper.combine([
        (v) => ValidationHelper.phoneNumber(v, isRequired: true),
      ]);

      expect(phoneValidator(''), isNotNull);
      expect(phoneValidator('0901234567'), isNull);
      expect(phoneValidator('123'), isNotNull);
    });

    test('password confirmation must match', () {
      const password = 'MyP@ssw0rd';
      expect(ValidationHelper.confirmPassword('MyP@ssw0rd', password), isNull);
      expect(
        ValidationHelper.confirmPassword('Different1', password),
        isNotNull,
      );
    });
  });

  // ============================================================
  // FLOW 6: ENROLLMENT STATISTICS
  // ============================================================
  group('Flow: Enrollment Statistics', () {
    test('parse enrollment stats for dashboard', () {
      final statsJson = {
        'totalEnrollments': 500,
        'activeEnrollments': 350,
        'completedEnrollments': 150,
        'averageProgress': 55.5,
        'completionRate': 30.0,
      };

      final stats = EnrollmentStatsDto.fromJson(statsJson);
      expect(stats.totalEnrollments, 500);
      expect(
        stats.activeEnrollments + stats.completedEnrollments,
        stats.totalEnrollments,
      );
      expect(stats.completionRate, 30.0);
      expect(stats.averageProgress, greaterThan(0));
    });

    test('enrollment stats with zero enrollments', () {
      final statsJson = {
        'totalEnrollments': 0,
        'activeEnrollments': 0,
        'completedEnrollments': 0,
        'averageProgress': 0.0,
        'completionRate': 0.0,
      };

      final stats = EnrollmentStatsDto.fromJson(statsJson);
      expect(stats.totalEnrollments, 0);
      expect(stats.completionRate, 0.0);
    });
  });
}
