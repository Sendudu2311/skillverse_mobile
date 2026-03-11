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
      'error for uppercase',
      () => expect(ValidationHelper.slug('Hello'), isNotNull),
    );
    test(
      'error for leading dash',
      () => expect(ValidationHelper.slug('-hello'), isNotNull),
    );
    test(
      'error for trailing dash',
      () => expect(ValidationHelper.slug('hello-'), isNotNull),
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
}
