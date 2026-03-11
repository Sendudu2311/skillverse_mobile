import 'package:flutter_test/flutter_test.dart';
import 'package:skillverse_mobile/presentation/providers/enrollment_provider.dart';
import 'package:skillverse_mobile/data/models/enrollment_models.dart';

/// ============================================================
/// ENROLLMENT PROVIDER TEST
/// Mục đích: Kiểm thử state management cho enrollment flows
/// - Enroll/Unenroll, Cache behavior, State transitions
/// ============================================================

void main() {
  group('EnrollmentProvider - Initial State', () {
    late EnrollmentProvider provider;

    setUp(() {
      provider = EnrollmentProvider();
    });

    test('initial enrollments list is empty', () {
      expect(provider.enrollments, isEmpty);
    });

    test('initial isLoading is false', () {
      expect(provider.isLoading, false);
    });

    test('initial errorMessage is null', () {
      expect(provider.errorMessage, isNull);
    });

    test('isEnrolled returns false for any courseId initially', () {
      expect(provider.isEnrolled(1), false);
      expect(provider.isEnrolled(999), false);
      expect(provider.isEnrolled(0), false);
    });
  });

  group('EnrollmentProvider - getEnrollment()', () {
    late EnrollmentProvider provider;

    setUp(() {
      provider = EnrollmentProvider();
    });

    test('getEnrollment returns null for unknown courseId', () {
      expect(provider.getEnrollment(1), isNull);
      expect(provider.getEnrollment(999), isNull);
    });
  });

  group('EnrollmentProvider - clear()', () {
    late EnrollmentProvider provider;

    setUp(() {
      provider = EnrollmentProvider();
    });

    test('clear resets all state', () {
      provider.clear();

      expect(provider.enrollments, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNull);
      expect(provider.isEnrolled(1), false);
    });

    test('clear notifies listeners', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.clear();
      expect(notifyCount, greaterThan(0));
    });
  });

  group('EnrollmentProvider - enrollInCourse() error handling', () {
    late EnrollmentProvider provider;

    setUp(() {
      provider = EnrollmentProvider();
    });

    test('enrollInCourse with invalid data returns false', () async {
      final result = await provider.enrollInCourse(courseId: -1, userId: -1);

      expect(result, false);
      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNotNull);
    });

    test('enrollInCourse sets loading during operation', () async {
      final states = <bool>[];
      provider.addListener(() {
        states.add(provider.isLoading);
      });

      await provider.enrollInCourse(courseId: 999, userId: 1);

      expect(states.isNotEmpty, true);
      expect(states.last, false);
    });

    test('failed enrollment does not add to list', () async {
      final initialLength = provider.enrollments.length;
      await provider.enrollInCourse(courseId: 999, userId: 1);

      expect(provider.enrollments.length, initialLength);
    });

    test('failed enrollment does not update cache', () async {
      await provider.enrollInCourse(courseId: 999, userId: 1);
      expect(provider.isEnrolled(999), false);
    });
  });

  group('EnrollmentProvider - unenrollFromCourse() error handling', () {
    late EnrollmentProvider provider;

    setUp(() {
      provider = EnrollmentProvider();
    });

    test('unenrollFromCourse with invalid data returns false', () async {
      final result = await provider.unenrollFromCourse(
        courseId: -1,
        userId: -1,
      );

      expect(result, false);
      expect(provider.isLoading, false);
    });

    test('unenrollFromCourse sets loading states', () async {
      final states = <bool>[];
      provider.addListener(() {
        states.add(provider.isLoading);
      });

      await provider.unenrollFromCourse(courseId: 1, userId: 1);
      expect(states.last, false);
    });
  });

  group('EnrollmentProvider - checkEnrollmentStatus()', () {
    late EnrollmentProvider provider;

    setUp(() {
      provider = EnrollmentProvider();
    });

    test('checkEnrollmentStatus returns false on API error', () async {
      final result = await provider.checkEnrollmentStatus(
        courseId: 999,
        userId: 1,
      );

      expect(result, false);
    });
  });

  group('EnrollmentProvider - fetchUserEnrollments()', () {
    late EnrollmentProvider provider;

    setUp(() {
      provider = EnrollmentProvider();
    });

    test('fetchUserEnrollments with invalid userId sets error', () async {
      await provider.fetchUserEnrollments(userId: -1);

      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNotNull);
    });

    test('fetchUserEnrollments sets loading during fetch', () async {
      final states = <bool>[];
      provider.addListener(() {
        states.add(provider.isLoading);
      });

      await provider.fetchUserEnrollments(userId: 1);

      expect(states.isNotEmpty, true);
      expect(states.last, false);
    });
  });

  group('EnrollmentProvider - updateProgress()', () {
    late EnrollmentProvider provider;

    setUp(() {
      provider = EnrollmentProvider();
    });

    test('updateProgress with invalid data returns false', () async {
      final result = await provider.updateProgress(
        courseId: 999,
        userId: 1,
        progressPercentage: 50,
      );

      expect(result, false);
    });

    test('updateProgress with 0% does not crash', () async {
      final result = await provider.updateProgress(
        courseId: 1,
        userId: 1,
        progressPercentage: 0,
      );
      expect(result, false); // Fails because no enrollment exists
    });

    test('updateProgress with 100% does not crash', () async {
      final result = await provider.updateProgress(
        courseId: 1,
        userId: 1,
        progressPercentage: 100,
      );
      expect(result, false);
    });
  });

  group('EnrollmentProvider - markAsCompleted()', () {
    late EnrollmentProvider provider;

    setUp(() {
      provider = EnrollmentProvider();
    });

    test('markAsCompleted with invalid courseId returns false', () async {
      final result = await provider.markAsCompleted(courseId: 999, userId: 1);

      expect(result, false);
    });
  });

  group('EnrollmentProvider - Listener notifications', () {
    test('all state changes notify listeners', () async {
      final provider = EnrollmentProvider();
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.enrollInCourse(courseId: 1, userId: 1);

      // Should notify at least for: setLoading(true), clearError, error/result, setLoading(false)
      expect(notifyCount, greaterThanOrEqualTo(2));
    });
  });
}
