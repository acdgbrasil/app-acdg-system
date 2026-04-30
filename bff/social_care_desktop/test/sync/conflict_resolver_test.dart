/// RED-phase tests for `ConflictResolver` (A18a-v2).
///
/// `ConflictResolver` maps an arbitrary error (the `error` field of a
/// `Failure<T>` returned by a sub-contract call) onto a `SyncDecision`
/// — the engine then translates the decision to a state transition on
/// the Outbox row.
///
/// ── Surface under test ────────────────────────────────────────────────
///   * `sealed class SyncDecision` with three final variants:
///       - `CompletedDecision`   — should never occur on a failure path,
///         present for completeness; not exercised here.
///       - `RetriableDecision(this.reason)`  — re-queue with backoff.
///       - `DeadDecision(this.reason)`       — terminal; manual reconcile.
///   * `class ConflictResolver { SyncDecision decide(Object error); }`
///
/// ── Mapping rules (from STATE.md) ─────────────────────────────────────
///   1. `BackendErrorResponse(http: 409)`         → `DeadDecision` (D2 (B))
///   2. `BackendErrorResponse(http: >=500)`       → `RetriableDecision`
///   3. `BackendErrorResponse(http: 400/401/403/404)` → `DeadDecision`
///   4. `DioException()` (timeout, network)       → `RetriableDecision`
///   5. unknown `Object`                          → `RetriableDecision`
///                                                  (conservative default)
///
/// REGRA #2: 4xx-other-than-409 dead vs retriable. STATE.md says ALL
/// 4xx (other than 409) → Dead, on the rationale that 4xx are caller
/// errors that won't fix themselves. We test 400/401/403/404 explicitly
/// as Dead. If the implementer chooses to special-case 401 (token
/// expired → retriable after refresh) they MUST flag that as a contract
/// change, not silently weaken the test.
///
/// IMPORTANT (RED phase): `ConflictResolver` and the `SyncDecision`
/// hierarchy do NOT exist yet. The `import` line fails — that is the
/// intended RED signal. W1 implements them at
/// `lib/src/sync/engine/conflict_resolver.dart`.
library;

import 'package:dio/dio.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/sync/engine/conflict_resolver.dart';

void main() {
  const resolver = ConflictResolver();

  /// Builds a synthetic `BackendErrorResponse` with a given http status.
  /// The other fields are unused by the resolver, so they are cosmetic.
  BackendErrorResponse backendErr({required int http, String code = 'X'}) {
    return BackendErrorResponse(
      error: BackendError(
        id: 'err-id',
        code: code,
        message: 'synthetic',
        http: http,
      ),
    );
  }

  group('ConflictResolver — backend error mapping', () {
    test('http 409 → DeadDecision (manual reconciliation, D2 (B))', () {
      final decision = resolver.decide(
        backendErr(http: 409, code: 'OPTIMISTIC_LOCK_CONFLICT'),
      );
      expect(decision, isA<DeadDecision>());
    });

    test('http 500/502/503 → RetriableDecision', () {
      for (final code in [500, 502, 503]) {
        expect(
          resolver.decide(backendErr(http: code)),
          isA<RetriableDecision>(),
          reason: 'http $code is a server-side fault, retriable',
        );
      }
    });

    test('http 400/401/403/404 → DeadDecision (caller error)', () {
      for (final code in [400, 401, 403, 404]) {
        expect(
          resolver.decide(backendErr(http: code)),
          isA<DeadDecision>(),
          reason: 'http $code will not fix itself by retrying',
        );
      }
    });
  });

  group('ConflictResolver — network / timeout', () {
    test('DioException (connection timeout) → RetriableDecision', () {
      final dioErr = DioException(
        requestOptions: RequestOptions(path: '/api/v1/patients'),
        type: DioExceptionType.connectionTimeout,
        message: 'connect timeout',
      );
      expect(resolver.decide(dioErr), isA<RetriableDecision>());
    });

    test('DioException (connection error / offline) → RetriableDecision', () {
      final dioErr = DioException(
        requestOptions: RequestOptions(path: '/api/v1/patients'),
        type: DioExceptionType.connectionError,
        message: 'host unreachable',
      );
      expect(resolver.decide(dioErr), isA<RetriableDecision>());
    });
  });

  group('ConflictResolver — unknown errors', () {
    test('arbitrary Exception → RetriableDecision (conservative)', () {
      expect(resolver.decide(Exception('boom')), isA<RetriableDecision>());
    });

    test('arbitrary String → RetriableDecision (conservative)', () {
      expect(resolver.decide('oops'), isA<RetriableDecision>());
    });
  });
}
