/// Token endpoint client — code-for-tokens exchange + refresh-token rotation.
///
/// Both endpoints are PKCE-only — `client_secret` MUST NEVER appear in the
/// form body (spike §5.8 + §5.9). Failures are normalised to [CliError]
/// variants; `RefreshTokenInvalidError` is the special case that drives
/// `auth refresh` exit code 7.
library;

import 'dart:convert';

import 'package:core_contracts/core_contracts.dart';
import 'package:http/http.dart' as http;

import '../config/oidc_config.dart';
import '../errors/cli_error.dart';
import 'oidc_discovery.dart';

/// Token-endpoint response shape.
final class TokenResponse with Equatable {
  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.idToken,
    required this.tokenType,
    required this.expiresIn,
  });

  final String accessToken;
  final String refreshToken;
  final String idToken;
  final String tokenType;
  final Duration expiresIn;

  @override
  List<Object?> get props => [
    accessToken,
    refreshToken,
    idToken,
    tokenType,
    expiresIn,
  ];
}

/// Thin POST-only client around the discovery `tokenEndpoint`.
///
/// `class` (not `final class`) so command-level orchestration tests
/// `implements TokenClient` to inject canned exchange/refresh Results.
class TokenClient {
  TokenClient({
    required OidcDiscovery discovery,
    required http.Client httpClient,
  }) : _discovery = discovery,
       _httpClient = httpClient;

  final OidcDiscovery _discovery;
  final http.Client _httpClient;

  /// Public read of the discovery doc this client is bound to.
  OidcDiscovery get discovery => _discovery;

  /// Trades a `code` (from the loopback callback) plus the matching PKCE
  /// `code_verifier` for an access/refresh/id token triple.
  Future<Result<TokenResponse>> exchangeCode({
    required String code,
    required String codeVerifier,
    required String redirectUri,
    String clientId = OidcConfig.clientId,
  }) {
    return _post({
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': redirectUri,
      'client_id': clientId,
      'code_verifier': codeVerifier,
    });
  }

  /// Rotates the refresh token. Zitadel returns a new refresh_token on
  /// every call; the previous one is invalidated server-side.
  Future<Result<TokenResponse>> refresh({
    required String refreshToken,
    String clientId = OidcConfig.clientId,
    String scopes = OidcConfig.scopes,
  }) {
    return _post({
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
      'client_id': clientId,
      'scope': scopes,
    });
  }

  Future<Result<TokenResponse>> _post(Map<String, String> form) async {
    try {
      final response = await _httpClient.post(
        Uri.parse(_discovery.tokenEndpoint),
        headers: const {'content-type': 'application/x-www-form-urlencoded'},
        body: form,
      );

      if (response.statusCode == 200) {
        return _parseSuccess(response.body);
      }
      return _parseError(response.statusCode, response.body);
    } on Object catch (e, stack) {
      return Failure(
        NetworkError('token endpoint transport failure: $e'),
        stackTrace: stack,
      );
    }
  }

  Result<TokenResponse> _parseSuccess(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
      // ignore: unused_catch_stack
    } on FormatException catch (e, st) {
      return Failure(NetworkError('token JSON malformed: ${e.message}'));
    }
    if (decoded is! Map<String, Object?>) {
      return const Failure(NetworkError('token body is not a JSON object'));
    }

    final accessToken = decoded['access_token'];
    final refreshToken = decoded['refresh_token'];
    final idToken = decoded['id_token'];
    final tokenType = decoded['token_type'];
    final expiresIn = decoded['expires_in'];

    if (accessToken is! String ||
        refreshToken is! String ||
        idToken is! String ||
        tokenType is! String ||
        expiresIn is! num) {
      return const Failure(
        NetworkError('token response missing required fields'),
      );
    }

    return Success(
      TokenResponse(
        accessToken: accessToken,
        refreshToken: refreshToken,
        idToken: idToken,
        tokenType: tokenType,
        expiresIn: Duration(seconds: expiresIn.toInt()),
      ),
    );
  }

  Result<TokenResponse> _parseError(int statusCode, String body) {
    Map<String, Object?>? errorJson;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, Object?>) {
        errorJson = decoded;
      }
    } on FormatException {
      errorJson = null;
    }

    final error = errorJson?['error']?.toString() ?? '';
    final description = errorJson?['error_description']?.toString() ?? '';

    if (statusCode == 400 &&
        error == 'invalid_grant' &&
        description.contains('RefreshTokenInvalid')) {
      return Failure(RefreshTokenInvalidError(description));
    }

    if (statusCode >= 500) {
      return Failure(
        ServerError(
          statusCode,
          description.isEmpty
              ? 'token endpoint failed: HTTP $statusCode'
              : description,
        ),
      );
    }

    final message = description.isEmpty
        ? (error.isEmpty ? 'token endpoint failed' : error)
        : '$error: $description';
    return Failure(ServerError(statusCode, message));
  }
}
