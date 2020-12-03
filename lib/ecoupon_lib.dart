import 'dart:async';
import 'package:flutter/services.dart';

class EcouponLib {
  static const MethodChannel _channel =
      const MethodChannel('ecoupon_lib');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<void> store(String key, String value) async {
    return await _channel.invokeMethod('store', <String, String>{
        'key': key,
        'value': value,
    });
  }

  static Future<String> load(String key) async {
    return await _channel.invokeMethod('load', <String, String>{'key': key});
  }

  static Future<bool> isDeviceSecured() async {
    return await _channel.invokeMethod('isDeviceSecured');
  }
}
