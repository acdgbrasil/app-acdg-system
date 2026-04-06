/// Configuration for BFF-based authentication on web.
///
/// The BFF handles the OIDC flow server-side, so the only config
/// needed is the BFF's base URL.
class BffAuthConfig {
  const BffAuthConfig({required this.bffBaseUrl});

  /// Base URL of the BFF (e.g., '/api' for same-origin,
  /// or 'http://localhost:8081' for dev).
  final String bffBaseUrl;
}
