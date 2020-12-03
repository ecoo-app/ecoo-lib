import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

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

  factory PaperWallet.from({@required String walletID, @required String base64Nonce, @required String base64PrivateKey}) {
    final nonce = hex.encode(base64Decode(base64Nonce));
    final privateKey = hex.encode(base64Decode(base64PrivateKey));
    return PaperWallet(walletID, nonce, privateKey);
  }

  factory PaperWallet.fromDeepLink(Uri deepLink) {
    final walletID = deepLink.queryParameters["id"];
    final nonce = deepLink.queryParameters["nonce"];
    final pk = deepLink.queryParameters["pk"];
    return PaperWallet.from(walletID: walletID, base64Nonce: nonce, base64PrivateKey: pk);
  }

  factory PaperWallet.fromJson(Map<String, dynamic> json) => _$PaperWalletFromJson(json);
  Map<String, dynamic> toJson() => _$PaperWalletToJson(this);
}
