// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_migration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WalletMigration _$WalletMigrationFromJson(Map<String, dynamic> json) {
  return WalletMigration(
    json['wallet'] as String,
    json['old_public_key'] as String,
    json['new_public_key'] as String,
    _$enumDecodeNullable(_$TransactionStateEnumMap, json['state']),
    json['created_at'] == null
        ? null
        : DateTime.parse(json['created_at'] as String),
    json['submitted_to_chain_at'] == null
        ? null
        : DateTime.parse(json['submitted_to_chain_at'] as String),
    json['operation_hash'] as String,
  );
}

Map<String, dynamic> _$WalletMigrationToJson(WalletMigration instance) {
  final val = <String, dynamic>{
    'wallet': instance.walletID,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('old_public_key', instance.oldPublicKey);
  val['new_public_key'] = instance.newPublicKey;
  writeNotNull('state', _$TransactionStateEnumMap[instance.state]);
  writeNotNull('created_at', instance.created?.toIso8601String());
  writeNotNull(
      'submitted_to_chain_at', instance.submittedToChainAt?.toIso8601String());
  writeNotNull('operation_hash', instance.operationHash);
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

const _$TransactionStateEnumMap = {
  TransactionState.open: 1,
  TransactionState.pending: 2,
  TransactionState.done: 3,
  TransactionState.failed: 4,
};
