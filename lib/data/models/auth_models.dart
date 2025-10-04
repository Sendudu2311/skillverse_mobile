import 'package:json_annotation/json_annotation.dart';

part 'auth_models.g.dart';

@JsonSerializable()
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class RegisterRequest {
  final String email;
  final String password;
  final String fullName;
  final String? phoneNumber;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.fullName,
    this.phoneNumber,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}

@JsonSerializable()
class AuthResponse {
  final String accessToken;
  final String? refreshToken;
  final UserDto user;

  AuthResponse({
    required this.accessToken,
    this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Debug: In ra để xem cấu trúc JSON
    print('AuthResponse.fromJson: $json');
    
    // Kiểm tra nếu có trường 'result' (wrapped response)
    if (json.containsKey('result') && json['result'] != null) {
      final result = json['result'] as Map<String, dynamic>;
      print('Using result: $result');
      return _$AuthResponseFromJson(result);
    }
    // Ngược lại, parse trực tiếp
    return _$AuthResponseFromJson(json);
  }

  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

@JsonSerializable()
class UserDto {
  final int id;
  final String email;
  final String? fullName;
  final List<String>? roles;

  UserDto({
    required this.id,
    required this.email,
    this.fullName,
    this.roles,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    print('UserDto.fromJson: $json');
    return _$UserDtoFromJson(json);
  }

  Map<String, dynamic> toJson() => _$UserDtoToJson(this);
}

@JsonSerializable()
class RefreshTokenRequest {
  final String refreshToken;

  RefreshTokenRequest({required this.refreshToken});

  factory RefreshTokenRequest.fromJson(Map<String, dynamic> json) =>
      _$RefreshTokenRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RefreshTokenRequestToJson(this);
}

@JsonSerializable()
class VerifyEmailRequest {
  final String email;
  final String otp;

  VerifyEmailRequest({
    required this.email,
    required this.otp,
  });

  factory VerifyEmailRequest.fromJson(Map<String, dynamic> json) =>
      _$VerifyEmailRequestFromJson(json);

  Map<String, dynamic> toJson() => _$VerifyEmailRequestToJson(this);
}

@JsonSerializable()
class ResendOtpRequest {
  final String email;

  ResendOtpRequest({required this.email});

  factory ResendOtpRequest.fromJson(Map<String, dynamic> json) =>
      _$ResendOtpRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ResendOtpRequestToJson(this);
}

@JsonSerializable()
class ApiErrorResponse {
  final String message;
  final String? code;
  final Map<String, dynamic>? details;

  ApiErrorResponse({
    required this.message,
    this.code,
    this.details,
  });

  factory ApiErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ApiErrorResponseToJson(this);
}