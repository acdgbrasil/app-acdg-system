import 'dart:convert';

import 'package:http/http.dart' as http;

/// Resolved OIDC endpoints loaded from the issuer's discovery document.
///
/// Per ADR-028, the BFF Dart MUST NOT hardcode paths like `/oauth/v2/token`
/// (Zitadel-specific). Endpoints are derived from the discovery document at
/// `<issuer>/.well-known/openid-configuration` at boot. This keeps the BFF
/// agnostic of IdP vendor (Zitadel today, Authentik tomorrow).
///
/// Fields mirror the OpenID Connect Discovery 1.0 spec.
final class OidcEndpoints {
  const OidcEndpoints({
    required this.issuer,
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    required this.userinfoEndpoint,
    required this.jwksUri,
    required this.revocationEndpoint,
    this.endSessionEndpoint,
    this.introspectionEndpoint,
  });

  /// Loads endpoints from the OIDC discovery document.
  ///
  /// Throws [OidcDiscoveryException] on transport error, non-2xx response,
  /// invalid JSON, or missing required field. Fail-fast on boot is the
  /// desired behavior — a half-configured IdP integration must NOT pass
  /// silent and turn into 401s later.
  static Future<OidcEndpoints> fromDiscovery({
    required Uri discoveryUri,
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final client = httpClient ?? http.Client();
    final response = await client.get(discoveryUri).timeout(timeout);
    if (response.statusCode != 200) {
      throw OidcDiscoveryException(
        'OIDC discovery returned status ${response.statusCode} at $discoveryUri',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw OidcDiscoveryException(
        'OIDC discovery returned non-object JSON at $discoveryUri',
      );
    }

    String requiredString(String key) {
      final value = decoded[key];
      if (value is! String || value.isEmpty) {
        throw OidcDiscoveryException(
          'OIDC discovery missing required field "$key" at $discoveryUri',
        );
      }
      return value;
    }

    String? optionalString(String key) {
      final value = decoded[key];
      return value is String && value.isNotEmpty ? value : null;
    }

    return OidcEndpoints(
      issuer: requiredString('issuer'),
      authorizationEndpoint: Uri.parse(
        requiredString('authorization_endpoint'),
      ),
      tokenEndpoint: Uri.parse(requiredString('token_endpoint')),
      userinfoEndpoint: Uri.parse(requiredString('userinfo_endpoint')),
      jwksUri: Uri.parse(requiredString('jwks_uri')),
      revocationEndpoint: Uri.parse(requiredString('revocation_endpoint')),
      endSessionEndpoint: optionalString('end_session_endpoint') != null
          ? Uri.parse(optionalString('end_session_endpoint')!)
          : null,
      introspectionEndpoint: optionalString('introspection_endpoint') != null
          ? Uri.parse(optionalString('introspection_endpoint')!)
          : null,
    );
  }

  /// `issuer` claim — must match the `iss` claim in tokens.
  final String issuer;
  final Uri authorizationEndpoint;
  final Uri tokenEndpoint;
  final Uri userinfoEndpoint;
  final Uri jwksUri;
  final Uri revocationEndpoint;
  final Uri? endSessionEndpoint;
  final Uri? introspectionEndpoint;
}

/// Thrown when OIDC discovery document cannot be loaded or is invalid.
/// Fail-fast on boot — IdP misconfiguration must NOT pass silent.
class OidcDiscoveryException implements Exception {
  OidcDiscoveryException(this.message);
  final String message;
  @override
  String toString() => 'OidcDiscoveryException: $message';
}
