import 'package:json_annotation/json_annotation.dart';

part 'client_info.g.dart';

@JsonSerializable()
class ClientInfo {
  
  final String name;
  @JsonKey(name: "client_id")
  final String clientID;

  ClientInfo(this.name, this.clientID);

  factory ClientInfo.fromJson(Map<String, dynamic> json) => _$ClientInfoFromJson(json);
  Map<String, dynamic> toJson() => _$ClientInfoToJson(this);
}
