import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart' as djw;
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

import '../auth/jwks_cache.dart';
import '../auth/session_store.dart';
import '../config/server_config.dart';

/// Context key under which the [Session] derived from a valid Bearer JWT
/// is exposed to downstream handlers.
///
/// Distinct from `sessionContextKey` (cookie-derived) by design: the D5
/// 4-state matrix mandates that Bearer and cookie sessions never live in
/// the same slot, so a downstream consumer that mistakenly reads the
/// wrong key cannot cross-attribute roles or identity (W0.5 S1).
const String bearerSessionContextKey = 'bearer_session';

/// Allowlist for the JOSE `alg` header — Zitadel signs with RS256.
/// Anything else (including `none`, `None`, `""`, HS256, HS512) is
/// rejected before any verify call (CVE-2015-9235 / RFC 8725 §3.1).
const Set<String> _allowedAlgs = <String>{'RS256'};

/// Allowlist for the JOSE `typ` header — RFC 8725 §3.11.
const Set<String> _allowedTyps = <String>{'JWT'};

/// Maximum allowed JSON depth in the JWT payload (DoS guard, constraint #39).
const int _maxJsonDepth = 10;

/// Hard cap on roles parsed from the JWT (memory-amplification guard,
/// constraint #40). Tokens with more roles are rejected.
const int _maxRoles = 256;

/// Zitadel claim path for project roles (D3, mirrors Swift backend).
const String _kZitadelRolesClaim = 'urn:zitadel:iam:org:project:roles';

/// Generic 401 body — constraint #10. Identical for every rejection
/// reason so the response carries no oracle.
final List<int> _genericAuthBody = utf8.encode(
  jsonEncode(<String, String>{
    'code': 'AUTH-001',
    'message': 'Invalid credentials',
  }),
);

final Logger _log = Logger('bearer_auth_middleware');

/// Builds a shelf [Middleware] that authenticates `Authorization: Bearer <jwt>`
/// requests against Zitadel-issued RS256 JWTs.
///
/// On success: populates `request.context[bearerSessionContextKey]` with a
/// fresh [Session] and forwards to the inner handler — but with the `Cookie`
/// header stripped so the downstream `sessionMiddleware` does NOT also
/// populate the cookie session (D5 matrix row 2; W0.5 S1).
///
/// On failure: returns a 401 with the canonical `{code: AUTH-001, message:
/// "Invalid credentials"}` body (constraint #10) — no oracle, no claim
/// names, no validation reason. The inner handler is never invoked
/// (D5 matrix row 3; W0.5 Lacuna 3).
///
/// On absence: forwards the request unchanged. Downstream `sessionMiddleware`
/// gets to try the cookie path (D5 matrix row 1).
Middleware bearerAuthMiddleware({
  required ServerConfig config,
  required JwksCache jwksCache,
  DateTime Function()? clock,
}) {
  final clockFn = clock ?? () => DateTime.now().toUtc();
  final hmac = crypto.Hmac(crypto.sha256, utf8.encode(config.sessionSecret));

  return (Handler innerHandler) {
    return (Request request) async {
      // -----------------------------------------------------------------
      // 0. RFC 6750 §2.3 — token MUST come via Authorization header only.
      //    Reject `?access_token=...` even if Authorization is also absent
      //    (constraint #8).
      // -----------------------------------------------------------------
      if (request.url.queryParameters.containsKey('access_token')) {
        return _generic401();
      }

      // -----------------------------------------------------------------
      // 1. Authorization header → "Bearer <token>" or pass-through.
      // -----------------------------------------------------------------
      final authHeader = request.headers['authorization'];
      if (authHeader == null) {
        // D5 row 1 / row 4 — let the cookie path try.
        return innerHandler(request);
      }

      // Scheme check.  Reject `Basic`, `Digest`, etc. and `Bearer ` (empty).
      const scheme = 'Bearer ';
      if (!authHeader.startsWith(scheme)) {
        return _generic401();
      }
      final token = authHeader.substring(scheme.length);
      if (token.isEmpty) {
        return _generic401();
      }

      // Constraint #1 — 8KB cap. Trip BEFORE any parse / JWKS fetch /
      // crypto work so a JWT-bombing attacker cannot amplify CPU/network.
      // Note: `String.length` measures UTF-16 code units, not bytes.
      // For ASCII-only Bearer JWTs (RFC 6750 §2.1 restricts the syntax
      // to a base64url-ish ASCII alphabet) the two are identical, so the
      // constraint is satisfied. If non-ASCII tokens are ever permitted,
      // switch to `utf8.encode(token).length` here.
      if (token.length > config.bearerMaxTokenBytes) {
        return _generic401();
      }

      // -----------------------------------------------------------------
      // 2. Parse + validate. Returns a Session on success, null on any
      //    failure. Errors are intentionally NOT distinguished: every
      //    rejection collapses to the same 401 body (constraint #10).
      // -----------------------------------------------------------------
      Session? session;
      try {
        session = await _validate(
          token: token,
          config: config,
          jwksCache: jwksCache,
          hmac: hmac,
          now: clockFn(),
        );
      } on Object catch (error) {
        // PII safety — never log the token or its substrings.  A leaky
        // upstream exception (e.g. JwksClient threw with the session
        // secret embedded) must not reach the log line as-is, so we
        // only emit the runtime type and a fixed marker.  Test #54
        // asserts session secrets and PEM markers never reach logs.
        // The stack trace is intentionally NOT captured — it could
        // carry `toString()` representations of upstream exceptions
        // that include secrets.
        _log.warning(
          'bearer.validate.error type=${error.runtimeType} '
          'authorization=[REDACTED]',
        );
        return _generic401();
      }

      if (session == null) {
        // D5 row 3 — invalid Bearer must NOT fall through to cookie.
        return _generic401();
      }

      // -----------------------------------------------------------------
      // 3. Bearer wins. Strip the Cookie header so downstream
      //    `sessionMiddleware` does not also resolve a cookie session
      //    under `sessionContextKey` (W0.5 S1 — prevents role-mix-up
      //    via misread context key).
      //
      //    Why we cannot just pass `{'cookie': null, 'Cookie': null}`:
      //    `Request.change` delegates to shelf's `updateMap`, which does
      //    a case-SENSITIVE `Map.remove(key)` on a `LinkedHashMap.of(...)`
      //    of the original headers. The original storage uses
      //    `CaseInsensitiveMap`, but its `entries` getter yields the
      //    *original-cased* key the caller registered (e.g. `COOKIE`).
      //    Passing only `{'cookie': null, 'Cookie': null}` therefore
      //    leaves variants like `COOKIE`, `CooKie`, `cookIE` intact —
      //    and the downstream `sessionMiddleware` reads via shelf's
      //    case-insensitive `request.headers['cookie']`, picking up the
      //    smuggled value. This is a security gap (W2 Round 1 M1).
      //
      //    Fix: enumerate `request.headersAll`, collect every key whose
      //    lowercase is `'cookie'`, and request removal of EACH variant
      //    by its exact original casing. Test #44b regresses this
      //    explicitly with an uppercase `COOKIE:` header.
      // -----------------------------------------------------------------
      final cookieRemovals = <String, Object?>{};
      for (final key in request.headersAll.keys) {
        if (key.toLowerCase() == 'cookie') {
          cookieRemovals[key] = null;
        }
      }
      final forwarded = request.change(
        headers: cookieRemovals,
        context: <String, Object?>{
          ...request.context,
          bearerSessionContextKey: session,
        },
      );
      return innerHandler(forwarded);
    };
  };
}

/// Performs the full JWT validation pipeline. Returns the constructed
/// [Session] on success, `null` on any validation failure.
///
/// This function is the only place where the token is parsed; it lives
/// at the adapter boundary, so `try/catch` is allowed (PATTERN_MATCHING_POLICY
/// P2b). All rejections funnel through `null`.
Future<Session?> _validate({
  required String token,
  required ServerConfig config,
  required JwksCache jwksCache,
  required crypto.Hmac hmac,
  required DateTime now,
}) async {
  // 1. Structural — exactly 3 segments.
  final parts = token.split('.');
  if (parts.length != 3) return null;
  if (parts[0].isEmpty || parts[1].isEmpty || parts[2].isEmpty) return null;

  // 2. Decode header + payload as Maps. Any malformed base64 or JSON → null.
  final Map<String, dynamic>? header = _decodeJsonSegment(parts[0]);
  final Map<String, dynamic>? payload = _decodeJsonSegment(parts[1]);
  if (header == null || payload == null) return null;

  // 3. JSON depth guard for the payload (constraint #39).
  if (_jsonDepth(payload) > _maxJsonDepth) return null;

  // 4. Header allowlists.
  final typ = header['typ'];
  if (typ is! String || !_allowedTyps.contains(typ)) return null;

  final alg = header['alg'];
  if (alg is! String || !_allowedAlgs.contains(alg)) return null;

  // RFC 7515 §4.1.11 — `crit` extension header MUST be honoured. Since
  // we declare zero understood extensions, any value triggers rejection.
  if (header.containsKey('crit')) return null;

  final kid = header['kid'];
  if (kid is! String || kid.isEmpty) return null;

  // 5. JWKS lookup — kid is opaque, used only as a Map key (constraint #4).
  final RsaKey? key = await jwksCache.getKey(kid);
  if (key == null) return null;

  // 6. Signature verify. RS256 → RSA-SHA256.
  final Uint8List signingInput = Uint8List.fromList(
    utf8.encode('${parts[0]}.${parts[1]}'),
  );
  final Uint8List signatureBytes;
  try {
    signatureBytes = _decodeBase64UrlBytes(parts[2]);
  } on Object {
    return null;
  }

  var sigValid = djw.JWTAlgorithm.RS256.verify(
    key.publicKey,
    signingInput,
    signatureBytes,
  );

  if (!sigValid) {
    // CVE-2018-0114 mitigation — known kid but failing signature triggers
    // exactly one refresh of the JWKS in case it rotated.  After the refresh
    // we look the kid up again (could be a new key or absent) and retry once.
    await jwksCache.refresh();
    final refreshedKey = await jwksCache.getKey(kid);
    if (refreshedKey == null) return null;
    sigValid = djw.JWTAlgorithm.RS256.verify(
      refreshedKey.publicKey,
      signingInput,
      signatureBytes,
    );
    if (!sigValid) return null;
  }

  // 7. Claim validation.
  final iss = payload['iss'];
  if (iss is! String || iss != config.oidcIssuer) return null;

  final sub = payload['sub'];
  if (sub is! String || sub.isEmpty) return null;

  final iat = payload['iat'];
  if (iat is! int) return null;
  // Sanity: `iat` cannot sit absurdly far in the future. We mirror the
  // RFC 8725 recommendation by allowing leeway only in the past direction;
  // future iat is rejected if it exceeds the leeway.
  final iatTime = DateTime.fromMillisecondsSinceEpoch(iat * 1000, isUtc: true);
  final leewaySec = config.bearerLeewaySeconds;
  if (iatTime.isAfter(now.add(Duration(seconds: leewaySec)))) {
    return null;
  }

  final exp = payload['exp'];
  if (exp is! int) return null;
  final expTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
  final expWithLeeway = expTime.add(Duration(seconds: leewaySec));
  if (now.isAfter(expWithLeeway)) return null;

  if (payload.containsKey('nbf')) {
    final nbf = payload['nbf'];
    if (nbf is! int) return null;
    final nbfTime = DateTime.fromMillisecondsSinceEpoch(
      nbf * 1000,
      isUtc: true,
    );
    final nbfWithLeeway = nbfTime.subtract(Duration(seconds: leewaySec));
    if (now.isBefore(nbfWithLeeway)) return null;
  }

  // Audience: string == cliClientId, OR list contains cliClientId.
  if (!_audienceMatches(payload['aud'], config.oidcCliClientId)) {
    return null;
  }

  // azp (D7.1): if present, MUST equal cliClientId.
  if (payload.containsKey('azp')) {
    final azp = payload['azp'];
    if (azp is! String || azp != config.oidcCliClientId) return null;
  }

  // 8. Roles (Zitadel-specific). Bounded extraction, malformed shapes
  //    skipped silently — middleware does not need to fail the token
  //    over a missing role map (auth_guard handles that).
  final roles = _extractRoles(payload[_kZitadelRolesClaim]);
  if (roles == null) return null;

  // 9. Build session. Session id ladder (constraint #3):
  //    - if `jti` is present, use it verbatim;
  //    - else HMAC-SHA256(sessionSecret, "$sub:$iat") base64url, no padding.
  final String sessionId;
  final dynamic jti = payload['jti'];
  if (jti is String && jti.isNotEmpty) {
    sessionId = jti;
  } else {
    final mac = hmac.convert(utf8.encode('$sub:$iat')).bytes;
    sessionId = base64Url.encode(mac).replaceAll('=', '');
  }

  return Session(
    id: sessionId,
    accessToken: token,
    refreshToken: '',
    userId: sub,
    roles: roles,
    expiresAt: expTime,
  );
}

/// Returns true iff [aud] is either the string [cliClientId], or a List
/// that contains [cliClientId].
bool _audienceMatches(dynamic aud, String cliClientId) {
  if (cliClientId.isEmpty) return false; // misconfigured BFF — fail closed.
  if (aud is String) return aud == cliClientId;
  if (aud is List) {
    for (final entry in aud) {
      if (entry is String && entry == cliClientId) return true;
    }
    return false;
  }
  return false;
}

/// Extracts the role set from the Zitadel claim. Returns null if the
/// claim shape is invalid (signals 401 to the caller); returns an
/// empty set if the claim is absent (auth_guard will decide what to do).
///
/// Bounded to [_maxRoles] entries (constraint #40 — memory amplification
/// guard). Surplus entries are silently dropped: the resulting Session
/// keeps the first [_maxRoles] role names, which auth_guard / handlers
/// then use for authorization. Rejecting the entire token over a fat
/// roles map would be a DoS amplifier (one weird token disables the
/// caller); silent truncation preserves availability while bounding
/// memory.
Set<String>? _extractRoles(dynamic claim) {
  if (claim == null) return <String>{};
  if (claim is! Map) return null;

  final roles = <String>{};
  for (final entry in claim.entries) {
    if (roles.length >= _maxRoles) break;
    final key = entry.key;
    if (key is String && key.isNotEmpty) roles.add(key);
  }
  return roles;
}

/// Decodes a JWT segment (base64url-no-padding) as JSON. Returns null
/// on invalid base64 OR invalid JSON OR a non-Map root.
Map<String, dynamic>? _decodeJsonSegment(String segment) {
  try {
    final bytes = _decodeBase64UrlBytes(segment);
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is Map<String, dynamic>) return decoded;
    return null;
  } on Object {
    return null;
  }
}

Uint8List _decodeBase64UrlBytes(String segment) {
  final pad = (4 - segment.length % 4) % 4;
  return base64Url.decode(segment + ('=' * pad));
}

/// Computes the maximum JSON nesting depth of a decoded structure.
/// Used by the depth-bomb guard (constraint #39).
int _jsonDepth(Object? value) {
  if (value is Map) {
    var max = 1;
    for (final v in value.values) {
      final d = 1 + _jsonDepth(v);
      if (d > max) max = d;
    }
    return max;
  }
  if (value is List) {
    var max = 1;
    for (final v in value) {
      final d = 1 + _jsonDepth(v);
      if (d > max) max = d;
    }
    return max;
  }
  return 0;
}

/// Builds the canonical 401 response. Identical body for every rejection
/// path (constraint #10 — no oracle leak).
Response _generic401() {
  return Response(
    401,
    body: _genericAuthBody,
    headers: const <String, String>{'content-type': 'application/json'},
  );
}
