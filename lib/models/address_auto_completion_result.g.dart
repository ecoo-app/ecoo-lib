// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_auto_completion_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddressAutoCompletionResult _$AddressAutoCompletionResultFromJson(
    Map<String, dynamic> json) {
  return AddressAutoCompletionResult(
    json['address_street'] as String,
    json['address_town'] as String,
    json['address_postal_code'] as String,
  );
}

Map<String, dynamic> _$AddressAutoCompletionResultToJson(
        AddressAutoCompletionResult instance) =>
    <String, dynamic>{
      'address_street': instance.street,
      'address_town': instance.town,
      'address_postal_code': instance.postalCode,
    };
