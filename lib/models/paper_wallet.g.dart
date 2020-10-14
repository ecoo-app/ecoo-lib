// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paper_wallet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaperWallet _$PaperWalletFromJson(Map<String, dynamic> json) {
  return PaperWallet(
    json['id'] as String,
    json['nonce'] as String,
    json['pk'] as String,
  );
}

Map<String, dynamic> _$PaperWalletToJson(PaperWallet instance) =>
    <String, dynamic>{
      'id': instance.walletID,
      'nonce': instance.nonce,
      'pk': instance.privateKey,
    };
