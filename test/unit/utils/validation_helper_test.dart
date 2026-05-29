import 'package:flutter_test/flutter_test.dart';
import 'package:skillverse_mobile/core/utils/validation_helper.dart';

void main() {
  group('ValidationHelper.required()', () {
    test(
      'returns error for null',
      () => expect(ValidationHelper.required(null), isNotNull),
    );
    test(
      'returns error for empty',
      () => expect(ValidationHelper.required(''), isNotNull),
    );
    test(
      'returns error for whitespace',
      () => expect(ValidationHelper.required('   '), isNotNull),
    );
    test(
      'returns null for valid',
      () => expect(ValidationHelper.required('Hello'), isNull),
    );
    test('uses custom field name', () {
      expect(
        ValidationHelper.required(null, fieldName: 'Email'),
        contains('Email'),
      );
    });
  });

  group('ValidationHelper.email()', () {
    test(
      'error for empty when required',
      () => expect(ValidationHelper.email(''), isNotNull),
    );
    test(
      'null for empty when optional',
      () => expect(ValidationHelper.email('', isRequired: false), isNull),
    );
    test('valid emails', () {
      expect(ValidationHelper.email('test@example.com'), isNull);
      expect(ValidationHelper.email('a+b@gmail.com'), isNull);
    });
    test('invalid emails', () {
      expect(ValidationHelper.email('not-an-email'), isNotNull);
      expect(ValidationHelper.email('user@'), isNotNull);
    });
  });

  group('ValidationHelper.password()', () {
    test(
      'error for empty',
      () => expect(ValidationHelper.password(''), isNotNull),
    );
    test(
      'null for empty when optional',
      () => expect(ValidationHelper.password('', isRequired: false), isNull),
    );
    test(
      'error for < 8 chars',
      () => expect(ValidationHelper.password('Ab1'), isNotNull),
    );
    test(
      'error for no uppercase',
      () => expect(ValidationHelper.password('alllower1'), isNotNull),
    );
    test(
      'error for no lowercase',
      () => expect(ValidationHelper.password('ALLUPPER1'), isNotNull),
    );
    test(
      'error for no digit',
      () => expect(ValidationHelper.password('NoDigitsHere'), isNotNull),
    );
    test(
      'valid password',
      () => expect(ValidationHelper.password('ValidPass1'), isNull),
    );
  });

  group('ValidationHelper.confirmPassword()', () {
    test(
      'error for empty',
      () => expect(ValidationHelper.confirmPassword('', 'pass'), isNotNull),
    );
    test(
      'error for mismatch',
      () => expect(ValidationHelper.confirmPassword('a', 'b'), isNotNull),
    );
    test(
      'null when match',
      () => expect(ValidationHelper.confirmPassword('Pass1', 'Pass1'), isNull),
    );
  });

  group('ValidationHelper.phoneNumber()', () {
    test(
      'null for empty optional',
      () => expect(ValidationHelper.phoneNumber(''), isNull),
    );
    test(
      'error for empty required',
      () =>
          expect(ValidationHelper.phoneNumber('', isRequired: true), isNotNull),
    );
    test(
      'valid VN number',
      () => expect(ValidationHelper.phoneNumber('0901234567'), isNull),
    );
    test(
      'invalid - no leading 0',
      () => expect(ValidationHelper.phoneNumber('1234567890'), isNotNull),
    );
    test(
      'invalid - too short',
      () => expect(ValidationHelper.phoneNumber('090123456'), isNotNull),
    );
  });

  group('ValidationHelper.url()', () {
    test(
      'null for empty optional',
      () => expect(ValidationHelper.url(''), isNull),
    );
    test('valid URLs', () {
      expect(ValidationHelper.url('https://example.com'), isNull);
      expect(ValidationHelper.url('http://www.test.com'), isNull);
    });
    test('invalid URLs', () {
      expect(ValidationHelper.url('not-a-url'), isNotNull);
      expect(ValidationHelper.url('ftp://invalid.com'), isNotNull);
    });
  });

  group('ValidationHelper.slug()', () {
    test('valid slugs', () {
      expect(ValidationHelper.slug('hello-world'), isNull);
      expect(ValidationHelper.slug('flutter-101'), isNull);
    });
    test(
      'null for uppercase (auto-lowercased by implementation)',
      () => expect(ValidationHelper.slug('Hello'), isNull),
    );
    test(
      'error for leading dash',
      () => expect(ValidationHelper.slug('-hello'), isNotNull),
    );
    test(
      'error for double dash',
      () => expect(ValidationHelper.slug('hello--world'), isNotNull),
    );
  });

  group('ValidationHelper.minLength()', () {
    test(
      'error for null',
      () => expect(ValidationHelper.minLength(null, 5), isNotNull),
    );
    test(
      'error for too short',
      () => expect(ValidationHelper.minLength('abc', 5), isNotNull),
    );
    test(
      'null for long enough',
      () => expect(ValidationHelper.minLength('abcde', 5), isNull),
    );
  });

  group('ValidationHelper.maxLength()', () {
    test(
      'null for null',
      () => expect(ValidationHelper.maxLength(null, 5), isNull),
    );
    test(
      'error for too long',
      () => expect(ValidationHelper.maxLength('abcdef', 5), isNotNull),
    );
    test(
      'null within limit',
      () => expect(ValidationHelper.maxLength('abc', 5), isNull),
    );
  });

  group('ValidationHelper.lengthRange()', () {
    test(
      'error for null',
      () => expect(ValidationHelper.lengthRange(null, 2, 10), isNotNull),
    );
    test(
      'error too short',
      () => expect(ValidationHelper.lengthRange('a', 2, 10), isNotNull),
    );
    test(
      'error too long',
      () => expect(ValidationHelper.lengthRange('a' * 11, 2, 10), isNotNull),
    );
    test(
      'null within range',
      () => expect(ValidationHelper.lengthRange('hello', 2, 10), isNull),
    );
  });

  group('ValidationHelper.numeric()', () {
    test(
      'valid number',
      () => expect(ValidationHelper.numeric('12345'), isNull),
    );
    test(
      'error for letters',
      () => expect(ValidationHelper.numeric('abc'), isNotNull),
    );
    test(
      'error for decimal',
      () => expect(ValidationHelper.numeric('12.5'), isNotNull),
    );
  });

  group('ValidationHelper.decimal()', () {
    test(
      'valid decimal',
      () => expect(ValidationHelper.decimal('12.5'), isNull),
    );
    test(
      'valid integer',
      () => expect(ValidationHelper.decimal('100'), isNull),
    );
    test(
      'error for letters',
      () => expect(ValidationHelper.decimal('abc'), isNotNull),
    );
  });

  group('ValidationHelper.numberRange()', () {
    test(
      'error for non-numeric',
      () => expect(ValidationHelper.numberRange('abc', 0, 100), isNotNull),
    );
    test(
      'error below min',
      () => expect(ValidationHelper.numberRange('-1', 0, 100), isNotNull),
    );
    test(
      'error above max',
      () => expect(ValidationHelper.numberRange('101', 0, 100), isNotNull),
    );
    test(
      'null in range',
      () => expect(ValidationHelper.numberRange('50', 0, 100), isNull),
    );
  });

  group('ValidationHelper.dateFormat()', () {
    test(
      'valid date',
      () => expect(ValidationHelper.dateFormat('2024-01-15'), isNull),
    );
    test(
      'invalid format',
      () => expect(ValidationHelper.dateFormat('15-01-2024'), isNotNull),
    );
    test(
      'null for empty',
      () => expect(ValidationHelper.dateFormat(null), isNull),
    );
  });

  group('ValidationHelper.dateRange()', () {
    test('null when end after start', () {
      expect(
        ValidationHelper.dateRange(DateTime(2024, 1, 1), DateTime(2024, 6, 1)),
        isNull,
      );
    });
    test('error when end before start', () {
      expect(
        ValidationHelper.dateRange(DateTime(2024, 6, 1), DateTime(2024, 1, 1)),
        isNotNull,
      );
    });
    test('null when either is null', () {
      expect(ValidationHelper.dateRange(null, DateTime.now()), isNull);
    });
  });

  group('ValidationHelper.githubUsername()', () {
    test(
      'valid',
      () => expect(ValidationHelper.githubUsername('octocat'), isNull),
    );
    test(
      'invalid with underscore',
      () => expect(ValidationHelper.githubUsername('user_name'), isNotNull),
    );
  });

  group('ValidationHelper.githubRepoUrl()', () {
    test(
      'valid',
      () => expect(
        ValidationHelper.githubRepoUrl('https://github.com/user/repo'),
        isNull,
      ),
    );
    test(
      'invalid domain',
      () => expect(
        ValidationHelper.githubRepoUrl('https://gitlab.com/u/r'),
        isNotNull,
      ),
    );
  });

  group('ValidationHelper.linkedInUrl()', () {
    test(
      'valid',
      () => expect(
        ValidationHelper.linkedInUrl('https://linkedin.com/in/user'),
        isNull,
      ),
    );
    test(
      'invalid',
      () => expect(
        ValidationHelper.linkedInUrl('https://linkedin.com/user'),
        isNotNull,
      ),
    );
  });

  group('ValidationHelper.twitterUsername()', () {
    test(
      'valid',
      () => expect(ValidationHelper.twitterUsername('user_name'), isNull),
    );
    test(
      'valid with @',
      () => expect(ValidationHelper.twitterUsername('@user'), isNull),
    );
    test(
      'error too long',
      () => expect(
        ValidationHelper.twitterUsername('this_is_way_too_long_name'),
        isNotNull,
      ),
    );
  });

  group('ValidationHelper.combine()', () {
    test('null when all pass', () {
      final v = ValidationHelper.combine([
        (v) => ValidationHelper.required(v),
        (v) => ValidationHelper.minLength(v, 3),
      ]);
      expect(v('hello'), isNull);
    });
    test('returns first error', () {
      final v = ValidationHelper.combine([
        (v) => ValidationHelper.required(v),
        (v) => ValidationHelper.minLength(v, 10),
      ]);
      expect(v('hi'), isNotNull);
    });
  });

  group('ValidationHelper.withFieldName()', () {
    test('passes field name', () {
      final v = ValidationHelper.withFieldName(
        ValidationHelper.required,
        'Username',
      );
      expect(v(''), contains('Username'));
    });
  });

  // ============================================================
  // TASK 6 — BỔ SUNG CÁC TEST THIẾU
  // ============================================================

  group('ValidationHelper.httpsUrl()', () {
    test('null cho chuỗi rỗng khi optional', () {
      expect(ValidationHelper.httpsUrl(''), isNull);
    });

    test('error cho chuỗi rỗng khi required', () {
      expect(ValidationHelper.httpsUrl('', isRequired: true), isNotNull);
    });

    test('null cho HTTPS URL hợp lệ', () {
      expect(ValidationHelper.httpsUrl('https://example.com'), isNull);
    });

    test('null cho HTTPS URL với path', () {
      expect(
        ValidationHelper.httpsUrl('https://example.com/path/to/page'),
        isNull,
      );
    });

    test('error cho HTTP URL (không phải HTTPS)', () {
      final result = ValidationHelper.httpsUrl('http://example.com');
      expect(result, isNotNull);
      expect(result, contains('HTTPS'));
    });

    test('error cho URL không có scheme', () {
      expect(ValidationHelper.httpsUrl('example.com'), isNotNull);
    });

    test('error cho URL không hợp lệ hoàn toàn', () {
      expect(ValidationHelper.httpsUrl('not a url at all'), isNotNull);
    });

    test('null cho HTTPS URL với query parameters', () {
      expect(
        ValidationHelper.httpsUrl('https://example.com?q=hello&page=1'),
        isNull,
      );
    });

    test('null cho HTTPS URL với subdomain', () {
      expect(ValidationHelper.httpsUrl('https://www.example.com'), isNull);
    });
  });

  group('ValidationHelper.githubUrl()', () {
    test('null cho chuỗi rỗng khi optional', () {
      expect(ValidationHelper.githubUrl(''), isNull);
    });

    test('error cho chuỗi rỗng khi required', () {
      expect(ValidationHelper.githubUrl('', isRequired: true), isNotNull);
    });

    test('null cho GitHub URL hợp lệ', () {
      expect(
        ValidationHelper.githubUrl('https://github.com/user/repo'),
        isNull,
      );
    });

    test('null cho GitHub URL profile', () {
      expect(
        ValidationHelper.githubUrl('https://github.com/username'),
        isNull,
      );
    });

    test('error cho domain khác (gitlab)', () {
      final result = ValidationHelper.githubUrl('https://gitlab.com/user/repo');
      expect(result, isNotNull);
      expect(result, contains('github.com'));
    });

    test('error cho domain khác (bitbucket)', () {
      expect(
        ValidationHelper.githubUrl('https://bitbucket.org/user/repo'),
        isNotNull,
      );
    });

    test('error cho HTTP thay vì HTTPS', () {
      final result =
          ValidationHelper.githubUrl('http://github.com/user/repo');
      expect(result, isNotNull);
      expect(result, contains('HTTPS'));
    });

    test('null cho GitHub URL với www', () {
      expect(
        ValidationHelper.githubUrl('https://www.github.com/user'),
        isNull,
      );
    });
  });

  group('ValidationHelper.behanceUrl()', () {
    test('null cho chuỗi rỗng khi optional', () {
      expect(ValidationHelper.behanceUrl(''), isNull);
    });

    test('error cho chuỗi rỗng khi required', () {
      expect(ValidationHelper.behanceUrl('', isRequired: true), isNotNull);
    });

    test('null cho Behance URL hợp lệ', () {
      expect(
        ValidationHelper.behanceUrl('https://www.behance.net/username'),
        isNull,
      );
    });

    test('null cho Behance URL không có www', () {
      expect(
        ValidationHelper.behanceUrl('https://behance.net/username'),
        isNull,
      );
    });

    test('error cho domain khác', () {
      final result =
          ValidationHelper.behanceUrl('https://dribbble.com/username');
      expect(result, isNotNull);
      expect(result, contains('behance.net'));
    });

    test('error cho HTTP thay vì HTTPS', () {
      final result =
          ValidationHelper.behanceUrl('http://behance.net/username');
      expect(result, isNotNull);
      expect(result, contains('HTTPS'));
    });
  });

  group('ValidationHelper.dribbbleUrl()', () {
    test('null cho chuỗi rỗng khi optional', () {
      expect(ValidationHelper.dribbbleUrl(''), isNull);
    });

    test('error cho chuỗi rỗng khi required', () {
      expect(ValidationHelper.dribbbleUrl('', isRequired: true), isNotNull);
    });

    test('null cho Dribbble URL hợp lệ', () {
      expect(
        ValidationHelper.dribbbleUrl('https://dribbble.com/username'),
        isNull,
      );
    });

    test('null cho Dribbble URL với www', () {
      expect(
        ValidationHelper.dribbbleUrl('https://www.dribbble.com/username'),
        isNull,
      );
    });

    test('error cho domain khác', () {
      final result =
          ValidationHelper.dribbbleUrl('https://behance.net/username');
      expect(result, isNotNull);
      expect(result, contains('dribbble.com'));
    });

    test('error cho HTTP thay vì HTTPS', () {
      final result =
          ValidationHelper.dribbbleUrl('http://dribbble.com/username');
      expect(result, isNotNull);
      expect(result, contains('HTTPS'));
    });
  });

  group('ValidationHelper.slug() — bổ sung reserved words & edge cases', () {
    test('error cho reserved word: create', () {
      final result = ValidationHelper.slug('create');
      expect(result, isNotNull);
      expect(result, contains('dự trữ'));
    });

    test('error cho reserved word: api', () {
      final result = ValidationHelper.slug('api');
      expect(result, isNotNull);
      expect(result, contains('dự trữ'));
    });

    test('error cho reserved word: admin', () {
      final result = ValidationHelper.slug('admin');
      expect(result, isNotNull);
      expect(result, contains('dự trữ'));
    });

    test('error cho reserved word: www', () {
      final result = ValidationHelper.slug('www');
      expect(result, isNotNull);
      expect(result, contains('dự trữ'));
    });

    test('error cho reserved word: portfolio', () {
      final result = ValidationHelper.slug('portfolio');
      expect(result, isNotNull);
      expect(result, contains('dự trữ'));
    });

    test('error cho slug quá dài (> 60 ký tự)', () {
      final longSlug = 'a' * 61;
      final result = ValidationHelper.slug(longSlug);
      expect(result, isNotNull);
      expect(result, contains('60'));
    });

    test('null cho slug đúng 60 ký tự', () {
      final slug60 = 'a' * 60;
      expect(ValidationHelper.slug(slug60), isNull);
    });

    test('error cho slug chỉ chứa số và dấu gạch ngang', () {
      final result = ValidationHelper.slug('123-456');
      expect(result, isNotNull);
      expect(result, contains('số'));
    });

    test('error cho slug chỉ chứa số', () {
      final result = ValidationHelper.slug('12345');
      expect(result, isNotNull);
    });

    test('error cho slug kết thúc bằng dấu gạch ngang', () {
      expect(ValidationHelper.slug('hello-'), isNotNull);
    });

    test('error cho slug quá ngắn (< 3 ký tự)', () {
      expect(ValidationHelper.slug('ab'), isNotNull);
    });

    test('null cho slug 3 ký tự hợp lệ', () {
      expect(ValidationHelper.slug('abc'), isNull);
    });

    test('error cho slug chứa ký tự đặc biệt', () {
      expect(ValidationHelper.slug('hello@world'), isNotNull);
    });

    test('null cho chuỗi rỗng khi optional', () {
      expect(ValidationHelper.slug(''), isNull);
    });

    test('error cho chuỗi rỗng khi required', () {
      expect(ValidationHelper.slug('', isRequired: true), isNotNull);
    });
  });

  group('ValidationHelper.phoneNumber() — bổ sung +84 prefix', () {
    test('valid cho +84 prefix', () {
      expect(ValidationHelper.phoneNumber('+84912345678'), isNull);
    });

    test('valid cho +84 prefix với đầu 3', () {
      expect(ValidationHelper.phoneNumber('+84312345678'), isNull);
    });

    test('valid cho +84 prefix với đầu 9', () {
      expect(ValidationHelper.phoneNumber('+84912345678'), isNull);
    });

    test('error cho +84 prefix sai đầu số (đầu 1)', () {
      expect(ValidationHelper.phoneNumber('+84112345678'), isNotNull);
    });

    test('error cho +84 prefix thiếu số', () {
      expect(ValidationHelper.phoneNumber('+849123456'), isNotNull);
    });

    test('error cho prefix +85 (không phải Việt Nam)', () {
      expect(ValidationHelper.phoneNumber('+85912345678'), isNotNull);
    });

    test('valid cho số bắt đầu bằng 0 với đầu 7', () {
      expect(ValidationHelper.phoneNumber('0712345678'), isNull);
    });
  });
}
