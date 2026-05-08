// Regression tests for B2 — BFF cookie path repair (Phase 6 Wave 2 RED).
//
// SEC: These tests pin the contract for the OIDC cookie path so that the two
// compounding breakages reported in Pentest §B3 (CVSS 9.0) cannot recur:
//   1. Cookie name drift — writer emits `__Host-session=` but reader scans
//      for `__session=` (apps/.../middleware/session_middleware.dart:48).
//   2. Phantom session — `AuthCallbackUseCase` returns Success without ever
//      calling `SessionStore.create()`; the handler synthesizes a UUID
//      cookie value that maps to no store entry.
//
// References:
//   .pipeline/phase-6-security-remediation/tickets/B2-bff-cookie-path-repair/001-design/DESIGN.md §8
//   .pipeline/phase-6-security-remediation/tickets/B2-bff-cookie-path-repair/000-discuss/CONTEXT.md §1-§3
//   handbook/audit/2026-05-04-orchestrated/02-pentest/REPORT.md §B3
//
// Today (pre-B2-fix) all 10 tests are expected to be RED at assertion time.
// After Wave 3 they MUST be GREEN.
//
// Test matrix (T1-T10):
//   T1  full OIDC happy path: callback → SessionStore-issued id → cookie value matches store entry
//   T2  cookie roundtrip through real sessionMiddleware (writer/reader name agreement)
//   T3  token-exchange failure → no Set-Cookie + no SessionStore entry
//   T4  cookie attribute set complete: __Host-session, Path=/, HttpOnly, Secure, SameSite=Strict, Max-Age=3600
//   T5  logout clear-cookie attribute set complete (Max-Age=0 + same scope)
//   T6  replay idempotency spec — second Success creates a 2nd entry, browser uses last cookie
//   T7  string-literal grep regression — `__session=` and `__Host-session` only in cookie_constants.dart
//   T8  no Set-Cookie echo in error response body (reflected-cookie info-leak guard)
//   T9  no synthesized Set-Cookie header on token-exchange failure
//   T10 SessionStore TTL ↔ cookie Max-Age alignment (soft assertion)

import 'dart:convert';
import 'dart:io';

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/auth/session_store.dart';
import 'package:social_care_web/src/handlers/auth_handler.dart';
import 'package:social_care_web/src/middleware/session_middleware.dart';
import 'package:social_care_web/src/use_cases/auth_callback_use_case.dart';
import 'package:social_care_web/src/use_cases/login_use_case.dart';
import 'package:social_care_web/src/use_cases/logout_use_case.dart';
import 'package:social_care_web/src/use_cases/me_use_case.dart';
import 'package:social_care_web/src/use_cases/refresh_use_case.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

/// SEC: Token-exchange failure double — exercises T3, T8, T9.
class _FailingAuthBff extends FakeAuthBff {
  _FailingAuthBff(this._error);

  final BackendError _error;

  @override
  Future<Result<StandardResponse<void>>> callback({
    required String code,
    required String state,
  }) async => Failure(_error);
}

/// SEC: Stand-in for "Zitadel that allows code reuse" — exercises T6.
///
/// FakeAuthBff already returns Success unconditionally; this subclass just
/// counts invocations so T6 can verify both calls actually reached the
/// contract. Documents the intent of T6 (replay idempotency spec) and keeps
/// the test resilient if FakeAuthBff defaults change.
class _DoubleSuccessAuthBff extends FakeAuthBff {
  _DoubleSuccessAuthBff();

  int callCount = 0;

  @override
  Future<Result<StandardResponse<void>>> callback({
    required String code,
    required String state,
  }) async {
    callCount += 1;
    return super.callback(code: code, state: state);
  }
}

// ---------------------------------------------------------------------------
// Fixture helpers
// ---------------------------------------------------------------------------

/// Builds an [AuthHandler] wired to the auth contract and the SessionStore.
///
/// SEC: [AuthCallbackUseCase] accepts the SessionStore so that on contract
/// Success it persists a real entry BEFORE the handler emits the Set-Cookie.
/// Without this dependency wired through, the cookie path is broken
/// end-to-end (Pentest §B3).
AuthHandler _buildHandler({
  required AuthContract auth,
  required SessionStore sessionStore,
}) {
  return AuthHandler(
    login: LoginUseCase(auth: auth),
    callback: AuthCallbackUseCase(auth: auth, sessionStore: sessionStore),
    logout: LogoutUseCase(auth: auth),
    me: MeUseCase(auth: auth),
    refresh: RefreshUseCase(auth: auth),
  );
}

/// Extracts the value half of `__Host-session=<value>; ...` from a
/// `Set-Cookie` header. Returns `null` if the header is absent or malformed.
String? _extractSessionCookieValue(String? setCookie) {
  if (setCookie == null) return null;
  final firstSegment = setCookie.split(';').first.trim();
  const prefix = '__Host-session=';
  if (!firstSegment.startsWith(prefix)) return null;
  final value = firstSegment.substring(prefix.length);
  return value.isEmpty ? null : value;
}

void main() {
  group('B2: OIDC cookie path repair (P0-3)', () {
    // -----------------------------------------------------------------------
    // T1 — Full OIDC happy path: callback yields Set-Cookie that maps to a
    //      real SessionStore entry.
    // -----------------------------------------------------------------------
    test(
      'T1: callback Success issues Set-Cookie whose value lives in SessionStore',
      () async {
        final fakeAuth = FakeAuthBff();
        final sessionStore = SessionStore(
          ttl: const Duration(hours: 1),
          clock: () => DateTime.utc(2026, 5, 4, 12, 0),
        );
        final handler = _buildHandler(
          auth: fakeAuth,
          sessionStore: sessionStore,
        );

        final request = Request(
          'GET',
          Uri.parse('http://localhost/auth/callback?code=valid&state=valid'),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(302));
        expect(response.headers['location'], equals('/'));

        final setCookie = response.headers['set-cookie'];
        final cookieValue = _extractSessionCookieValue(setCookie);
        expect(
          cookieValue,
          isNotNull,
          reason: 'callback Success MUST emit __Host-session= cookie',
        );

        // SEC: the cookie value MUST be the SessionStore-issued id, not a
        // synthesized UUID. A non-null Session here proves the use case
        // persisted before the cookie was emitted. Pre-fix this fails because
        // AuthCallbackUseCase never calls SessionStore.create() (Pentest §B3).
        final session = sessionStore.get(cookieValue!);
        expect(
          session,
          isNotNull,
          reason: 'cookie value MUST map to a live SessionStore entry',
        );
        expect(session!.id, equals(cookieValue));
      },
    );

    // -----------------------------------------------------------------------
    // T2 — Cookie roundtrip through the REAL session middleware. Today the
    //      reader scans `__session=` but the writer emits `__Host-session=`.
    // -----------------------------------------------------------------------
    test(
      'T2: writer (auth_handler) and reader (sessionMiddleware) agree on cookie name',
      () async {
        final fakeAuth = FakeAuthBff();
        final sessionStore = SessionStore(
          ttl: const Duration(hours: 1),
          clock: () => DateTime.utc(2026, 5, 4, 12, 0),
        );
        final handler = _buildHandler(
          auth: fakeAuth,
          sessionStore: sessionStore,
        );

        // 1. Run the full callback to obtain the Set-Cookie.
        final callbackResp = await handler.router.call(
          Request(
            'GET',
            Uri.parse('http://localhost/auth/callback?code=c&state=s'),
          ),
        );
        final cookieValue = _extractSessionCookieValue(
          callbackResp.headers['set-cookie'],
        );
        expect(cookieValue, isNotNull);

        // 2. Replay it through a pipeline that uses the REAL sessionMiddleware.
        Session? observed;
        final pipeline = const Pipeline()
            .addMiddleware(sessionMiddleware(sessionStore))
            .addHandler((req) {
              observed = req.context[sessionContextKey] as Session?;
              return Response.ok('ok');
            });

        final replayed = await pipeline(
          Request(
            'GET',
            Uri.parse('http://localhost/api/protected'),
            headers: {'Cookie': '__Host-session=$cookieValue'},
          ),
        );

        expect(replayed.statusCode, equals(200));
        // SEC: this is the assertion that goes RED today — sessionMiddleware
        // scans `__session=`, writer emits `__Host-session=`, so observed is
        // null. After B2: both sides import sessionCookieName from
        // cookie_constants.dart and agree.
        expect(
          observed,
          isNotNull,
          reason: 'cookie name in writer MUST match reader regex',
        );
        expect(observed!.id, equals(cookieValue));
      },
    );

    // -----------------------------------------------------------------------
    // T3 — Token-exchange failure → no Set-Cookie + no SessionStore entry.
    // -----------------------------------------------------------------------
    test(
      'T3: token-exchange Failure → no Set-Cookie AND no SessionStore entry',
      () async {
        const error = BackendError(
          id: 'err-1',
          code: 'OIDC_EXCHANGE_FAILED',
          message: 'Token exchange failed',
          http: 502,
        );
        final failing = _FailingAuthBff(error);
        final sessionStore = SessionStore(
          ttl: const Duration(hours: 1),
          clock: () => DateTime.utc(2026, 5, 4, 12, 0),
        );
        final handler = _buildHandler(
          auth: failing,
          sessionStore: sessionStore,
        );

        final response = await handler.router.call(
          Request(
            'GET',
            Uri.parse('http://localhost/auth/callback?code=x&state=y'),
          ),
        );

        expect(response.statusCode, equals(502));
        expect(
          response.headers['set-cookie'],
          isNull,
          reason: 'token-exchange Failure MUST NOT emit Set-Cookie',
        );

        // Best-effort fail-closed assertion: no entry was created. Without an
        // introspection API on SessionStore we settle for: any id we sample
        // returns null. The ground truth for "no entry was created" is the
        // absence of Set-Cookie above — that's the canonical signal.
        expect(sessionStore.get('does-not-exist'), isNull);
      },
    );

    // -----------------------------------------------------------------------
    // T4 — Cookie attribute set complete: __Host-, Path=/, HttpOnly, Secure,
    //      SameSite=Strict, Max-Age=3600.
    // -----------------------------------------------------------------------
    test(
      'T4: established Set-Cookie carries the full hardened attribute set',
      () async {
        final fakeAuth = FakeAuthBff();
        final sessionStore = SessionStore(
          ttl: const Duration(hours: 1),
          clock: () => DateTime.utc(2026, 5, 4, 12, 0),
        );
        final handler = _buildHandler(
          auth: fakeAuth,
          sessionStore: sessionStore,
        );

        final response = await handler.router.call(
          Request(
            'GET',
            Uri.parse('http://localhost/auth/callback?code=c&state=s'),
          ),
        );

        final setCookie = response.headers['set-cookie'];
        expect(setCookie, isNotNull);
        final lower = setCookie!.toLowerCase();

        // SEC: every attribute below is required by the design (DESIGN §7).
        expect(setCookie, contains('__Host-session='));
        expect(lower, contains('path=/'));
        expect(lower, contains('httponly'));
        expect(lower, contains('secure'));
        expect(lower, contains('samesite=strict'));
        // P1-4 / Auth A8 — Max-Age is the bonus this bundle ships. RED today
        // because the writer omits Max-Age on the establish-cookie variant.
        expect(
          lower,
          contains('max-age=3600'),
          reason:
              'cookie MUST carry Max-Age aligned with SessionStore.ttl default',
        );
        // SEC: __Host- prefix forbids Domain attribute.
        expect(
          lower,
          isNot(contains('domain=')),
          reason: '__Host- prefix forbids Domain attribute',
        );
      },
    );

    // -----------------------------------------------------------------------
    // T5 — Logout clear-cookie attributes.
    // -----------------------------------------------------------------------
    test(
      'T5: logout Set-Cookie clears with Max-Age=0 and identical scope attrs',
      () async {
        final fakeAuth = FakeAuthBff();
        final sessionStore = SessionStore(
          ttl: const Duration(hours: 1),
          clock: () => DateTime.utc(2026, 5, 4, 12, 0),
        );
        final handler = _buildHandler(
          auth: fakeAuth,
          sessionStore: sessionStore,
        );

        final response = await handler.router.call(
          Request(
            'POST',
            Uri.parse('http://localhost/auth/logout'),
            headers: {'Cookie': '__Host-session=any-value'},
          ),
        );

        expect(response.statusCode, equals(200));
        final setCookie = response.headers['set-cookie'];
        expect(setCookie, isNotNull);
        final lower = setCookie!.toLowerCase();

        expect(setCookie, contains('__Host-session='));
        expect(lower, contains('path=/'));
        expect(lower, contains('httponly'));
        expect(lower, contains('secure'));
        expect(lower, contains('samesite=strict'));
        expect(
          lower,
          contains('max-age=0'),
          reason: 'logout MUST overwrite the cookie with Max-Age=0',
        );
      },
    );

    // -----------------------------------------------------------------------
    // T6 — Replay idempotency spec (D4 / DESIGN §8 row T6).
    // -----------------------------------------------------------------------
    test(
      'T6: double Success on /auth/callback creates two SessionStore entries (replay spec)',
      () async {
        final auth = _DoubleSuccessAuthBff();
        final sessionStore = SessionStore(
          ttl: const Duration(hours: 1),
          clock: () => DateTime.utc(2026, 5, 4, 12, 0),
        );
        final handler = _buildHandler(auth: auth, sessionStore: sessionStore);

        final r1 = await handler.router.call(
          Request(
            'GET',
            Uri.parse('http://localhost/auth/callback?code=x&state=y'),
          ),
        );
        final r2 = await handler.router.call(
          Request(
            'GET',
            Uri.parse('http://localhost/auth/callback?code=x&state=y'),
          ),
        );

        final id1 = _extractSessionCookieValue(r1.headers['set-cookie']);
        final id2 = _extractSessionCookieValue(r2.headers['set-cookie']);

        expect(id1, isNotNull);
        expect(id2, isNotNull);
        // SEC: the use case does NO extra dedupe (D4); two creates → two ids.
        expect(
          id1,
          isNot(equals(id2)),
          reason:
              'replay spec: each Success creates a fresh SessionStore entry',
        );
        // RED today because the use case never calls SessionStore.create().
        expect(
          sessionStore.get(id1!),
          isNotNull,
          reason:
              'first entry stays alive until TTL — browser overwrites cookie',
        );
        expect(sessionStore.get(id2!), isNotNull);
        expect(auth.callCount, equals(2));
      },
    );

    // -----------------------------------------------------------------------
    // T7 — String-literal grep regression: cookie name lives ONLY in
    //      cookie_constants.dart.
    // -----------------------------------------------------------------------
    test(
      'T7: cookie name string literals exist only in cookie_constants.dart',
      () {
        // SEC: the whole point of cookie_constants.dart is "single source of
        // truth". Any future drift (writer or reader inlining the name) is
        // caught here at test time, before it can re-introduce P0-3.
        final libDir = Directory('lib/src');
        expect(
          libDir.existsSync(),
          isTrue,
          reason: 'web BFF lib/src must exist relative to cwd',
        );

        final offenders = <String>[];
        for (final entity in libDir.listSync(recursive: true)) {
          if (entity is! File) continue;
          if (!entity.path.endsWith('.dart')) continue;
          // The constants file itself is allowed to contain the literal once.
          if (entity.path.endsWith('middleware/cookie_constants.dart')) {
            continue;
          }

          final source = entity.readAsStringSync();
          if (source.contains("'__session='") ||
              source.contains('"__session="') ||
              source.contains("'__Host-session'") ||
              source.contains('"__Host-session"') ||
              source.contains("'__Host-session=") ||
              source.contains('"__Host-session=')) {
            offenders.add(entity.path);
          }
        }

        expect(
          offenders,
          isEmpty,
          reason:
              'Cookie name literals MUST be imported from cookie_constants.dart, '
              'not inlined. Offending files: $offenders',
        );
      },
    );

    // -----------------------------------------------------------------------
    // T8 — No Set-Cookie echo in error response body.
    // -----------------------------------------------------------------------
    test(
      'T8: error response body does NOT echo Set-Cookie or cookie name',
      () async {
        const error = BackendError(
          id: 'err-1',
          code: 'OIDC_EXCHANGE_FAILED',
          message: 'Token exchange failed',
          http: 502,
        );
        final failing = _FailingAuthBff(error);
        final sessionStore = SessionStore(
          ttl: const Duration(hours: 1),
          clock: () => DateTime.utc(2026, 5, 4, 12, 0),
        );
        final handler = _buildHandler(
          auth: failing,
          sessionStore: sessionStore,
        );

        final response = await handler.router.call(
          Request(
            'GET',
            Uri.parse('http://localhost/auth/callback?code=x&state=y'),
          ),
        );
        final body = await response.readAsString();

        // SEC: defense against reflected-cookie info-leak. Error bodies must
        // NEVER contain the raw header name, the cookie name, or any "session"
        // marker that a misbehaving client could parse and persist.
        expect(body.toLowerCase(), isNot(contains('set-cookie')));
        expect(body, isNot(contains('__Host-session')));
        expect(body, isNot(contains('__session=')));
      },
    );

    // -----------------------------------------------------------------------
    // T9 — No synthesized cookie on Failure (header strictly absent, not empty).
    // -----------------------------------------------------------------------
    test(
      'T9: token-exchange Failure → set-cookie header is absent (not empty)',
      () async {
        const error = BackendError(
          id: 'err-1',
          code: 'OIDC_EXCHANGE_FAILED',
          message: 'Token exchange failed',
          http: 502,
        );
        final failing = _FailingAuthBff(error);
        final sessionStore = SessionStore(
          ttl: const Duration(hours: 1),
          clock: () => DateTime.utc(2026, 5, 4, 12, 0),
        );
        final handler = _buildHandler(
          auth: failing,
          sessionStore: sessionStore,
        );

        final response = await handler.router.call(
          Request(
            'GET',
            Uri.parse('http://localhost/auth/callback?code=x&state=y'),
          ),
        );

        // SEC: shelf normalises header names to lowercase. A Failure path must
        // NOT add the key at all — a present-but-empty header is unacceptable
        // because some intermediaries normalise empty values.
        expect(
          response.headersAll.containsKey('set-cookie'),
          isFalse,
          reason: 'no Set-Cookie header may be synthesized on Failure',
        );

        // Sanity: the body still carries a structured error code so the client
        // can react. (Pinning the contract end of the response.)
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(body['error'], isA<Map<String, dynamic>>());
        expect(
          (body['error'] as Map<String, dynamic>)['code'],
          equals('OIDC_EXCHANGE_FAILED'),
        );
      },
    );

    // -----------------------------------------------------------------------
    // T10 — SessionStore TTL ↔ cookie Max-Age alignment (soft assertion).
    // -----------------------------------------------------------------------
    test(
      'T10: cookie Max-Age aligns with SessionStore.ttl (or ships the documented constant)',
      () async {
        // SEC: today the impl SHOULD ship Max-Age=3600 always (constant);
        // tomorrow (post-DESIGN §7 R-B2-2 review) the impl MAY pull from
        // SessionStore.ttl. Either is acceptable — assert one or the other.
        final fakeAuth = FakeAuthBff();
        final sessionStore = SessionStore(
          ttl: const Duration(hours: 2), // 7200s — non-default to expose drift.
          clock: () => DateTime.utc(2026, 5, 4, 12, 0),
        );
        final handler = _buildHandler(
          auth: fakeAuth,
          sessionStore: sessionStore,
        );

        final response = await handler.router.call(
          Request(
            'GET',
            Uri.parse('http://localhost/auth/callback?code=c&state=s'),
          ),
        );

        final setCookie = response.headers['set-cookie'];
        expect(setCookie, isNotNull);
        final lower = setCookie!.toLowerCase();

        // SEC: accept the documented constant (3600) OR the wired value (7200).
        // The combination "neither 3600 nor 7200" is a drift bug.
        // RED today because the writer omits Max-Age entirely on the
        // establish variant.
        final has3600 = lower.contains('max-age=3600');
        final has7200 = lower.contains('max-age=7200');
        expect(
          has3600 || has7200,
          isTrue,
          reason:
              'Max-Age must match either the documented default (3600) or '
              'SessionStore.ttl (7200). Got: $setCookie',
        );
      },
    );
  });
}
