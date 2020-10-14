import 'currency.dart';
import 'package:json_annotation/json_annotation.dart';

part 'wallet.g.dart';

@JsonSerializable()
class Wallet {

  @JsonKey(name: "wallet_id", nullable: false)
  final String walletID;
  
  @JsonKey(name: "public_key", nullable: false)
  final String publicKey;
  
  @JsonKey(name: "currency_details")
  final Currency currency;
  
  @JsonKey(nullable: false)
  final WalletCategory category;
  
  @JsonKey(nullable: true)
  final int balance;
  
  @JsonKey(nullable: false)
  final WalletState state;

  @JsonKey(nullable: false)
  final int nonce;

  Wallet(this.walletID, this.publicKey, this.currency, this.category, this.balance, this.state, this.nonce);

  factory Wallet.fromJson(Map<String, dynamic> json) => _$WalletFromJson(json);
  Map<String, dynamic> toJson() => _$WalletToJson(this);
}

enum WalletCategory {
  @JsonValue(0) consumer,
  @JsonValue(1) company,
  @JsonValue(2) owner
}

enum WalletState {
  @JsonValue(0) unverified,
  @JsonValue(1) pending,
  @JsonValue(2) verified
}
