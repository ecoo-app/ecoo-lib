// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'company_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompanyProfile _$CompanyProfileFromJson(Map<String, dynamic> json) {
  return CompanyProfile(
    json['uuid'] as String,
    json['wallet'] as String,
    json['name'] as String,
    json['google_business_account'] as String,
    json['uid'] as String,
    json['address_street'] as String,
    json['address_town'] as String,
    json['address_postal_code'] as String,
    json['phone_number'] as String,
    _$enumDecodeNullable(
        _$VerificationStageEnumMap, json['verification_stage']),
  );
}

Map<String, dynamic> _$CompanyProfileToJson(CompanyProfile instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('uuid', instance.uuid);
  val['wallet'] = instance.walletID;
  val['name'] = instance.name;
  val['google_business_account'] = instance.googleBusinessAccount;
  val['uid'] = instance.uid;
  val['address_street'] = instance.addressStreet;
  val['address_town'] = instance.addressTown;
  val['address_postal_code'] = instance.addressPostalCode;
  val['phone_number'] = instance.telephoneNumber;
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
