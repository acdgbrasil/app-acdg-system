/// Regression tests for B1 — BFF auth fail-closed (P0-1 + N1 bundle).
///
/// Locks the protected pipeline contract: every protected route returns the
/// canonical AUTH-001 401 when no session is in context, and reaches the
/// handler with a populated `Session` when bearer or cookie auth succeeds.
///
/// References:
///   .pipeline/phase-6-security-remediation/tickets/B1-bff-auth-fail-closed/
///     001-design/DESIGN.md §8 (15-test matrix), §6 (canonical 401 body)
///   handbook/audit/2026-05-04-orchestrated/02-pentest/REPORT.md §B1 §B2
///   handbook/audit/2026-05-04-orchestrated/06-secure-review/REVIEW.md §N1
library;

import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/auth/jwks_cache.dart';
import 'package:social_care_web/src/auth/session_store.dart';
import 'package:social_care_web/src/middleware/auth_guard_middleware.dart';
import 'package:social_care_web/src/middleware/bearer_auth_middleware.dart';
import 'package:social_care_web/src/middleware/session_middleware.dart';

import '../middleware/_bearer_test_fixtures.dart';
import '../middleware/_bearer_test_helpers.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Shared setup — clock, JWKS, bearer middleware, session store, pipeline
  // ---------------------------------------------------------------------------
  late DateTime currentTime;
  late JwksCache jwksCache;
  late FakeJwksClient jwksClient;
  late Middleware bearerMw;
  late SessionStore sessionStore;
  late String validCookieSessionId;

  /// Captured by the inner handler — set whenever the gate lets a request
  /// through.
  Session? capturedSession;
  bool innerInvoked = false;

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
    bearerMw = bearerAuthMiddleware(
      config: buildTestServerConfig(),
      jwksCache: jwksCache,
      clock: () => currentTime,
    );
    sessionStore = SessionStore(
      ttl: const Duration(hours: 1),
      clock: () => currentTime,
    );
    validCookieSessionId = sessionStore.create(
      accessToken: 'cookie-access',
      refreshToken: 'cookie-refresh',
      userId: 'cookie-user',
      roles: {'social_worker'},
    );
    capturedSession = null;
    innerInvoked = false;
  });

  /// Builds the post-B1 protected pipeline:
  ///   bearerAuth -> sessionMiddleware -> authGuard -> innerHandler
  ///
  /// The inner handler captures the resolved Session under [sessionContextKey]
  /// (the canonical slot per DESIGN.md §3 / §4). When the gate fails closed,
  /// the inner handler must NOT be invoked — `innerInvoked` stays `false`.
  ///
  /// `observabilityMiddleware()` is intentionally omitted: it does not
  /// participate in the auth contract and would add unrelated logging
  /// surface to every test. Its position in production is documented in
  /// DESIGN.md §5; B1's gate is downstream of it.
  Handler buildPipeline() {
    Future<Response> inner(Request request) async {
      innerInvoked = true;
      // SEC: read the canonical slot. Post-B1, both auth paths populate
      // sessionContextKey; pre-B1 (today) only sessionMiddleware does.
      final raw = request.context[sessionContextKey];
      capturedSession = raw is Session ? raw : null;
      return Response.ok('inner-ok');
    }

    return const Pipeline()
        .addMiddleware(bearerMw)
        .addMiddleware(sessionMiddleware(sessionStore))
        .addMiddleware(authGuardMiddleware())
        .addHandler(inner);
  }

  /// Asserts the response is the canonical B1 401:
  ///   * status 401
  ///   * `content-type: application/json`
  ///   * body `{"code":"AUTH-001","message":"Invalid credentials"}` exact key
  ///     set (no extra fields)
  ///   * body must not name any auth path / token / claim — closes the
  ///     oracle leak DESIGN.md §6 forbids.
  Future<void> expectCanonicalAuthError(
    Response response, {
    int expectedStatus = 401,
  }) async {
    expect(
      response.statusCode,
      equals(expectedStatus),
      reason: 'B1 canonical auth error must be $expectedStatus',
    );
    expect(
      response.headers['content-type'],
      contains('application/json'),
      reason: 'B1 canonical auth error must be JSON',
    );

    final raw = await response.readAsString();
    final body = jsonDecode(raw) as Map<String, dynamic>;
    expect(
      body,
      containsPair('code', 'AUTH-001'),
      reason: 'DESIGN §6 — canonical error code',
    );
    expect(
      body,
      containsPair('message', 'Invalid credentials'),
      reason: 'DESIGN §6 — canonical message, no validation reason',
    );
    expect(
      body.keys.toSet(),
      equals(<String>{'code', 'message'}),
      reason:
          'DESIGN §6 — body has exactly two fields; extra fields could carry '
          'an oracle (e.g. error category, request_id, kid) and let an '
          'attacker distinguish failure modes',
    );

    final lowered = raw.toLowerCase();
    for (final forbidden in const <String>[
      'bearer',
      'cookie',
      'session',
      'token',
      'expired',
      'signature',
      'audience',
      'issuer',
      'kid',
      'authorization',
    ]) {
      expect(
        lowered,
        isNot(contains(forbidden)),
        reason:
            'DESIGN §6 — auth_guard 401 body must not name "$forbidden"; '
            'naming any specific failure path lets a pentester distinguish '
            '"no token" vs "bad token" vs "expired cookie" vs "destroyed '
            'session" — collapsing every path to AUTH-001 closes the leak.',
      );
    }
  }

  /// Builds a Request with optional headers against the protected sentinel
  /// route `GET /patients`.
  Request buildSentinelRequest({Map<String, String>? headers}) {
    return Request(
      'GET',
      Uri.parse('http://localhost/patients'),
      headers: headers,
    );
  }

  // ===========================================================================
  // Group A — Auth scenarios on a single sentinel route (DESIGN §8 Group A)
  // ===========================================================================

  group('B1: protected pipeline gating', () {
    test('A1: anonymous (no Authorization, no Cookie) → 401 AUTH-001, '
        'inner handler never invoked', () async {
      final response = await buildPipeline()(buildSentinelRequest());

      await expectCanonicalAuthError(response);
      expect(
        innerInvoked,
        isFalse,
        reason:
            'DESIGN §2 — auth_guard short-circuits the pipeline; the inner '
            'handler must never run on an anonymous request. This is the '
            'P0-1 (CVSS 9.8) regression — today the inner runs and returns 200.',
      );
      expect(capturedSession, isNull);
    });

    test(
      'A2: valid Bearer JWT (RS256 / valid kid / exp +1h) → 200, handler '
      'invoked, getSession() returns Session with userId == kValidSubject',
      () async {
        final token = buildValidJwt();

        final response = await buildPipeline()(
          buildSentinelRequest(headers: {'Authorization': bearer(token)}),
        );

        expect(
          response.statusCode,
          equals(200),
          reason: 'B1 contract: valid Bearer reaches the inner handler',
        );
        expect(await response.readAsString(), equals('inner-ok'));
        expect(
          innerInvoked,
          isTrue,
          reason: 'inner handler must run for an authenticated Bearer request',
        );
        expect(
          capturedSession,
          isNotNull,
          reason:
              'DESIGN §3 — bearer middleware writes to sessionContextKey '
              '(canonical slot); the protected pipeline must surface the '
              'Bearer-derived Session to the handler.',
        );
        expect(
          capturedSession!.userId,
          equals(kValidSubject),
          reason:
              'session.userId comes from JWT sub (constraint #58); confirms '
              'the Session reaching the handler was Bearer-derived, not a '
              'cross-attribution from the cookie path',
        );
      },
    );

    test('A3: expired Bearer (exp = now - 1h, beyond leeway) → 401 AUTH-001, '
        'inner never invoked', () async {
      final pastExp =
          currentTime
              .subtract(const Duration(hours: 1))
              .millisecondsSinceEpoch ~/
          1000;
      final token = buildValidJwt(payloadOverrides: {'exp': pastExp});

      final response = await buildPipeline()(
        buildSentinelRequest(headers: {'Authorization': bearer(token)}),
      );

      await expectCanonicalAuthError(response);
      expect(
        innerInvoked,
        isFalse,
        reason:
            'invalid Bearer must short-circuit before the inner handler — '
            'D5 row 3 NO-fallback contract',
      );
    });

    test('A4: forged signature (re-encode header.payload, append "AAAA") → 401 '
        'AUTH-001, inner never invoked', () async {
      final original = buildValidJwt();
      final parts = original.split('.');
      final tampered = '${parts[0]}.${parts[1]}.AAAA';

      final response = await buildPipeline()(
        buildSentinelRequest(headers: {'Authorization': bearer(tampered)}),
      );

      await expectCanonicalAuthError(response);
      expect(innerInvoked, isFalse);
    });

    test('A5: alg "none" (header alg=none, empty signature segment) → 401 '
        'AUTH-001, inner never invoked', () async {
      final token = buildJwt(alg: 'none', rawSignatureOverride: '');

      final response = await buildPipeline()(
        buildSentinelRequest(headers: {'Authorization': bearer(token)}),
      );

      await expectCanonicalAuthError(response);
      expect(innerInvoked, isFalse);
    });

    test(
      'A6: malformed Authorization headers ("Bearer ", "Bearer abc", missing '
      'prefix) → 401 AUTH-001, inner never invoked',
      () async {
        // (a) empty token after Bearer scheme
        final r1 = await buildPipeline()(
          buildSentinelRequest(headers: {'Authorization': 'Bearer '}),
        );
        await expectCanonicalAuthError(r1);
        expect(innerInvoked, isFalse, reason: 'Bearer with empty token');

        // (b) garbage payload after Bearer scheme — not a JWT shape
        innerInvoked = false;
        final r2 = await buildPipeline()(
          buildSentinelRequest(headers: {'Authorization': 'Bearer abc'}),
        );
        await expectCanonicalAuthError(r2);
        expect(innerInvoked, isFalse, reason: 'Bearer + non-JWT garbage');

        // (c) wrong scheme — Basic. Bearer middleware lets it through with no
        // session populated; auth_guard then rejects on missing session.
        innerInvoked = false;
        final r3 = await buildPipeline()(
          buildSentinelRequest(
            headers: {'Authorization': 'Basic dXNlcjpwYXNz'},
          ),
        );
        await expectCanonicalAuthError(r3);
        expect(
          innerInvoked,
          isFalse,
          reason: 'wrong scheme falls through to gate',
        );
      },
    );

    test(
      'A7: valid cookie session (existing SessionStore entry, no Bearer) → '
      '200, handler invoked, getSession() returns Session with the store userId',
      () async {
        final response = await buildPipeline()(
          buildSentinelRequest(
            headers: {'Cookie': '__Host-session=$validCookieSessionId'},
          ),
        );

        expect(
          response.statusCode,
          equals(200),
          reason: 'cookie path must reach handler when no Bearer is present',
        );
        expect(innerInvoked, isTrue);
        expect(
          capturedSession,
          isNotNull,
          reason:
              'sessionMiddleware writes to sessionContextKey (canonical); '
              'auth_guard reads same slot — this case is GREEN today and '
              'must stay GREEN after B1.',
        );
        expect(
          capturedSession!.userId,
          equals('cookie-user'),
          reason:
              'session resolved from SessionStore via the __Host-session cookie',
        );
      },
    );

    test(
      'A8: cookie present but maps to no SessionStore entry '
      '(destroyed/expired/garbage) → 401 AUTH-001, inner never invoked',
      () async {
        final response = await buildPipeline()(
          buildSentinelRequest(
            headers: {'Cookie': '__Host-session=garbage-id-xyz'},
          ),
        );

        await expectCanonicalAuthError(response);
        expect(
          innerInvoked,
          isFalse,
          reason:
              'sessionMiddleware does not populate the slot when lookup fails; '
              'auth_guard then short-circuits with the canonical 401',
        );
      },
    );
  });

  // ===========================================================================
  // Group B — Multi-route smoke (verifies pipeline composition)
  // ===========================================================================
  //
  // We exercise one URL per protected route group, asserting anonymous
  // requests are gated at the pipeline level — not at the handler. The
  // routes are not actually wired to handlers in this test file: each URL
  // is fed to the same `buildPipeline()` whose inner is the stub, because
  // the gate runs BEFORE routing. If the gate is correctly composed, no
  // anonymous request can reach any router cascade — regardless of the
  // route shape (idempotent GET vs body-bearing POST/PUT, lookup vs team).
  //
  // RED today: production `app_router.dart` does NOT include
  // `authGuardMiddleware()`, so anonymous requests reach the cascade and
  // hit business handlers. Our pipeline ALSO models the post-fix shape;
  // these tests fail because the canonical 401 body is not yet emitted by
  // the rewritten `auth_guard_middleware.dart` and (for some routes) the
  // current bearer middleware leaves `sessionContextKey` empty even on a
  // valid bearer (see A2). The gate's behavior on anonymous however is
  // already shape-correct in current auth_guard — what fails is the body
  // shape (see expectCanonicalAuthError).

  group('B1: multi-route smoke (7 protected handlers, anonymous → 401)', () {
    Future<void> runAnonymous(String method, String path) async {
      final response = await buildPipeline()(
        Request(method, Uri.parse('http://localhost$path')),
      );
      await expectCanonicalAuthError(response);
      expect(
        innerInvoked,
        isFalse,
        reason:
            'gate must short-circuit anonymous on $method $path before any '
            'handler runs — closing P0-1 across every protected route group',
      );
      // Reset for the next sub-call within a single test (helpers chain).
      innerInvoked = false;
    }

    test('B-registry-patient: GET /patients → 401 AUTH-001', () async {
      await runAnonymous('GET', '/patients');
    });

    test(
      'B-registry-family: GET /patients/p-1/audit-trail → 401 AUTH-001',
      () async {
        await runAnonymous('GET', '/patients/p-1/audit-trail');
      },
    );

    test(
      'B-assessment: PUT /patients/p-1/assessment/housing → 401 AUTH-001',
      () async {
        await runAnonymous('PUT', '/patients/p-1/assessment/housing');
      },
    );

    test('B-care: POST /patients/p-1/appointments → 401 AUTH-001', () async {
      await runAnonymous('POST', '/patients/p-1/appointments');
    });

    test('B-protection: POST /patients/p-1/referrals → 401 AUTH-001', () async {
      await runAnonymous('POST', '/patients/p-1/referrals');
    });

    test('B-lookup: GET /lookups → 401 AUTH-001', () async {
      await runAnonymous('GET', '/lookups');
    });

    test('B-team: GET /team → 401 AUTH-001', () async {
      await runAnonymous('GET', '/team');
    });
  });
}
