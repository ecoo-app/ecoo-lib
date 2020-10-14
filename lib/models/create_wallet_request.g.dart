// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_wallet_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateWalletRequest _$CreateWalletRequestFromJson(Map<String, dynamic> json) {
  return CreateWalletRequest(
    json['public_key'] as String,
    json['currency'] as String,
    _$enumDecode(_$WalletCategoryEnumMap, json['category']),
  );
}

Map<String, dynamic> _$CreateWalletRequestToJson(
        CreateWalletRequest instance) =>
    <String, dynamic>{
      'public_key': instance.publicKey,
      'currency': instance.currency,
      'category': _$WalletCategoryEnumMap[instance.category],
    };

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

const _$WalletCategoryEnumMap = {
  WalletCategory.consumer: 0,
  WalletCategory.company: 1,
  WalletCategory.owner: 2,
};
