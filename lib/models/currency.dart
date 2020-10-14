import 'package:ecoupon_lib/models/wallet.dart';
import 'package:json_annotation/json_annotation.dart';

part 'currency.g.dart';

@JsonSerializable()
class Currency {

  final String uuid;
  
  final String name;
  
  final String symbol;
  
  @JsonKey(name: "token_id")
  final int tokenID;
  
  final int decimals;
  
  @JsonKey(name: "campaign_end")
  final DateTime campaignEnd;
  
  @JsonKey(name: "claim_deadline")
  final DateTime claimDeadline;
  
  @JsonKey(name: "allow_minting")
  final bool allowMinting;
  
  @JsonKey(name: "owner_wallet")
  final Wallet owner;
  
  @JsonKey(name: "starting_capital")
  final int startingCapital;

  Currency(this.uuid, this.name, this.symbol, this.tokenID, this.decimals, this.campaignEnd, this.claimDeadline, this.allowMinting, this.owner, this.startingCapital);

  factory Currency.fromJson(Map<String, dynamic> json) => _$CurrencyFromJson(json);
  Map<String, dynamic> toJson() => _$CurrencyToJson(this);
}
