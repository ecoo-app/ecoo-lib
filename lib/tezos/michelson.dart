import 'package:bs58check/bs58check.dart' as bs58Check;
import 'package:convert/convert.dart';
import 'package:ecoupon_lib/common/errors.dart';

abstract class MichelsonType {
  
  String toHex();

  String pack() {
    return "05" + toHex();
  }

  static String valueHexLength(String value, [int size = 4]) {
    final length = (value.length ~/ 2);
    var lengthHex = hex.encode([length]);
    final outputLength = size * 2;
    while (lengthHex.length < outputLength) {
      lengthHex = "00" + lengthHex;
    }
    return lengthHex;
  }
}

class MichelsonPair extends MichelsonType {

  static final String _hexType = "0707"; // 07 = prim 07 = Pair

  final MichelsonType first;
  final MichelsonType second;
  
  MichelsonPair(this.first, this.second);

  @override
  String toHex() {
    return _hexType + first.toHex() + second.toHex();
  }
}

class MichelsonInt extends MichelsonType {

  static final String _hexType = "00";

  final int value;

  MichelsonInt(this.value);

  @override
  String toHex() {
    return _hexType + _encoded();
  }

  String _encoded() {
    if (value == 0) {
      return "00";
    }

    final n = BigInt.from(value);
    final l = n.bitLength;
    List<int> arr = List<int>();
    var v = n;
    for (var i = 0; i < l; i += 7) {
      var byte = BigInt.zero;
      if (i == 0) {
        byte = v & BigInt.from(0x3f);
        v = v >> 6;
      } else {
        byte = v & BigInt.from(0x7f);
        v = v >> 7;
      }

      if (value < 0 && i == 0) {
        byte = byte | BigInt.from(0x40);
      }

      if (i + 7 < l) {
        byte = byte | BigInt.from(0x80);
      }
      arr.add(byte.toInt());
    }

    if (l % 7 == 0) {
      arr[arr.length - 1] = arr[arr.length - 1] | 0x80;
      arr.add(1);
    }

    return arr.map((e) => _intToHex(e)).join();
  }

  String _intToHex(int value) {
    var h = "0" + value.toRadixString(16);
    return h.substring(h.length - 2);
  }
}

class MichelsonNat extends MichelsonType {

  static final String _hexType = "00";

  final int value;

  MichelsonNat(this.value);

  @override
  String toHex() {
    return _hexType + _encoded();
  }

  String _encoded() {
    var hexValue = _twoByteHex(value);
    var encodedList = hex.decode(hexValue).asMap().entries.map((entry) => entry.key == 0 ? entry.value : entry.value ^ 0x80).toList().reversed.toList();
    return hex.encode(encodedList);
  }

  String _twoByteHex(int n) {
    if (n < 128) { 
      final result = "0" + n.toRadixString(16);
      return result.substring(result.length - 2);
    }
    
    var h = '';
    var r = BigInt.from(n);
    while (r > BigInt.from(0)) {
      var hex = ("0" + (r & BigInt.from(127)).toRadixString(16));
      h = hex.substring(hex.length - 2) + h;
      r = r >> 7;
    }
    return h;
  }
}

class MichelsonString extends MichelsonType {

  static final String _hexType = "01";

  final String value;

  MichelsonString(this.value);

  @override
  String toHex() {
    final encoded = hex.encode(value.codeUnits);
    var lengthHex = MichelsonType.valueHexLength(encoded);
    return _hexType + lengthHex + encoded;
  }
}

class MichelsonAddress extends MichelsonType {

  static final String _hexType = "0a";

  final String value;

  MichelsonAddress(this.value);

  @override
  String toHex() {
    final encoded = _encoded();
    var lengthHex = MichelsonType.valueHexLength(encoded);
    return _hexType + lengthHex + encoded;
  }

  String _encoded() {
    final hexValue = hex.encode(bs58Check.decode(value).sublist(3));
    final prefix = value.substring(0, 3).toLowerCase();
    switch (prefix) {
      case "tz1":
        return "0000" + hexValue;
      case "tz2":
        return "0001" + hexValue;
      case "tz3":
        return "0002" + hexValue;
      case "kt1":
        return "01" + hexValue + "00";
      default:
        throw UnsupportedTezosAddress();
    }
  }
}

class MichelsonKey extends MichelsonType {

  static final String _hexType = "0a";

  final String value;

  MichelsonKey(this.value);

  @override
  String toHex() {
    final encoded = _encoded();
    var lengthHex = MichelsonType.valueHexLength(encoded);
    return _hexType + lengthHex + encoded;
  }

  String _encoded() {
    final hexValue = hex.encode(bs58Check.decode(value).sublist(4));
    final prefix = value.substring(0, 4).toLowerCase();
    switch (prefix) {
      case "edpk":
        return "00" + hexValue;
      case "sppk":
        return "01" + hexValue;
      case "p2pk":
        return "02" + hexValue;
      default:
        throw UnsupportedKeyFormat();
    }
  }
}

class MichelsonList extends MichelsonType {

  static final String _hexType = "02";

  final List<MichelsonType> values;

  MichelsonList(this.values);

  @override
  String toHex() {
    final encoded = _encoded();
    var lengthHex = MichelsonType.valueHexLength(encoded);
    return _hexType + lengthHex + encoded;
  }

  String _encoded() {
    return this.values.map((e) => e.toHex()).join();
  }
}
