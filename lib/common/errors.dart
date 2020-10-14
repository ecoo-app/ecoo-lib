class HTTPError extends Error {
  
  final int statusCode;
  final Map<String, List<String>> details;

  HTTPError(this.statusCode, this.details);
}

class NotAuthenticatedError extends Error {}
class InvalidPublicKey extends Error {}
class InvalidSecretKey extends Error {}
class UnsupportedTezosAddress extends Error {}
class UnsupportedKeyFormat extends Error {}
class InvalidWallet extends Error {}
