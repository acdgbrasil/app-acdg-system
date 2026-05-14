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
    required this.peopleContextBaseUrl,
    required this.oidcIssuer,
    required this.oidcClientId,
    required this.oidcClientSecret,
    required this.oidcRedirectUri,
    required this.sessionSecret,
    this.oidcScopes = 'openid profile email offline_access',
    this.sessionTtl = const Duration(hours: 1),
    this.frontendOrigin,
    this.postLoginRedirectUrl,
    this.oidcCliClientId = '',
    this.bearerLeewaySeconds = 30,
    this.jwksCacheTtl = const Duration(minutes: 10),
    this.bearerMaxTokenBytes = 8192,
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

    final cliClientIdRaw = e['OIDC_CLI_CLIENT_ID'];
    final cliClientId = (cliClientIdRaw == null || cliClientIdRaw.isEmpty)
        ? ''
        : cliClientIdRaw;

    final leewayRaw = e['BEARER_LEEWAY_SECONDS'];
    final leeway = leewayRaw != null ? int.tryParse(leewayRaw) : null;
    if (leewayRaw != null && leeway == null) {
      throw StateError(
        'Invalid BEARER_LEEWAY_SECONDS value: "$leewayRaw" (must be an integer)',
      );
    }

    final jwksTtlRaw = e['JWKS_CACHE_TTL_MINUTES'];
    final jwksTtlMinutes = jwksTtlRaw != null ? int.tryParse(jwksTtlRaw) : null;
    if (jwksTtlRaw != null && jwksTtlMinutes == null) {
      throw StateError(
        'Invalid JWKS_CACHE_TTL_MINUTES value: "$jwksTtlRaw" (must be an integer)',
      );
    }

    final maxBytesRaw = e['BEARER_MAX_TOKEN_BYTES'];
    final maxBytes = maxBytesRaw != null ? int.tryParse(maxBytesRaw) : null;
    if (maxBytesRaw != null && maxBytes == null) {
      throw StateError(
        'Invalid BEARER_MAX_TOKEN_BYTES value: "$maxBytesRaw" (must be an integer)',
      );
    }

    // ADR-028: normalizar issuer com trailing slash para que a resolucao
    // de paths relativos (`./.well-known/openid-configuration`) funcione
    // tanto para issuer Zitadel (`https://auth.acdgbrasil.com.br`) quanto
    // Authentik (`http://authentik:9000/application/o/<slug>/`).
    String issuer = required('OIDC_ISSUER');
    if (!issuer.endsWith('/')) issuer = '$issuer/';

    return ServerConfig(
      port: int.tryParse(e['PORT'] ?? '') ?? 8081,
      host: e['HOST'] ?? '0.0.0.0',
      apiBaseUrl: required('API_BASE_URL'),
      peopleContextBaseUrl: required('PEOPLE_CONTEXT_BASE_URL'),
      oidcIssuer: issuer,
      oidcClientId: required('OIDC_CLIENT_ID'),
      oidcClientSecret: required('OIDC_CLIENT_SECRET'),
      oidcRedirectUri: required('OIDC_REDIRECT_URI'),
      sessionSecret: required('SESSION_SECRET'),
      // ADR-028: scopes externalizados — sem hardcode de Zitadel-specifics
      // (`urn:zitadel:iam:org:project:roles`). Authentik requer `offline_access`
      // explicito desde 2024.2 para receber refresh_token.
      oidcScopes: e['OIDC_SCOPES'] ?? 'openid profile email offline_access',
      sessionTtl: parsedTtl != null
          ? Duration(minutes: parsedTtl)
          : const Duration(hours: 1),
      frontendOrigin: e['FRONTEND_ORIGIN'],
      postLoginRedirectUrl: e['POST_LOGIN_REDIRECT_URL'],
      oidcCliClientId: cliClientId,
      bearerLeewaySeconds: leeway ?? 30,
      jwksCacheTtl: jwksTtlMinutes != null
          ? Duration(minutes: jwksTtlMinutes)
          : const Duration(minutes: 10),
      bearerMaxTokenBytes: maxBytes ?? 8192,
    );
  }

  /// Port the server listens on.
  final int port;

  /// Host address to bind to.
  final String host;

  /// Backend API base URL (Swift/Vapor service).
  final String apiBaseUrl;

  /// People Context service base URL.
  final String peopleContextBaseUrl;

  /// OIDC issuer URL (Zitadel).
  final String oidcIssuer;

  /// OIDC client ID (Confidential Client) used by the Web/browser flow.
  final String oidcClientId;

  /// OIDC client secret (Confidential Client).
  final String oidcClientSecret;

  /// OIDC redirect URI for the BFF callback.
  final String oidcRedirectUri;

  /// Scopes requested in the OIDC authorize URL (ADR-028: externalized).
  /// Default cobre OIDC standard + `offline_access` (required by Authentik
  /// since 2024.2 to emit refresh_token). Override via `OIDC_SCOPES` env.
  /// Scopes IdP-specific (ex: `acdg-roles` property mapping no Authentik)
  /// devem ser adicionados via env, NUNCA hardcoded aqui.
  final String oidcScopes;

  /// Secret key used for session cookie encryption AND HMAC-derived
  /// session ids in the Bearer flow (constraint #3).
  final String sessionSecret;

  /// Session time-to-live duration.
  final Duration sessionTtl;

  /// Frontend origin for CORS (e.g. `http://localhost:8080`).
  /// When set, enables CORS middleware. Only used in local development.
  final String? frontendOrigin;

  /// URL to redirect to after successful login callback.
  /// Defaults to `/` (same-origin). Set to frontend URL for cross-origin dev.
  final String? postLoginRedirectUrl;

  /// OIDC client id of the NATIVE_API CLI app (D1).
  ///
  /// Bearer JWTs are accepted only if their `aud` (string OR array) and
  /// optional `azp` claim match this value. Empty string means the Bearer
  /// path will reject every token (no CLI access configured).
  ///
  /// Production deployments MUST set `OIDC_CLI_CLIENT_ID` in the environment.
  /// When the env var is unset, `bin/server.dart` emits a startup warning
  /// via `Logger.root.warning(...)` so operators see the misconfiguration
  /// at boot time rather than discovering it through a 401 storm. The
  /// runtime contract remains fail-closed (every Bearer is rejected).
  final String oidcCliClientId;

  /// Clock-skew leeway applied to `exp` and `nbf` validation, in seconds.
  /// Default 30s per ticket C00 D7.
  final int bearerLeewaySeconds;

  /// JWKS cache TTL (default 10 minutes per ticket C00).
  final Duration jwksCacheTtl;

  /// Maximum accepted Authorization Bearer payload size, in bytes
  /// (constraint #1, default 8 KiB). Tokens above this are rejected
  /// before any parsing or JWKS fetch.
  final int bearerMaxTokenBytes;

  /// OpenID Connect discovery document URI derived from [oidcIssuer].
  /// ADR-028: o issuer e normalizado com trailing slash em `fromEnvironment`,
  /// permitindo `Uri.parse(issuer).resolve('.well-known/openid-configuration')`
  /// gerar URL valida tanto para Zitadel quanto Authentik.
  Uri get discoveryDocumentUri =>
      Uri.parse(oidcIssuer).resolve('.well-known/openid-configuration');
}
