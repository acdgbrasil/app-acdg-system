import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/me_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/me_use_case.dart';

import 'test_observability.dart';

class _FailingAuthBff extends FakeAuthBff {
  _FailingAuthBff(this._error);

  final BackendError _error;

  @override
  Future<Result<StandardResponse<MeResponse>>> me() async => Failure(_error);
}

void main() {
  group('MeUseCase', () {
    late FakeAuthBff fakeAuth;
    late ObservabilityContext obs;
    late MeUseCase useCase;

    setUp(() {
      fakeAuth = FakeAuthBff();
      obs = ObservabilityContext.noop();
      useCase = MeUseCase(auth: fakeAuth);
    });

    test('returns Success with MeResponse payload', () async {
      final result = await useCase.execute(
        const MeIntent(sessionId: 'session-abc'),
        obs,
      );

      expect(result, isA<Success<MeResponse>>());
      switch (result) {
        case Success(:final value):
          expect(value.userId, equals('fake-user-id'));
          expect(value.email, equals('fake@acdgbrasil.com.br'));
          expect(value.roles, equals(<String>['social_worker']));
        case Failure():
          fail('Expected Success');
      }
    });

    test('emits auth.me.received breadcrumb on dispatch', () async {
      await useCase.execute(const MeIntent(sessionId: 'session-abc'), obs);

      expect(obs.breadcrumbs, contains(hasEvent('auth.me.received')));
    });

    test('emits auth.me.resolved breadcrumb on success', () async {
      await useCase.execute(const MeIntent(sessionId: 'session-abc'), obs);

      expect(obs.breadcrumbs, contains(hasEvent('auth.me.resolved')));
    });

    test('breadcrumbs do NOT contain user email in raw form (PII)', () async {
      fakeAuth.setMe(
        const MeResponse(
          userId: 'user-1',
          email: 'alice.secret@example.com',
          fullName: 'Alice Secret',
          roles: <String>['social_worker'],
        ),
      );

      await useCase.execute(const MeIntent(sessionId: 'session-abc'), obs);

      for (final record in obs.breadcrumbs) {
        final dumped = record.data.toString();
        expect(
          dumped,
          isNot(contains('alice.secret@example.com')),
          reason:
              'Email must not be logged in full (hash parcial ou domain-only)',
        );
      }
    });

    test('returns Failure when AuthContract.me fails', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'SESSION_INVALID',
        message: 'No valid session',
        http: 401,
      );
      final failing = _FailingAuthBff(error);
      final failingUseCase = MeUseCase(auth: failing);

      final result = await failingUseCase.execute(
        const MeIntent(sessionId: 'session-abc'),
        obs,
      );

      expect(result, isA<Failure<MeResponse>>());
    });

    test('emits auth.me.failed breadcrumb on backend failure', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'SESSION_INVALID',
        message: 'No valid session',
        http: 401,
      );
      final failing = _FailingAuthBff(error);
      final failingUseCase = MeUseCase(auth: failing);

      await failingUseCase.execute(
        const MeIntent(sessionId: 'session-abc'),
        obs,
      );

      expect(obs.breadcrumbs, contains(hasEvent('auth.me.failed')));
    });
  });
}
