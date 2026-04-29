import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/assign_role_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/assign_role_use_case.dart';

import 'test_observability.dart';

class _FailingTeam extends FakeTeamBff {
  _FailingTeam(this.error);
  final BackendError error;

  @override
  Future<Result<StandardIdResponse>> assignRole(
    String memberId,
    AssignRoleRequest request,
  ) async => Failure(error);
}

AssignRoleIntent _intent() => AssignRoleIntent(
  memberId: 'm-1',
  request: const AssignRoleRequest(system: 'social-care', role: 'social_worker'),
);

void main() {
  group('AssignRoleUseCase', () {
    late FakeTeamBff fakeTeam;
    late ObservabilityContext obs;
    late AssignRoleUseCase useCase;

    setUp(() {
      fakeTeam = FakeTeamBff();
      obs = ObservabilityContext.noop();
      useCase = AssignRoleUseCase(team: fakeTeam);
    });

    test('returns Success with generated roleId on happy path', () async {
      final result = await useCase.execute(_intent(), obs);

      switch (result) {
        case Success(:final value):
          expect(value.data.id, isNotEmpty);
        case Failure():
          fail('Expected Success');
      }
    });

    test(
      'emits team.role.assign.received and completed with roleId',
      () async {
        final result = await useCase.execute(_intent(), obs);

        expect(
          obs.breadcrumbs,
          contains(hasEvent('team.role.assign.received')),
        );
        switch (result) {
          case Success(:final value):
            expect(
              obs.breadcrumbs,
              contains(
                hasEventWithData('team.role.assign.completed', {
                  'roleId': value.data.id,
                }),
              ),
            );
          case Failure():
            fail('Expected Success');
        }
      },
    );

    test(
      'emits team.role.assign.failed with errorCode on backend failure',
      () async {
        const error = BackendError(
          id: 'err-1',
          code: 'ROLE_CONFLICT',
          message: 'already assigned',
          http: 409,
        );
        final useCaseFail = AssignRoleUseCase(team: _FailingTeam(error));

        await useCaseFail.execute(_intent(), obs);

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('team.role.assign.failed', {
              'errorCode': 'ROLE_CONFLICT',
            }),
          ),
        );
      },
    );
  });
}
