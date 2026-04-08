import 'package:flutter_test/flutter_test.dart';
import 'package:skillverse_mobile/data/models/auth_models.dart';

void main() {
  // ============================================================
  // LoginRequest Tests
  // ============================================================
  group('LoginRequest', () {
    test('fromJson() creates instance with correct fields', () {
      final json = {'email': 'test@example.com', 'password': 'Pass123!'};
      final request = LoginRequest.fromJson(json);

      expect(request.email, 'test@example.com');
      expect(request.password, 'Pass123!');
    });

    test('toJson() returns correct map', () {
      final request = LoginRequest(email: 'a@b.com', password: 'secret');
      final json = request.toJson();

      expect(json['email'], 'a@b.com');
      expect(json['password'], 'secret');
    });

    test('fromJson → toJson round-trip preserves data', () {
      final original = {'email': 'user@test.com', 'password': 'MyP@ss1'};
      final result = LoginRequest.fromJson(original).toJson();

      expect(result, original);
    });
  });

  // ============================================================
  // RegisterRequest Tests
  // ============================================================
  group('RegisterRequest', () {
    test('fromJson() with all fields', () {
      final json = {
        'email': 'new@user.com',
        'password': 'Pass1234',
        'confirmPassword': 'Pass1234',
        'fullName': 'Nguyen Van A',
        'phoneNumber': '0901234567',
      };
      final request = RegisterRequest.fromJson(json);

      expect(request.email, 'new@user.com');
      expect(request.password, 'Pass1234');
      expect(request.fullName, 'Nguyen Van A');
      expect(request.phoneNumber, '0901234567');
    });

    test('fromJson() with phoneNumber null', () {
      final json = {
        'email': 'new@user.com',
        'password': 'Pass1234',
        'confirmPassword': 'Pass1234',
        'fullName': 'Nguyen Van A',
      };
      final request = RegisterRequest.fromJson(json);

      expect(request.phoneNumber, isNull);
    });

    test('toJson() includes all fields', () {
      final request = RegisterRequest(
        email: 'test@example.com',
        password: 'password',
        confirmPassword: 'password',
        fullName: 'Test User',
        phoneNumber: '0123456789',
      );
      final json = request.toJson();

      expect(json['email'], 'test@example.com');
      expect(json['fullName'], 'Test User');
      expect(json['phoneNumber'], '0123456789');
    });

    test('toJson() with null phoneNumber', () {
      final request = RegisterRequest(
        email: 'a@b.com',
        password: 'p',
        confirmPassword: 'p',
        fullName: 'Test',
      );
      final json = request.toJson();

      expect(json['phoneNumber'], isNull);
    });
  });

  // ============================================================
  // UserDto Tests
  // ============================================================
  group('UserDto', () {
    test('fromJson() with all fields', () {
      final json = {
        'id': 1,
        'email': 'admin@skillverse.vn',
        'fullName': 'Admin User',
        'roles': ['ADMIN', 'USER'],
      };
      final user = UserDto.fromJson(json);

      expect(user.id, 1);
      expect(user.email, 'admin@skillverse.vn');
      expect(user.fullName, 'Admin User');
      expect(user.roles, ['ADMIN', 'USER']);
    });

    test('fromJson() with optional fields null', () {
      final json = {'id': 2, 'email': 'basic@test.com'};
      final user = UserDto.fromJson(json);

      expect(user.id, 2);
      expect(user.fullName, isNull);
      expect(user.roles, isNull);
    });

    test('toJson() produces correct map', () {
      final user = UserDto(
        id: 5,
        email: 'x@y.com',
        fullName: 'Full Name',
        roles: ['USER'],
      );
      final json = user.toJson();

      expect(json['id'], 5);
      expect(json['email'], 'x@y.com');
      expect(json['fullName'], 'Full Name');
      expect(json['roles'], ['USER']);
    });
  });

  // ============================================================
  // AuthResponse Tests
  // ============================================================
  group('AuthResponse', () {
    test('fromJson() direct format (no wrapper)', () {
      final json = {
        'accessToken': 'eyJhbGciOiJIUzI1NiJ9.abc',
        'refreshToken': 'refresh_token_value',
        'user': {
          'id': 1,
          'email': 'test@test.com',
          'fullName': 'Test User',
          'roles': ['USER'],
        },
      };
      final response = AuthResponse.fromJson(json);

      expect(response.accessToken, 'eyJhbGciOiJIUzI1NiJ9.abc');
      expect(response.refreshToken, 'refresh_token_value');
      expect(response.user.id, 1);
      expect(response.user.email, 'test@test.com');
    });

    test('fromJson() wrapped in "result" key', () {
      final json = {
        'result': {
          'accessToken': 'wrapped_token',
          'refreshToken': null,
          'user': {'id': 2, 'email': 'wrapped@test.com'},
        },
      };
      final response = AuthResponse.fromJson(json);

      expect(response.accessToken, 'wrapped_token');
      expect(response.refreshToken, isNull);
      expect(response.user.id, 2);
    });

    test('toJson() includes all fields', () {
      final response = AuthResponse(
        accessToken: 'token123',
        refreshToken: 'refresh456',
        user: UserDto(id: 1, email: 'u@t.com'),
      );
      final json = response.toJson();

      expect(json['accessToken'], 'token123');
      expect(json['refreshToken'], 'refresh456');
      expect(json['user'], isNotNull);
    });
  });

  // ============================================================
  // RefreshTokenRequest Tests
  // ============================================================
  group('RefreshTokenRequest', () {
    test('fromJson() and toJson() round-trip', () {
      final json = {
        'refreshToken': 'my_refresh_token',
        'deviceSessionId': 'dev_123',
      };
      final request = RefreshTokenRequest.fromJson(json);

      expect(request.refreshToken, 'my_refresh_token');
      expect(request.deviceSessionId, 'dev_123');
      expect(request.toJson(), json);
    });
  });

  // ============================================================
  // VerifyEmailRequest Tests
  // ============================================================
  group('VerifyEmailRequest', () {
    test('fromJson() creates correct instance', () {
      final json = {'email': 'verify@test.com', 'otp': '123456'};
      final request = VerifyEmailRequest.fromJson(json);

      expect(request.email, 'verify@test.com');
      expect(request.otp, '123456');
    });

    test('toJson() returns correct map', () {
      final request = VerifyEmailRequest(email: 'a@b.com', otp: '000000');
      final json = request.toJson();

      expect(json['email'], 'a@b.com');
      expect(json['otp'], '000000');
    });
  });

  // ============================================================
  // ResendOtpRequest Tests
  // ============================================================
  group('ResendOtpRequest', () {
    test('fromJson() and toJson() round-trip', () {
      final original = {'email': 'resend@test.com'};
      final result = ResendOtpRequest.fromJson(original).toJson();

      expect(result, original);
    });
  });

  // ============================================================
  // ApiErrorResponse Tests
  // ============================================================
  group('ApiErrorResponse', () {
    test('fromJson() with all fields', () {
      final json = {
        'message': 'Something went wrong',
        'code': 'ERR_001',
        'details': {'field': 'email', 'reason': 'already taken'},
      };
      final error = ApiErrorResponse.fromJson(json);

      expect(error.message, 'Something went wrong');
      expect(error.code, 'ERR_001');
      expect(error.details?['field'], 'email');
    });

    test('fromJson() with only message', () {
      final json = {'message': 'Error occurred'};
      final error = ApiErrorResponse.fromJson(json);

      expect(error.message, 'Error occurred');
      expect(error.code, isNull);
      expect(error.details, isNull);
    });

    test('toJson() produces correct map', () {
      final error = ApiErrorResponse(
        message: 'Bad request',
        code: 'BAD_REQ',
        details: {'info': 'test'},
      );
      final json = error.toJson();

      expect(json['message'], 'Bad request');
      expect(json['code'], 'BAD_REQ');
      expect(json['details'], {'info': 'test'});
    });
  });
}
