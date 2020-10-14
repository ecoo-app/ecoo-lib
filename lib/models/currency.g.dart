// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'currency.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Currency _$CurrencyFromJson(Map<String, dynamic> json) {
  return Currency(
    json['uuid'] as String,
    json['name'] as String,
    json['symbol'] as String,
    json['token_id'] as int,
    json['decimals'] as int,
    json['campaign_end'] == null
        ? null
        : DateTime.parse(json['campaign_end'] as String),
    json['claim_deadline'] == null
        ? null
        : DateTime.parse(json['claim_deadline'] as String),
    json['allow_minting'] as bool,
    json['owner_wallet'] == null
        ? null
        : Wallet.fromJson(json['owner_wallet'] as Map<String, dynamic>),
    json['starting_capital'] as int,
  );
}

Map<String, dynamic> _$CurrencyToJson(Currency instance) => <String, dynamic>{
      'uuid': instance.uuid,
      'name': instance.name,
      'symbol': instance.symbol,
      'token_id': instance.tokenID,
      'decimals': instance.decimals,
      'campaign_end': instance.campaignEnd?.toIso8601String(),
      'claim_deadline': instance.claimDeadline?.toIso8601String(),
      'allow_minting': instance.allowMinting,
      'owner_wallet': instance.owner,
      'starting_capital': instance.startingCapital,
    };
