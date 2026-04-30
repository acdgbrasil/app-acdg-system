/// RED-phase tests for Health use cases (A18b-v2).
///
/// 2 use cases, both pure passthroughs (Pattern 3):
///   * `CheckHealthUseCase` — delegates to `remote.checkHealth()`.
///   * `CheckReadyUseCase`  — delegates to `remote.checkReady()`.
///
/// Liveness/readiness are real-time signals — no cache, no queue.
///
/// IMPORTANT (RED phase): Use cases under
/// `lib/src/use_cases/health/...` do NOT exist yet. Imports fail.
library;

import 'package:core_contracts/core_contracts.dart';
import 'package:test/test.dart';

// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/health/check_health_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/health/check_ready_use_case.dart';

import '_test_helpers.dart';

void main() {
  group('CheckHealthUseCase (Pattern 3 — passthrough)', () {
    test('delegates to remote.checkHealth and returns Success', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      final useCase = CheckHealthUseCase(remote: ctx.fakeHealth);

      final result = await useCase();
      expect(result, isA<Success<void>>());
    });

    test('propagates Failure from remote', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      // Cast to access programmable fake.
      (ctx.fakeHealth as dynamic).healthResult =
          const Failure<void>('upstream down');

      final useCase = CheckHealthUseCase(remote: ctx.fakeHealth);

      final result = await useCase();
      expect(result, isA<Failure<void>>());
    });

    test('does not touch caches or outbox', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      final useCase = CheckHealthUseCase(remote: ctx.fakeHealth);

      await useCase();

      // Outbox stayed empty.
      final pending = await ctx.outbox.listByStatus(OutboxStatus.pending);
      expect((pending as Success<List<OutboxEntry>>).value, isEmpty);

      // Engine NOT triggered.
      expect(ctx.fakeEngine.triggerDrainCount, 0);
    });
  });

  group('CheckReadyUseCase (Pattern 3 — passthrough)', () {
    test('delegates to remote.checkReady and returns Success', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      final useCase = CheckReadyUseCase(remote: ctx.fakeHealth);

      final result = await useCase();
      expect(result, isA<Success<void>>());
    });

    test('propagates Failure from remote', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      (ctx.fakeHealth as dynamic).readyResult =
          const Failure<void>('dependency unhealthy');

      final useCase = CheckReadyUseCase(remote: ctx.fakeHealth);

      final result = await useCase();
      expect(result, isA<Failure<void>>());
    });

    test('does not touch caches or outbox', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      final useCase = CheckReadyUseCase(remote: ctx.fakeHealth);

      await useCase();

      final pending = await ctx.outbox.listByStatus(OutboxStatus.pending);
      expect((pending as Success<List<OutboxEntry>>).value, isEmpty);
      expect(ctx.fakeEngine.triggerDrainCount, 0);
    });
  });
}
