// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Wallet _$WalletFromJson(Map<String, dynamic> json) {
  return Wallet(
    json['wallet_id'] as String,
    json['public_key'] as String,
    json['currency_details'] == null
        ? null
        : Currency.fromJson(json['currency_details'] as Map<String, dynamic>),
    _$enumDecode(_$WalletCategoryEnumMap, json['category']),
    json['balance'] as int,
    _$enumDecode(_$WalletStateEnumMap, json['state']),
    json['nonce'] as int,
    json['can_be_used_for_verification'] as bool ?? false,
  );
}

Map<String, dynamic> _$WalletToJson(Wallet instance) => <String, dynamic>{
      'wallet_id': instance.walletID,
      'public_key': instance.publicKey,
      'currency_details': instance.currency,
      'category': _$WalletCategoryEnumMap[instance.category],
      'balance': instance.balance,
      'state': _$WalletStateEnumMap[instance.state],
      'nonce': instance.nonce,
      'can_be_used_for_verification': instance.canVerify,
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

const _$WalletStateEnumMap = {
  WalletState.unverified: 0,
  WalletState.pending: 1,
  WalletState.verified: 2,
};
