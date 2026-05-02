/// W0 RED tests — Group G: JWKS cache concurrency, rotation, fail-closed.
///
/// These tests live in a separate file because they exercise [JwksCache]
/// directly (single-flight semantics, TTL, retry-on-mismatch) more than the
/// middleware itself.  Some of them run the middleware end-to-end to verify
/// failure propagation.
library;

import 'dart:async';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/auth/jwks_cache.dart';
import 'package:social_care_web/src/middleware/bearer_auth_middleware.dart';

import '_bearer_test_fixtures.dart';
import '_bearer_test_helpers.dart';

void main() {
  group('G. JWKS cache', () {
    late FakeJwksClient jwksClient;
    late JwksCache jwksCache;
    late Middleware middleware;
    late DateTime currentTime;

    setUp(() {
      currentTime = kNow;
      jwksClient = FakeJwksClient(
        initialJson: buildJwksJson([
          (kid: kValidKid, pair: primaryKeyPair()),
        ]),
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

    test(
      'Test #47: 100 concurrent cold-start requests → 1 JWKS fetch '
      '(single-flight)',
      () async {
        // Slow the fetch to widen the contention window.
        jwksClient.injectDelay(const Duration(milliseconds: 50));

        final futures = List.generate(
          100,
          (_) => jwksCache.getKey(kValidKid),
        );
        await Future.wait(futures);

        expect(
          jwksClient.callCount,
          equals(1),
          reason:
              '100 concurrent getKey() calls must coalesce into 1 fetch '
              '(single-flight protects the upstream JWKS endpoint)',
        );
      },
    );

    test('Test #48: JWKS endpoint timeout (5s) → fail-closed, 401 within ~5.5s',
        () async {
      // Inject a delay much longer than the configured 5s timeout.
      // The middleware MUST give up at the 5s mark (constraint: 5s timeout)
      // and return 401 — it must NOT wait the full injected duration.
      jwksClient.injectDelay(const Duration(seconds: 30));

      final token = buildValidJwt();

      // S5 hardening (W0-bis): bound the response time. If W1 ships without
      // a JWKS timeout, this test would otherwise sit waiting up to the
      // outer 10s test timeout and silently pass after ~10s. With the
      // assertion below it FAILS when W1 forgot to wire a timeout.
      final stopwatch = Stopwatch()..start();
      final result = await callBearer(
        middleware,
        authHeader: bearer(token),
      );
      stopwatch.stop();

      await expectGenericAuthError(result.response);
      expect(
        stopwatch.elapsed,
        lessThan(const Duration(milliseconds: 5500)),
        reason:
            'JWKS fetch must time out at ~5s and fail-closed. Took '
            '${stopwatch.elapsedMilliseconds}ms — middleware likely missing '
            'the upstream timeout (constraint: 5s).',
      );
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('Test #49: JWKS returns malformed JSON → fail-closed, 401', () async {
      jwksClient.jwksJson = '{not valid json';

      // Bust cache so the next call refetches.
      currentTime = currentTime.add(const Duration(minutes: 11));

      final token = buildValidJwt();
      final result = await callBearer(
        middleware,
        authHeader: bearer(token),
      );

      await expectGenericAuthError(result.response);
    });

    test('Test #50: rotation — old kid stays valid until TTL expires',
        () async {
      // Step 1: warm cache with the original (primary) key.
      await jwksCache.getKey(kValidKid);
      final initialFetches = jwksClient.callCount;

      // Step 2: Zitadel rotates — JWKS now serves only the secondary key.
      jwksClient.jwksJson = buildJwksJson([
        (kid: kSecondaryKid, pair: secondaryKeyPair()),
      ]);

      // Step 3: within the TTL, the old kid is still found locally.
      currentTime = currentTime.add(const Duration(minutes: 5));
      final keyDuringTtl = await jwksCache.getKey(kValidKid);
      expect(keyDuringTtl, isNotNull,
          reason: 'old kid must remain valid until TTL expires');
      expect(jwksClient.callCount, equals(initialFetches),
          reason: 'in-TTL hit must not refetch');

      // Step 4: after TTL the cache refreshes — old kid is now gone.
      currentTime = currentTime.add(const Duration(minutes: 6));
      final keyAfterTtl = await jwksCache.getKey(kValidKid);
      expect(keyAfterTtl, isNull,
          reason: 'after TTL the rotated-out kid must disappear');
      expect(jwksClient.callCount, greaterThan(initialFetches));
    });

    test(
      'Test #51: refresh on signature mismatch — known kid, sig fails → '
      '1 refetch, retry, then 401',
      () async {
        // Token signed with secondary key but advertises primary kid; cache
        // currently maps primary → primaryKeyPair (mismatch).
        await jwksCache.getKey(kValidKid); // warm cache
        final baseline = jwksClient.callCount;

        // Even after the implementer-driven refetch, the JWKS still maps
        // primary → primaryKeyPair (no rotation), so the second verify also
        // fails: the policy is "1 refetch only, then fail".
        final token = buildJwt(
          kid: kValidKid,
          signingKey: secondaryKeyPair(),
        );
        final result = await callBearer(
          middleware,
          authHeader: bearer(token),
        );

        await expectGenericAuthError(result.response);
        expect(
          jwksClient.callCount - baseline,
          equals(1),
          reason:
              'sig mismatch must trigger exactly one refetch; further attempts '
              'must NOT loop',
        );
      },
    );
  });
}
