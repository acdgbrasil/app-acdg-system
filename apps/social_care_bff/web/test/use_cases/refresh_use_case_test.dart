import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/refresh_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/refresh_use_case.dart';

import 'test_observability.dart';

class _FailingAuthBff extends FakeAuthBff {
  _FailingAuthBff(this._error);

  final BackendError _error;

  @override
  Future<Result<StandardResponse<void>>> refresh() async => Failure(_error);
}

void main() {
  group('RefreshUseCase', () {
    late FakeAuthBff fakeAuth;
    late ObservabilityContext obs;
    late RefreshUseCase useCase;

    setUp(() {
      fakeAuth = FakeAuthBff();
      obs = ObservabilityContext.noop();
      useCase = RefreshUseCase(auth: fakeAuth);
    });

    test('returns Success when AuthContract.refresh succeeds', () async {
      final result = await useCase.execute(
        const RefreshIntent(sessionId: 'session-abc'),
        obs,
      );

      expect(result, isA<Success>());
    });

    test('emits auth.refresh.received breadcrumb on dispatch', () async {
      await useCase.execute(const RefreshIntent(sessionId: 'session-abc'), obs);

      expect(obs.breadcrumbs, contains(hasEvent('auth.refresh.received')));
    });

    test('emits auth.refresh.completed breadcrumb on success', () async {
      await useCase.execute(const RefreshIntent(sessionId: 'session-abc'), obs);

      expect(obs.breadcrumbs, contains(hasEvent('auth.refresh.completed')));
    });

    test('returns Failure when AuthContract.refresh fails', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'REFRESH_FAILED',
        message: 'Refresh token invalid',
      );
      final failing = _FailingAuthBff(error);
      final failingUseCase = RefreshUseCase(auth: failing);

      final result = await failingUseCase.execute(
        const RefreshIntent(sessionId: 'session-abc'),
        obs,
      );

      expect(result, isA<Failure>());
    });

    test('emits auth.refresh.failed breadcrumb on backend failure', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'REFRESH_FAILED',
        message: 'Refresh token invalid',
      );
      final failing = _FailingAuthBff(error);
      final failingUseCase = RefreshUseCase(auth: failing);

      await failingUseCase.execute(
        const RefreshIntent(sessionId: 'session-abc'),
        obs,
      );

      expect(obs.breadcrumbs, contains(hasEvent('auth.refresh.failed')));
    });

    test(
      'breadcrumbs do NOT contain refresh token or access token in any form',
      () async {
        await useCase.execute(
          const RefreshIntent(sessionId: 'session-abc'),
          obs,
        );

        for (final record in obs.breadcrumbs) {
          final dumped = record.data.toString().toLowerCase();
          expect(
            dumped,
            isNot(contains('access_token')),
            reason: 'Tokens must never appear in observability payloads',
          );
          expect(
            dumped,
            isNot(contains('refresh_token')),
            reason: 'Tokens must never appear in observability payloads',
          );
        }
      },
    );
  });
}
