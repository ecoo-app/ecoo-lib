import 'package:json_annotation/json_annotation.dart';

part 'session_token.g.dart';

@JsonSerializable()
class SessionToken {

  @JsonKey(name: "access_token")
  final String access;
  
  @JsonKey(name: "refresh_token")
  final String refresh;
  
  @JsonKey(name: "expires_in")
  final int expires;
  
  @JsonKey(name: "token_type")
  final String tokenType;
  
  final String scope;

  SessionToken(this.access, this.refresh, this.expires, this.tokenType, this.scope);

  factory SessionToken.fromJson(Map<String, dynamic> json) => _$SessionTokenFromJson(json);
  Map<String, dynamic> toJson() => _$SessionTokenToJson(this);
}