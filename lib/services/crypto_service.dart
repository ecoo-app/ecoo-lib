import 'dart:typed_data';

import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:convert/convert.dart';

class CryptoService {

  final Uint8List _key;

  CryptoService(String key): _key = Uint8List.fromList(hex.decode(key));

  String encrypt(String message, String hexNonce) {
    final nonce = Uint8List.fromList(hex.decode(hexNonce));
    final cypher = Sodium.cryptoAeadXchacha20poly1305IetfEncrypt(Uint8List.fromList(message.codeUnits), null, null, nonce, _key);
    return hex.encode(cypher.toList());
  }

  Uint8List decrypt(String hexMessage, String hexNonce) {
    final message = Uint8List.fromList(hex.decode(hexMessage));
    final nonce = Uint8List.fromList(hex.decode(hexNonce));
    return Sodium.cryptoAeadXchacha20poly1305IetfDecrypt(null, message, null, nonce, _key);
  }

  static String generateRadomKey(int size) {
    final bytes = Sodium.randombytesBuf(size);
    return hex.encode(bytes.toList());
  }
}