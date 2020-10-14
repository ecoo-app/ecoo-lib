import 'package:ecoupon_lib/models/transaction.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cash_out.g.dart';

@JsonSerializable()
class CashOut {

  @JsonKey(name: "transaction", nullable: false)
  final String transactionUUID;
  
  @JsonKey(name: "beneficiary_name", nullable: false)
  final String beneficiaryName;
  
  @JsonKey(name: "beneficiary_iban", nullable: false)
  final String beneficiaryIBAN;
  
  @JsonKey(includeIfNull: false)
  final TransactionState state;
  
  @JsonKey(name: "created_at", includeIfNull: false)
  final DateTime created;

  CashOut(this.transactionUUID, this.beneficiaryName, this.beneficiaryIBAN, this.state, this.created);

  factory CashOut.fromJson(Map<String, dynamic> json) => _$CashOutFromJson(json);
  Map<String, dynamic> toJson() => _$CashOutToJson(this);
}
