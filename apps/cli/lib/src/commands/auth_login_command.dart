/// `acdg auth login` — drive the PKCE Loopback handshake and persist the
/// resulting [OidcSession].
///
/// Orchestration sequence (spike §5.1..§5.8):
///
/// 1. Discovery (`<issuer>/.well-known/openid-configuration`).
/// 2. Generate PKCE pair + state + nonce.
/// 3. Bind loopback listener on an OS-assigned port.
/// 4. Build authorize URL with `prompt=login` + S256 challenge + scopes.
/// 5. Print URL to stdout (so SSH/CI users can copy-paste).
/// 6. Open browser via injected [browserOpener].
/// 7. Await loopback callback — `Result<String>` of the captured `code`.
/// 8. Exchange code at the token endpoint.
/// 9. Decode the id_token (no signature verification — that's the BFF's job)
///    and extract `sub`, `email`, roles into an [OidcSession].
/// 10. Persist via [credentialStore.write].
///
/// Every failure short-circuits to a non-zero exit and MUST NOT save a
/// partial session.
library;

import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../config/oidc_config.dart';
import '../oidc/loopback_listener.dart';
import '../oidc/oidc_discovery.dart';
import '../oidc/pkce_pair.dart';
import '../oidc/token_client.dart';
import '../session/credential_store.dart';
import '../session/oidc_session.dart';

/// `acdg auth login` — see file-level docstring.
final class AuthLoginCommand extends Command<int> {
  AuthLoginCommand({
    required this.discoveryLoader,
    required this.pkceFactory,
    required this.listenerFactory,
    required this.tokenClientFactory,
    required this.credentialStore,
    required this.browserOpener,
    required this.stateNonceFactory,
    this.stdout,
    this.stderr,
  });

  final Future<Result<OidcDiscovery>> Function() discoveryLoader;
  final PkcePair Function() pkceFactory;
  final LoopbackListener Function({required String expectedState})
  listenerFactory;
  final TokenClient Function(OidcDiscovery) tokenClientFactory;
  final CredentialStore credentialStore;
  final Future<void> Function(Uri) browserOpener;
  final ({String state, String nonce}) Function() stateNonceFactory;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'login';

  @override
  String get description =>
      'Authenticate via OIDC (PKCE Loopback against Zitadel)';

  @override
  Future<int> run() async {
    final discoveryResult = await discoveryLoader();
    final discovery = switch (discoveryResult) {
      Success(:final value) => value,
      Failure(:final error) => () {
        _writeErr('Discovery failed: $error');
        return null;
      }(),
    };
    if (discovery == null) return 1;

    final pkce = pkceFactory();
    final sn = stateNonceFactory();
    final listener = listenerFactory(expectedState: sn.state);

    final port = await listener.bindEphemeralPort();
    final redirectUri = OidcConfig.redirectUriFor(port);

    final authorizeUrl = _buildAuthorizeUrl(
      endpoint: discovery.authorizationEndpoint,
      redirectUri: redirectUri,
      challenge: pkce.challenge,
      state: sn.state,
      nonce: sn.nonce,
    );

    _writeOut(
      'Open this URL in your browser if it does not open automatically:',
    );
    _writeOut(authorizeUrl.toString());

    await browserOpener(authorizeUrl);

    final callbackResult = await listener.awaitCallback();
    final code = switch (callbackResult) {
      Success(:final value) => value,
      Failure(:final error) => () {
        _writeErr('Login failed: $error');
        return null;
      }(),
    };
    if (code == null) return 2;

    final tokenClient = tokenClientFactory(discovery);
    final exchange = await tokenClient.exchangeCode(
      code: code,
      codeVerifier: pkce.verifier,
      redirectUri: redirectUri,
    );

    final tokens = switch (exchange) {
      Success(:final value) => value,
      Failure(:final error) => () {
        _writeErr('Token exchange failed: $error');
        return null;
      }(),
    };
    if (tokens == null) return 3;

    final claims = _decodeIdTokenClaims(
      tokens.idToken,
      expectedNonce: sn.nonce,
    );
    if (claims == null) {
      _writeErr(
        'Token exchange succeeded but id_token is malformed or nonce '
        'mismatch — possible replay attack.',
      );
      return 4;
    }

    final session = OidcSession(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      idToken: tokens.idToken,
      accessExpiresAt: DateTime.now().toUtc().add(tokens.expiresIn),
      sub: claims.sub,
      email: claims.email,
      roles: claims.roles,
    );

    await credentialStore.write(session);

    _writeOut('Logged in as ${session.email}');
    if (session.roles.isNotEmpty) {
      _writeOut('Roles: ${session.roles.join(', ')}');
    }
    _writeOut(
      'Session valid until ${session.accessExpiresAt.toIso8601String()}.',
    );
    return 0;
  }

  Uri _buildAuthorizeUrl({
    required String endpoint,
    required String redirectUri,
    required String challenge,
    required String state,
    required String nonce,
  }) {
    final base = Uri.parse(endpoint);
    return base.replace(
      queryParameters: <String, String>{
        ...base.queryParameters,
        'response_type': 'code',
        'client_id': OidcConfig.clientId,
        'redirect_uri': redirectUri,
        'scope': OidcConfig.scopes,
        'state': state,
        'nonce': nonce,
        'code_challenge': challenge,
        'code_challenge_method': PkcePair.method,
        'prompt': OidcConfig.authorizePrompt,
      },
    );
  }

  void _writeOut(String line) {
    final out = stdout;
    if (out != null) out.writeln(line);
  }

  void _writeErr(String line) {
    final err = stderr ?? stdout;
    if (err != null) err.writeln(line);
  }
}

/// Decoded claims from the id_token. The CLI only reads them locally; the
/// BFF Bearer middleware (C00) is the source of truth for security.
final class _IdTokenClaims {
  const _IdTokenClaims({
    required this.sub,
    required this.email,
    required this.roles,
  });
  final String sub;
  final String email;
  final List<String> roles;
}

_IdTokenClaims? _decodeIdTokenClaims(
  String idToken, {
  required String expectedNonce,
}) {
  final segments = idToken.split('.');
  if (segments.length < 2) return null;
  final payloadB64 = _padBase64Url(segments[1]);
  final Map<String, Object?> payload;
  try {
    payload =
        jsonDecode(utf8.decode(base64Url.decode(payloadB64)))
            as Map<String, Object?>;
  } on FormatException {
    return null;
  } on Object {
    return null;
  }

  final sub = (payload['sub'] ?? '').toString();
  final email = (payload['email'] ?? '').toString();
  final nonce = payload['nonce'];
  if (sub.isEmpty || email.isEmpty) return null;
  if (nonce != expectedNonce) return null;

  final rolesNode =
      payload[OidcConfig.rolesClaim] ??
      payload[OidcConfig.rolesClaimProjectSpecific];
  final roles = rolesNode is Map<String, Object?>
      ? (rolesNode.keys.map((e) => e.toString()).toList(growable: false)
          ..sort())
      : const <String>[];

  return _IdTokenClaims(sub: sub, email: email, roles: roles);
}

String _padBase64Url(String input) {
  final pad = (4 - input.length % 4) % 4;
  return input + ('=' * pad);
}
