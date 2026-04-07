import 'package:flutter_test/flutter_test.dart';
import 'package:skillverse_mobile/data/models/course_models.dart';

void main() {
  // ============================================================
  // CourseStatus & CourseLevel Enums
  // ============================================================
  group('CourseStatus enum', () {
    test('values contain all expected statuses', () {
      expect(CourseStatus.values.length, 6);
      expect(CourseStatus.values, contains(CourseStatus.draft));
      expect(CourseStatus.values, contains(CourseStatus.pending));
      expect(CourseStatus.values, contains(CourseStatus.public));
      expect(CourseStatus.values, contains(CourseStatus.archived));
      expect(CourseStatus.values, contains(CourseStatus.rejected));
      expect(CourseStatus.values, contains(CourseStatus.suspended));
    });
  });

  group('CourseStatusExtension.fromString()', () {
    test('returns correct enum for valid strings', () {
      expect(CourseStatusExtension.fromString('PUBLIC'), CourseStatus.public);
      expect(CourseStatusExtension.fromString('DRAFT'), CourseStatus.draft);
      expect(CourseStatusExtension.fromString('PENDING'), CourseStatus.pending);
      expect(
        CourseStatusExtension.fromString('ARCHIVED'),
        CourseStatus.archived,
      );
    });

    test('is case-insensitive', () {
      expect(CourseStatusExtension.fromString('public'), CourseStatus.public);
      expect(CourseStatusExtension.fromString('Public'), CourseStatus.public);
    });

    test('returns null for null input', () {
      expect(CourseStatusExtension.fromString(null), isNull);
    });

    test('defaults to public for unknown value', () {
      expect(CourseStatusExtension.fromString('UNKNOWN'), CourseStatus.public);
    });
  });

  group('CourseLevel enum', () {
    test('values contain all expected levels', () {
      expect(CourseLevel.values.length, 3);
      expect(CourseLevel.values, contains(CourseLevel.beginner));
      expect(CourseLevel.values, contains(CourseLevel.intermediate));
      expect(CourseLevel.values, contains(CourseLevel.advanced));
    });
  });

  group('CourseLevelExtension.fromString()', () {
    test('returns correct enum for valid strings', () {
      expect(CourseLevelExtension.fromString('BEGINNER'), CourseLevel.beginner);
      expect(
        CourseLevelExtension.fromString('INTERMEDIATE'),
        CourseLevel.intermediate,
      );
      expect(CourseLevelExtension.fromString('ADVANCED'), CourseLevel.advanced);
    });

    test('returns null for null input', () {
      expect(CourseLevelExtension.fromString(null), isNull);
    });

    test('defaults to beginner for unknown value', () {
      expect(CourseLevelExtension.fromString('EXPERT'), CourseLevel.beginner);
    });
  });

  // ============================================================
  // AuthorDto Tests
  // ============================================================
  group('AuthorDto', () {
    test('fromJson() with all fields', () {
      final json = {
        'id': 1,
        'firstName': 'Nguyen',
        'lastName': 'Van A',
        'email': 'author@test.com',
        'fullName': 'Nguyen Van A',
        'roles': ['INSTRUCTOR'],
        'authProvider': 'LOCAL',
        'googleLinked': false,
      };
      final author = AuthorDto.fromJson(json);

      expect(author.id, 1);
      expect(author.firstName, 'Nguyen');
      expect(author.lastName, 'Van A');
      expect(author.email, 'author@test.com');
      expect(author.fullName, 'Nguyen Van A');
      expect(author.roles, ['INSTRUCTOR']);
      expect(author.authProvider, 'LOCAL');
      expect(author.googleLinked, false);
    });

    test('fromJson() with only required fields', () {
      final json = {'id': 2, 'email': 'min@test.com'};
      final author = AuthorDto.fromJson(json);

      expect(author.id, 2);
      expect(author.email, 'min@test.com');
      expect(author.firstName, isNull);
      expect(author.lastName, isNull);
      expect(author.fullName, isNull);
    });

    test('toJson() produces correct map', () {
      final author = AuthorDto(id: 1, email: 'a@b.com', fullName: 'Test');
      final json = author.toJson();

      expect(json['id'], 1);
      expect(json['email'], 'a@b.com');
      expect(json['fullName'], 'Test');
    });
  });

  // ============================================================
  // MediaDto Tests
  // ============================================================
  group('MediaDto', () {
    test('fromJson() with all fields', () {
      final json = {
        'id': 10,
        'url': 'https://cdn.example.com/thumbnail.jpg',
        'type': 'IMAGE',
        'fileName': 'thumbnail.jpg',
        'fileSize': 102400,
        'uploadedBy': 1,
        'uploadedByName': 'Admin',
        'uploadedAt': '2024-01-01T00:00:00',
      };
      final media = MediaDto.fromJson(json);

      expect(media.id, 10);
      expect(media.url, 'https://cdn.example.com/thumbnail.jpg');
      expect(media.type, 'IMAGE');
      expect(media.fileName, 'thumbnail.jpg');
      expect(media.fileSize, 102400);
    });

    test('fromJson() with only required fields', () {
      final json = {
        'id': 1,
        'url': 'https://test.com/f.png',
        'type': 'IMAGE',
        'fileName': 'f.png',
      };
      final media = MediaDto.fromJson(json);

      expect(media.id, 1);
      expect(media.fileSize, isNull);
      expect(media.uploadedBy, isNull);
    });
  });

  // ============================================================
  // CourseSummaryDto Tests
  // ============================================================
  group('CourseSummaryDto', () {
    Map<String, dynamic> fullCourseJson() => {
      'id': 1,
      'title': 'Flutter Development',
      'description': 'Learn Flutter from scratch',
      'shortDescription': 'Flutter basics',
      'level': 'BEGINNER',
      'status': 'PUBLIC',
      'author': {'id': 1, 'email': 'author@test.com'},
      'authorName': 'Mr. Author',
      'thumbnail': {
        'id': 1,
        'url': 'https://cdn.test.com/thumb.jpg',
        'type': 'IMAGE',
        'fileName': 'thumb.jpg',
      },
      'thumbnailUrl': 'https://cdn.test.com/thumb.jpg',
      'enrollmentCount': 150,
      'moduleCount': 5,
      'lessonCount': 25,
      'price': 99.99,
      'currency': 'VND',
      'rating': 4.5,
      'reviewCount': 30,
      'createdAt': '2024-01-01T00:00:00',
      'updatedAt': '2024-06-01T00:00:00',
    };

    test('fromJson() with full data', () {
      final course = CourseSummaryDto.fromJson(fullCourseJson());

      expect(course.id, 1);
      expect(course.title, 'Flutter Development');
      expect(course.level, CourseLevel.beginner);
      expect(course.status, CourseStatus.public);
      expect(course.enrollmentCount, 150);
      expect(course.moduleCount, 5);
      expect(course.price, 99.99);
      expect(course.rating, 4.5);
      expect(course.author.id, 1);
    });

    test('fromJson() with minimal data', () {
      final json = {
        'id': 2,
        'title': 'Minimal Course',
        'level': 'ADVANCED',
        'status': 'DRAFT',
        'author': {'id': 1, 'email': 'a@b.com'},
        'enrollmentCount': 0,
      };
      final course = CourseSummaryDto.fromJson(json);

      expect(course.id, 2);
      expect(course.title, 'Minimal Course');
      expect(course.level, CourseLevel.advanced);
      expect(course.status, CourseStatus.draft);
      expect(course.description, isNull);
      expect(course.thumbnail, isNull);
      expect(course.price, isNull);
    });

    test('toJson() includes all fields', () {
      final course = CourseSummaryDto.fromJson(fullCourseJson());
      final json = course.toJson();

      expect(json['id'], 1);
      expect(json['title'], 'Flutter Development');
      expect(json['enrollmentCount'], 150);
    });
  });

  // ============================================================
  // PageResponse Tests
  // ============================================================
  group('PageResponse', () {
    test('fromJson() parses pagination correctly', () {
      final json = {
        'items': [
          {
            'id': 1,
            'title': 'Course 1',
            'level': 'BEGINNER',
            'status': 'PUBLIC',
            'author': {'id': 1, 'email': 'a@b.com'},
            'enrollmentCount': 10,
          },
          {
            'id': 2,
            'title': 'Course 2',
            'level': 'ADVANCED',
            'status': 'PUBLIC',
            'author': {'id': 2, 'email': 'c@d.com'},
            'enrollmentCount': 5,
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
        json,
        (obj) => CourseSummaryDto.fromJson(obj as Map<String, dynamic>),
      );

      expect(page.content?.length, 2);
      expect(page.page, 0);
      expect(page.size, 10);
      expect(page.totalElements, 2);
      expect(page.totalPages, 1);
      expect(page.first, true);
      expect(page.last, true);
      expect(page.empty, false);
      expect(page.content![0].title, 'Course 1');
      expect(page.content![1].title, 'Course 2');
    });

    test('fromJson() with empty result', () {
      final json = {
        'items': [],
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

      expect(page.content, isEmpty);
      expect(page.empty, true);
      expect(page.totalElements, 0);
    });
  });

  // ============================================================
  // CourseDetailDto Tests
  // ============================================================
  group('CourseDetailDto', () {
    test('fromJson() creates instance with all fields', () {
      final json = {
        'id': 1,
        'title': 'Advanced Dart',
        'description': 'Deep dive into Dart',
        'level': 'ADVANCED',
        'status': 'PUBLIC',
        'author': {'id': 1, 'email': 'author@test.com'},
        'enrollmentCount': 42,
        'moduleCount': 8,
        'lessonCount': 40,
        'price': 199.0,
        'currency': 'VND',
      };
      final detail = CourseDetailDto.fromJson(json);

      expect(detail.id, 1);
      expect(detail.title, 'Advanced Dart');
      expect(detail.level, 'ADVANCED');
      expect(detail.enrollmentCount, 42);
      expect(detail.price, 199.0);
    });

    test('toJson() round-trip preserves required data', () {
      final json = {
        'id': 1,
        'title': 'Test',
        'description': 'Desc',
        'level': 'BEGINNER',
        'status': 'DRAFT',
        'author': {'id': 1, 'email': 'a@b.com'},
        'enrollmentCount': 0,
      };
      final detail = CourseDetailDto.fromJson(json);
      final result = detail.toJson();

      expect(result['id'], 1);
      expect(result['title'], 'Test');
    });
  });
}
