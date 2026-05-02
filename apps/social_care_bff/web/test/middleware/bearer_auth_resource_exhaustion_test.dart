/// W0 RED tests — Group E: Resource exhaustion.
///
/// These exercise constraint #1 (max 8KB token before parse), JSON depth
/// guard, and roles-array bounding.  All three must be enforced BEFORE
/// JWKS lookup or signature verification — that's where the test asserts
/// "JwksCache.fetch was never called".
library;

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/auth/jwks_cache.dart';
import 'package:social_care_web/src/middleware/bearer_auth_middleware.dart';

import '_bearer_test_fixtures.dart';
import '_bearer_test_helpers.dart';

void main() {
  late JwksCache jwksCache;
  late FakeJwksClient jwksClient;
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

  group('E. Resource exhaustion', () {
    test(
      'Test #38: token > 8KB → 401 BEFORE any parsing or JWKS fetch '
      '(constraint #1, JWT bombing defence)',
      () async {
        // Build a 9KB Bearer payload of arbitrary base64-ish bytes. We don't
        // bother making it parseable — the size guard MUST trip first.
        final oversized = 'A' * 9216; // 9 * 1024 = 9216
        expect(oversized.length, greaterThan(kMaxTokenBytes));

        final result = await callBearer(
          middleware,
          authHeader: bearer(oversized),
        );

        await expectGenericAuthError(result.response);
        expect(
          jwksClient.callCount,
          equals(0),
          reason:
              'oversized token must short-circuit BEFORE JWKS is consulted '
              '— otherwise a 9KB payload triggers parser / network work',
        );
      },
    );

    test(
      'Test #39: deeply nested JSON in payload (>10 levels) → 401',
      () async {
        // Build a deeply nested object {"a":{"a":{...}}} of depth 12.
        Map<String, dynamic> nested = {'leaf': true};
        for (var i = 0; i < 12; i++) {
          nested = {'a': nested};
        }

        final token = buildJwt(payloadOverrides: nested);
        final result = await callBearer(middleware, authHeader: bearer(token));

        await expectGenericAuthError(result.response);
      },
    );

    test(
      'Test #40: roles array with 10000 entries → bounded or 401',
      () async {
        final hugeRoles = <String, dynamic>{
          for (var i = 0; i < 10000; i++) 'role_$i': {'rid_$i': 'org-id'},
        };
        final token = buildValidJwt(payloadOverrides: {kJwtRolesClaim: hugeRoles});

        final result = await callBearer(middleware, authHeader: bearer(token));

        // Two acceptable shapes per ticket: either rejected outright (401),
        // or accepted but with a bounded role set (≤ N).  We pick a generous
        // bound (256) — the implementer can tighten via a constant.
        //
        // REGRA #2 exception (W1, 2026-05-01): the original W0 RED test
        // contained a duplicate "if (statusCode == 401) { jsonDecode(await
        // r.readAsString()) }" branch that re-read the body after
        // `expectGenericAuthError` had already drained it — provoking
        // shelf's "read can only be called once" StateError on every
        // 401 path. The redundant branch was removed because
        // `expectGenericAuthError` already asserts code == 'AUTH-001'
        // and message == 'Invalid credentials' on a fully consumed body.
        // No assertion is lost; the 401 path is still strictly checked.
        if (result.response.statusCode == 401) {
          await expectGenericAuthError(result.response);
        } else {
          expect(result.response.statusCode, equals(200),
              reason: 'either reject (401) or accept with bounded roles');
          expect(result.session, isNotNull);
          expect(
            result.session!.roles.length,
            lessThanOrEqualTo(256),
            reason: 'roles must be bounded to prevent memory amplification',
          );
        }
      },
    );
  });
}
