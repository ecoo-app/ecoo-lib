import 'dart:convert';
// import 'dart:io';

import 'package:convert/convert.dart';
import 'package:ecoupon_lib/common/errors.dart';
import 'package:ecoupon_lib/common/verification_stage.dart';
import 'package:ecoupon_lib/ecoupon_lib.dart';
import 'package:ecoupon_lib/models/currency.dart';
import 'package:ecoupon_lib/models/list_response.dart';
import 'package:ecoupon_lib/models/address_auto_completion_result.dart';
import 'package:ecoupon_lib/models/paper_wallet.dart';
import 'package:ecoupon_lib/models/session_token.dart';
import 'package:ecoupon_lib/models/transaction.dart';
import 'package:ecoupon_lib/models/wallet.dart';
import 'package:ecoupon_lib/services/crypto_service.dart';
import 'package:ecoupon_lib/services/session_service.dart';
import 'package:ecoupon_lib/tezos/tezos.dart';
import 'package:ecoupon_lib/services/wallet_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:device_info/device_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _useSignInWithApple = true;
  bool _isCompany = false;
  bool _clearSession = true;
  bool _isLocal = true;

  // final service = WalletService("https://ecoupon-backend.dev.gke.papers.tech");
  final service = WalletService("http://localhost:8000");
  // final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
    if (_clearSession) {
      final prefs = await SharedPreferences.getInstance();
      prefs.remove("session_token");
    }

    _loadCachedSessionToken();

    // _firebaseMessaging.configure(
    //   onMessage: (Map<String, dynamic> message) async {
    //     print("onMessage: $message");
    //   },
    //   onLaunch: (Map<String, dynamic> message) async {
    //     print("onLaunch: $message");
    //   },
    //   onResume: (Map<String, dynamic> message) async {
    //     print("onResume: $message");
    //   },
    // );
  }

  _loadCachedSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString("session_token");
    SessionToken sessionToken;
    if (jsonString != null) {
      final json = jsonDecode(jsonString);
      sessionToken = SessionToken.fromJson(json);
      if (sessionToken.access != null) {
        service.session().token = sessionToken;
        return;
      }
    }
  }

  _login() async {
    if (service.session().token?.access != null) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    SessionToken sessionToken;
    final clientInfo = await service.session().fetchClientInfo();
    if (_isLocal) {
      sessionToken = await service.session().fetchToken("mike", "alfA13.!");
    } else if (!_useSignInWithApple) {
      final googleSignIn = GoogleSignIn(scopes: ['email']);
      final response = await googleSignIn.signIn();
      final authentication = await response.authentication;
      sessionToken = await service.session().convertToken(
          authentication.accessToken, clientInfo, AuthProvider.google);
    } 
    // else {
    //   final credential = await SignInWithApple.getAppleIDCredential(
    //       scopes: [AppleIDAuthorizationScopes.email]);
    //   sessionToken = await service.session().convertToken(
    //       credential.identityToken, clientInfo, AuthProvider.apple);
    // }
    if (sessionToken.access != null) {
      prefs.setString("session_token", jsonEncode(sessionToken.toJson()));
    }
  }

  _registerDevice() async {
    // final permissionGranted = await _firebaseMessaging
    //     .requestNotificationPermissions(const IosNotificationSettings(
    //         sound: false, badge: true, alert: true, provisional: true));
    // if (permissionGranted) {
    //   final token = await _firebaseMessaging.getToken();
    //   DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    //   String deviceID;
    //   String name;
    //   if (Platform.isAndroid) {
    //     var build = await deviceInfo.androidInfo;
    //     name = build.model;
    //     deviceID = build.androidId; //UUID for Android
    //   } else if (Platform.isIOS) {
    //     var data = await deviceInfo.iosInfo;
    //     name = data.name;
    //     deviceID = data.identifierForVendor; //UUID for iOS
    //   }
    //   final registration =
    //       await service.registerDevice(token, deviceID: deviceID, name: name);
    // }
  }

  _createWallet() async {
    final currencies = await service.fetchCurrencies();
    final currency = currencies.items.first;
    final wallet = await service.createWallet(currency, isCompany: _isCompany);
    print("Wallet: ${wallet.walletID}");
  }

  _migrateWallet() async {
    final wallet = await service.fetchWallet("AB123456");
    final canSign = false;
    if (!canSign) {
      final migration = await service.migrateWallet(wallet);
      print(migration.toJson().toString());
    } else {
      print("No need to migrate");
    }
  }

  _createProfile() async {
    if (_isCompany) {
      final wallet = (await service.fetchWallets(pageSize: 100))
          .items
          .firstWhere((e) =>
              e.category == WalletCategory.company &&
              e.state == WalletState.unverified);
      final profile = await service.createCompanyProfile(
          wallet,
          "Example AG",
          null,
          "CHE-111.222.333",
          "Main Street 1",
          "Zurich",
          "80000",
          "+41791234567");
      print(profile.toJson().toString());
    } else {
      final wallet = await service.fetchWallet("AB123456");
      final profile = await service.createUserProfile(
          wallet,
          "John",
          "Doe",
          "+41791234567",
          DateTime.parse("2001-01-01"),
          "Main Street 1",
          "Zurich",
          "8000",
          "Zurich");
      print(profile.toJson().toString());
    }
  }

  _profiles() async {
    if (_isCompany) {
      final profiles = await service.fetchCompanyProfiles();
      for (final profile in profiles.items) {
        print(profile.toJson().toString());
      }
    } else {
      final profiles = await service.fetchUserProfiles();
      for (final profile in profiles.items) {
        print(profile.toJson().toString());
      }
    }
  }

  _deleteProfile() async {
    if (_isCompany) {
      final profiles = await service.fetchCompanyProfiles();
      final profile = profiles.items.firstWhere(
          (element) => element.verificationStage != VerificationStage.verified);
      await service.deleteCompanyProfile(profile);
    } else {
      final profiles = await service.fetchUserProfiles();
      final profile = profiles.items.first;
      await service.deleteUserProfile(profile);
    }
  }

  _resendPIN() async {
    final profiles = await service.fetchUserProfiles();
    final profile = profiles.items.firstWhere(
        (element) => element.verificationStage == VerificationStage.pendingPIN);
    await service.resendPIN(profile);
  }

  _verifyProfile() async {
    if (_isCompany) {
      final profile = (await service.fetchCompanyProfiles()).items.firstWhere(
          (element) =>
              element.verificationStage == VerificationStage.pendingPIN);
      await service.verifyCompany(profile, "123456");
    } else {
      final profile = (await service.fetchUserProfiles()).items.firstWhere(
          (element) =>
              element.verificationStage == VerificationStage.pendingPIN);
      await service.verifyUser(profile, "123456");
    }
  }

  _transactions([ListCursor cursor]) async {
    if (cursor == null) {
      final wallet = await service.fetchWallet("AB123456");
      final txs = await service.fetchTransactions(
          walletID: wallet.walletID, pageSize: 2);
      for (final tx in txs.items) {
        print(tx.toJson().toString());
      }
      if (txs.cursor.next != null) {
        await _transactions(txs.cursor);
      } else {
        print("NO MORE TO LOAD $cursor");
      }
    } else {
      final txs = await service.fetchTransactions(cursor: cursor);
      for (final tx in txs.items) {
        print(tx.toJson().toString());
      }
    }
  }

  _openCashoutTransactions([ListCursor cursor]) async {
    if (cursor == null) {
      final wallet = await service.fetchWallet("AB123456");
      final txs = await service.fetchOpenCashoutTransactions(
          walletID: wallet.walletID, pageSize: 2);
      for (final tx in txs.items) {
        print(tx.toJson().toString());
      }
      if (txs.cursor.next != null) {
        await _openCashoutTransactions(txs.cursor);
      } else {
        print("NO MORE TO LOAD $cursor");
      }
    } else {
      final txs = await service.fetchOpenCashoutTransactions(cursor: cursor);
      for (final tx in txs.items) {
        print(tx.toJson().toString());
      }
    }
  }

  _wallets() async {
    final wallets = await service.fetchWallets();
    for (final wallet in wallets.items) {
      print(wallet.toJson().toString());
      print(wallet.currency.toJson().toString());
    }
  }

  _migrations() async {
    final migrations = await service.fetchWalletMigrations();
    for (final migration in migrations.items) {
      print(migration.toJson().toString());
    }
  }

  _currencies() async {
    final currencies = await service.fetchCurrencies();
    for (final currency in currencies.items) {
      print(currency.toJson().toString());
    }
  }

  _transfer() async {
    final fromWallet = await service.fetchWallet("AB123456");
    final toWallet = await service.fetchWallet("CD123456");
    final tx = await service.transfer(fromWallet, toWallet, 100);
    print(tx.toJson().toString());
  }

  _cashOut() async {
    final fromWallet = await service.fetchWallet("AB123456");
    Transaction transaction;
    if (fromWallet.balance > 0) {
      final ownerWallet = fromWallet.currency.owner;
      transaction =
          await service.transfer(fromWallet, ownerWallet, fromWallet.balance);
    } else {
      transaction = (await service.fetchOpenCashoutTransactions(
              walletID: fromWallet.currency.owner.walletID, pageSize: 100))
          .items
          .first;
    }
    final cashOut = await service.cashOut(
        transaction, "Example AG", "CH93 0076 2011 6238 5295 7");
    print(cashOut.toJson().toString());
  }

  _signVerify() {
    final walletService = WalletService();
    final entropy = Tezos.generateEntropy();
    final keyPair = Tezos.generateKeyPairFromEntropy(entropy);
    final address = Tezos.getAddress(keyPair.publicKey);
    print("Address: $address");
    final toAddress = "tz1d75oB6T4zUMexzkr5WscGktZ1Nss1JrT7";
    final amount = 10;
    final nonce = 1;
    final tokenID = 0;

    final signature = walletService.signTransfer(
        keyPair.edpk(), toAddress, amount, nonce, tokenID, keyPair.privateKey);
    final verification = walletService.verifyTransfer(keyPair.edpk(), toAddress,
        amount, nonce, tokenID, signature, keyPair.publicKey);
    print("Verification: $verification");
  }

  _secureStorage() async {
    final entropy = Tezos.generateEntropy();
    final keyPair = Tezos.generateKeyPairFromEntropy(entropy);
    final address = Tezos.getAddress(keyPair.publicKey);
    print("Address: $address");
    final key = "TestID1";
    await EcouponLib.store(key, entropy);
    print("Stored Entropy: " + entropy);
    final entropy1 = await EcouponLib.load(key);
    print("Loaded Entropy: " + entropy1);
  }

  _crypto() async {
    final entropy = Tezos.generateEntropy();
    final keyPair = Tezos.generateKeyPairFromEntropy(entropy);
    final key = CryptoService.generateRadomKey(32);
    final nonce = CryptoService.generateRadomKey(24);
    final crypto = CryptoService(key);
    final encryptedSKHex = crypto.encrypt(keyPair.edsk(), nonce);
    final plain = crypto.decrypt(encryptedSKHex, nonce);
    final list = plain.toList();
    print(String.fromCharCodes(list));
    final pair = Tezos.generateKeyPairFromEntropy(Tezos.generateEntropy());
    print(pair.edpk());
  }

  _fetchAutoCompletion() async {
    final suggestions = await service.fetchAutoCompletions(
        target: AddressAutoCompletionTarget.user,
        partialAddress: "W",
        pageSize: 100);
    for (final suggestion in suggestions.items) {
      print(suggestion.toJson().toString());
    }
  }

  _paperWallet() async {
    final entropy = Tezos.generateEntropy();
    final keyPair = Tezos.generateKeyPairFromEntropy(entropy);
    final key = CryptoService.generateRadomKey(32);
    final nonce = CryptoService.generateRadomKey(24);
    final nonceHex = hex.encode(nonce.codeUnits);
    final crypto = CryptoService(key);
    final wallet = PaperWallet(
        "AB123456", nonceHex, crypto.encrypt(keyPair.edsk(), nonceHex));
    final wallet2 = await service.fetchWallet("CD123456");
    final transaction = await service.paperTransfer(
        wallet, wallet2, 2, hex.encode(key.codeUnits));
    print(transaction);
  }

  _paperWalletDetails() async {
    final uri = Uri.parse("");
    final paperWallet = PaperWallet.fromDeepLink(uri);
    final wallet = await service.fetchWallet(paperWallet.walletID);
    final paperWalletDetails = await service.fetchPaperWalletDetailsWithBalance(paperWallet, wallet, "");
    print(paperWalletDetails);
  }

  _verification_new() async {
    final paperWalletUri = Uri.parse("");
    final paperWallet = PaperWallet.fromDeepLink(paperWalletUri);
    final currencies = await service.fetchCurrencies();
    final wallet = await service.createWallet(currencies.items.last);
    final paperWalletDetails = await service.fetchPaperWalletDetailsWithBalance(paperWallet, await service.fetchWallet(paperWallet.walletID), "");
    final transaction = await service.paperTransfer(paperWallet, wallet, paperWalletDetails.balance, "");
    print(transaction);
  }

  _do() async {
    // await _transactions();
    // await _registerDevice();
    // await _openCashoutTransactions();
    // await _currencies();
    // await _wallets();
    // await _migrations();
    // await _transfer();
    // await _secureStorage();
    // await _login();
    // await _createWallet();
    // await _migrateWallet();
    // await _createProfile();
    // await _resendPIN();
    // await _deleteProfile();
    // await _profiles();
    // await _verifyProfile();
    // await _cashOut();
    // await _crypto();
    // await _fetchAutoCompletion();
    // await _paperWallet();
    // await _paperWalletDetails();
    await _verification_new();
  }

  _perform() async {
    try {
      await _do();
    } on HTTPError catch (e) {
      print("ERROR Code: ${e.statusCode}");
      print("ERROR Message: ${e.details.toString()}");
    } catch (e) {
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: BackButton(
            onPressed: () async {
              try {
                await _perform();
              } on NotAuthenticatedError catch (_) {
                await _login();
                await _perform();
              } catch (e) {
                print("ERROR: ${e.toString()}");
              }
            },
          ),
        ),
      ),
    );
  }
}
