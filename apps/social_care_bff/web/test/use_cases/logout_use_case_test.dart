import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/logout_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/logout_use_case.dart';

import 'test_observability.dart';

class _FailingAuthBff extends FakeAuthBff {
  _FailingAuthBff(this._error);

  final BackendError _error;

  @override
  Future<Result<StandardResponse<void>>> logout() async => Failure(_error);
}

void main() {
  group('LogoutUseCase', () {
    late FakeAuthBff fakeAuth;
    late ObservabilityContext obs;
    late LogoutUseCase useCase;

    setUp(() {
      fakeAuth = FakeAuthBff();
      obs = ObservabilityContext.noop();
      useCase = LogoutUseCase(auth: fakeAuth);
    });

    test('returns Success when AuthContract.logout succeeds', () async {
      final result = await useCase.execute(
        const LogoutIntent(sessionId: 'session-abc'),
        obs,
      );

      expect(result, isA<Success>());
    });

    test('emits auth.logout.received breadcrumb on dispatch', () async {
      await useCase.execute(const LogoutIntent(sessionId: 'session-abc'), obs);

      expect(obs.breadcrumbs, contains(hasEvent('auth.logout.received')));
    });

    test('emits auth.logout.completed breadcrumb on success', () async {
      await useCase.execute(const LogoutIntent(sessionId: 'session-abc'), obs);

      expect(obs.breadcrumbs, contains(hasEvent('auth.logout.completed')));
    });

    test('sessionId never appears in breadcrumb data in raw form', () async {
      const rawSessionId = 'session-super-secret-id';
      await useCase.execute(const LogoutIntent(sessionId: rawSessionId), obs);

      for (final record in obs.breadcrumbs) {
        final dumped = record.data.toString();
        expect(
          dumped,
          isNot(contains(rawSessionId)),
          reason:
              'Session identifiers must be masked or omitted in breadcrumbs',
        );
      }
    });

    test('returns Failure when AuthContract.logout fails', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'LOGOUT_FAILED',
        message: 'Revocation failed',
      );
      final failing = _FailingAuthBff(error);
      final failingUseCase = LogoutUseCase(auth: failing);

      final result = await failingUseCase.execute(
        const LogoutIntent(sessionId: 'session-abc'),
        obs,
      );

      expect(result, isA<Failure>());
    });

    test('emits auth.logout.failed breadcrumb on backend failure', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'LOGOUT_FAILED',
        message: 'Revocation failed',
      );
      final failing = _FailingAuthBff(error);
      final failingUseCase = LogoutUseCase(auth: failing);

      await failingUseCase.execute(
        const LogoutIntent(sessionId: 'session-abc'),
        obs,
      );

      expect(obs.breadcrumbs, contains(hasEvent('auth.logout.failed')));
    });
  });
}
