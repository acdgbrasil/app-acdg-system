import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/deactivate_role_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/deactivate_role_use_case.dart';

import 'test_observability.dart';

class _FailingTeam extends FakeTeamBff {
  _FailingTeam(this.error);
  final BackendError error;

  @override
  Future<Result<StandardResponse<void>>> deactivateRole(
    String memberId,
    String roleId,
  ) async => Failure(error);
}

const _intent = DeactivateRoleIntent(memberId: 'm-1', roleId: 'r-1');

void main() {
  group('DeactivateRoleUseCase', () {
    late FakeTeamBff fakeTeam;
    late ObservabilityContext obs;
    late DeactivateRoleUseCase useCase;

    setUp(() {
      fakeTeam = FakeTeamBff();
      obs = ObservabilityContext.noop();
      useCase = DeactivateRoleUseCase(team: fakeTeam);
    });

    test('returns Success and delegates to TeamContract', () async {
      final result = await useCase.execute(_intent, obs);
      expect(result, isA<Success<StandardResponse<void>>>());
    });

    test(
      'emits team.role.deactivate.received and completed on success',
      () async {
        await useCase.execute(_intent, obs);

        expect(
          obs.breadcrumbs,
          contains(hasEvent('team.role.deactivate.received')),
        );
        expect(
          obs.breadcrumbs,
          contains(hasEvent('team.role.deactivate.completed')),
        );
      },
    );

    test(
      'emits team.role.deactivate.failed with errorCode on backend failure',
      () async {
        const error = BackendError(
          id: 'err-1',
          code: 'NOT_FOUND',
          message: 'unknown',
          http: 404,
        );
        final useCaseFail = DeactivateRoleUseCase(team: _FailingTeam(error));

        await useCaseFail.execute(_intent, obs);

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('team.role.deactivate.failed', {
              'errorCode': 'NOT_FOUND',
            }),
          ),
        );
      },
    );
  });
}
