import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:ecoupon_lib/common/errors.dart';
import 'package:ecoupon_lib/models/address_auto_completion_result.dart';
import 'package:ecoupon_lib/models/cash_out.dart';
import 'package:ecoupon_lib/models/company_profile.dart';
import 'package:ecoupon_lib/models/create_wallet_request.dart';
import 'package:ecoupon_lib/models/currency.dart';
import 'package:ecoupon_lib/models/device_registration.dart';
import 'package:ecoupon_lib/models/paper_wallet.dart';
import 'package:ecoupon_lib/models/user_profile.dart';
import 'package:ecoupon_lib/models/wallet_migration.dart';
import 'package:ecoupon_lib/models/transaction.dart';
import 'package:ecoupon_lib/models/list_response.dart';
import 'package:ecoupon_lib/models/wallet.dart';
import 'package:ecoupon_lib/services/crypto_service.dart';
import 'package:ecoupon_lib/services/http_service.dart';
import 'package:ecoupon_lib/services/session_service.dart';
import 'package:ecoupon_lib/tezos/michelson.dart';
import 'package:ecoupon_lib/tezos/tezos.dart';
import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;
import 'package:bs58check/bs58check.dart' as bs58Check;

import '../ecoupon_lib.dart';

/// WalletService is the main class to use to communicate with the eCoupon backend.
/// Before being able to access the resource on the backend, the user needs to authenticated.
/// To authenticate the user, use SessionService object accessible via WalletService.session():
/// There are 2 way to authenticate the user:
/// 
/// 1. Basic Authentication:
/// ```dart
/// final baseURL = "<BACK_END_URL>";
/// final service = WalletService(baseURL);
/// try {
///     await service.session().fetchToken("<USERNAME>", "<PASSWORD>");
///     // User is authenticate, access the backend resources now
/// } catch (e) {
///     // handle error
/// }
/// ```
/// 2. Using Sign In with Google/Apple:
/// ```dart
/// final baseURL = "<BACK_END_URL>";
/// final service = WalletService(baseURL);
/// final clientInfo = await service.session().fetchClientInfo();
/// // fetch access token from Google or Apple.
/// final String oAuthAccessToken = ...
/// try {
///     await service.session().convertToken(oAuthAccessToken, clientInfo, AuthProvider.google); // or AuthProvide.apple in case of Sign in with Apple
///     // User is authenticate, access the backend resources now
/// } catch (e) {
///     // handle error
/// }
/// ```
/// To get the OAuth token from Google use the google_sign_in package (https://pub.dev/packages/google_sign_in):
/// ```dart
/// final googleSignIn = GoogleSignIn(scopes: ['email']);
/// final response = await googleSignIn.signIn();
/// final oAuthToken = await response.authentication.accessToken;
/// ```
/// To get the OAuth token from Apple use the sign_in_with_apple package (https://pub.dev/packages/sign_in_with_apple):
/// ```dart
/// final credential = await SignInWithApple.getAppleIDCredential(scopes: [AppleIDAuthorizationScopes.email]);
/// final oAuthToken = await response.authentication.identityToken;
/// ```
/// 
/// If any of the APIs throws an [NotAuthenticatedError] exception, then the authentication token has expired and the login process needs to be repeated.
class WalletService {

  static const String _transactionEndpoint = '/api/wallet/transaction/';
  static const String _metaTransactionEndpoint = '/api/wallet/meta_transaction/';
  static const String _currencyListEndpoint = '/api/currency/currency/list/';
  static const String _walletEndpoint = '/api/wallet/wallet/';
  static const String _registerDeviceEndpoint = '/api/devices/';
  static const String _migrationEndpoint = '/api/wallet/wallet_public_key_transfer_request/';
  static const String _cashOutEndpoint = '/api/wallet/cash_out_request/';
  static const String _userProfilesEndpoint = '/api/profiles/user_profiles/';
  static const String _companyProfilesEndpoint = '/api/profiles/company_profiles/';
  static const String _verifyUserEndpoint = '/api/verification/verify_user_profile_pin/';
  static const String _verifyCompanyEndpoint = '/api/verification/verify_company_profile_pin/';
  static const String _resendPINEndpoint = '/api/verification/resend_user_profile_pin/';
  static const String _userAutoCompletionEndpoint = '/api/verification/autocomplete_user/';
  static const String _companyAutoCompletionEndpoint = '/api/verification/autocomplete_company/';
  static const String _openCashoutTransactionEndpoint = '/api/wallet/open_cashout_transaction/';

  final HTTPService _http;

  /// Create the WalletService.
  /// 
  /// [baseURL]: the eCoupon backend base URL (e.g. https://ecoupon-backend.dev.gke.papers.tech)
  WalletService([String baseURL = "https://ecoupon-backend.prod.gke.papers.tech", http.Client client]): _http = HTTPService(baseURL, session: SessionService.getInstance(baseURL), client: client);

  SessionService session() => _http.session;
  
  /// Creates a wallet for the logged in user.
  /// It takes a [currency] and an optional [isCompany] flag with default value set to [false].
  /// Throws [HTTPError] if the eCoupon backend returns an error response (meaning HTTP status code is not between 200-299).
  /// Throws [NotAuthenticatedError] if the user is not logged in.
  Future<Wallet> createWallet(Currency currency, {bool isCompany = false}) async {
    final entropy = Tezos.generateEntropy();
    final keyPair = Tezos.generateKeyPairFromEntropy(entropy);
    final request = CreateWalletRequest(keyPair.edpk(), currency.uuid, isCompany ? WalletCategory.company : WalletCategory.consumer);
    final json = await _http.postTo(WalletService._walletEndpoint, request.toJson());
    final wallet = Wallet.fromJson(json);
    await EcouponLib.store(wallet.walletID, entropy);
    return wallet;
  }

  /// Checks if the device can sign a transaction for the given [wallet].
  /// If the result is [false] it most likely means that the user installed the app on a new phone so the wallet needs to be migrated.
  Future<bool> canSignWithWallet(Wallet wallet) async {
    try {
      final entropy = await EcouponLib.load(wallet.walletID);
      if (entropy == null) {
        return false;
      }
      final keyPair = Tezos.generateKeyPairFromEntropy(entropy);
      final message = hex.encode("test message".codeUnits);
      final signature = Tezos.sign(message, keyPair.privateKey);
      final publicKey = Tezos.getKeyBytesFromEncoded(wallet.publicKey);
      return Tezos.verify(message, signature, publicKey);
    } catch (e) {
      return false;
    }
  }

  /// Migrates the given [wallet] to this device. Once migrated, the wallet will not be usable anymore from the old device.
  /// Throws [HTTPError] if the eCoupon backend returns an error response (meaning HTTP status code is not between 200-299).
  /// Throws [NotAuthenticatedError] if the user is not logged in.
  Future<WalletMigration> migrateWallet(Wallet wallet) async {
    final entropy = Tezos.generateEntropy();
    final keyPair = Tezos.generateKeyPairFromEntropy(entropy);
    final request = WalletMigration(wallet.walletID, null, keyPair.edpk(), null, null, null, null);
    final json = await _http.postTo(WalletService._migrationEndpoint, request.toJson());
    final newWallet = WalletMigration.fromJson(json);
    await EcouponLib.store(newWallet.walletID, entropy);
    return newWallet;
  }

  /// Fetches the list of wallet migraitons for the current user.
  /// Throws [HTTPError] if the eCoupon backend returns an error response (meaning HTTP status code is not between 200-299).
  /// Throws [NotAuthenticatedError] if the user is not logged in.
  Future<ListResponse<WalletMigration>> fetchWalletMigrations({ListCursor cursor, int pageSize = 10}) async {
    final endpoint = cursor?.next ?? "${WalletService._migrationEndpoint}?page_size=$pageSize";
    return _fetchList((dynamic json) { return WalletMigration.fromJson(json); }, endpoint);
  }

  /// Fetches the list of currencies.
  /// Throws [HTTPError] if the eCoupon backend returns an error response (meaning HTTP status code is not between 200-299).
  /// Throws [NotAuthenticatedError] if the user is not logged in.
  Future<ListResponse<Currency>> fetchCurrencies({ListCursor cursor, int pageSize = 10}) async {
    final endpoint = cursor?.next ?? "${WalletService._currencyListEndpoint}?page_size=$pageSize";
    return _fetchList((dynamic json) { return Currency.fromJson(json); }, endpoint);
  }

  /// Creates a transfer between the [source] wallet to the [destination] wallet for the given [amount].
  /// Throws [HTTPError] if the eCoupon backend returns an error response (meaning HTTP status code is not between 200-299).
  /// Throws [NotAuthenticatedError] if the user is not logged in.
  Future<Transaction> transfer(Wallet source, Wallet destination, int amount) async {
    final entropy = await EcouponLib.load(source.walletID);
    final pair = Tezos.generateKeyPairFromEntropy(entropy);
    final nonce = await _fetchNonce(walletID: source.walletID);
    final signature = signTransfer(pair.edpk(), Tezos.getAddressFromEncodedPublicKey(destination.publicKey), amount, nonce + 1, source.currency.tokenID, pair.privateKey);
    final transaction = Transaction(null, source.walletID, destination.walletID, amount, null, null, null, nonce + 1, signature, null);
    final json = await _http.postTo(WalletService._metaTransactionEndpoint, transaction.toJson());
    return Transaction.fromJson(json);
  }
  
  /// Creates a transaction from the given [source] to the given [destination] wallet for the given [amount]. In addition, a [decryptionKey] needs to be passed in
  /// to decrypt the paper wallet's private key. This key should not be hardcoded in the code and committed to git.
  /// Throws [HTTPError] if the eCoupon backend returns an error response (meaning HTTP status code is not between 200-299).
  /// Throws [NotAuthenticatedError] if the user is not logged in.
  Future<Transaction> paperTransfer(PaperWallet source, Wallet destination, int amount, String decryptionKey) async {
    final crypto = CryptoService(decryptionKey);
    final privateKey = crypto.decrypt(source.privateKey, source.nonce);
    final edsk = String.fromCharCodes(privateKey.toList());
    final wallet = await fetchWallet(source.walletID);
    final secretKey = bs58Check.decode(edsk).sublist(4);
    final publicKey = bs58Check.decode(wallet.publicKey).sublist(4);
    final secretKeyList = secretKey.toList();
    secretKeyList.addAll(publicKey);
    final fullSecret = Uint8List.fromList(secretKeyList);
    final signature = signTransfer(wallet.publicKey, Tezos.getAddressFromEncodedPublicKey(destination.publicKey), amount, wallet.nonce + 1, destination.currency.tokenID, fullSecret);
    final transaction = Transaction(null, source.walletID, destination.walletID, amount, null, null, null, wallet.nonce + 1, signature, null);
    final json = await _http.postTo(WalletService._metaTransactionEndpoint, transaction.toJson());
    return Transaction.fromJson(json);
  }

  /// Fetches the wallets belonging to the currently logged in user.
  /// Throws [HTTPError] if the eCoupon backend returns an error response (meaning HTTP status code is not between 200-299).
  /// Throws [NotAuthenticatedError] if the user is not logged in.
  Future<ListResponse<Wallet>> fetchWallets({ListCursor cursor, int pageSize = 10}) async {
    final endpoint = cursor?.next ?? "${WalletService._walletEndpoint}?page_size=$pageSize";
    return _fetchList((dynamic json) { return Wallet.fromJson(json); }, endpoint);
  }

  /// Fetches the wallet for the given [walletID].
  /// Throws [HTTPError] if the eCoupon backend returns an error response (meaning HTTP status code is not between 200-299).
  /// Throws [NotAuthenticatedError] if the user is not logged in.
  Future<Wallet> fetchWallet(String walletID) async {
    final Map<String, dynamic> json = await _http.getFrom("${WalletService._walletEndpoint}$walletID/");
    return Wallet.fromJson(json);
  }

  /// Fetches the created user profiles for the currently logged in user.
  /// Throws [HTTPError] if the eCoupon backend returns an error response (meaning HTTP status code is not between 200-299).
  /// Throws [NotAuthenticatedError] if the user is not logged in.
  Future<ListResponse<UserProfile>> fetchUserProfiles({ListCursor cursor, int pageSize = 10}) async {
    final endpoint = cursor?.next ?? "${WalletService._userProfilesEndpoint}?page_size=$pageSize";
    return _fetchList((dynamic json) { return UserProfile.fromJson(json); }, endpoint);
  }

  /// Creates a company profile for the given [wallet] with the given [firstName], [lastName], [telephoneNumber], [dateOfBirth] and [addressStreet].
  /// Optionally [addressTown] and [addressPostalCode] can be provided, if not, default values are "Wetzikon" and "8620" respectively.
  /// A pin will be sent via SMS to the provided [telephoneNumber] that needs to be later used to verify this profile.
  /// Throws [HTTPError] if the eCoupon backend returns an error response (meaning HTTP status code is not between 200-299).
  /// Throws [NotAuthenticatedError] if the user is not logged in.
  /// Throws [InvalidWallet] if the given [wallet] is not a consumer wallet.
  Future<UserProfile> createUserProfile(Wallet wallet, String firstName, String lastName, String telephoneNumber, DateTime dateOfBirth, String addressStreet, String addressTown, String addressPostalCode, String placeOfOrigin) async {
    if (wallet.category != WalletCategory.consumer) {
      throw InvalidWallet();
    }
    final profile = UserProfile(null, wallet.walletID, firstName, lastName, addressStreet, addressTown, addressPostalCode, telephoneNumber, dateOfBirth, placeOfOrigin, null);
    final Map<String, dynamic> json = await _http.postTo(WalletService._userProfilesEndpoint, profile.toJson());
    return UserProfile.fromJson(json);
  }

  /// Fetches the created company profiles for the currently logged in user.
  /// Throws [HTTPError] if the eCoupon backend returns an error response (meaning HTTP status code is not between 200-299).
  /// Throws [NotAuthenticatedError] if the user is not logged in.
  Future<ListResponse<CompanyProfile>> fetchCompanyProfiles({ListCursor cursor, int pageSize = 10}) async {
    String endpoint = cursor?.next ?? "${WalletService._companyProfilesEndpoint}?page_size=$pageSize";
    return _fetchList((dynamic json) { return CompanyProfile.fromJson(json); }, endpoint);
  }

  /// Creates a company profile for the given [wallet] with the given [name] and [uid], optionally [addressStreet], [addressTown] and [addressPostalCode] can be provided.
  /// A pin will be sent to the company address that needs to be later used to verify this profile.
  /// Throws [HTTPError] if the eCoupon backend returns an error response (meaning HTTP status code is not between 200-299).
  /// Throws [NotAuthenticatedError] if the user is not logged in.
  /// Throws [InvalidWallet] if the given [wallet] is not a company wallet.
  Future<CompanyProfile> createCompanyProfile(Wallet wallet, String name, String uid, String addressStreet, String addressTown, String addressPostalCode, String telephoneNumber) async {
    if (wallet.category != WalletCategory.company) {
      throw InvalidWallet();
    }
    final profile = CompanyProfile(null, wallet.walletID, name, uid, addressStreet, addressTown, addressPostalCode, telephoneNumber, null);
    final Map<String, dynamic> json = await _http.postTo(WalletService._companyProfilesEndpoint, profile.toJson());
    return CompanyProfile.fromJson(json);
  }

  /// Deletes the provided [profile].
  /// Throws [HTTPError] if the eCoupon backend returns an error response (meaning HTTP status code is not between 200-299).
  /// Throws [NotAuthenticatedError] if the user is not logged in.
  Future<void> deleteUserProfile(UserProfile profile) async {
    final endpoint = "${WalletService._userProfilesEndpoint}${profile.uuid}/";
    await _http.deleteAt(endpoint);
  }

  /// Deletes the provided [profile].
  /// Throws [HTTPError] if the eCoupon backend returns an error response (meaning HTTP status code is not between 200-299).
  /// Throws [NotAuthenticatedError] if the user is not logged in.
  Future<void> deleteCompanyProfile(CompanyProfile profile) async {
    final endpoint = "${WalletService._companyProfilesEndpoint}${profile.uuid}/";
    await _http.deleteAt(endpoint);
  }

  /// Resends the pin via sms for the provided [profile] if its verificationState is pendingPIN.
  /// Throws [HTTPError] if the eCoupon backend returns an error response (meaning HTTP status code is not between 200-299).
  /// Throws [NotAuthenticatedError] if the user is not logged in.
  Future<void> resendPIN(UserProfile profile) async {
    final endpoint = "${WalletService._resendPINEndpoint}${profile.uuid}";
    await _http.postTo(endpoint, profile.toJson());
  }

  /// Verifies the given user [profile] with the given [pin].
  /// Throws [HTTPError] if the eCoupon backend returns an error response (meaning HTTP status code is not between 200-299).
  /// Throws [NotAuthenticatedError] if the user is not logged in.
  Future<void> verifyUser(UserProfile profile, String pin) async {
    final endpoint = "${WalletService._verifyUserEndpoint}${profile.uuid}";
    await _http.postTo(endpoint, {"pin": pin});
  }

  /// Verifies the given user [profile] with the given [pin].
  /// Throws [HTTPError] if the eCoupon backend returns an error response (meaning HTTP status code is not between 200-299).
  /// Throws [NotAuthenticatedError] if the user is not logged in.
  Future<void> verifyCompany(CompanyProfile profile, String pin) async {
    final endpoint = "${WalletService._verifyCompanyEndpoint}${profile.uuid}";
    await _http.postTo(endpoint, {"pin": pin});
  }

  /// Fetches transactions for the given [walletID]. It optionally takes a [pageSize].
  /// For pagination, pass as argument the returned [cursor] to fetch the next page.
  /// Either the [walletID] or the [cursor] parameter need to be supplied.
  /// Throws [HTTPError] if the eCoupon backend returns an error response (meaning HTTP status code is not between 200-299).
  /// Throws [NotAuthenticatedError] if the user is not logged in.
  Future<ListResponse<Transaction>> fetchTransactions({String walletID, ListCursor cursor, int pageSize = 10}) async {
    final endpoint = cursor?.next ?? "${WalletService._transactionEndpoint}?search=$walletID&page_size=$pageSize";
    return _fetchList((dynamic json) { return Transaction.fromJson(json); }, endpoint);
  }

  /// Fetches open cashout transactions for the given [walletID]. It optionally takes a [pageSize].
  /// For pagination, pass as argument the returned [cursor] to fetch the next page.
  /// Either the [walletID] or the [cursor] parameter need to be supplied.
  /// Throws [HTTPError] if the eCoupon backend returns an error response (meaning HTTP status code is not between 200-299).
  /// Throws [NotAuthenticatedError] if the user is not logged in.
  Future<ListResponse<Transaction>> fetchOpenCashoutTransactions({String walletID, ListCursor cursor, int pageSize = 10}) async {
    final endpoint = cursor?.next ?? "${WalletService._openCashoutTransactionEndpoint}?wallet_id=$walletID&page_size=$pageSize";
    return _fetchList((dynamic json) { return Transaction.fromJson(json); }, endpoint);
  }

  /// Registers the device for push notifications.
  /// It takes a [notificationToken] that should be retrieved using the flutter firebase_messaging package (https://pub.dev/packages/firebase_messaging).
  /// It optionally takes a device [name] and [deviceID] that can be retrieved using the device_info package (https://pub.dev/packages/device_info).
  /// Throws [HTTPError] if the eCoupon backend returns an error response (meaning HTTP status code is not between 200-299).
  /// Throws [NotAuthenticatedError] if the user is not logged in.
  Future<DeviceRegistration> registerDevice(String notificationToken, {String name, String deviceID}) async {
    final type = Platform.isIOS ? RegisterDeviceType.ios : RegisterDeviceType.android;
    final registration = DeviceRegistration(null, name, notificationToken, deviceID, null, null, type);
    final Map<String, dynamic> json = await _http.postTo(WalletService._registerDeviceEndpoint, registration.toJson());
    return DeviceRegistration.fromJson(json);
  }

  /// Starts the cashout flow. The given [transaction] needs to be a transaction from a company wallet to the currency's owner wallet. 
  /// It will trasnfer the balance of the given [wallet] to the currency's owner wallet and trigger a payment request to 
  /// the given [beneficiaryName] and [beneficiaryIBAN].
  /// Throws [HTTPError] if the eCoupon backend returns an error response (meaning HTTP status code is not between 200-299).
  /// Throws [NotAuthenticatedError] if the user is not logged in.
  Future<CashOut> cashOut(Transaction transaction, String beneficiaryName, String beneficiaryIBAN) async {
    final request = CashOut(transaction.uuid, beneficiaryName, beneficiaryIBAN, null, null);
    final Map<String, dynamic> json = await _http.postTo(WalletService._cashOutEndpoint, request.toJson());
    return CashOut.fromJson(json);
  }

  /// Fetches the created cash out requests for the currently logged in user.
  /// Throws [HTTPError] if the eCoupon backend returns an error response (meaning HTTP status code is not between 200-299).
  /// Throws [NotAuthenticatedError] if the user is not logged in.
  Future<ListResponse<CashOut>> fetchCashOuts({ListCursor cursor, int pageSize = 10}) {
    final endpoint = cursor?.next ?? "${WalletService._cashOutEndpoint}?page_size=$pageSize";
    return _fetchList((dynamic json) { return CashOut.fromJson(json); }, endpoint);
  }

  /// Fetches a list of suggested addresses for the specified [target] group and the [partialAddress].
  /// Throws [HTTPError] if the eCoupon backend returns an error response (meaning HTTP status code is not between 200-299).
  /// Throws [NotAuthenticatedError] if the user is not logged in.
  Future<ListResponse<AddressAutoCompletionResult>> fetchAutoCompletions({AddressAutoCompletionTarget target, String partialAddress, ListCursor cursor, int pageSize = 10}) async {
    String endpoint = cursor?.next ?? _autoCompletionEndpoint(target, partialAddress, pageSize);
    return _fetchList((dynamic json) { return AddressAutoCompletionResult.fromJson(json); }, endpoint);
  }

  String _autoCompletionEndpoint(AddressAutoCompletionTarget target, String partialAddress, int pageSize) {
    return "${target == AddressAutoCompletionTarget.user ? WalletService._userAutoCompletionEndpoint : WalletService._companyAutoCompletionEndpoint}?search=$partialAddress&page_size=$pageSize";
  }

  Future<int> _fetchNonce({@required String walletID}) async {
    final Map<String, dynamic> json = await _http.getFrom("${WalletService._walletEndpoint}$walletID/");
    return json["nonce"];
  }

  Future<ListResponse<T>> _fetchList<T>(Function itemFactory, String endpoint) async {
    final Map<String, dynamic> json = await _http.getFrom(endpoint);
    final List<dynamic> results = json["results"];
    final items = results.map<T>((e) => itemFactory(e)).toList();
    return ListResponse(items, ListCursor(json["previous"], json["next"]));
  }

  String signTransfer(String from, String to, int amount, int nonce, int tokenID, Uint8List privateKey) {
    final message = _createMessage(from, to, amount, nonce, tokenID);
    return Tezos.sign(message, privateKey);
  }

  bool verifyTransfer(String from, String to, int amount, int nonce, int tokenID, String signature, Uint8List publicKey) {
    final message = _createMessage(from, to, amount, nonce, tokenID);
    return Tezos.verify(message, signature, publicKey);
  }

  String _createMessage(String from, String to, int amount, int nonce, int tokenID) {
    /*
    (pair
      (key %from_public_key)
      (pair 
        (nat %nonce)
        (list %txs
          (pair	
            (address %to_address)
            (pair	
              (nat %token_id) 
              (nat %amount)
          )
        )
      )
    )
    */
    return MichelsonPair(
      MichelsonKey(from),
      MichelsonPair(
        MichelsonInt(nonce), 
        MichelsonList([
          MichelsonPair(
            MichelsonAddress(to),
            MichelsonPair(
              MichelsonInt(tokenID), 
              MichelsonInt(amount)
            )
          )
        ])
      )
    ).pack();
  }
}

