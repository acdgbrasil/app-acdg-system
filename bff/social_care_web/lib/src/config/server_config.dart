import 'dart:io';

/// Configuration for the Web BFF server, parsed from environment variables.
///
/// Accepts an optional [Map<String, String>] for testing instead of reading
/// from [Platform.environment].
class ServerConfig {
  const ServerConfig({
    required this.port,
    required this.host,
    required this.apiBaseUrl,
    required this.oidcIssuer,
    required this.oidcClientId,
    required this.oidcClientSecret,
    required this.oidcRedirectUri,
    required this.sessionSecret,
    this.sessionTtl = const Duration(hours: 1),
  });

  /// Creates config from environment variables.
  ///
  /// Accepts optional [env] map for testing (defaults to [Platform.environment]).
  /// Throws [StateError] if any required variable is missing.
  factory ServerConfig.fromEnvironment([Map<String, String>? env]) {
    final e = env ?? Platform.environment;

    String required(String key) {
      final value = e[key];
      if (value == null || value.isEmpty) {
        throw StateError('Missing required environment variable: $key');
      }
      return value;
    }

    final ttlMinutes = e['SESSION_TTL_MINUTES'];
    final parsedTtl = ttlMinutes != null ? int.tryParse(ttlMinutes) : null;
    if (ttlMinutes != null && parsedTtl == null) {
      throw StateError(
        'Invalid SESSION_TTL_MINUTES value: "$ttlMinutes" (must be an integer)',
      );
    }

    return ServerConfig(
      port: int.tryParse(e['PORT'] ?? '') ?? 8081,
      host: e['HOST'] ?? '0.0.0.0',
      apiBaseUrl: required('API_BASE_URL'),
      oidcIssuer: required('OIDC_ISSUER'),
      oidcClientId: required('OIDC_CLIENT_ID'),
      oidcClientSecret: required('OIDC_CLIENT_SECRET'),
      oidcRedirectUri: required('OIDC_REDIRECT_URI'),
      sessionSecret: required('SESSION_SECRET'),
      sessionTtl: parsedTtl != null
          ? Duration(minutes: parsedTtl)
          : const Duration(hours: 1),
    );
  }

  /// Port the server listens on.
  final int port;

  /// Host address to bind to.
  final String host;

  /// Backend API base URL (Swift/Vapor service).
  final String apiBaseUrl;

  /// OIDC issuer URL (Zitadel).
  final String oidcIssuer;

  /// OIDC client ID (Confidential Client).
  final String oidcClientId;

  /// OIDC client secret (Confidential Client).
  final String oidcClientSecret;

  /// OIDC redirect URI for the BFF callback.
  final String oidcRedirectUri;

  /// Secret key used for session cookie encryption.
  final String sessionSecret;

  /// Session time-to-live duration.
  final Duration sessionTtl;

  /// OpenID Connect discovery document URI derived from [oidcIssuer].
  Uri get discoveryDocumentUri =>
      Uri.parse('$oidcIssuer/.well-known/openid-configuration');

  /// Token endpoint derived from [oidcIssuer].
  Uri get tokenEndpoint => Uri.parse('$oidcIssuer/oauth/v2/token');
}
