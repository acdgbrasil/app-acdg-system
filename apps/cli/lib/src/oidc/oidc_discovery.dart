/// OIDC discovery — fetch + parse `<issuer>/.well-known/openid-configuration`.
///
/// Called once per `acdg auth login` (and once per `auth logout` /
/// `auth refresh`). Validates the `issuer` claim against the expected
/// value to defeat a hostile metadata document. Per spike §3.2 +
/// §A.1, every endpoint advertised by Zitadel is captured upfront so
/// downstream code never has to hit the well-known URL again.
///
/// The class is `class` (not `final class`) so command-level orchestration
/// tests can `implements OidcDiscovery` to inject canned discovery
/// fixtures (constructor accepts the same fields). Equality is structural
/// (Equatable).
library;

import 'dart:convert';

import 'package:core_contracts/core_contracts.dart';
import 'package:http/http.dart' as http;

import '../errors/cli_error.dart';

/// Discovery document — every endpoint the CLI ever needs.
///
/// Not `final class` (per W0 §4.3) so command tests may implement it.
class OidcDiscovery with Equatable {
  const OidcDiscovery({
    required this.issuer,
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    required this.jwksUri,
    required this.userinfoEndpoint,
    required this.endSessionEndpoint,
    required this.revocationEndpoint,
    required this.deviceAuthorizationEndpoint,
  });

  final String issuer;
  final String authorizationEndpoint;
  final String tokenEndpoint;
  final String jwksUri;
  final String userinfoEndpoint;
  final String endSessionEndpoint;
  final String revocationEndpoint;
  final String deviceAuthorizationEndpoint;

  /// Fetches `<issuer>/.well-known/openid-configuration`, validates the
  /// `issuer` claim matches [issuer] (anti-spoof), and returns a fully
  /// populated [OidcDiscovery].
  ///
  /// HTTP non-200, malformed JSON, missing required endpoint, or issuer
  /// mismatch all surface as [Failure] with a [CliError] payload — never
  /// as a thrown exception.
  static Future<Result<OidcDiscovery>> load({
    required http.Client httpClient,
    required String issuer,
  }) async {
    final url = Uri.parse('$issuer/.well-known/openid-configuration');
    try {
      final response = await httpClient.get(url);
      if (response.statusCode != 200) {
        return Failure(
          ServerError(
            response.statusCode,
            'discovery failed: ${response.reasonPhrase ?? 'HTTP ${response.statusCode}'}',
          ),
        );
      }

      final Object? decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException catch (e) {
        return Failure(NetworkError('discovery JSON malformed: ${e.message}'));
      }

      if (decoded is! Map<String, Object?>) {
        return const Failure(
          NetworkError('discovery body is not a JSON object'),
        );
      }

      final claimedIssuer = decoded['issuer'];
      if (claimedIssuer != issuer) {
        return Failure(
          NetworkError(
            'discovery issuer mismatch: expected "$issuer", got "$claimedIssuer"',
          ),
        );
      }

      final required = <String, String>{
        'authorization_endpoint': '',
        'token_endpoint': '',
        'jwks_uri': '',
        'userinfo_endpoint': '',
        'end_session_endpoint': '',
        'revocation_endpoint': '',
        'device_authorization_endpoint': '',
      };
      for (final key in required.keys.toList()) {
        final value = decoded[key];
        if (value is! String || value.isEmpty) {
          return Failure(
            NetworkError('discovery missing required endpoint: $key'),
          );
        }
        required[key] = value;
      }

      return Success(
        OidcDiscovery(
          issuer: issuer,
          authorizationEndpoint: required['authorization_endpoint']!,
          tokenEndpoint: required['token_endpoint']!,
          jwksUri: required['jwks_uri']!,
          userinfoEndpoint: required['userinfo_endpoint']!,
          endSessionEndpoint: required['end_session_endpoint']!,
          revocationEndpoint: required['revocation_endpoint']!,
          deviceAuthorizationEndpoint:
              required['device_authorization_endpoint']!,
        ),
      );
    } on Object catch (e, stack) {
      return Failure(
        NetworkError('discovery transport failure: $e'),
        stackTrace: stack,
      );
    }
  }

  @override
  List<Object?> get props => [
    issuer,
    authorizationEndpoint,
    tokenEndpoint,
    jwksUri,
    userinfoEndpoint,
    endSessionEndpoint,
    revocationEndpoint,
    deviceAuthorizationEndpoint,
  ];
}
