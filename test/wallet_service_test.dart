import 'dart:convert';
import 'dart:io';

import 'package:ecoupon_lib/common/errors.dart';
import 'package:ecoupon_lib/common/verification_stage.dart';
import 'package:ecoupon_lib/ecoupon_lib.dart';
import 'package:ecoupon_lib/models/cash_out.dart';
import 'package:ecoupon_lib/models/company_profile.dart';
import 'package:ecoupon_lib/models/currency.dart';
import 'package:ecoupon_lib/models/device_registration.dart';
import 'package:ecoupon_lib/models/paper_wallet.dart';
import 'package:ecoupon_lib/models/transaction.dart';
import 'package:ecoupon_lib/models/user_profile.dart';
import 'package:ecoupon_lib/models/wallet.dart';
import 'package:ecoupon_lib/models/wallet_migration.dart';
import 'package:ecoupon_lib/services/crypto_service.dart';
import 'package:ecoupon_lib/services/wallet_service.dart';
import 'package:ecoupon_lib/tezos/tezos.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:convert/convert.dart';

class MockClient extends Mock implements http.Client {}

const baseURL = 'https://ecoupon-backend.tech';

String _url(String path) {
  return "$baseURL$path";
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel('ecoupon_lib');
  final storage = Map<String, String>();

  final ownerWallet = Wallet("OW123456", "publicKey", null, WalletCategory.owner, 100000, WalletState.verified, 0);
  final currency = Currency("testUUID-aaaaaa", "Cash", "\$", 0, 2, DateTime(2021), DateTime(2021), true, ownerWallet, 50);
  Wallet consumerWallet;
  Wallet companyWallet;

  Future<Wallet> _createWallet(walletID, {WalletCategory category = WalletCategory.consumer, WalletState state = WalletState.unverified, String publicKey}) async {
    String edpk;
    if (publicKey == null) {
      final entropy = Tezos.generateEntropy();
      await EcouponLib.store(walletID, entropy);
      final keyPair = Tezos.generateKeyPairFromEntropy(entropy);
      edpk = keyPair.edpk();
    } else {
      edpk = publicKey;
    }
    return Wallet(walletID, edpk, currency, category, 50, state, 0);
  }

  setUp(() async {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'store':
          storage[methodCall.arguments["key"]] = methodCall.arguments["value"];
          return null;
        case 'load':
          return storage[methodCall.arguments["key"]];
        default:
          throw Error();
      }
    });

    consumerWallet = await _createWallet("RS123456");
    companyWallet = await _createWallet("CP123456", category: WalletCategory.company);
  });

  test("Create consumer wallet Success", () async {
    final client = MockClient();

    when(client.get(_url("/api/currency/currency/list/?page_size=10"), headers: anyNamed("headers"))).thenAnswer((_) async => http.Response(jsonEncode({"next": null, "prev": null, "results": [currency.toJson()]}), 200, headers: {HttpHeaders.contentTypeHeader: "application/json"}));
    when(client.post(_url("/api/wallet/wallet/"), headers: anyNamed("headers"), body: anyNamed("body"))).thenAnswer((invocation) async {
      final Map<String, dynamic> body = jsonDecode(invocation.namedArguments[Symbol("body")]);
      return http.Response(
        jsonEncode((
          await _createWallet(
            "CR123456", 
            category: body["category"] == 0 ? WalletCategory.consumer : WalletCategory.company,
            state: WalletState.unverified,
            publicKey: body["public_key"]
          )).toJson()), 
        200, 
        headers: {HttpHeaders.contentTypeHeader: "application/json"}
      );
    });
    
    final service = WalletService(baseURL, client);
    final currencies = (await service.fetchCurrencies()).items;
    expect(currencies.length, equals(1));
    expect(currencies.first.toJson().toString(), equals(currency.toJson().toString()));

    final createdWallet = await service.createWallet(currencies.first);
    expect(createdWallet, isA<Wallet>());
    expect(createdWallet.category, equals(WalletCategory.consumer));
    expect(createdWallet.state, equals(WalletState.unverified));
    expect(await service.canSignWithWallet(createdWallet), equals(true));
  });

  test("Create company wallet Success", () async {
    final client = MockClient();

    when(client.get(_url("/api/currency/currency/list/?page_size=10"), headers: anyNamed("headers"))).thenAnswer((_) async => http.Response(jsonEncode({"next": null, "prev": null, "results": [currency.toJson()]}), 200, headers: {HttpHeaders.contentTypeHeader: "application/json"}));
    when(client.post(_url("/api/wallet/wallet/"), headers: anyNamed("headers"), body: anyNamed("body"))).thenAnswer((invocation) async {
      final Map<String, dynamic> body = jsonDecode(invocation.namedArguments[Symbol("body")]);
      return http.Response(
        jsonEncode((
          await _createWallet(
            "CC123456", 
            category: body["category"] == 1 ? WalletCategory.company : WalletCategory.consumer,
            state: WalletState.unverified,
            publicKey: body["public_key"]
          )).toJson()), 
        200, 
        headers: {HttpHeaders.contentTypeHeader: "application/json"}
      );
    });
    
    final service = WalletService(baseURL, client);
    final currencies = (await service.fetchCurrencies()).items;
    expect(currencies.length, equals(1));
    expect(currencies.first.toJson().toString(), equals(currency.toJson().toString()));
    
    final createdWallet = await service.createWallet(currencies.first, isCompany: true);
    expect(createdWallet, isA<Wallet>());
    expect(createdWallet.category, equals(WalletCategory.company));
    expect(await service.canSignWithWallet(createdWallet), equals(true));
  });

  test("Create wallet Failure", () async {
    final client = MockClient();

    when(client.get(_url("/api/currency/currency/list/?page_size=10"), headers: anyNamed("headers"))).thenAnswer((_) async => http.Response(jsonEncode({"next": null, "prev": null, "results": [currency.toJson(), currency.toJson()]}), 200, headers: {HttpHeaders.contentTypeHeader: "application/json"}));
    when(client.post(_url("/api/wallet/wallet/"), headers: anyNamed("headers"), body: anyNamed("body"))).thenAnswer((_) async => http.Response(jsonEncode({"details": ["invalid token"]}), 401, headers: {HttpHeaders.contentTypeHeader: "application/json"}));
    final service = WalletService(baseURL, client);
    final currencies = (await service.fetchCurrencies()).items;
    expect(currencies.length, equals(2));
    expect(currencies.first.toJson().toString(), equals(currency.toJson().toString()));
    try {
      await service.createWallet(currencies.first);
      fail("createWallet is expected to fail");
    } catch (e) {
      expect(e, isInstanceOf<NotAuthenticatedError>());
    }
  });

  test("Cannot sign with wallet", () async {
    final service = WalletService(baseURL);
    expect(await service.canSignWithWallet(ownerWallet), equals(false));
  });

  test("Migrate Wallet", () async {
    final client = MockClient();
    when(client.post(_url("/api/wallet/wallet_public_key_transfer_request/"), headers: anyNamed("headers"), body: anyNamed("body"))).thenAnswer((invocation) async {
      final Map<String, dynamic> body = jsonDecode(invocation.namedArguments[Symbol("body")]);
      final migration = WalletMigration(body["wallet"], consumerWallet.publicKey, body["new_public_key"], TransactionState.open, DateTime.now(), null, null);
      return http.Response(jsonEncode(migration.toJson()), 200, headers: {HttpHeaders.contentTypeHeader: "application/json"});
    });

    final service = WalletService(baseURL, client);
    final migration2 = await service.migrateWallet(consumerWallet);
    expect(migration2, isA<WalletMigration>());
    expect(migration2.state, equals(TransactionState.open));
    expect(migration2.newPublicKey, isNot(equals(consumerWallet.publicKey)));
    expect(await service.canSignWithWallet(consumerWallet), equals(false));
  });

  test("Fetch Wallet Migrations", () async {
    final client = MockClient();
    final migration = WalletMigration(consumerWallet.walletID, consumerWallet.publicKey, "edpkvVxzNEm44VHE2YcsJAgqWbv7VLJAXQWvoFcpgmDdsGEhkedJAv", TransactionState.open, DateTime.now(), null, null);
    when(client.get(_url("/api/wallet/wallet_public_key_transfer_request/?page_size=10"), headers: anyNamed("headers"))).thenAnswer((_) async => http.Response(jsonEncode({"next": null, "prev": null, "results": [migration.toJson(), migration.toJson()]}), 200, headers: {HttpHeaders.contentTypeHeader: "application/json"}));

    final service = WalletService(baseURL, client);
    final migrations = await service.fetchWalletMigrations();

    expect(migrations.items.length, equals(2));
    expect(migrations.items.first.toJson().toString(), equals(migration.toJson().toString()));
  });

  test("Test Transfer success", () async {
    final client = MockClient();
    final service = WalletService(baseURL, client);
    
    when(client.get(_url("/api/wallet/wallet/${consumerWallet.walletID}/"), headers: anyNamed("headers"))).thenAnswer((realInvocation) async => http.Response('{"nonce": 0}', 200, headers: {HttpHeaders.contentTypeHeader: "application/json"}));
    when(client.post(_url("/api/wallet/meta_transaction/"), headers: anyNamed("headers"), body: anyNamed("body"))).thenAnswer((invocation) async {
      final Map<String, dynamic> body = jsonDecode(invocation.namedArguments[Symbol("body")]);
      final signature = body["signature"];
      final fromPK = Tezos.generateKeyPairFromEntropy(await EcouponLib.load(body["from_wallet"])).edpk();
      final toAddress = Tezos.getAddressFromEncodedPublicKey(Tezos.generateKeyPairFromEntropy(await EcouponLib.load(body["to_wallet"])).edpk());
      final verified = service.verifyTransfer(fromPK, toAddress, body["amount"], body["nonce"], currency.tokenID, signature, Tezos.getKeyBytesFromEncoded(fromPK));
      if (verified) {
        return http.Response(
          jsonEncode(Transaction("asdasdasda", body["from_wallet"], body["to_wallet"], body["amount"], TransactionState.open, DateTime.now(), "", body["nonce"], signature, null).toJson()), 
          200, 
          headers: {HttpHeaders.contentTypeHeader: "application/json"}
        );
      } else {
        return http.Response('{"details": "invalid signature"}', 400, headers: {HttpHeaders.contentTypeHeader: "application/json"});
      }
    });

    final transaction = await service.transfer(consumerWallet, companyWallet, 1);
    expect(transaction, isA<Transaction>());
    expect(transaction.from, equals(consumerWallet.walletID));
    expect(transaction.to, equals(companyWallet.walletID));
    expect(transaction.amount, equals(1));
    expect(transaction.signature, isNotNull);
    expect(transaction.state, equals(TransactionState.open));
  });

  test("Test Transfer fail", () async {
    final client = MockClient();
    final service = WalletService(baseURL, client);
    
    when(client.get(_url("/api/wallet/wallet/${consumerWallet.walletID}/"), headers: anyNamed("headers"))).thenAnswer((realInvocation) async => http.Response('{"nonce": 0}', 200, headers: {HttpHeaders.contentTypeHeader: "application/json"}));
    when(client.post(_url("/api/wallet/meta_transaction/"), headers: anyNamed("headers"), body: anyNamed("body"))).thenAnswer((invocation) async {
      final Map<String, dynamic> body = jsonDecode(invocation.namedArguments[Symbol("body")]);
      final signature = body["signature"];
      final fromPK = Tezos.generateKeyPairFromEntropy(await EcouponLib.load(body["from_wallet"])).edpk();
      final toAddress = Tezos.getAddressFromEncodedPublicKey(Tezos.generateKeyPairFromEntropy(await EcouponLib.load(body["to_wallet"])).edpk());
      final verified = service.verifyTransfer(fromPK, toAddress, body["amount"], body["nonce"] + 1, currency.tokenID, signature, Tezos.getKeyBytesFromEncoded(fromPK));
      if (verified) {
        return http.Response(
          jsonEncode(Transaction("asdasdasda", body["from_wallet"], body["to_wallet"], body["amount"], TransactionState.open, DateTime.now(), "", body["nonce"], signature, null).toJson()), 
          200, 
          headers: {HttpHeaders.contentTypeHeader: "application/json"}
        );
      } else {
        return http.Response('{"details": "invalid signature"}', 400, headers: {HttpHeaders.contentTypeHeader: "application/json"});
      }
    });

    try {
      await service.transfer(consumerWallet, companyWallet, 1);
      fail("transfer is supposed to fail");
    } catch (e) {
      expect(e, isInstanceOf<HTTPError>());
      expect((e as HTTPError).statusCode, equals(400));
    }
  });

  test("Test Paper Transfer success", () async {
    final client = MockClient();
    final service = WalletService(baseURL, client);

    final encKey = CryptoService.generateRadomKey(32);
    final cryptoService = CryptoService(encKey);
    final keyPair = Tezos.generateKeyPairFromEntropy(Tezos.generateEntropy());
    final nonce = CryptoService.generateRadomKey(24);
    
    final paperWallet = PaperWallet("AB123456", nonce, cryptoService.encrypt(keyPair.edsk(true), nonce));
    
    when(client.get(_url("/api/wallet/wallet/${paperWallet.walletID}/"), headers: anyNamed("headers"))).thenAnswer((realInvocation) async => http.Response('{"wallet_id": "${paperWallet.walletID}", "nonce": 0, "public_key": "${keyPair.edpk()}", "category": 0, "state": 2}', 200, headers: {HttpHeaders.contentTypeHeader: "application/json"}));
    when(client.post(_url("/api/wallet/meta_transaction/"), headers: anyNamed("headers"), body: anyNamed("body"))).thenAnswer((invocation) async {
      final Map<String, dynamic> body = jsonDecode(invocation.namedArguments[Symbol("body")]);
      final signature = body["signature"];
      final fromPK = keyPair.edpk();
      final toAddress = Tezos.getAddressFromEncodedPublicKey(Tezos.generateKeyPairFromEntropy(await EcouponLib.load(body["to_wallet"])).edpk());
      final verified = service.verifyTransfer(fromPK, toAddress, body["amount"], body["nonce"], currency.tokenID, signature, Tezos.getKeyBytesFromEncoded(fromPK));
      if (verified) {
        return http.Response(
          jsonEncode(Transaction("asdasdasda", body["from_wallet"], body["to_wallet"], body["amount"], TransactionState.open, DateTime.now(), "", body["nonce"], signature, null).toJson()), 
          200, 
          headers: {HttpHeaders.contentTypeHeader: "application/json"}
        );
      } else {
        return http.Response('{"details": "invalid signature"}', 400, headers: {HttpHeaders.contentTypeHeader: "application/json"});
      }
    });

    final transaction = await service.paperTransfer(paperWallet, companyWallet, 1, encKey);
    expect(transaction, isA<Transaction>());
    expect(transaction.from, equals(paperWallet.walletID));
    expect(transaction.to, equals(companyWallet.walletID));
    expect(transaction.amount, equals(1));
    expect(transaction.signature, isNotNull);
    expect(transaction.state, equals(TransactionState.open));
  });

  test("Test Paper Transfer 2 success", () async {  
    final client = MockClient();
    final service = WalletService(baseURL, client);

    final encKey = CryptoService.generateRadomKey(32);
    final cryptoService = CryptoService(encKey);
    final keyPair = Tezos.generateKeyPairFromEntropy(Tezos.generateEntropy());
    final nonce = CryptoService.generateRadomKey(24);
    final deepLink = Uri.https("app.ecoo.ch", "/deeplink/v1/wallet", {
      "id": "AB123456",
      "nonce": base64Encode(hex.decode(nonce)),
      "pk": base64Encode(hex.decode(cryptoService.encrypt(keyPair.edsk(true), nonce)))
    });
    
    final paperWallet = PaperWallet.fromDeepLink(deepLink);
    
    when(client.get(_url("/api/wallet/wallet/${paperWallet.walletID}/"), headers: anyNamed("headers"))).thenAnswer((realInvocation) async => http.Response('{"wallet_id": "${paperWallet.walletID}", "nonce": 0, "public_key": "${keyPair.edpk()}", "category": 0, "state": 2}', 200, headers: {HttpHeaders.contentTypeHeader: "application/json"}));
    when(client.post(_url("/api/wallet/meta_transaction/"), headers: anyNamed("headers"), body: anyNamed("body"))).thenAnswer((invocation) async {
      final Map<String, dynamic> body = jsonDecode(invocation.namedArguments[Symbol("body")]);
      final signature = body["signature"];
      final fromPK = keyPair.edpk();
      final toAddress = Tezos.getAddressFromEncodedPublicKey(Tezos.generateKeyPairFromEntropy(await EcouponLib.load(body["to_wallet"])).edpk());
      final verified = service.verifyTransfer(fromPK, toAddress, body["amount"], body["nonce"], currency.tokenID, signature, Tezos.getKeyBytesFromEncoded(fromPK));
      if (verified) {
        return http.Response(
          jsonEncode(Transaction("asdasdasda", body["from_wallet"], body["to_wallet"], body["amount"], TransactionState.open, DateTime.now(), "", body["nonce"], signature, null).toJson()), 
          200, 
          headers: {HttpHeaders.contentTypeHeader: "application/json"}
        );
      } else {
        return http.Response('{"details": "invalid signature"}', 400, headers: {HttpHeaders.contentTypeHeader: "application/json"});
      }
    });
    
    final transaction = await service.paperTransfer(paperWallet, companyWallet, 1, encKey);
    expect(transaction, isA<Transaction>());
    expect(transaction.from, equals(paperWallet.walletID));
    expect(transaction.to, equals(companyWallet.walletID));
    expect(transaction.amount, equals(1));
    expect(transaction.signature, isNotNull);
    expect(transaction.state, equals(TransactionState.open));
  });

  test("Fetch Wallets", () async {
    final client = MockClient();
    final service = WalletService(baseURL, client);

    when(client.get(_url("/api/wallet/wallet/?page_size=10"), headers: anyNamed("headers"))).thenAnswer((_) async => http.Response(jsonEncode({"next": null, "prev": null, "results": [consumerWallet.toJson(), companyWallet.toJson()]}), 200, headers: {HttpHeaders.contentTypeHeader: "application/json"}));

    final wallets = await service.fetchWallets();
    expect(wallets.items.length, equals(2));
    expect(wallets.items.first.walletID, equals(consumerWallet.walletID));
    expect(wallets.items.last.walletID, equals(companyWallet.walletID));
    expect(wallets.cursor.next, isNull);
  });

  test("Fetch User Profiles", () async {
    final client = MockClient();
    final service = WalletService(baseURL, client);

    final date1 = DateTime.parse("1970-01-01");
    final date2 = DateTime.parse("2010-11-12");

    when(client.get(_url("/api/profiles/user_profiles/?page_size=10"), headers: anyNamed("headers"))).thenAnswer((_) async {
      final profile1 = UserProfile("jdiosadj", consumerWallet.walletID, "First", "Name", "Test Street 1", "Wetzikon", "8620", "+41791234567", date1, "Locarno", VerificationStage.pendingPIN);
      final profile2 = UserProfile("jaassasd", consumerWallet.walletID, "First", "Name", "Test Street 1", "Wetzikon", "8620", "+41791234567", date2, "Locarno", VerificationStage.pendingPIN);
      return http.Response(jsonEncode({"next": null, "prev": null, "results": [profile1.toJson(), profile2.toJson()]}), 200, headers: {HttpHeaders.contentTypeHeader: "application/json"});
    });

    final result = await service.fetchUserProfiles();
    expect(result.items.length, equals(2));
    expect(result.items.first.walletID, equals(consumerWallet.walletID));
    expect(result.items.first.verificationStage, equals(VerificationStage.pendingPIN));
    expect(result.items.first.dateOfBirth, equals(date1));
    expect(result.items.last.dateOfBirth, equals(date2));
    expect(result.cursor.next, isNull);
  });

  test("Create User Profiles", () async {
    final client = MockClient();
    final service = WalletService(baseURL, client);

    when(client.post(_url("/api/profiles/user_profiles/"), headers: anyNamed("headers"), body: anyNamed("body"))).thenAnswer((invocation) async {
      final Map<String, dynamic> body = jsonDecode(invocation.namedArguments[Symbol("body")]);
      return http.Response(jsonEncode(UserProfile("asdasjiodas", body["wallet"], body["first_name"], body["last_name"], body["address_street"], body["address_town"], body["address_postal_code"], body["telephone_number"], DateTime.parse(body["date_of_birth"]), body["place_of_origin"], VerificationStage.pendingPIN).toJson()), 200, headers: {HttpHeaders.contentTypeHeader: "application/json"});
    });

    final date = DateTime.parse("1970-01-01");
    final result = await service.createUserProfile(consumerWallet, "First", "Name", "+41791234567", date, "Test Street 1", "Locarno", "6600", "Locarno");
    expect(result.walletID, equals(consumerWallet.walletID));
    expect(result.dateOfBirth, equals(date));
    expect(result.verificationStage, equals(VerificationStage.pendingPIN));
  });

  test("Fetch Company Profiles", () async {
    final client = MockClient();
    final service = WalletService(baseURL, client);

    when(client.get(_url("/api/profiles/company_profiles/?page_size=10"), headers: anyNamed("headers"))).thenAnswer((_) async {
      final profile1 = CompanyProfile("dkaoijdsa", companyWallet.walletID, "Example AG", "12-3-4-5", "Test Street 1", "Wetzikon", "8620", "+41 91 123 45 67", VerificationStage.pendingPIN);
      final profile2 = CompanyProfile("dkfdsijdsa", companyWallet.walletID, "Example AG", "12-3-4-5", "Test Street 1", "Wetzikon", "8620", "+41 91 123 45 67", VerificationStage.pendingPIN);
      return http.Response(jsonEncode({"next": null, "prev": null, "results": [profile1.toJson(), profile2.toJson()]}), 200, headers: {HttpHeaders.contentTypeHeader: "application/json"});
    });

    final result = await service.fetchCompanyProfiles();
    expect(result.items.length, equals(2));
    expect(result.items.first.walletID, equals(companyWallet.walletID));
    expect(result.items.first.verificationStage, equals(VerificationStage.pendingPIN));
    expect(result.cursor.next, isNull);
  });

  test("Create Company Profiles", () async {
    final client = MockClient();
    final service = WalletService(baseURL, client);

    when(client.post(_url("/api/profiles/company_profiles/"), headers: anyNamed("headers"), body: anyNamed("body"))).thenAnswer((invocation) async {
      final Map<String, dynamic> body = jsonDecode(invocation.namedArguments[Symbol("body")]);
      return http.Response(jsonEncode(CompanyProfile("asdasjiodas", body["wallet"], body["name"], body["uid"], body["address_street"], body["address_town"], body["address_postal_code"], body["telephone_number"], VerificationStage.pendingPIN).toJson()), 200, headers: {HttpHeaders.contentTypeHeader: "application/json"});
    });

    final result = await service.createCompanyProfile(companyWallet, "Example AG", "12-3-4-5", "Test Street 1", "Locarno", "6600", "+41 91 123 45 67");
    expect(result.walletID, equals(companyWallet.walletID));
    expect(result.verificationStage, equals(VerificationStage.pendingPIN));
    expect(result.addressTown, equals("Locarno"));
    expect(result.addressPostalCode, equals("6600"));
  });

  test("Fetch Transactions", () async {
    final client = MockClient();
    final service = WalletService(baseURL, client);

    when(client.get(_url("/api/wallet/transaction/?search=${consumerWallet.walletID}&page_size=10"), headers: anyNamed("headers"))).thenAnswer((_) async {
      final transaction1 = Transaction("sdasadas", consumerWallet.walletID, companyWallet.walletID, 1, TransactionState.open, DateTime.now(), "", null, null, null);
      final transaction2 = Transaction("sdasadas", companyWallet.walletID, consumerWallet.walletID, 10, TransactionState.open, DateTime.now(), "", null, null, "oodGpFWJu9M5sBB1P7i7DL45awS6sNiuLJVJZzwwUFwVp43MPV3");
      return http.Response(jsonEncode({"next": null, "prev": null, "results": [transaction1.toJson(), transaction2.toJson()]}), 200, headers: {HttpHeaders.contentTypeHeader: "application/json"});
    });

    final result = await service.fetchTransactions(walletID: consumerWallet.walletID);
    expect(result.items.length, equals(2));
    expect(result.items.first.from, equals(consumerWallet.walletID));
    expect(result.items.first.to, equals(companyWallet.walletID));
    expect(result.items.first.amount, equals(1));
    expect(result.items.last.from, equals(companyWallet.walletID));
    expect(result.items.last.to, equals(consumerWallet.walletID));
    expect(result.items.last.amount, equals(10));
    expect(result.items.first.state, equals(TransactionState.open));
    expect(result.cursor.next, isNull);
  });

  test("Register Device", () async {
    final client = MockClient();
    final service = WalletService(baseURL, client);

    final type = RegisterDeviceType.ios;

    when(client.post(_url("/api/devices/"), headers: anyNamed("headers"), body: anyNamed("body"))).thenAnswer((invocation) async {
      final Map<String, dynamic> body = jsonDecode(invocation.namedArguments[Symbol("body")]);
      return http.Response(jsonEncode(DeviceRegistration(1, body["name"], body["registration_id"], body["device_id"], body["active"], DateTime.now(), type).toJson()), 200, headers: {HttpHeaders.contentTypeHeader: "application/json"});
    });

    final result = await service.registerDevice("testtoken1", name: "Test", deviceID: "asdloapsd");
    expect(result.active, isNull);
    expect(result.name, equals("Test"));
    expect(result.notificationToken, equals("testtoken1"));
    expect(result.deviceID, equals("asdloapsd"));
    expect(result.created, isNotNull);
  });

  test("Create Cash Out", () async {
    final client = MockClient();
    final service = WalletService(baseURL, client);

    final transaction = Transaction("sdasadas", consumerWallet.walletID, companyWallet.walletID, 1, TransactionState.open, DateTime.now(), "", 1, "adssada", null);

    when(client.post(_url("/api/wallet/cash_out_request/"), headers: anyNamed("headers"), body: anyNamed("body"))).thenAnswer((invocation) async {
      final Map<String, dynamic> body = jsonDecode(invocation.namedArguments[Symbol("body")]);
      return http.Response(jsonEncode(CashOut(body["transaction"], body["beneficiary_name"], body["beneficiary_iban"], TransactionState.open, DateTime.now()).toJson()), 200, headers: {HttpHeaders.contentTypeHeader: "application/json"});
    });

    final result = await service.cashOut(transaction, "Example AG", "CH12 3456 7890 1234 5678 0");
    expect(result.transactionUUID, equals(transaction.uuid));
    expect(result.beneficiaryName, equals("Example AG"));
    expect(result.beneficiaryIBAN, equals("CH12 3456 7890 1234 5678 0"));
    expect(result.state, equals(TransactionState.open));
    expect(result.created, isNotNull);
  });

  test("Fetch Cash Outs", () async {
    final client = MockClient();
    final service = WalletService(baseURL, client);

    when(client.get(_url("/api/wallet/cash_out_request/?page_size=10"), headers: anyNamed("headers"))).thenAnswer((_) async {
      final item1 = CashOut("dkaoijdsa", "Example AG", "CH12 3456 7890 1234 5678 0", TransactionState.done, DateTime.now());
      final item2 = CashOut("dkfdsijdsa", "Example AG", "CH12 3456 7890 1234 5678 0", TransactionState.pending, DateTime.now());
      return http.Response(jsonEncode({"next": null, "prev": null, "results": [item1.toJson(), item2.toJson()]}), 200, headers: {HttpHeaders.contentTypeHeader: "application/json"});
    });

    final result = await service.fetchCashOuts();
    expect(result.items.length, equals(2));
    expect(result.items.first.beneficiaryName, equals("Example AG"));
    expect(result.items.first.beneficiaryIBAN, equals("CH12 3456 7890 1234 5678 0"));
    expect(result.cursor.next, isNull);
  });
}