import 'package:ecoupon_lib/models/transaction.dart';
import 'package:json_annotation/json_annotation.dart';

part 'wallet_migration.g.dart';

@JsonSerializable()
class WalletMigration {

  @JsonKey(name: "wallet", nullable: false)
  final String walletID;
  
  @JsonKey(name: "old_public_key", includeIfNull: false)
  final String oldPublicKey;
  
  @JsonKey(name: "new_public_key", nullable: false)
  final String newPublicKey;
  
  @JsonKey(includeIfNull: false)
  final TransactionState state;
  
  @JsonKey(name: "created_at", includeIfNull: false)
  final DateTime created;
  
  @JsonKey(name: "submitted_to_chain_at", includeIfNull: false)
  final DateTime submittedToChainAt;
  
  @JsonKey(name: "operation_hash", includeIfNull: false)
  final String operationHash;

  WalletMigration(this.walletID, this.oldPublicKey, this.newPublicKey, this.state, this.created, this.submittedToChainAt, this.operationHash);

  factory WalletMigration.fromJson(Map<String, dynamic> json) => _$WalletMigrationFromJson(json);
  Map<String, dynamic> toJson() => _$WalletMigrationToJson(this);
}
