import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecoupon_lib/ecoupon_lib.dart';

void main() {
  const MethodChannel channel = MethodChannel('ecoupon_lib');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await EcouponLib.platformVersion, '42');
  });
}
