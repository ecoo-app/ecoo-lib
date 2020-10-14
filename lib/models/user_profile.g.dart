// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) {
  return UserProfile(
    json['uuid'] as String,
    json['wallet'] as String,
    json['first_name'] as String,
    json['last_name'] as String,
    json['address_street'] as String,
    json['address_town'] as String,
    json['address_postal_code'] as String,
    json['telephone_number'] as String,
    const DateOfBirthConverter().fromJson(json['date_of_birth'] as String),
    json['place_of_origin'] as String,
    _$enumDecodeNullable(
        _$VerificationStageEnumMap, json['verification_stage']),
  );
}

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('uuid', instance.uuid);
  val['wallet'] = instance.walletID;
  val['first_name'] = instance.firstName;
  val['last_name'] = instance.lastName;
  val['address_street'] = instance.addressStreet;
  val['address_town'] = instance.addressTown;
  val['address_postal_code'] = instance.addressPostalCode;
  val['telephone_number'] = instance.telephoneNumber;
  val['date_of_birth'] =
      const DateOfBirthConverter().toJson(instance.dateOfBirth);
  val['place_of_origin'] = instance.placeOfOrigin;
  writeNotNull('verification_stage',
      _$VerificationStageEnumMap[instance.verificationStage]);
  return val;
}

T _$enumDecode<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }

  final value = enumValues.entries
      .singleWhere((e) => e.value == source, orElse: () => null)
      ?.key;

  if (value == null && unknownValue == null) {
    throw ArgumentError('`$source` is not one of the supported values: '
        '${enumValues.values.join(', ')}');
  }
  return value ?? unknownValue;
}

T _$enumDecodeNullable<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<T>(enumValues, source, unknownValue: unknownValue);
}

const _$VerificationStageEnumMap = {
  VerificationStage.notMatched: 0,
  VerificationStage.pendingPIN: 1,
  VerificationStage.verified: 2,
  VerificationStage.maxClaimsReached: 3,
};
