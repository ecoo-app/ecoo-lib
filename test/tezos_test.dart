import 'package:ecoupon_lib/tezos/michelson.dart';
import 'package:ecoupon_lib/tezos/tezos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("KeyPair generation", () {
    final keyPair = Tezos.generateKeyPairFromMnemonic("opera deer same lab arrow kid jaguar cube start burger hub one fruit gentle little hard bridge course reveal provide test merry uncle sniff");
    expect(keyPair.edsk(), equals("edskReN1S6HNyQyrbq4UfqbwkGTg8KfadvuUBTqbyqtX4GCah6uLhMyd5ovK4BVpJV1NfP1gccAPWQn1BaokmfyiWruiSjziL6"));
    expect(keyPair.edpk(), equals("edpkuAJhbFLfJ4zWbQQWTZNGDg7hrcG1m1CBSWVB3iDHChjuzeaZB6"));
    final address = Tezos.getAddress(keyPair.publicKey);
    expect(address, equals("tz1d75oB6T4zUMexzkr5WscGktZ1Nss1JrT7"));
  });

  test("Random KeyPair generation", () {
    final entropy1 = Tezos.generateEntropy();
    expect(entropy1, isNotNull);
    final keyPair1 = Tezos.generateKeyPairFromEntropy(entropy1);
    final entropy2 = Tezos.generateEntropy();
    expect(entropy2, isNotNull);
    expect(entropy1, isNot(equals(entropy2)));
    final keyPair2 = Tezos.generateKeyPairFromEntropy(entropy2);
    expect(keyPair1.edsk(), isNot(equals(keyPair2.edsk())));
    expect(keyPair1.edpk(), isNot(equals(keyPair2.edpk())));
    final address1 = Tezos.getAddress(keyPair1.publicKey);
    final address2 = Tezos.getAddress(keyPair2.publicKey);
    expect(address1, isNot(equals(address2)));
  });

  test("KeyPair generation from private key", () {
    final keyPair1 = Tezos.generateKeyPairFromMnemonic("opera deer same lab arrow kid jaguar cube start burger hub one fruit gentle little hard bridge course reveal provide test merry uncle sniff");
    final keyPair2 = Tezos.generateKeyPairFromEncodedPrivateKey(keyPair1.edsk());
    expect(keyPair1.edpk(), equals(keyPair2.edpk()));
    expect(Tezos.getAddressFromEncodedPublicKey(keyPair1.edpk()), equals(Tezos.getAddressFromEncodedPublicKey(keyPair2.edpk())));
  });

  test("Get Key bytes from encoded", () {
    final keyPair = Tezos.generateKeyPairFromMnemonic("opera deer same lab arrow kid jaguar cube start burger hub one fruit gentle little hard bridge course reveal provide test merry uncle sniff");
    expect(Tezos.getKeyBytesFromEncoded(keyPair.edpk()), equals(keyPair.publicKey));
    expect(Tezos.getKeyBytesFromEncoded(keyPair.edsk()), equals(keyPair.privateKey));
  });

  test("Sign/Verify", () {
    final keyPair = Tezos.generateKeyPairFromMnemonic("opera deer same lab arrow kid jaguar cube start burger hub one fruit gentle little hard bridge course reveal provide test merry uncle sniff");
    final message = MichelsonPair(MichelsonKey(keyPair.edpk()), MichelsonPair(MichelsonInt(1), MichelsonList([MichelsonPair(MichelsonAddress("tz1Mj7RzPmMAqDUNFBn5t5VbXmWW4cSUAdtT"), MichelsonPair(MichelsonInt(0), MichelsonInt(100)))]))).pack();
    expect(message, equals("0507070a0000002100444e1f4ab90c304a5ac003d367747aab63815f583ff2330ce159d12c1ecceba107070001020000002407070a00000016000016e64994c2ddbd293695b63e4cade029d3c8b5e30707000000a401"));
    final signature = Tezos.sign(message, keyPair.privateKey);
    expect(signature, equals("edsigtyKGKbtWuuf2Pvqda2SvG9LPiE21gEhb4Vsxw6gEGnpKpYAMJXDHtmpWHRFNZYfMwzdMey4EBioNLHVsG83z3Fj9qzuibV"));
    expect(Tezos.verify(message, signature, keyPair.publicKey), true);
  });
}

