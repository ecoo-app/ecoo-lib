import 'package:json_annotation/json_annotation.dart';

part 'paper_wallet.g.dart';

@JsonSerializable()
class PaperWallet {

  @JsonKey(name: "id", nullable: false)
  final String walletID;
  
  @JsonKey(nullable: false)
  final String nonce;
  
  @JsonKey(name: "pk", nullable: false)
  final String privateKey;

  PaperWallet(this.walletID, this.nonce, this.privateKey);

  factory PaperWallet.fromJson(Map<String, dynamic> json) => _$PaperWalletFromJson(json);
  Map<String, dynamic> toJson() => _$PaperWalletToJson(this);
}
