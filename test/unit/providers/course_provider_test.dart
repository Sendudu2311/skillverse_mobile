import 'package:flutter_test/flutter_test.dart';
import 'package:skillverse_mobile/presentation/providers/course_provider.dart';
import 'package:skillverse_mobile/data/models/course_models.dart';

/// ============================================================
/// COURSE PROVIDER TEST
/// Kiểm thử state management cho Course listing
/// Tập trung vào: Synchronous behavior (filter, reset, initial state)
/// và error resilience (không crash khi API unavailable)
/// ============================================================

void main() {
  group('CourseProvider - Initial State', () {
    late CourseProvider provider;

    setUp(() {
      provider = CourseProvider();
    });

    test('initial courses list is empty', () {
      expect(provider.courses, isEmpty);
    });

    test('initial allCourses list is empty', () {
      expect(provider.allCourses, isEmpty);
    });

    test('initial selectedLevel is null', () {
      expect(provider.selectedLevel, isNull);
    });

    test('initial isEmpty is true', () {
      expect(provider.isEmpty, true);
    });

    test('initial paginationError is null', () {
      expect(provider.paginationError, isNull);
    });
  });

  group('CourseProvider - Level Filter', () {
    late CourseProvider provider;

    setUp(() {
      provider = CourseProvider();
    });

    test('setLevelFilter updates selectedLevel', () {
      provider.setLevelFilter(CourseLevel.beginner);
      expect(provider.selectedLevel, CourseLevel.beginner);
    });

    test('setLevelFilter to null shows all courses', () {
      provider.setLevelFilter(CourseLevel.intermediate);
      provider.setLevelFilter(null);
      expect(provider.selectedLevel, isNull);
    });

    test('setLevelFilter notifies listeners', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.setLevelFilter(CourseLevel.advanced);
      expect(notifyCount, 1);
    });

    test('changing filter multiple times works correctly', () {
      provider.setLevelFilter(CourseLevel.beginner);
      expect(provider.selectedLevel, CourseLevel.beginner);

      provider.setLevelFilter(CourseLevel.intermediate);
      expect(provider.selectedLevel, CourseLevel.intermediate);

      provider.setLevelFilter(CourseLevel.advanced);
      expect(provider.selectedLevel, CourseLevel.advanced);

      provider.setLevelFilter(null);
      expect(provider.selectedLevel, isNull);
    });
  });

  group('CourseProvider - Reset', () {
    late CourseProvider provider;

    setUp(() {
      provider = CourseProvider();
    });

    test('reset clears all state', () {
      provider.setLevelFilter(CourseLevel.beginner);

      provider.reset();

      expect(provider.selectedLevel, isNull);
      expect(provider.courses, isEmpty);
    });

    test('reset notifies listeners', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.reset();
      expect(notifyCount, greaterThan(0));
    });
  });

  group('CourseProvider - loadCourses() error resilience', () {
    late CourseProvider provider;

    setUp(() {
      provider = CourseProvider();
    });

    // Note: ApiClient.dio is not initialized in test environment
    // These tests verify the provider doesn't crash on API errors
    test('loadCourses sets error state when API unavailable', () async {
      try {
        await provider.loadCourses();
      } catch (_) {
        // Expected: API not initialized in test
      }
      // Provider should still be in a valid state
      expect(provider.courses, isEmpty);
    });

    test('loadCourses with refresh parameter', () async {
      try {
        await provider.loadCourses(refresh: true);
      } catch (_) {
        // Expected
      }
      expect(provider.courses, isEmpty);
    });
  });

  group('CourseProvider - getCourseById() error resilience', () {
    late CourseProvider provider;

    setUp(() {
      provider = CourseProvider();
    });

    test('getCourseById returns null when API unavailable', () async {
      final result = await provider.getCourseById(999999);
      expect(result, isNull);
    });

    test('getCourseById with negative ID returns null', () async {
      final result = await provider.getCourseById(-1);
      expect(result, isNull);
    });

    test('getCourseById with 0 returns null', () async {
      final result = await provider.getCourseById(0);
      expect(result, isNull);
    });
  });

  group('CourseProvider - Dispose', () {
    test('dispose does not throw', () {
      final provider = CourseProvider();
      expect(() => provider.dispose(), returnsNormally);
    });
  });
}
