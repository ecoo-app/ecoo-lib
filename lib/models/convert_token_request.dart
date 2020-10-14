import 'package:json_annotation/json_annotation.dart';

part 'convert_token_request.g.dart';

@JsonSerializable()
class ConvertTokenRequest {

  @JsonKey(name: "client_id")
  final String clientID;
  @JsonKey(name: "grant_type")
  final String grantType;
  final String token;
  final String backend;

  ConvertTokenRequest(this.clientID, this.grantType, this.token, this.backend);

  factory ConvertTokenRequest.fromJson(Map<String, dynamic> json) => _$ConvertTokenRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ConvertTokenRequestToJson(this);
}