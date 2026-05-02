import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/deactivate_worker_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/deactivate_worker_use_case.dart';

import 'test_observability.dart';

class _FailingTeam extends FakeTeamBff {
  _FailingTeam(this.error);
  final BackendError error;

  @override
  Future<Result<StandardResponse<void>>> deactivateWorker(
    String memberId,
  ) async => Failure(error);
}

const _intent = DeactivateWorkerIntent(memberId: 'm-1');

void main() {
  group('DeactivateWorkerUseCase', () {
    late FakeTeamBff fakeTeam;
    late ObservabilityContext obs;
    late DeactivateWorkerUseCase useCase;

    setUp(() {
      fakeTeam = FakeTeamBff();
      obs = ObservabilityContext.noop();
      useCase = DeactivateWorkerUseCase(team: fakeTeam);
    });

    test('returns Success and delegates to TeamContract', () async {
      fakeTeam.store.register(
        const TeamMemberResponse(
          id: 'm-1',
          personId: 'p-1',
          fullName: 'M',
          email: null,
          phone: null,
          active: true,
          primaryRole: null,
        ),
      );

      final result = await useCase.execute(_intent, obs);

      expect(result, isA<Success<StandardResponse<void>>>());
      expect(fakeTeam.store.get('m-1')?.active, isFalse);
    });

    test('emits team.deactivate.received and completed on success', () async {
      await useCase.execute(_intent, obs);

      expect(obs.breadcrumbs, contains(hasEvent('team.deactivate.received')));
      expect(obs.breadcrumbs, contains(hasEvent('team.deactivate.completed')));
    });

    test('emits team.deactivate.failed with errorCode on backend failure', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'WORKER_LOCKED',
        message: 'cannot deactivate',
        http: 409,
      );
      final useCaseFail = DeactivateWorkerUseCase(team: _FailingTeam(error));

      final result = await useCaseFail.execute(_intent, obs);

      expect(result, isA<Failure<StandardResponse<void>>>());
      expect(
        obs.breadcrumbs,
        contains(
          hasEventWithData('team.deactivate.failed', {
            'errorCode': 'WORKER_LOCKED',
          }),
        ),
      );
    });
  });
}
