import 'package:ecoupon_lib/services/crypto_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("Ecryption/Decryption", () {
    final key = CryptoService.generateRadomKey(32);
    final nonce = CryptoService.generateRadomKey(24);
    final service = CryptoService(key);
    final message = "test message";
    final cypher = service.encrypt(message, nonce);
    expect(cypher, isNotNull);
    final plain = service.decrypt(cypher, nonce);
    expect(message, equals(String.fromCharCodes(plain.toList())));
  });
}