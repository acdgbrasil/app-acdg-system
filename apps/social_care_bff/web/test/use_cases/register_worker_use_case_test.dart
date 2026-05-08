import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/register_worker_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/register_worker_use_case.dart';

import 'test_observability.dart';

class _FailingTeam extends FakeTeamBff {
  _FailingTeam(this.error);
  final BackendError error;

  @override
  Future<Result<StandardIdResponse>> registerWorker(
    RegisterPersonWithLoginRequest request,
  ) async => Failure(error);
}

const _request = RegisterPersonWithLoginRequest(
  fullName: 'Maria Silva',
  birthDate: '1990-05-12',
  email: 'maria.silva@acdgbrasil.com.br',
);

void main() {
  group('RegisterWorkerUseCase', () {
    late FakeTeamBff fakeTeam;
    late ObservabilityContext obs;
    late RegisterWorkerUseCase useCase;

    setUp(() {
      fakeTeam = FakeTeamBff();
      obs = ObservabilityContext.noop();
      useCase = RegisterWorkerUseCase(team: fakeTeam);
    });

    test('returns Success with generated id on happy path', () async {
      final result = await useCase.execute(
        const RegisterWorkerIntent(request: _request),
        obs,
      );

      switch (result) {
        case Success(:final value):
          expect(value.data.id, isNotEmpty);
          expect(fakeTeam.store.members, hasLength(1));
        case Failure():
          fail('Expected Success');
      }
    });

    test('emits team.register.received with empty data', () async {
      await useCase.execute(const RegisterWorkerIntent(request: _request), obs);

      expect(obs.breadcrumbs, contains(hasEvent('team.register.received')));
    });

    test(
      'emits team.register.completed with generated id on success',
      () async {
        final result = await useCase.execute(
          const RegisterWorkerIntent(request: _request),
          obs,
        );

        switch (result) {
          case Success(:final value):
            expect(
              obs.breadcrumbs,
              contains(
                hasEventWithData('team.register.completed', {
                  'id': value.data.id,
                }),
              ),
            );
          case Failure():
            fail('Expected Success');
        }
      },
    );

    test(
      'breadcrumb data NEVER includes fullName / email / cpf / initialPassword',
      () async {
        const request = RegisterPersonWithLoginRequest(
          fullName: 'Maria Silva',
          birthDate: '1990-05-12',
          email: 'maria.silva@acdgbrasil.com.br',
          cpf: '12345678901',
          initialPassword: 'TempPass!2026',
        );
        await useCase.execute(
          const RegisterWorkerIntent(request: request),
          obs,
        );

        for (final bc in obs.breadcrumbs) {
          for (final v in bc.data.values) {
            if (v is String) {
              expect(v, isNot(equals('Maria Silva')));
              expect(v, isNot(equals('maria.silva@acdgbrasil.com.br')));
              expect(v, isNot(equals('12345678901')));
              expect(v, isNot(equals('TempPass!2026')));
            }
          }
        }
      },
    );

    test('propagates Failure when team.registerWorker fails', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'EMAIL_TAKEN',
        message: 'curated upstream message',
        http: 409,
      );
      final useCaseFail = RegisterWorkerUseCase(team: _FailingTeam(error));

      final result = await useCaseFail.execute(
        const RegisterWorkerIntent(request: _request),
        obs,
      );

      expect(result, isA<Failure<StandardIdResponse>>());
    });

    test(
      'emits team.register.failed with errorCode on backend failure',
      () async {
        const error = BackendError(
          id: 'err-1',
          code: 'EMAIL_TAKEN',
          message: 'curated upstream message',
          http: 409,
        );
        final useCaseFail = RegisterWorkerUseCase(team: _FailingTeam(error));

        await useCaseFail.execute(
          const RegisterWorkerIntent(request: _request),
          obs,
        );

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('team.register.failed', {
              'errorCode': 'EMAIL_TAKEN',
            }),
          ),
        );
      },
    );
  });
}
