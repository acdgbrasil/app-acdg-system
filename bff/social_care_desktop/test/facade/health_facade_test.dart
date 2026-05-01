/// RED-phase tests for [HealthFacade] (A18c-v2).
///
/// 2 public methods delegate to the 2 Health use cases (A18b-v2). Health
/// is Pattern 3 — pure passthrough; no cache, no queue.
///
/// Locked contract:
///
///   class HealthFacade {
///     HealthFacade._({
///       required CheckHealthUseCase checkHealth,
///       required CheckReadyUseCase checkReady,
///     });
///     Future<Result<void>> checkHealth();
///     Future<Result<void>> checkReady();
///   }
///
/// IMPORTANT (RED phase): the facade does NOT exist yet. Imports fail.
library;

import 'package:shared/shared.dart';
// ignore_for_file: depend_on_referenced_packages
import 'package:test/test.dart';

import '_test_helpers.dart';

void main() {
  Future<SocialCareDesktop> build(FacadeTestContext ctx) =>
      SocialCareDesktop.create(
        baseUrl: 'http://localhost:8080',
        actorId: 'actor-123',
        tokenProvider: kStaticToken('test-token'),
        cacheFilePath: ':memory:',
        syncQueueFilePath: ':memory:',
        dio: ctx.dio,
        clock: ctx.fakeClock,
        connectivity: ctx.fakeConnectivity,
      );

  group('HealthFacade — wiring smoke', () {
    test('checkHealth returns Result<void>', () async {
      final ctx = FacadeTestContext.fresh();
      addTearDown(ctx.close);
      final desktop = await build(ctx);
      addTearDown(desktop.close);

      final result = await desktop.health.checkHealth();
      expect(result, isA<Result<void>>());
    });

    test('checkReady returns Result<void>', () async {
      final ctx = FacadeTestContext.fresh();
      addTearDown(ctx.close);
      final desktop = await build(ctx);
      addTearDown(desktop.close);

      final result = await desktop.health.checkReady();
      expect(result, isA<Result<void>>());
    });
  });
}
