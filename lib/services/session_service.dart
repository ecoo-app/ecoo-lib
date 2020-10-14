import 'package:ecoupon_lib/common/errors.dart';
import 'package:ecoupon_lib/models/client_info.dart';
import 'package:ecoupon_lib/models/convert_token_request.dart';
import 'package:ecoupon_lib/models/session_token.dart';
import 'package:ecoupon_lib/services/http_service.dart';
import 'package:http/http.dart' as http;

class AuthProvider {

  static final AuthProvider google = AuthProvider("google-oauth2");
  static final AuthProvider apple = AuthProvider("apple-id");

  final String value;

  AuthProvider(this.value);
}

class SessionService {

  static final Map<String, SessionService> _instanceMap = Map<String, SessionService>();

  static SessionService getInstance(String baseURL) {
    SessionService result = _instanceMap[baseURL];
    if (result == null) {
      result = SessionService(baseURL);
      _instanceMap[baseURL] = result;
    }
    return result;
  }

  static const String _tokenEndpoint = "/api/token/";
  static const String _convertEndpoint = "/api/oauth/convert-token";
  static const String _refreshEndpoint = "/api/token/refresh/";
  static const String _applicationsEndpoint = "/api/auth/applications";

  SessionToken token;

  HTTPService _http;

  SessionService(String baseURL, [http.Client client]): _http = HTTPService(baseURL, client: client);

  Future<ClientInfo> fetchClientInfo() async {
    final Map<String, dynamic> json = await _http.getFrom(SessionService._applicationsEndpoint);
    final applications = json["results"];
    return ClientInfo.fromJson(applications.first);
  }

  Future<SessionToken> convertToken(String oAuthToken, ClientInfo info, AuthProvider provider) async {
    final ConvertTokenRequest convertRequest = ConvertTokenRequest(info.clientID, "convert_token", oAuthToken, provider.value);
    final Map<String, dynamic> json = await _http.postTo(SessionService._convertEndpoint, convertRequest.toJson());
    token = SessionToken.fromJson(json);
    return token;
  }

  Future<SessionToken> fetchToken(String username, String password) async {
    final Map<String, dynamic> json = await _http.postTo(SessionService._tokenEndpoint, {"username": username, "password": password });
    token = SessionToken.fromJson(json);
    return token;
  }

  Future<SessionToken> refreshToken() async {
    if (token != null) {
      final Map<String, dynamic> json = await _http.postTo(SessionService._refreshEndpoint, {"refresh": token.refresh});
      token = SessionToken.fromJson(json);
      return token;
    } else {
      throw NotAuthenticatedError();
    }
  }
}