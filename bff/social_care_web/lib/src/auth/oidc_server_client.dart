import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../config/server_config.dart';

/// Exception thrown when an OIDC operation fails.
class OidcException implements Exception {
  const OidcException({
    required this.error,
    this.errorDescription,
    this.statusCode,
  });

  /// OAuth2 error code (e.g., `invalid_grant`).
  final String error;

  /// Human-readable description of the error.
  final String? errorDescription;

  /// HTTP status code of the response, if available.
  final int? statusCode;

  @override
  String toString() =>
      'OidcException($error${errorDescription != null ? ': $errorDescription' : ''})';
}

/// Response from the OIDC token endpoint.
class TokenResponse {
  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.idToken,
    required this.expiresIn,
  });

  final String accessToken;
  final String refreshToken;
  final String idToken;
  final int expiresIn;
}

/// Server-side OIDC client for Confidential Client flow with Zitadel.
///
/// Handles authorization URL generation, code exchange, token refresh,
/// and token revocation -- all server-side with client_secret.
class OidcServerClient {
  OidcServerClient({required ServerConfig config, http.Client? httpClient})
    : _config = config,
      _httpClient = httpClient ?? http.Client();

  final ServerConfig _config;
  final http.Client _httpClient;

  /// Authorization endpoint derived from issuer.
  Uri get _authorizationEndpoint =>
      Uri.parse('${_config.oidcIssuer}/oauth/v2/authorize');

  /// Token endpoint derived from issuer.
  Uri get _tokenEndpoint => Uri.parse('${_config.oidcIssuer}/oauth/v2/token');

  /// Revocation endpoint derived from issuer.
  Uri get _revocationEndpoint =>
      Uri.parse('${_config.oidcIssuer}/oauth/v2/revoke');

  /// Builds the authorization URL to redirect the user to Zitadel.
  ///
  /// Includes client_id, redirect_uri, response_type=code, scope, and state.
  /// Also uses PKCE (code_challenge) for extra security even with confidential client.
  Uri buildAuthorizationUrl({
    required String state,
    required String codeVerifier,
  }) {
    final codeChallenge = _generateCodeChallenge(codeVerifier);

    return _authorizationEndpoint.replace(
      queryParameters: {
        'client_id': _config.oidcClientId,
        'redirect_uri': _config.oidcRedirectUri,
        'response_type': 'code',
        'scope': 'openid profile email offline_access '
            'urn:zitadel:iam:org:project:roles '
            'urn:zitadel:iam:org:project:id:zitadel:aud',
        'state': state,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
      },
    );
  }

  /// Exchanges an authorization code for tokens.
  ///
  /// POST to token endpoint with:
  /// - grant_type=authorization_code
  /// - code, redirect_uri, client_id, client_secret, code_verifier (PKCE)
  Future<TokenResponse> exchangeCode(
    String code, {
    required String codeVerifier,
  }) async {
    final response = await _httpClient.post(
      _tokenEndpoint,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': _config.oidcRedirectUri,
        'client_id': _config.oidcClientId,
        'client_secret': _config.oidcClientSecret,
        'code_verifier': codeVerifier,
      },
    );

    return _parseTokenResponse(response);
  }

  /// Refreshes tokens using a refresh token.
  Future<TokenResponse> refreshToken(String refreshToken) async {
    final response = await _httpClient.post(
      _tokenEndpoint,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': _config.oidcClientId,
        'client_secret': _config.oidcClientSecret,
      },
    );

    return _parseTokenResponse(response);
  }

  /// Revokes a token (access or refresh).
  Future<void> revokeToken(String token) async {
    await _httpClient.post(
      _revocationEndpoint,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'token': token,
        'client_id': _config.oidcClientId,
        'client_secret': _config.oidcClientSecret,
      },
    );
  }

  /// Parses ID token claims without verification.
  ///
  /// BFF trusts its own token endpoint response received over HTTPS,
  /// so no signature verification is needed.
  Map<String, dynamic> parseIdTokenClaims(String idToken) {
    final parts = idToken.split('.');
    if (parts.length != 3) {
      throw const FormatException('Invalid JWT format');
    }

    final payload = parts[1];
    // Add padding if needed for base64 decoding
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    return jsonDecode(decoded) as Map<String, dynamic>;
  }

  /// Generates S256 code challenge from a code verifier.
  String _generateCodeChallenge(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier));
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// Parses a token endpoint response, throwing [OidcException] on error.
  TokenResponse _parseTokenResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw OidcException(
        error: body['error'] as String? ?? 'unknown_error',
        errorDescription: body['error_description'] as String?,
        statusCode: response.statusCode,
      );
    }

    return TokenResponse(
      accessToken: body['access_token'] as String,
      refreshToken: body['refresh_token'] as String,
      idToken: body['id_token'] as String,
      expiresIn: body['expires_in'] as int,
    );
  }
}
