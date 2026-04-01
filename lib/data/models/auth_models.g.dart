// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
  email: json['email'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{'email': instance.email, 'password': instance.password};

RegisterRequest _$RegisterRequestFromJson(Map<String, dynamic> json) =>
    RegisterRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      fullName: json['fullName'] as String,
      phoneNumber: json['phoneNumber'] as String?,
    );

Map<String, dynamic> _$RegisterRequestToJson(RegisterRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'fullName': instance.fullName,
      'phoneNumber': instance.phoneNumber,
    };

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
  accessToken: json['accessToken'] as String,
  refreshToken: json['refreshToken'] as String?,
  user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
  deviceSessionId: json['deviceSessionId'] as String?,
);

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'user': instance.user,
      'deviceSessionId': instance.deviceSessionId,
    };

UserDto _$UserDtoFromJson(Map<String, dynamic> json) => UserDto(
  id: (json['id'] as num).toInt(),
  email: json['email'] as String,
  fullName: json['fullName'] as String?,
  roles: (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$UserDtoToJson(UserDto instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'fullName': instance.fullName,
  'roles': instance.roles,
};

RefreshTokenRequest _$RefreshTokenRequestFromJson(Map<String, dynamic> json) =>
    RefreshTokenRequest(
      refreshToken: json['refreshToken'] as String,
      deviceSessionId: json['deviceSessionId'] as String?,
    );

Map<String, dynamic> _$RefreshTokenRequestToJson(
  RefreshTokenRequest instance,
) => <String, dynamic>{
  'refreshToken': instance.refreshToken,
  'deviceSessionId': instance.deviceSessionId,
};

VerifyEmailRequest _$VerifyEmailRequestFromJson(Map<String, dynamic> json) =>
    VerifyEmailRequest(
      email: json['email'] as String,
      otp: json['otp'] as String,
    );

Map<String, dynamic> _$VerifyEmailRequestToJson(VerifyEmailRequest instance) =>
    <String, dynamic>{'email': instance.email, 'otp': instance.otp};

ResendOtpRequest _$ResendOtpRequestFromJson(Map<String, dynamic> json) =>
    ResendOtpRequest(email: json['email'] as String);

Map<String, dynamic> _$ResendOtpRequestToJson(ResendOtpRequest instance) =>
    <String, dynamic>{'email': instance.email};

ApiErrorResponse _$ApiErrorResponseFromJson(Map<String, dynamic> json) =>
    ApiErrorResponse(
      message: json['message'] as String,
      code: json['code'] as String?,
      details: json['details'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ApiErrorResponseToJson(ApiErrorResponse instance) =>
    <String, dynamic>{
      'message': instance.message,
      'code': instance.code,
      'details': instance.details,
    };
