import 'package:flutter_test/flutter_test.dart';
import 'package:skillverse_mobile/data/models/enrollment_models.dart';

void main() {
  // ============================================================
  // EnrollRequestDto Tests
  // ============================================================
  group('EnrollRequestDto', () {
    test('fromJson() creates instance correctly', () {
      final json = {'courseId': 42};
      final request = EnrollRequestDto.fromJson(json);

      expect(request.courseId, 42);
    });

    test('toJson() returns correct map', () {
      const request = EnrollRequestDto(courseId: 10);
      final json = request.toJson();

      expect(json['courseId'], 10);
    });

    test('fromJson → toJson round-trip', () {
      final original = {'courseId': 5};
      final result = EnrollRequestDto.fromJson(original).toJson();

      expect(result, original);
    });
  });

  // ============================================================
  // EnrollmentDetailDto Tests
  // ============================================================
  group('EnrollmentDetailDto', () {
    test('fromJson() with all fields', () {
      final json = {
        'id': 1,
        'courseId': 10,
        'courseTitle': 'Flutter Development',
        'courseSlug': 'flutter-development',
        'userId': 42,
        'status': 'ENROLLED',
        'progressPercent': 35,
        'entitlementSource': 'PURCHASE',
        'entitlementRef': 'TXN_001',
        'enrolledAt': '2024-01-15T10:00:00.000Z',
        'completedAt': null,
        'completed': false,
      };
      final enrollment = EnrollmentDetailDto.fromJson(json);

      expect(enrollment.id, 1);
      expect(enrollment.courseId, 10);
      expect(enrollment.courseTitle, 'Flutter Development');
      expect(enrollment.courseSlug, 'flutter-development');
      expect(enrollment.userId, 42);
      expect(enrollment.status, 'ENROLLED');
      expect(enrollment.progressPercent, 35);
      expect(enrollment.entitlementSource, 'PURCHASE');
      expect(enrollment.entitlementRef, 'TXN_001');
      expect(enrollment.enrolledAt, isNotNull);
      expect(enrollment.completedAt, isNull);
      expect(enrollment.completed, false);
    });

    test('fromJson() completed course', () {
      final json = {
        'id': 2,
        'courseId': 10,
        'courseTitle': 'Completed Course',
        'courseSlug': 'completed-course',
        'userId': 42,
        'status': 'COMPLETED',
        'progressPercent': 100,
        'enrolledAt': '2024-01-01T00:00:00.000Z',
        'completedAt': '2024-03-01T00:00:00.000Z',
        'completed': true,
      };
      final enrollment = EnrollmentDetailDto.fromJson(json);

      expect(enrollment.status, 'COMPLETED');
      expect(enrollment.progressPercent, 100);
      expect(enrollment.completed, true);
      expect(enrollment.completedAt, isNotNull);
    });

    test('toJson() preserves all fields', () {
      final enrollment = EnrollmentDetailDto(
        id: 1,
        courseId: 5,
        courseTitle: 'Test Course',
        courseSlug: 'test-course',
        userId: 99,
        status: 'ENROLLED',
        progressPercent: 50,
        completed: false,
      );
      final json = enrollment.toJson();

      expect(json['courseId'], 5);
      expect(json['courseTitle'], 'Test Course');
      expect(json['progressPercent'], 50);
      expect(json['completed'], false);
    });
  });

  // ============================================================
  // EnrollmentStatusDto Tests
  // ============================================================
  group('EnrollmentStatusDto', () {
    test('fromJson() enrolled=true', () {
      final json = {'enrolled': true};
      final status = EnrollmentStatusDto.fromJson(json);

      expect(status.enrolled, true);
    });

    test('fromJson() enrolled=false', () {
      final json = {'enrolled': false};
      final status = EnrollmentStatusDto.fromJson(json);

      expect(status.enrolled, false);
    });

    test('toJson() round-trip', () {
      const original = EnrollmentStatusDto(enrolled: true);
      final json = original.toJson();

      expect(json['enrolled'], true);
    });
  });

  // ============================================================
  // EnrollmentStatsDto Tests
  // ============================================================
  group('EnrollmentStatsDto', () {
    test('fromJson() with all stats', () {
      final json = {
        'totalEnrollments': 150,
        'activeEnrollments': 120,
        'completedEnrollments': 30,
        'averageProgress': 45.5,
        'completionRate': 20.0,
      };
      final stats = EnrollmentStatsDto.fromJson(json);

      expect(stats.totalEnrollments, 150);
      expect(stats.activeEnrollments, 120);
      expect(stats.completedEnrollments, 30);
      expect(stats.averageProgress, 45.5);
      expect(stats.completionRate, 20.0);
    });

    test('toJson() preserves all fields', () {
      const stats = EnrollmentStatsDto(
        totalEnrollments: 100,
        activeEnrollments: 80,
        completedEnrollments: 20,
        averageProgress: 60.0,
        completionRate: 20.0,
      );
      final json = stats.toJson();

      expect(json['totalEnrollments'], 100);
      expect(json['activeEnrollments'], 80);
      expect(json['completedEnrollments'], 20);
      expect(json['averageProgress'], 60.0);
      expect(json['completionRate'], 20.0);
    });
  });

  // ============================================================
  // Enum Tests
  // ============================================================
  group('EnrollmentStatus enum', () {
    test('contains all expected values', () {
      expect(EnrollmentStatus.values.length, 4);
      expect(EnrollmentStatus.values, contains(EnrollmentStatus.enrolled));
      expect(EnrollmentStatus.values, contains(EnrollmentStatus.completed));
      expect(EnrollmentStatus.values, contains(EnrollmentStatus.dropped));
      expect(EnrollmentStatus.values, contains(EnrollmentStatus.expired));
    });
  });

  group('EntitlementSource enum', () {
    test('contains all expected values', () {
      expect(EntitlementSource.values.length, 4);
      expect(EntitlementSource.values, contains(EntitlementSource.purchase));
      expect(EntitlementSource.values, contains(EntitlementSource.admin));
      expect(EntitlementSource.values, contains(EntitlementSource.promotion));
      expect(EntitlementSource.values, contains(EntitlementSource.scholarship));
    });
  });
}
