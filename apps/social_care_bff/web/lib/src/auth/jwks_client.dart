import 'package:http/http.dart' as http;

/// Abstract contract for the JWKS endpoint client.
///
/// Returns the raw JSON document served by the upstream JWKS endpoint
/// (e.g. `${oidcIssuer}/oauth/v2/keys`). Parsing happens in [JwksCache];
/// the client's only responsibility is HTTP I/O with a timeout.
///
/// Implementations MUST fail-closed: any timeout, non-2xx response, or
/// transport error must surface as a thrown [Exception] so [JwksCache]
/// turns it into a 401 at the middleware boundary (constraint #10 — no
/// oracle leak).
abstract interface class JwksClient {
  /// Fetches the raw JWKS JSON. Throws on timeout / non-2xx / transport error.
  Future<String> fetch();
}

/// HTTP-backed [JwksClient] with a bounded timeout (default 5s — ticket
/// C00 constraint).
///
/// Constructor takes the absolute JWKS [Uri] (typically derived from
/// `ServerConfig.jwksUri`). `httpClient` is injectable for tests; default
/// is a fresh `http.Client()`.
class HttpJwksClient implements JwksClient {
  HttpJwksClient({
    required Uri jwksUri,
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 5),
  }) : _jwksUri = jwksUri,
       _httpClient = httpClient ?? http.Client(),
       _timeout = timeout;

  final Uri _jwksUri;
  final http.Client _httpClient;
  final Duration _timeout;

  @override
  Future<String> fetch() async {
    final response = await _httpClient.get(_jwksUri).timeout(_timeout);
    if (response.statusCode != 200) {
      throw _JwksFetchException(
        'JWKS endpoint returned status ${response.statusCode}',
      );
    }
    return response.body;
  }
}

class _JwksFetchException implements Exception {
  _JwksFetchException(this.message);
  final String message;
  @override
  String toString() => 'JwksFetchException: $message';
}
