/// Shared test helpers for BearerAuthMiddleware.
///
/// Provides RSA keypair generation, JWT builders, JWKS fixtures, and a
/// `FakeJwksClient` so middleware tests stay deterministic (no network,
/// no clock drift, no real Zitadel).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart' as djw;
import 'package:pointycastle/export.dart' as pc;
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/auth/jwks_client.dart';
import 'package:social_care_web/src/auth/session_store.dart';
import 'package:social_care_web/src/config/server_config.dart';
import 'package:social_care_web/src/middleware/session_middleware.dart';

import '_bearer_test_fixtures.dart';

// ---------------------------------------------------------------------------
// RSA key pair (lazy, per-process singleton)
// ---------------------------------------------------------------------------

/// Carries the PointyCastle RSA pair plus pre-rendered JWK n/e components.
///
/// We hold the *raw* PointyCastle keys so dart_jsonwebtoken can sign without
/// us having to ship a full PEM serializer in tests.
class TestRsaKeyPair {
  TestRsaKeyPair({
    required this.privateKey,
    required this.publicKey,
    required this.modulusBase64Url,
    required this.exponentBase64Url,
  });

  final pc.RSAPrivateKey privateKey;
  final pc.RSAPublicKey publicKey;

  /// Base64url-encoded modulus `n` for JWKS payload.
  final String modulusBase64Url;

  /// Base64url-encoded exponent `e` for JWKS payload.
  final String exponentBase64Url;
}

TestRsaKeyPair? _primaryKeyPair;
TestRsaKeyPair? _secondaryKeyPair;

/// Primary signing key (kid = [kValidKid]).
TestRsaKeyPair primaryKeyPair() => _primaryKeyPair ??= _generateRsaKeyPair();

/// Secondary signing key (kid = [kSecondaryKid]).
TestRsaKeyPair secondaryKeyPair() =>
    _secondaryKeyPair ??= _generateRsaKeyPair();

TestRsaKeyPair _generateRsaKeyPair() {
  final secureRandom = pc.SecureRandom('Fortuna')
    ..seed(pc.KeyParameter(_seedBytes()));
  final params = pc.RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64);
  final keyGen = pc.RSAKeyGenerator()
    ..init(pc.ParametersWithRandom(params, secureRandom));
  final pair = keyGen.generateKeyPair();
  final priv = pair.privateKey;
  final pub = pair.publicKey;
  return TestRsaKeyPair(
    privateKey: priv,
    publicKey: pub,
    modulusBase64Url: _bigIntToBase64Url(pub.modulus!),
    exponentBase64Url: _bigIntToBase64Url(pub.exponent!),
  );
}

Uint8List _seedBytes() {
  final r = Random.secure();
  return Uint8List.fromList(List<int>.generate(32, (_) => r.nextInt(256)));
}

String _bigIntToBase64Url(BigInt value) {
  final bytes = _bigIntToBytes(value);
  return base64Url.encode(bytes).replaceAll('=', '');
}

Uint8List _bigIntToBytes(BigInt value) {
  var hex = value.toRadixString(16);
  if (hex.length.isOdd) hex = '0$hex';
  final bytes = <int>[];
  for (var i = 0; i < hex.length; i += 2) {
    bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
  }
  return Uint8List.fromList(bytes);
}

// ---------------------------------------------------------------------------
// JWT builder (compact serialisation)
// ---------------------------------------------------------------------------

/// Builds a compact JWT with full control over header, payload and signing.
///
/// Defaults produce a *valid* token (alg RS256, all required claims, exp +1h).
/// Each test overrides exactly the field under examination.
///
/// Override behaviour:
/// - Passing a key with value `null` in [headerOverrides] / [payloadOverrides]
///   removes that field entirely (used to model "claim absent" tests).
String buildJwt({
  Map<String, dynamic>? headerOverrides,
  Map<String, dynamic>? payloadOverrides,
  TestRsaKeyPair? signingKey,
  String? alg,
  String? kid,
  bool stripSignature = false,
  String? rawSignatureOverride,
  DateTime? now,
}) {
  final keyPair = signingKey ?? primaryKeyPair();
  final t = now ?? kNow;
  final iat = t.millisecondsSinceEpoch ~/ 1000;
  final exp = t.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;

  final header = <String, dynamic>{
    'alg': alg ?? 'RS256',
    'typ': 'JWT',
    'kid': kid ?? kValidKid,
  };
  if (headerOverrides != null) {
    headerOverrides.forEach((k, v) {
      if (v == null) {
        header.remove(k);
      } else {
        header[k] = v;
      }
    });
  }

  final payload = <String, dynamic>{
    'iss': kValidIssuer,
    'sub': kValidSubject,
    'aud': kValidCliClientId,
    'azp': kValidCliClientId,
    'iat': iat,
    'exp': exp,
    kJwtRolesClaim: {
      'social_worker': {'role-id-1': 'org-id'},
    },
  };
  if (payloadOverrides != null) {
    payloadOverrides.forEach((k, v) {
      if (v == null) {
        payload.remove(k);
      } else {
        payload[k] = v;
      }
    });
  }

  final encodedHeader = _b64UrlJson(header);
  final encodedPayload = _b64UrlJson(payload);
  final signingInput = '$encodedHeader.$encodedPayload';

  if (stripSignature) {
    return '$signingInput.';
  }
  if (rawSignatureOverride != null) {
    return '$signingInput.$rawSignatureOverride';
  }

  // Use dart_jsonwebtoken's RSAPrivateKey.raw — accepts the PointyCastle
  // key directly so we don't need a PEM serializer.
  final djwKey = djw.RSAPrivateKey.raw(keyPair.privateKey);
  final signature = djw.JWTAlgorithm.RS256.sign(
    djwKey,
    Uint8List.fromList(utf8.encode(signingInput)),
  );
  final encodedSig = base64Url.encode(signature).replaceAll('=', '');
  return '$signingInput.$encodedSig';
}

String _b64UrlJson(Object data) {
  return base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');
}

// ---------------------------------------------------------------------------
// JWKS fixture
// ---------------------------------------------------------------------------

/// Builds a JWKS JSON document containing one or more RSA public keys.
String buildJwksJson(List<({String kid, TestRsaKeyPair pair})> keys) {
  final entries = keys
      .map(
        (k) => {
          'kty': 'RSA',
          'use': 'sig',
          'alg': 'RS256',
          'kid': k.kid,
          'n': k.pair.modulusBase64Url,
          'e': k.pair.exponentBase64Url,
        },
      )
      .toList();
  return jsonEncode({'keys': entries});
}

// ---------------------------------------------------------------------------
// FakeJwksClient — controllable fake for JwksClient
// ---------------------------------------------------------------------------

/// Records every call and lets tests pre-program responses (success, timeout,
/// malformed JSON, empty keys, post-rotation refresh).
class FakeJwksClient implements JwksClient {
  FakeJwksClient({String? initialJson}) : _currentJson = initialJson;

  String? _currentJson;
  Duration? _injectedDelay;
  Object? _throwOnNext;

  /// Total number of `fetch()` calls received.
  int callCount = 0;

  /// Set the JSON the next fetch should return.
  // ignore: avoid_setters_without_getters
  set jwksJson(String value) => _currentJson = value;

  /// Inject an artificial delay before the next response.
  void injectDelay(Duration delay) => _injectedDelay = delay;

  /// Make the next [fetch] throw [error].
  void throwOnNext(Object error) => _throwOnNext = error;

  @override
  Future<String> fetch() async {
    callCount += 1;
    if (_injectedDelay != null) {
      final d = _injectedDelay!;
      _injectedDelay = null;
      await Future<void>.delayed(d);
    }
    if (_throwOnNext != null) {
      final err = _throwOnNext!;
      _throwOnNext = null;
      throw err;
    }
    final json = _currentJson;
    if (json == null) {
      throw StateError('FakeJwksClient: no JWKS JSON configured');
    }
    return json;
  }
}

// ---------------------------------------------------------------------------
// Test ServerConfig builder
// ---------------------------------------------------------------------------

/// Build a ServerConfig with the bearer-related fields the middleware needs.
///
/// IMPORTANT — RED: ServerConfig today does NOT carry `oidcCliClientId`,
/// `bearerLeewaySeconds`, `jwksCacheTtl`, `bearerMaxTokenBytes`. W1 must add
/// them per ticket C00 §"Update server_config.dart". This helper invokes
/// the future API; calls fail to compile until then.
ServerConfig buildTestServerConfig({
  String issuer = kValidIssuer,
  String cliClientId = kValidCliClientId,
  String sessionSecret = kSessionSecret,
  Duration? bearerLeeway,
  Duration? jwksCacheTtl,
  int? bearerMaxTokenBytes,
}) {
  return ServerConfig(
    port: 8081,
    host: '0.0.0.0',
    apiBaseUrl: 'http://api.local',
    peopleContextBaseUrl: 'http://people.local',
    oidcIssuer: issuer,
    oidcClientId: 'web-client-id',
    oidcClientSecret: 'web-client-secret',
    oidcRedirectUri: 'http://localhost/auth/callback',
    sessionSecret: sessionSecret,
    oidcCliClientId: cliClientId,
    bearerLeewaySeconds: (bearerLeeway ?? kDefaultLeeway).inSeconds,
    jwksCacheTtl: jwksCacheTtl ?? const Duration(minutes: 10),
    bearerMaxTokenBytes: bearerMaxTokenBytes ?? kMaxTokenBytes,
  );
}

// ---------------------------------------------------------------------------
// Middleware invocation harness
// ---------------------------------------------------------------------------

/// Captured outcome of one middleware run.
class MiddlewareCallResult {
  MiddlewareCallResult({
    required this.response,
    required this.session,
    required this.handlerInvoked,
  });

  final Response response;

  /// Session that landed in `request.context` (or null).
  final Session? session;

  /// Whether the inner handler was reached at all.
  final bool handlerInvoked;
}

/// Run [middleware] against a single GET request with optional headers and
/// return everything the test typically asserts on.
Future<MiddlewareCallResult> callBearer(
  Middleware middleware, {
  String? authHeader,
  String? cookieHeader,
  String path = '/whoami',
}) async {
  Session? captured;
  var invoked = false;

  Future<Response> inner(Request request) async {
    invoked = true;
    captured = request.context[sessionContextKey] as Session?;
    return Response.ok('inner-ok');
  }

  final pipeline = const Pipeline().addMiddleware(middleware).addHandler(inner);

  final headers = <String, String>{
    'Authorization': ?authHeader,
    'Cookie': ?cookieHeader,
  };

  final request = Request(
    'GET',
    Uri.parse('http://localhost$path'),
    headers: headers,
  );
  final response = await pipeline(request);

  return MiddlewareCallResult(
    response: response,
    session: captured,
    handlerInvoked: invoked,
  );
}

// ---------------------------------------------------------------------------
// Assertion helpers
// ---------------------------------------------------------------------------

/// Asserts the response is a generic 401 with the canonical body shape
/// `{code: "AUTH-001", message: "Invalid credentials"}` and no oracle leak.
Future<void> expectGenericAuthError(
  Response r, {
  List<String> mustNotContain = const <String>[],
}) async {
  expect(
    r.statusCode,
    equals(401),
    reason: 'every Bearer rejection must be 401 (no 403/400/500 leak)',
  );
  expect(
    r.headers['content-type'],
    contains('application/json'),
    reason: 'error body must be JSON',
  );

  final raw = await r.readAsString();
  final body = jsonDecode(raw) as Map<String, dynamic>;

  expect(
    body,
    containsPair('code', 'AUTH-001'),
    reason: 'constraint #10 — generic error code',
  );
  expect(
    body,
    containsPair('message', 'Invalid credentials'),
    reason: 'constraint #10 — generic message, no validation reason',
  );

  for (final forbidden in mustNotContain) {
    expect(
      raw,
      isNot(contains(forbidden)),
      reason: 'must not leak: $forbidden',
    );
  }
  for (final phrase in const [
    'expired',
    'signature',
    'invalid alg',
    'kid not found',
    'audience',
    'issuer',
  ]) {
    expect(
      raw.toLowerCase(),
      isNot(contains(phrase)),
      reason: 'constraint #10 — body must not name claim "$phrase"',
    );
  }
}

/// Compute the expected HMAC-SHA256-derived session id (constraint #3).
String expectedHmacSessionId({
  required String secret,
  required String sub,
  required int iat,
}) {
  final hmac = crypto.Hmac(crypto.sha256, utf8.encode(secret));
  final mac = hmac.convert(utf8.encode('$sub:$iat')).bytes;
  return base64Url.encode(mac).replaceAll('=', '');
}

/// Compute `sha256(input)` as a lowercase hex string.
///
/// Used by the negative HMAC assertion (Test #56) to forbid the naive
/// `session.id = sha256(token)` implementation. The exact encoding
/// (hex vs base64url) does not matter — the contract is "session id must
/// not equal *any* deterministic transform of the raw token".
String sha256Hex(String input) {
  final digest = crypto.sha256.convert(utf8.encode(input));
  return digest.toString();
}

/// Compute `sha256(input)` as a base64url string (no padding).
///
/// Belt-and-suspenders companion to [sha256Hex] — covers the case where
/// W1 might pick base64url over hex. Used by Test #56.
String sha256Base64Url(String input) {
  final digest = crypto.sha256.convert(utf8.encode(input));
  return base64Url.encode(digest.bytes).replaceAll('=', '');
}

/// 4-segment token shape (resembles JWE) used by Test #12.
String build4SegmentToken() => 'a.b.c.d';

/// Convenience: a JWT that is *valid in every respect except* the field under
/// test.  Each test typically calls this with a single override.
String buildValidJwt({
  Map<String, dynamic>? headerOverrides,
  Map<String, dynamic>? payloadOverrides,
  TestRsaKeyPair? signingKey,
  String? kid,
}) {
  return buildJwt(
    headerOverrides: headerOverrides,
    payloadOverrides: payloadOverrides,
    signingKey: signingKey,
    kid: kid,
  );
}

/// Bearer Authorization header from a token string.
String bearer(String token) => 'Bearer $token';
