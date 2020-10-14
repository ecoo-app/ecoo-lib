import 'package:ecoupon_lib/models/wallet.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_wallet_request.g.dart';

@JsonSerializable()
class CreateWalletRequest {
  
  @JsonKey(name: "public_key", nullable: false)
  final String publicKey;

  @JsonKey(nullable: false)
  final String currency;
  
  @JsonKey(nullable: false)
  final WalletCategory category;

  CreateWalletRequest(this.publicKey, this.currency, this.category);

  factory CreateWalletRequest.fromJson(Map<String, dynamic> json) => _$CreateWalletRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateWalletRequestToJson(this);
}

