import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:ecoupon_lib/services/crypto_service.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:bs58check/bs58check.dart' as bs58Check;

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

  Uint8List secret(String decryptionKey, String publicKey) {
    final crypto = CryptoService(decryptionKey);
    final privateKey = crypto.decrypt(this.privateKey, this.nonce);
    final edsk = String.fromCharCodes(privateKey.toList());
    final secretKey = bs58Check.decode(edsk).sublist(4);
    final pubKey = bs58Check.decode(publicKey).sublist(4);
    final secretKeyList = secretKey.toList();
    secretKeyList.addAll(pubKey);
    return Uint8List.fromList(secretKeyList);
  }

  factory PaperWallet.fromJson(Map<String, dynamic> json) => _$PaperWalletFromJson(json);
  Map<String, dynamic> toJson() => _$PaperWalletToJson(this);
}
