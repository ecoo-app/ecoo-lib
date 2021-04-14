import 'package:json_annotation/json_annotation.dart';

part 'transaction.g.dart';

@JsonSerializable()
class Transaction {
  
  @JsonKey(includeIfNull: false)
  final String uuid;

  @JsonKey(name: "from_wallet", nullable: false)
  final String from;

  @JsonKey(name: "to_wallet", nullable: false)
  final String to;

  @JsonKey(nullable: false)
  final int amount;
  
  @JsonKey(includeIfNull: false)
  final TransactionState state;
  
  @JsonKey(name: "created_at", includeIfNull: false)
  final DateTime created;
  
  @JsonKey(includeIfNull: false)
  final String tag;

  @JsonKey(nullable: false, includeIfNull: false)
  final int nonce;

  @JsonKey(nullable: false, includeIfNull: false)
  final String signature;

  @JsonKey(nullable: true, includeIfNull: false)
  final String operationHash;

  @JsonKey(nullable: true, includeIfNull: false)
  final String notes;

  Transaction(this.uuid, this.from, this.to, this.amount, this.state, this.created, this.tag, this.nonce, this.signature, this.operationHash, this.notes);

  factory Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);
  Map<String, dynamic> toJson() => _$TransactionToJson(this);
}

enum TransactionState {
  @JsonValue(1) open,
  @JsonValue(2) pending,
  @JsonValue(3) done,
  @JsonValue(4) failed
}
