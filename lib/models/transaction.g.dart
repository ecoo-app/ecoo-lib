// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Transaction _$TransactionFromJson(Map<String, dynamic> json) {
  return Transaction(
    json['uuid'] as String,
    json['from_wallet'] as String,
    json['to_wallet'] as String,
    json['amount'] as int,
    _$enumDecodeNullable(_$TransactionStateEnumMap, json['state']),
    json['created_at'] == null
        ? null
        : DateTime.parse(json['created_at'] as String),
    json['tag'] as String,
    json['nonce'] as int,
    json['signature'] as String,
    json['operation_hash'] as String,
    json['notes'] as String,
  );
}

Map<String, dynamic> _$TransactionToJson(Transaction instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('uuid', instance.uuid);
  val['from_wallet'] = instance.from;
  val['to_wallet'] = instance.to;
  val['amount'] = instance.amount;
  writeNotNull('state', _$TransactionStateEnumMap[instance.state]);
  writeNotNull('created_at', instance.created?.toIso8601String());
  writeNotNull('tag', instance.tag);
  val['nonce'] = instance.nonce;
  val['signature'] = instance.signature;
  writeNotNull('operation_hash', instance.operationHash);
  writeNotNull('notes', instance.notes);
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
