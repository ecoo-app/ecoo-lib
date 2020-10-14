// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionToken _$SessionTokenFromJson(Map<String, dynamic> json) {
  return SessionToken(
    json['access_token'] as String,
    json['refresh_token'] as String,
    json['expires_in'] as int,
    json['token_type'] as String,
    json['scope'] as String,
  );
}

Map<String, dynamic> _$SessionTokenToJson(SessionToken instance) =>
    <String, dynamic>{
      'access_token': instance.access,
      'refresh_token': instance.refresh,
      'expires_in': instance.expires,
      'token_type': instance.tokenType,
      'scope': instance.scope,
    };
