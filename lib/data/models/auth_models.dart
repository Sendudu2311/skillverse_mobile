import 'package:json_annotation/json_annotation.dart';

part 'auth_models.g.dart';

@JsonSerializable()
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class RegisterRequest {
  final String email;
  final String password;
  final String confirmPassword;
  final String fullName;
  final String? phoneNumber;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.confirmPassword,
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
  final String? deviceSessionId;

  AuthResponse({
    required this.accessToken,
    this.refreshToken,
    required this.user,
    this.deviceSessionId,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Kiểm tra nếu có trường 'result' (wrapped response)
    if (json.containsKey('result') && json['result'] != null) {
      final result = json['result'] as Map<String, dynamic>;
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
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;
  final String? primaryRole;
  final String? authProvider;
  @JsonKey(defaultValue: false)
  final bool googleLinked;
  @JsonKey(defaultValue: {})
  final Set<String>? roles;

  UserDto({
    required this.id,
    required this.email,
    this.fullName,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    this.primaryRole,
    this.authProvider,
    this.googleLinked = false,
    this.roles,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return _$UserDtoFromJson(json);
  }

  Map<String, dynamic> toJson() => _$UserDtoToJson(this);
}

/// Registration response matching backend's BaseRegistrationResponse.
/// Backend does NOT return tokens on registration — user must verify email first.
@JsonSerializable()
class UserRegistrationResponse {
  @JsonKey(defaultValue: false)
  final bool success;
  final String? message;
  final String? email;
  final int? userId;
  @JsonKey(defaultValue: true)
  final bool requiresVerification;
  final int? otpExpiryMinutes;
  final String? otpExpiryTime;
  final String? nextStep;

  UserRegistrationResponse({
    this.success = false,
    this.message,
    this.email,
    this.userId,
    this.requiresVerification = true,
    this.otpExpiryMinutes,
    this.otpExpiryTime,
    this.nextStep,
  });

  factory UserRegistrationResponse.fromJson(Map<String, dynamic> json) =>
      _$UserRegistrationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UserRegistrationResponseToJson(this);
}

@JsonSerializable()
class RefreshTokenRequest {
  final String refreshToken;
  final String? deviceSessionId;

  RefreshTokenRequest({required this.refreshToken, this.deviceSessionId});

  factory RefreshTokenRequest.fromJson(Map<String, dynamic> json) =>
      _$RefreshTokenRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RefreshTokenRequestToJson(this);
}

@JsonSerializable()
class VerifyEmailRequest {
  final String email;
  final String otp;

  VerifyEmailRequest({required this.email, required this.otp});

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

  ApiErrorResponse({required this.message, this.code, this.details});

  factory ApiErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ApiErrorResponseToJson(this);
}
