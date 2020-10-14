// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClientInfo _$ClientInfoFromJson(Map<String, dynamic> json) {
  return ClientInfo(
    json['name'] as String,
    json['client_id'] as String,
  );
}

Map<String, dynamic> _$ClientInfoToJson(ClientInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'client_id': instance.clientID,
    };
