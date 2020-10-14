// import 'dart:async';
// import 'package:meta/meta.dart';
import 'dart:typed_data';
import 'dart:math';

import 'package:bip39/bip39.dart' as bip39;
import 'package:ecoupon_lib/common/errors.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:bs58check/bs58check.dart' as bs58Check;
import 'package:pointycastle/digests/sha512.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/api.dart';
import 'dart:convert';
import 'package:convert/convert.dart';

class TezosKeyPair {
  final Uint8List publicKey;
  final Uint8List privateKey;

  TezosKeyPair(this.publicKey, this.privateKey);

  String edpk() {
    final prefixed = [13, 15, 37, 217] + publicKey;
    return bs58Check.encode(Uint8List.fromList(prefixed));
  }

  String edsk() {
    final prefixed = [43, 246, 78, 7] + privateKey;
    return bs58Check.encode(Uint8List.fromList(prefixed));
  }
}

class _Key {
  List<int> value;
  List<int> chainCode;

  _Key(this.value, this.chainCode);
}

class Tezos {

  static const standardDerivationPath = "m/44'/1729'/0'/0'";

  static final _ed25519KeyParam = KeyParameter(utf8.encode('ed25519 seed'));
  static const int _hardenedOffset = 0x80000000;

  static final Uint8List _tz1Prefix = Uint8List.fromList(List<int>.from([6, 161, 159]));
  static final Uint8List _edsigPrefix = Uint8List.fromList(List<int>.from([9, 245, 205, 134, 18]));

  static String generateEntropy() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    final hash = Sodium.cryptoGenerichash(32, Uint8List.fromList(values), null);
    return hex.encode(hash);
  }
  
  static TezosKeyPair generateKeyPairFromEntropy(String entropy, [String derivationPath = Tezos.standardDerivationPath]) {
    final mnemonic = generateMnemonic(entropy);
    return generateKeyPairFromMnemonic(mnemonic, derivationPath);
  }

  static TezosKeyPair generateKeyPairFromMnemonic(String mnemonic, [String derivationPath = Tezos.standardDerivationPath]) {
    final seed = generateSeed(mnemonic);
    final derived = _derivePath(seed, derivationPath);
    final pair = Sodium.cryptoSignSeedKeypair(Uint8List.fromList(derived.value));
    return TezosKeyPair(pair.pk, pair.sk);
  }

  static TezosKeyPair generateKeyPairFromEncodedPrivateKey(String privateKey) {
    if (!privateKey.startsWith("edsk")) {
      throw InvalidSecretKey();
    }
    final decoded = bs58Check.decode(privateKey).sublist(4);
    final pair = generateKeyPairFromPrivateKey(decoded);
    return pair;
  }

  static TezosKeyPair generateKeyPairFromPrivateKey(Uint8List privateKey) {
    final seed = Sodium.cryptoSignEd25519SkToSeed(privateKey);
    final pair = Sodium.cryptoSignSeedKeypair(Uint8List.fromList(seed));
    return TezosKeyPair(pair.pk, pair.sk);
  }

  static String generateMnemonic(String entropy) {
    return bip39.entropyToMnemonic(entropy);
  }

  static Uint8List generateSeed(String mnemonic) {
    return bip39.mnemonicToSeed(mnemonic);
  }

  static String getAddress(Uint8List publicKey) {
    final payload = Sodium.cryptoGenerichash(20, publicKey, null);
    final prefixedPayload = _tz1Prefix + payload;
    return bs58Check.encode(Uint8List.fromList(prefixedPayload));
  }

  static String getAddressFromEncodedPublicKey(String publicKey) {
    if (!publicKey.startsWith("edpk")) {
      throw InvalidPublicKey();
    }
    final decoded = bs58Check.decode(publicKey).sublist(4);
    return getAddress(decoded);
  }

  static Uint8List getKeyBytesFromEncoded(String encodedKey) {
    final decoded = bs58Check.decode(encodedKey);
    return decoded.sublist(4);
  }

  static String sign(String message, Uint8List privateKey) {
    final hash = Sodium.cryptoGenerichash(32, Uint8List.fromList(hex.decode(message)), null);
    final signature = Sodium.cryptoSignDetached(hash, privateKey);
    return bs58Check.encode(Uint8List.fromList(_edsigPrefix + signature));
  }

  static bool verify(String message, String signature, Uint8List publicKey) {
    final decodedSignature = bs58Check.decode(signature).sublist(_edsigPrefix.length);
    final hash = Sodium.cryptoGenerichash(32, hex.decode(message), null);
    return Sodium.cryptoSignVerifyDetached(decodedSignature, hash, publicKey) == 0;
  }

  static _Key _derivePath(Uint8List seed, String path) {
    final master = _getKey(seed, _ed25519KeyParam);
    List<String> segments = path.split('/');
    segments = segments.sublist(1); 
    return segments.fold<_Key>(master, (prevKeyData, indexStr) {
      int index = int.parse(indexStr.substring(0, indexStr.length - 1));
      return _getCKDPriv(prevKeyData, index + _hardenedOffset);
    });
  }

  static _Key _getKey(Uint8List seed, KeyParameter param) {
    final digest = SHA512Digest();
    final hmac = HMac(digest, 128);
    hmac.init(param);
    final data = hmac.process(seed);
    return _Key(data.sublist(0, 32), data.sublist(32));
  }

  static _Key _getCKDPriv(_Key data, int index) {
    Uint8List dataBytes = Uint8List(37);
    dataBytes[0] = 0x00;
    dataBytes.setRange(1, 33, data.value);
    dataBytes.buffer.asByteData().setUint32(33, index);
    return _getKey(dataBytes, KeyParameter(data.chainCode));
  }
}
