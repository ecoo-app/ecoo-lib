// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cash_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CashOut _$CashOutFromJson(Map<String, dynamic> json) {
  return CashOut(
    json['transaction'] as String,
    json['beneficiary_name'] as String,
    json['beneficiary_iban'] as String,
    _$enumDecodeNullable(_$TransactionStateEnumMap, json['state']),
    json['created_at'] == null
        ? null
        : DateTime.parse(json['created_at'] as String),
  );
}

Map<String, dynamic> _$CashOutToJson(CashOut instance) {
  final val = <String, dynamic>{
    'transaction': instance.transactionUUID,
    'beneficiary_name': instance.beneficiaryName,
    'beneficiary_iban': instance.beneficiaryIBAN,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('state', _$TransactionStateEnumMap[instance.state]);
  writeNotNull('created_at', instance.created?.toIso8601String());
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
