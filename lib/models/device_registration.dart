import 'package:json_annotation/json_annotation.dart';

part 'device_registration.g.dart';

@JsonSerializable()
class DeviceRegistration {
  
  @JsonKey(includeIfNull: false)
  final int id;
  
  @JsonKey(includeIfNull: false)
  final String name;
  
  @JsonKey(name: "registration_id", nullable: false)
  final String notificationToken;
  
  @JsonKey(name: "device_id", includeIfNull: false)
  final String deviceID;
  
  @JsonKey(includeIfNull: false)
  final bool active;
  
  @JsonKey(name: "date_created", includeIfNull: false)
  final DateTime created;
  
  @JsonKey(nullable: false)
  final RegisterDeviceType type;

  DeviceRegistration(this.id, this.name, this.notificationToken, this.deviceID, this.active, this.created, this.type);

  factory DeviceRegistration.fromJson(Map<String, dynamic> json) => _$DeviceRegistrationFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceRegistrationToJson(this);
}

enum RegisterDeviceType {
  @JsonValue("web") web,
  @JsonValue("ios") ios,
  @JsonValue("android") android
}
