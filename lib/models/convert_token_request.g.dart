// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'convert_token_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConvertTokenRequest _$ConvertTokenRequestFromJson(Map<String, dynamic> json) {
  return ConvertTokenRequest(
    json['client_id'] as String,
    json['grant_type'] as String,
    json['token'] as String,
    json['backend'] as String,
  );
}

Map<String, dynamic> _$ConvertTokenRequestToJson(
        ConvertTokenRequest instance) =>
    <String, dynamic>{
      'client_id': instance.clientID,
      'grant_type': instance.grantType,
      'token': instance.token,
      'backend': instance.backend,
    };
