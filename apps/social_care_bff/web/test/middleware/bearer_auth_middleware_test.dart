/// W0 RED tests for `BearerAuthMiddleware` — Groups A, B, C, D, F, H.
///
/// These tests intentionally fail to compile until W1 (`flutter-bff-implementer`)
/// creates the production code. Each test references the ticket's numbered
/// case (e.g. "Test #1") so reviewers can map back to `000-request.md`.
///
/// Group E (resource exhaustion) lives in
/// `bearer_auth_resource_exhaustion_test.dart` to keep payload-builder noise
/// isolated. Group G (JWKS cache concurrency / rotation) lives in
/// `bearer_auth_jwks_cache_test.dart`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/auth/jwks_cache.dart';
import 'package:social_care_web/src/auth/session_store.dart';
import 'package:social_care_web/src/middleware/bearer_auth_middleware.dart';
import 'package:social_care_web/src/middleware/session_middleware.dart';

import '_bearer_test_fixtures.dart';
import '_bearer_test_helpers.dart';

void main() {
  // -------------------------------------------------------------------------
  // Shared setup (per test): clock, JWKS cache, ServerConfig, middleware.
  // -------------------------------------------------------------------------

  late JwksCache jwksCache;
  late FakeJwksClient jwksClient;
  late Middleware middleware;
  late DateTime currentTime;

  setUp(() {
    currentTime = kNow;
    jwksClient = FakeJwksClient(
      initialJson: buildJwksJson([(kid: kValidKid, pair: primaryKeyPair())]),
    );
    jwksCache = JwksCache(
      client: jwksClient,
      ttl: const Duration(minutes: 10),
      clock: () => currentTime,
    );

    middleware = bearerAuthMiddleware(
      config: buildTestServerConfig(),
      jwksCache: jwksCache,
      clock: () => currentTime,
    );
  });

  // ===========================================================================
  // Group A — Algorithm Attacks (RFC 8725 §3.1) — 6 tests
  // ===========================================================================

  group('A. Algorithm attacks (RFC 8725 §3.1)', () {
    test('Test #1: alg "none" → 401', () async {
      final token = buildJwt(
        alg: 'none',
        // Force empty signature to mirror the alg=none attack shape.
        rawSignatureOverride: '',
      );

      final result = await callBearer(middleware, authHeader: bearer(token));

      await expectGenericAuthError(result.response);
      expect(
        result.handlerInvoked,
        isFalse,
        reason: 'alg=none must be rejected before reaching the handler',
      );
    });

    test('Test #2: alg "None" (case variation) → 401', () async {
      final token = buildJwt(alg: 'None', rawSignatureOverride: '');
      final result = await callBearer(middleware, authHeader: bearer(token));
      await expectGenericAuthError(result.response);
    });

    test('Test #3: alg "" (empty) → 401', () async {
      final token = buildJwt(alg: '', rawSignatureOverride: '');
      final result = await callBearer(middleware, authHeader: bearer(token));
      await expectGenericAuthError(result.response);
    });

    test('Test #4: alg "HS256" with public key as secret → 401 '
        '(CVE-2015-9235 alg-confusion)', () async {
      // Attack shape: forge HS256 token using the JWKS public-key bytes
      // (modulus n, in the JWK base64url encoding) as the shared secret.
      // The middleware MUST refuse to call HMAC verify when the configured
      // algorithm is RS256.
      final token = _forgedSymmetricToken(
        secretMaterial: primaryKeyPair().modulusBase64Url,
        kid: kValidKid,
        alg: 'HS256',
      );

      final result = await callBearer(middleware, authHeader: bearer(token));
      await expectGenericAuthError(result.response);
    });

    test(
      'Test #5: alg "HS512" rejected (any symmetric when expecting RS256)',
      () async {
        final token = _forgedSymmetricToken(
          secretMaterial: primaryKeyPair().modulusBase64Url,
          kid: kValidKid,
          alg: 'HS512',
        );

        final result = await callBearer(middleware, authHeader: bearer(token));
        await expectGenericAuthError(result.response);
      },
    );

    test('Test #6: alg missing from header → 401', () async {
      final headerNoAlg = base64Url
          .encode(utf8.encode(jsonEncode({'typ': 'JWT', 'kid': kValidKid})))
          .replaceAll('=', '');
      final payload = base64Url
          .encode(
            utf8.encode(
              jsonEncode({
                'iss': kValidIssuer,
                'sub': kValidSubject,
                'aud': kValidCliClientId,
                'iat': kNow.millisecondsSinceEpoch ~/ 1000,
                'exp':
                    kNow.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
                    1000,
              }),
            ),
          )
          .replaceAll('=', '');
      final token = '$headerNoAlg.$payload.aaaa';

      final result = await callBearer(middleware, authHeader: bearer(token));
      await expectGenericAuthError(result.response);
    });
  });

  // ===========================================================================
  // Group B — Signature & Integrity — 6 tests
  // ===========================================================================

  group('B. Signature & integrity', () {
    test('Test #7: signature byte tampered → 401', () async {
      final original = buildValidJwt();
      final parts = original.split('.');
      final sig = parts[2];
      final tamperedSig =
          sig.substring(0, sig.length - 1) + (sig.endsWith('A') ? 'B' : 'A');
      final token = '${parts[0]}.${parts[1]}.$tamperedSig';

      final result = await callBearer(middleware, authHeader: bearer(token));
      await expectGenericAuthError(result.response);
    });

    test('Test #8: header tampered, signature recomputed with attacker key '
        '→ 401', () async {
      // Sign with secondary, but advertise primary kid → verifier must refuse.
      final token = buildJwt(kid: kValidKid, signingKey: secondaryKeyPair());

      final result = await callBearer(middleware, authHeader: bearer(token));
      await expectGenericAuthError(result.response);
    });

    test(
      'Test #9: payload tampered post-signing (role injection) → 401',
      () async {
        final original = buildValidJwt();
        final parts = original.split('.');

        final payloadBytes = base64Url.decode(_padBase64(parts[1]));
        final decoded =
            jsonDecode(utf8.decode(payloadBytes)) as Map<String, dynamic>;
        decoded[kJwtRolesClaim] = {
          'admin': {'role-id-2': 'org-id'},
        };
        final reencoded = base64Url
            .encode(utf8.encode(jsonEncode(decoded)))
            .replaceAll('=', '');

        final token = '${parts[0]}.$reencoded.${parts[2]}';
        final result = await callBearer(middleware, authHeader: bearer(token));
        await expectGenericAuthError(result.response);
      },
    );

    test('Test #10: empty signature segment → 401', () async {
      final token = buildJwt(stripSignature: true);
      final result = await callBearer(middleware, authHeader: bearer(token));
      await expectGenericAuthError(result.response);
    });

    test('Test #11: 2-part token (signature missing) → 401', () async {
      final original = buildValidJwt();
      final parts = original.split('.');
      final token = '${parts[0]}.${parts[1]}';

      final result = await callBearer(middleware, authHeader: bearer(token));
      await expectGenericAuthError(result.response);
    });

    test('Test #12: 4-part token (looks like JWE) → 401', () async {
      final result = await callBearer(
        middleware,
        authHeader: bearer(build4SegmentToken()),
      );
      await expectGenericAuthError(result.response);
    });
  });

  // ===========================================================================
  // Group C — Claims Validation — 17 tests
  // ===========================================================================

  group('C. Claims validation', () {
    test('Test #13: exp in the past → 401', () async {
      final pastExp =
          currentTime
              .subtract(const Duration(hours: 1))
              .millisecondsSinceEpoch ~/
          1000;
      final token = buildValidJwt(payloadOverrides: {'exp': pastExp});
      final result = await callBearer(middleware, authHeader: bearer(token));
      await expectGenericAuthError(result.response);
    });

    test('Test #14: exp absent → 401', () async {
      final token = buildJwt(payloadOverrides: {'exp': null});
      final result = await callBearer(middleware, authHeader: bearer(token));
      await expectGenericAuthError(result.response);
    });

    test('Test #15: exp in past within leeway (-29s) → 200', () async {
      // Realistic token: issued 1h ago, expired 29 seconds ago.
      final iat =
          currentTime
              .subtract(const Duration(hours: 1))
              .millisecondsSinceEpoch ~/
          1000;
      final exp =
          currentTime
              .subtract(const Duration(seconds: 29))
              .millisecondsSinceEpoch ~/
          1000;
      final token = buildValidJwt(payloadOverrides: {'iat': iat, 'exp': exp});
      final result = await callBearer(middleware, authHeader: bearer(token));
      expect(
        result.response.statusCode,
        equals(200),
        reason: '30s default leeway must accept -29s clock skew',
      );
      expect(result.session, isNotNull);
    });

    test('Test #16: exp in past beyond leeway (-31s) → 401', () async {
      final iat =
          currentTime
              .subtract(const Duration(hours: 1))
              .millisecondsSinceEpoch ~/
          1000;
      final exp =
          currentTime
              .subtract(const Duration(seconds: 31))
              .millisecondsSinceEpoch ~/
          1000;
      final token = buildValidJwt(payloadOverrides: {'iat': iat, 'exp': exp});
      final result = await callBearer(middleware, authHeader: bearer(token));
      await expectGenericAuthError(result.response);
    });

    test('Test #17: iat absurdly in future (>1h) → 401', () async {
      final iat =
          currentTime.add(const Duration(hours: 2)).millisecondsSinceEpoch ~/
          1000;
      final exp =
          currentTime.add(const Duration(hours: 3)).millisecondsSinceEpoch ~/
          1000;
      final token = buildValidJwt(payloadOverrides: {'iat': iat, 'exp': exp});
      final result = await callBearer(middleware, authHeader: bearer(token));
      await expectGenericAuthError(result.response);
    });

    test('Test #18: nbf in future beyond leeway → 401', () async {
      final nbf =
          currentTime.add(const Duration(seconds: 60)).millisecondsSinceEpoch ~/
          1000;
      final token = buildValidJwt(payloadOverrides: {'nbf': nbf});
      final result = await callBearer(middleware, authHeader: bearer(token));
      await expectGenericAuthError(result.response);
    });

    test('Test #19: nbf in future within leeway (+29s) → 200', () async {
      final nbf =
          currentTime.add(const Duration(seconds: 29)).millisecondsSinceEpoch ~/
          1000;
      final token = buildValidJwt(payloadOverrides: {'nbf': nbf});
      final result = await callBearer(middleware, authHeader: bearer(token));
      expect(result.response.statusCode, equals(200));
    });

    test('Test #20: nbf absent → 200 (claim is optional)', () async {
      final token = buildJwt();
      final result = await callBearer(middleware, authHeader: bearer(token));
      expect(result.response.statusCode, equals(200));
    });

    test('Test #21: iss wrong → 401', () async {
      final token = buildValidJwt(
        payloadOverrides: {'iss': 'https://attacker.example'},
      );
      final result = await callBearer(middleware, authHeader: bearer(token));
      await expectGenericAuthError(result.response);
    });

    test('Test #22: iss absent → 401', () async {
      final token = buildJwt(payloadOverrides: {'iss': null});
      final result = await callBearer(middleware, authHeader: bearer(token));
      await expectGenericAuthError(result.response);
    });

    test('Test #23: aud as string equal → 200', () async {
      final token = buildValidJwt(payloadOverrides: {'aud': kValidCliClientId});
      final result = await callBearer(middleware, authHeader: bearer(token));
      expect(result.response.statusCode, equals(200));
    });

    test('Test #24: aud as array containing → 200', () async {
      final token = buildValidJwt(
        payloadOverrides: {
          'aud': <String>['some-other-app', kValidCliClientId, 'analytics'],
        },
      );
      final result = await callBearer(middleware, authHeader: bearer(token));
      expect(result.response.statusCode, equals(200));
    });

    test('Test #25: aud as array NOT containing → 401', () async {
      final token = buildValidJwt(
        payloadOverrides: {
          'aud': <String>['some-other-app', 'analytics'],
        },
      );
      final result = await callBearer(middleware, authHeader: bearer(token));
      await expectGenericAuthError(result.response);
    });

    test('Test #26: aud absent → 401', () async {
      final token = buildJwt(payloadOverrides: {'aud': null});
      final result = await callBearer(middleware, authHeader: bearer(token));
      await expectGenericAuthError(result.response);
    });

    test('Test #27: azp ≠ client_id → 401', () async {
      final token = buildValidJwt(payloadOverrides: {'azp': kOtherClientId});
      final result = await callBearer(middleware, authHeader: bearer(token));
      await expectGenericAuthError(result.response);
    });

    test('Test #28: azp absent → 200 (claim is optional, D7.1)', () async {
      final token = buildJwt(payloadOverrides: {'azp': null});
      final result = await callBearer(middleware, authHeader: bearer(token));
      expect(result.response.statusCode, equals(200));
    });

    test('Test #29: sub absent → 401 (cannot build Session)', () async {
      final token = buildJwt(payloadOverrides: {'sub': null});
      final result = await callBearer(middleware, authHeader: bearer(token));
      await expectGenericAuthError(result.response);
    });
  });

  // ===========================================================================
  // Group D — Header & Format Attacks — 8 tests
  // ===========================================================================

  group('D. Header & format attacks', () {
    test('Test #30: typ "JWE" → 401', () async {
      final token = buildValidJwt(headerOverrides: {'typ': 'JWE'});
      final result = await callBearer(middleware, authHeader: bearer(token));
      await expectGenericAuthError(result.response);
    });

    test('Test #31: typ "JOSE+JSON" → 401', () async {
      final token = buildValidJwt(headerOverrides: {'typ': 'JOSE+JSON'});
      final result = await callBearer(middleware, authHeader: bearer(token));
      await expectGenericAuthError(result.response);
    });

    test('Test #32: crit ["unknown-ext"] → 401 (RFC 7515 §4.1.11)', () async {
      final token = buildValidJwt(
        headerOverrides: {
          'crit': <String>['unknown-ext'],
        },
      );
      final result = await callBearer(middleware, authHeader: bearer(token));
      await expectGenericAuthError(result.response);
    });

    test('Test #33: malformed JSON in any segment → 401', () async {
      final original = buildValidJwt();
      final parts = original.split('.');
      final badJson = base64Url
          .encode(utf8.encode('{"alg":"RS256","typ":"JWT"')) // missing brace
          .replaceAll('=', '');
      final token = '$badJson.${parts[1]}.${parts[2]}';

      final result = await callBearer(middleware, authHeader: bearer(token));
      await expectGenericAuthError(result.response);
    });

    test('Test #34: invalid base64 in any segment → 401', () async {
      final original = buildValidJwt();
      final parts = original.split('.');
      final token = '***.${parts[1]}.${parts[2]}';

      final result = await callBearer(middleware, authHeader: bearer(token));
      await expectGenericAuthError(result.response);
    });

    test('Test #35: kid unknown → exactly 1 JWKS refetch then 401 '
        '(no kid path interpolation, constraint #4)', () async {
      // Pre-warm the cache.
      await jwksCache.getKey(kValidKid);
      final baseline = jwksClient.callCount;

      final token = buildValidJwt(kid: 'unknown-kid');
      final result = await callBearer(middleware, authHeader: bearer(token));

      await expectGenericAuthError(result.response);
      expect(
        jwksClient.callCount - baseline,
        equals(1),
        reason:
            'unknown kid must trigger exactly one refetch (refresh-on-miss)',
      );
    });

    test('Test #36: kid absent when JWKS has multiple keys → 401', () async {
      // Reload JWKS with two keys.
      jwksClient.jwksJson = buildJwksJson([
        (kid: kValidKid, pair: primaryKeyPair()),
        (kid: kSecondaryKid, pair: secondaryKeyPair()),
      ]);
      // Force a refetch by exhausting TTL.
      currentTime = currentTime.add(const Duration(minutes: 11));
      await jwksCache.getKey(kValidKid);
      currentTime = kNow;

      final token = buildJwt(headerOverrides: {'kid': null});
      final result = await callBearer(middleware, authHeader: bearer(token));
      await expectGenericAuthError(result.response);
    });

    test(
      'Test #37: kid valid but signature from different JWKS key → 401',
      () async {
        jwksClient.jwksJson = buildJwksJson([
          (kid: kValidKid, pair: primaryKeyPair()),
          (kid: kSecondaryKid, pair: secondaryKeyPair()),
        ]);
        // Token claims kid=primary but is signed with secondary.
        final token = buildJwt(kid: kValidKid, signingKey: secondaryKeyPair());
        final result = await callBearer(middleware, authHeader: bearer(token));
        await expectGenericAuthError(result.response);
      },
    );

    // -----------------------------------------------------------------------
    // S4 hardening (W0-bis): malicious kid input falls through standard
    // "kid not found" path. Each must produce 401 with no special handling
    // (no path interpolation, no SQL, no null-byte side effects).
    //
    // We do NOT assert callCount here because the implementer may or may
    // not refresh JWKS on miss for each case. The contract is "treat as
    // unknown kid → 401 via canonical body, no oracle leak".
    // -----------------------------------------------------------------------

    test('Test #37a: kid path-traversal "../../etc/passwd" → 401 '
        '(constraint #4 — kid is opaque, no filesystem semantics)', () async {
      final token = buildValidJwt(kid: '../../etc/passwd');
      final result = await callBearer(middleware, authHeader: bearer(token));
      await expectGenericAuthError(result.response);
    });

    test(
      'Test #37b: kid null-byte injection "key1\\x00evil" → 401 '
      '(constraint #4 — kid must not be string-concatenated anywhere)',
      () async {
        final token = buildValidJwt(kid: 'key1 evil');
        final result = await callBearer(middleware, authHeader: bearer(token));
        await expectGenericAuthError(result.response);
      },
    );

    test(
      'Test #37c: kid SQL fragment "\'; DROP TABLE keys; --" → 401 '
      '(constraint #4 — paranoid coverage: kid never touches a query)',
      () async {
        final token = buildValidJwt(kid: "'; DROP TABLE keys; --");
        final result = await callBearer(middleware, authHeader: bearer(token));
        await expectGenericAuthError(result.response);
      },
    );
  });

  // ===========================================================================
  // Group F — Transport & Pipeline — 6 tests
  // ===========================================================================

  group('F. Transport & pipeline (D5 4-state matrix)', () {
    test(
      'Test #41: token in ?access_token=... → 401 (RFC 6750 §2.3)',
      () async {
        final token = buildValidJwt();

        Session? captured;
        var invoked = false;
        final pipeline = const Pipeline().addMiddleware(middleware).addHandler((
          req,
        ) async {
          invoked = true;
          captured = req.context[sessionContextKey] as Session?;
          return Response.ok('inner');
        });
        final response = await pipeline(
          Request(
            'GET',
            Uri.parse('http://localhost/whoami?access_token=$token'),
          ),
        );

        await expectGenericAuthError(response);
        expect(captured, isNull);
        expect(
          invoked,
          isFalse,
          reason:
              '?access_token=... must be hard-rejected, not silently '
              'ignored — otherwise a downstream handler may parse it.',
        );
      },
    );

    test('Test #42: scheme "Basic <token>" → 401', () async {
      final token = buildValidJwt();
      final result = await callBearer(middleware, authHeader: 'Basic $token');
      await expectGenericAuthError(result.response);
    });

    test('Test #43: scheme "Bearer " (empty token) → 401', () async {
      final result = await callBearer(middleware, authHeader: 'Bearer ');
      await expectGenericAuthError(result.response);
    });

    test('Test #44: valid Bearer + cookie → use Bearer, IGNORE cookie '
        '(D5 row 2)', () async {
      final store = SessionStore(
        ttl: const Duration(hours: 1),
        clock: () => currentTime,
      );
      final cookieSessionId = store.create(
        accessToken: 'cookie-access',
        refreshToken: 'cookie-refresh',
        userId: 'cookie-user',
        roles: {'admin'}, // distinct role to detect mix-up
      );

      final token = buildValidJwt();

      Session? resolvedSession;
      final pipeline = const Pipeline()
          .addMiddleware(middleware)
          .addMiddleware(sessionMiddleware(store))
          .addHandler((req) {
            // Post-B1: both auth paths populate the canonical
            // sessionContextKey slot. Bearer wins because the bearer
            // middleware strips the Cookie header before forwarding, so
            // sessionMiddleware never resolves the cookie session here.
            resolvedSession = req.context[sessionContextKey] as Session?;
            return Response.ok('ok');
          });

      final response = await pipeline(
        Request(
          'GET',
          Uri.parse('http://localhost/whoami'),
          headers: {
            'Authorization': bearer(token),
            'Cookie': '__Host-session=$cookieSessionId',
          },
        ),
      );

      expect(response.statusCode, equals(200));
      expect(
        resolvedSession,
        isNotNull,
        reason: 'Bearer must populate the canonical session slot',
      );
      expect(
        resolvedSession!.userId,
        equals(kValidSubject),
        reason: 'session.userId comes from JWT sub, not cookie',
      );
      expect(
        resolvedSession!.roles,
        contains('social_worker'),
        reason: 'roles come from JWT, not cookie',
      );
      // SEC: W0.5 S1 invariant — cookie role MUST NOT bleed into the
      // bearer-derived session. Post-B1 unification, this check is the
      // primary guarantor that the bearer middleware stripped the Cookie
      // header before sessionMiddleware ran (otherwise sessionMiddleware
      // would have overwritten the bearer Session under sessionContextKey
      // with the cookie one carrying the "admin" role).
      expect(
        resolvedSession!.roles,
        isNot(contains('admin')),
        reason: 'cookie role must NOT bleed into bearer-derived session',
      );
    });

    test('Test #44b: valid Bearer + COOKIE (uppercase) → cookie stripped '
        'regardless of header casing (W2 Round 1 M1 regression)', () async {
      // Regression for W2 Round 1 M1: shelf's `Request.change(headers: ...)`
      // delegates to a case-SENSITIVE `Map.remove(key)`, so a naive strip
      // that only nulls `'cookie'` and `'Cookie'` leaves variants like
      // `COOKIE`, `CooKie`, `cookIE` intact. The downstream
      // `sessionMiddleware` then resolves the smuggled cookie via shelf's
      // case-INSENSITIVE `request.headers['cookie']` lookup, defeating
      // the W0.5 S1 contract pinned by Test #44.
      //
      // This test exercises the adversarial casing path that Test #44
      // does not: a stolen cookie smuggled under `COOKIE:` while the
      // attacker also presents a valid Bearer. The cookie must NOT
      // surface under `sessionContextKey` even though Bearer wins.
      final store = SessionStore(
        ttl: const Duration(hours: 1),
        clock: () => currentTime,
      );
      final cookieSessionId = store.create(
        accessToken: 'cookie-access',
        refreshToken: 'cookie-refresh',
        userId: 'cookie-user',
        roles: {'admin'}, // distinct role to detect mix-up
      );

      final token = buildValidJwt();

      Session? resolvedSession;
      final pipeline = const Pipeline()
          .addMiddleware(middleware)
          .addMiddleware(sessionMiddleware(store))
          .addHandler((req) {
            resolvedSession = req.context[sessionContextKey] as Session?;
            return Response.ok('ok');
          });

      final response = await pipeline(
        Request(
          'GET',
          Uri.parse('http://localhost/whoami'),
          headers: {
            'Authorization': bearer(token),
            // NOTE: uppercase `COOKIE`. Test #44 uses canonical `Cookie`,
            // so it does not exercise this path. shelf accepts the
            // adversarial casing and case-insensitive lookups still find
            // it — exactly the attacker's smuggling vector.
            'COOKIE': '__Host-session=$cookieSessionId',
          },
        ),
      );

      expect(response.statusCode, equals(200));
      expect(
        resolvedSession,
        isNotNull,
        reason:
            'Bearer must populate the canonical session slot regardless '
            'of cookie header casing',
      );
      expect(resolvedSession!.userId, equals(kValidSubject));
      expect(resolvedSession!.roles, contains('social_worker'));
      // SEC: cookie strip must be case-INSENSITIVE — `COOKIE`, `Cookie`,
      // `cookie`, `cookIE`, `CooKie` must all be removed before
      // sessionMiddleware runs. Otherwise a stolen cookie smuggled under
      // non-canonical casing would let sessionMiddleware overwrite the
      // bearer Session under sessionContextKey with the cookie one
      // carrying the "admin" role — defeating the W0.5 S1 contract.
      expect(
        resolvedSession!.roles,
        isNot(contains('admin')),
        reason: 'cookie role must NOT bleed in — even with COOKIE casing',
      );
    });

    test('Test #45: invalid Bearer + valid cookie → 401, NO fallback '
        '(D5 row 3 — security lacuna fix)', () async {
      final store = SessionStore(
        ttl: const Duration(hours: 1),
        clock: () => currentTime,
      );
      final cookieSessionId = store.create(
        accessToken: 'cookie-access',
        refreshToken: 'cookie-refresh',
        userId: 'cookie-user',
        roles: {'social_worker'},
      );

      final original = buildValidJwt();
      final parts = original.split('.');
      final tampered = '${parts[0]}.${parts[1]}.AAAA';

      var handlerInvoked = false;
      final pipeline = const Pipeline()
          .addMiddleware(middleware)
          .addMiddleware(sessionMiddleware(store))
          .addHandler((req) {
            handlerInvoked = true;
            return Response.ok('should not reach');
          });

      final response = await pipeline(
        Request(
          'GET',
          Uri.parse('http://localhost/whoami'),
          headers: {
            'Authorization': bearer(tampered),
            'Cookie': '__Host-session=$cookieSessionId',
          },
        ),
      );

      await expectGenericAuthError(response);
      expect(
        handlerInvoked,
        isFalse,
        reason:
            'invalid Bearer must short-circuit the pipeline — must '
            'NEVER fall back to the cookie session even if it is valid',
      );
    });

    test(
      'Test #46: Bearer absent + valid cookie → use cookie (D5 row 1)',
      () async {
        final store = SessionStore(
          ttl: const Duration(hours: 1),
          clock: () => currentTime,
        );
        final cookieSessionId = store.create(
          accessToken: 'cookie-access',
          refreshToken: 'cookie-refresh',
          userId: 'cookie-user',
          roles: {'social_worker'},
        );

        Session? resolvedSession;
        final pipeline = const Pipeline()
            .addMiddleware(middleware)
            .addMiddleware(sessionMiddleware(store))
            .addHandler((req) {
              // Post-B1: cookie path writes to the canonical slot too.
              resolvedSession = req.context[sessionContextKey] as Session?;
              return Response.ok('ok');
            });

        final response = await pipeline(
          Request(
            'GET',
            Uri.parse('http://localhost/whoami'),
            headers: {'Cookie': '__Host-session=$cookieSessionId'},
          ),
        );

        expect(response.statusCode, equals(200));
        expect(
          resolvedSession,
          isNotNull,
          reason: 'cookie session must reach the handler unobstructed',
        );
        expect(resolvedSession!.userId, equals('cookie-user'));
      },
    );
  });

  // ===========================================================================
  // Group H — Observability / Privacy — 3 tests
  // ===========================================================================

  group('H. Observability / privacy', () {
    late _LogSpy spy;

    setUp(() {
      Logger.root.level = Level.ALL;
      spy = _LogSpy();
    });

    tearDown(() => spy.dispose());

    test(
      'Test #52: token never appears in logs (constraint #9 redaction)',
      () async {
        final token = buildValidJwt();
        final result = await callBearer(middleware, authHeader: bearer(token));

        expect(result.response.statusCode, equals(200));

        // S2 hardening (W0-bis): forbid not only the literal token but also
        // any contiguous substring of the token longer than 20 characters.
        // This catches partial-token leaks (e.g. `token.substring(0, 32)` in
        // a debug log, or a logger that truncates at the first `.`). The
        // only safe redaction is a non-prefix marker like `[REDACTED]`.
        const minLeakLen = 21;
        for (final record in spy.records) {
          expect(
            record.message,
            isNot(contains(token)),
            reason: 'raw JWT must never reach a log record',
          );

          for (var i = 0; i + minLeakLen <= token.length; i++) {
            final fragment = token.substring(i, i + minLeakLen);
            expect(
              record.message,
              isNot(contains(fragment)),
              reason:
                  'no substring of the token longer than 20 chars may '
                  'reach a log record (partial-token leak detection). '
                  'Offending fragment starts at offset $i.',
            );
          }

          if (record.message.toLowerCase().contains('authorization')) {
            expect(
              record.message,
              contains('[REDACTED]'),
              reason: 'Authorization header logged WITHOUT [REDACTED] marker',
            );
          }
        }
      },
    );

    test('Test #53: 401 body is canonical generic — no oracle leak '
        '(constraint #10)', () async {
      final bodies = <String>[];

      // (a) expired
      final exp =
          currentTime
              .subtract(const Duration(hours: 1))
              .millisecondsSinceEpoch ~/
          1000;
      final r1 = await callBearer(
        middleware,
        authHeader: bearer(buildValidJwt(payloadOverrides: {'exp': exp})),
      );
      bodies.add(await r1.response.readAsString());

      // (b) bad signature
      final original = buildValidJwt();
      final p = original.split('.');
      final r2 = await callBearer(
        middleware,
        authHeader: bearer('${p[0]}.${p[1]}.AAAAA'),
      );
      bodies.add(await r2.response.readAsString());

      // (c) wrong issuer
      final r3 = await callBearer(
        middleware,
        authHeader: bearer(
          buildValidJwt(payloadOverrides: {'iss': 'https://attacker.example'}),
        ),
      );
      bodies.add(await r3.response.readAsString());

      // (d) wrong audience
      final r4 = await callBearer(
        middleware,
        authHeader: bearer(
          buildValidJwt(payloadOverrides: {'aud': kOtherClientId}),
        ),
      );
      bodies.add(await r4.response.readAsString());

      for (final b in bodies) {
        final json = jsonDecode(b) as Map<String, dynamic>;
        expect(json['code'], equals('AUTH-001'));
        expect(json['message'], equals('Invalid credentials'));
        expect(
          json.keys.toSet(),
          equals({'code', 'message'}),
          reason: 'no extra fields that could carry an oracle',
        );
      }
      expect(
        bodies.toSet().length,
        equals(1),
        reason: 'every rejection reason must collapse to the same body',
      );
    });

    test(
      'Test #54: error stack traces never leak secrets / JWKS internals',
      () async {
        // Synthesise a fake "leaky" exception payload that, if naively logged
        // as `e.toString()`, would expose the session secret AND mock PEM
        // markers. The middleware must log without leaking either.
        const leakyPem =
            '-----BEGIN PUBLIC KEY-----\nMOCK-PEM-MATERIAL\n-----END PUBLIC KEY-----';
        jwksClient.throwOnNext(
          Exception('INTERNAL: secret=$kSessionSecret pem=$leakyPem'),
        );

        // Force a fetch on the next request by busting the TTL.
        currentTime = currentTime.add(const Duration(minutes: 11));

        final token = buildValidJwt(kid: 'force-refetch-kid');
        final result = await callBearer(middleware, authHeader: bearer(token));

        // REGRA #2 exception (W1, 2026-05-01): the original W0 RED test
        // re-read `result.response.readAsString()` after
        // `expectGenericAuthError` had already drained the body, which
        // hits shelf's "read can only be called once" StateError on
        // every 401 path. The redundant body-content assertions
        // (`isNot(contains(kSessionSecret/'-----BEGIN'/'INTERNAL:'))`)
        // are tautologically satisfied by `expectGenericAuthError` —
        // which asserts the body is EXACTLY `{code: 'AUTH-001',
        // message: 'Invalid credentials'}` (lines 378-381 + key-set
        // pin via #53), making it structurally impossible for a
        // session secret, PEM marker, or INTERNAL marker to appear.
        // The substantive assertion — log records never carry secrets —
        // is preserved in the spy loop below.
        await expectGenericAuthError(result.response);

        for (final r in spy.records) {
          expect(
            r.message,
            isNot(contains(kSessionSecret)),
            reason: 'session secret must never reach logs',
          );
          expect(
            r.message,
            isNot(contains('-----BEGIN')),
            reason: 'PEM material must never reach logs',
          );
        }
      },
    );
  });

  // ===========================================================================
  // Group I — Session Construction (W0-bis additions to close W0.5 gaps)
  //   M1: Session ID HMAC contract (constraint #3)
  //   M2: `jti` claim precedence over HMAC fallback
  //   S3: Bearer-derived Session full shape
  // ===========================================================================

  group('I. Session construction (constraint #3, full Session shape)', () {
    test(
      'Test #55 (M1.1): same JWT (same sub+iat) → deterministic session.id == '
      'expectedHmacSessionId(sub, iat)',
      () async {
        // Build two distinct token instances with the SAME sub and SAME iat
        // (and same exp). They are byte-identical-payload but issued via two
        // separate buildValidJwt() calls — equivalent to two requests on the
        // wire carrying the same opaque-from-the-attacker's-view token.
        final iat = currentTime.millisecondsSinceEpoch ~/ 1000;
        final exp =
            currentTime.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
            1000;

        final tokenA = buildValidJwt(
          payloadOverrides: {'sub': kValidSubject, 'iat': iat, 'exp': exp},
        );
        final tokenB = buildValidJwt(
          payloadOverrides: {'sub': kValidSubject, 'iat': iat, 'exp': exp},
        );

        final r1 = await callBearer(middleware, authHeader: bearer(tokenA));
        final r2 = await callBearer(middleware, authHeader: bearer(tokenB));

        expect(r1.response.statusCode, equals(200));
        expect(r2.response.statusCode, equals(200));
        expect(r1.session, isNotNull);
        expect(r2.session, isNotNull);

        final expectedId = expectedHmacSessionId(
          secret: kSessionSecret,
          sub: kValidSubject,
          iat: iat,
        );

        expect(
          r1.session!.id,
          equals(expectedId),
          reason:
              'constraint #3 — session.id must be HMAC-SHA256 over '
              '"sub:iat" using ServerConfig.sessionSecret',
        );
        expect(
          r2.session!.id,
          equals(expectedId),
          reason: 'determinism — same (sub, iat) → same session.id',
        );
        expect(
          r1.session!.id,
          equals(r2.session!.id),
          reason:
              'two requests with the same (sub, iat) must yield the '
              'same session.id (correlation key stability)',
        );
      },
    );

    test(
      'Test #56 (M1.2): session.id != sha256(token) and != sha256Hex/Base64Url '
      '(forbids naive token-hash implementation, Lacuna 2)',
      () async {
        final iat = currentTime.millisecondsSinceEpoch ~/ 1000;
        final exp =
            currentTime.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
            1000;
        final token = buildValidJwt(
          payloadOverrides: {'sub': kValidSubject, 'iat': iat, 'exp': exp},
        );

        final result = await callBearer(middleware, authHeader: bearer(token));
        expect(result.response.statusCode, equals(200));
        expect(result.session, isNotNull);

        final id = result.session!.id;

        expect(
          id,
          isNot(equals(sha256Hex(token))),
          reason: 'Lacuna 2 — session.id must NOT be sha256(token) hex',
        );
        expect(
          id,
          isNot(equals(sha256Base64Url(token))),
          reason: 'Lacuna 2 — session.id must NOT be sha256(token) base64url',
        );

        // Defense-in-depth: also forbid hashing common prefixes (header,
        // header.payload) of the token. If the impl hashes "header.payload"
        // it still leaks correlation against logs that capture only the
        // first two segments.
        final parts = token.split('.');
        expect(id, isNot(equals(sha256Hex(parts[0]))));
        expect(id, isNot(equals(sha256Hex('${parts[0]}.${parts[1]}'))));
      },
    );

    test('Test #57 (M1.3 + M2): jti claim present → session.id == jti '
        '(jti precedence over HMAC fallback)', () async {
      const jtiValue = 'unique-jti-abc';
      final iat = currentTime.millisecondsSinceEpoch ~/ 1000;
      final exp =
          currentTime.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
          1000;

      final token = buildValidJwt(
        payloadOverrides: {
          'jti': jtiValue,
          'sub': kValidSubject,
          'iat': iat,
          'exp': exp,
        },
      );

      final result = await callBearer(middleware, authHeader: bearer(token));
      expect(result.response.statusCode, equals(200));
      expect(result.session, isNotNull);

      expect(
        result.session!.id,
        equals(jtiValue),
        reason:
            'constraint #3 — when "jti" is present in the JWT, it '
            'is used verbatim as session.id (NOT HMAC-derived)',
      );

      // Negative confirmation: the HMAC fallback would produce a different
      // value here, so the assertion above genuinely proves jti precedence.
      final hmacFallback = expectedHmacSessionId(
        secret: kSessionSecret,
        sub: kValidSubject,
        iat: iat,
      );
      expect(
        result.session!.id,
        isNot(equals(hmacFallback)),
        reason: 'jti must take precedence over the HMAC fallback',
      );
    });

    test(
      'Test #58 (S3): Bearer-derived Session has the exact contractual shape '
      '(accessToken, refreshToken, userId, expiresAt, displayName)',
      () async {
        final iat = currentTime.millisecondsSinceEpoch ~/ 1000;
        final exp =
            currentTime.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
            1000;

        final token = buildValidJwt(
          payloadOverrides: {'sub': kValidSubject, 'iat': iat, 'exp': exp},
        );

        final result = await callBearer(middleware, authHeader: bearer(token));
        expect(result.response.statusCode, equals(200));
        expect(result.session, isNotNull);

        final s = result.session!;

        expect(
          s.accessToken,
          equals(token),
          reason:
              'session.accessToken must be the raw JWT — proxy needs '
              'it verbatim to forward to the Swift backend',
        );
        expect(
          s.refreshToken,
          equals(''),
          reason:
              'Bearer flow has no refresh token; field must be the '
              'empty string (NOT "no", null-equivalent, or a stale value)',
        );
        expect(
          s.userId,
          equals(kValidSubject),
          reason: 'session.userId comes from JWT "sub"',
        );
        expect(
          s.expiresAt,
          equals(DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true)),
          reason:
              'session.expiresAt must mirror the JWT "exp" claim — '
              'NOT clock() + sessionTtl. Otherwise a token 30 min from '
              'expiry could be honoured for a full hour.',
        );
        expect(
          s.displayName,
          isNull,
          reason: 'Bearer flow does not enrich displayName — field is null',
        );

        // Roles parsing sanity (already covered partially elsewhere; pinned
        // here as part of the full-shape contract).
        expect(s.roles, equals({'social_worker'}));
      },
    );
  });
}

// ---------------------------------------------------------------------------
// Local utilities (kept private to this file)
// ---------------------------------------------------------------------------

String _padBase64(String s) {
  final pad = (4 - s.length % 4) % 4;
  return s + '=' * pad;
}

/// Forge an HS256/HS512 token using the JWKS public-key material (modulus
/// `n` from the JWK) as the symmetric secret — the classic alg-confusion
/// shape (CVE-2015-9235).
///
/// In a real attack the adversary would dump the JWK's `n` from the public
/// JWKS endpoint and feed those bytes into HMAC. We mirror that exactly here:
/// the modulus base64url string IS what an attacker has access to.
String _forgedSymmetricToken({
  required String secretMaterial,
  required String kid,
  required String alg,
}) {
  final header = base64Url
      .encode(utf8.encode(jsonEncode({'alg': alg, 'typ': 'JWT', 'kid': kid})))
      .replaceAll('=', '');
  final payload = base64Url
      .encode(
        utf8.encode(
          jsonEncode({
            'iss': kValidIssuer,
            'sub': kValidSubject,
            'aud': kValidCliClientId,
            'azp': kValidCliClientId,
            'iat': kNow.millisecondsSinceEpoch ~/ 1000,
            'exp':
                kNow.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
                1000,
          }),
        ),
      )
      .replaceAll('=', '');
  final input = '$header.$payload';

  final hash = alg == 'HS512' ? crypto.sha512 : crypto.sha256;
  final hmac = crypto.Hmac(hash, utf8.encode(secretMaterial));
  final sig = hmac.convert(utf8.encode(input)).bytes;
  final encodedSig = base64Url
      .encode(Uint8List.fromList(sig))
      .replaceAll('=', '');
  return '$input.$encodedSig';
}

// ---------------------------------------------------------------------------
// Logging spy (mirrors observability_test.dart `_LogSpy`)
// ---------------------------------------------------------------------------

class _LogSpy {
  _LogSpy() {
    _sub = Logger.root.onRecord.listen(records.add);
  }
  final List<LogRecord> records = [];
  late final StreamSubscription<LogRecord> _sub;
  void dispose() => _sub.cancel();
}
