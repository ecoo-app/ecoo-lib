// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_registration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceRegistration _$DeviceRegistrationFromJson(Map<String, dynamic> json) {
  return DeviceRegistration(
    json['id'] as int,
    json['name'] as String,
    json['registration_id'] as String,
    json['device_id'] as String,
    json['active'] as bool,
    json['date_created'] == null
        ? null
        : DateTime.parse(json['date_created'] as String),
    _$enumDecode(_$RegisterDeviceTypeEnumMap, json['type']),
  );
}

Map<String, dynamic> _$DeviceRegistrationToJson(DeviceRegistration instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  writeNotNull('name', instance.name);
  val['registration_id'] = instance.notificationToken;
  writeNotNull('device_id', instance.deviceID);
  writeNotNull('active', instance.active);
  writeNotNull('date_created', instance.created?.toIso8601String());
  val['type'] = _$RegisterDeviceTypeEnumMap[instance.type];
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

const _$RegisterDeviceTypeEnumMap = {
  RegisterDeviceType.web: 'web',
  RegisterDeviceType.ios: 'ios',
  RegisterDeviceType.android: 'android',
};
