import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/get_team_member_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/get_team_member_use_case.dart';

import 'test_observability.dart';

class _FailingTeam extends FakeTeamBff {
  _FailingTeam(this.error);
  final BackendError error;

  @override
  Future<Result<StandardResponse<TeamMemberDetailResponse>>> getTeamMember(
    String memberId,
  ) async => Failure(error);
}

const _intent = GetTeamMemberIntent(memberId: 'm-1');

void main() {
  group('GetTeamMemberUseCase', () {
    late FakeTeamBff fakeTeam;
    late ObservabilityContext obs;
    late GetTeamMemberUseCase useCase;

    setUp(() {
      fakeTeam = FakeTeamBff();
      obs = ObservabilityContext.noop();
      useCase = GetTeamMemberUseCase(team: fakeTeam);
    });

    test('returns Success with the seeded member', () async {
      fakeTeam.store.register(
        const TeamMemberResponse(
          id: 'm-1',
          personId: 'p-1',
          fullName: 'Maria Silva',
          email: 'maria@example.com',
          phone: null,
          active: true,
          primaryRole: null,
        ),
      );

      final result = await useCase.execute(_intent, obs);

      switch (result) {
        case Success(:final value):
          expect(value.data.id, equals('m-1'));
          expect(value.data.fullName, equals('Maria Silva'));
        case Failure():
          fail('Expected Success');
      }
    });

    test('emits team.get.received and completed with roleCount', () async {
      fakeTeam.store.register(
        const TeamMemberResponse(
          id: 'm-1',
          personId: 'p-1',
          fullName: 'Maria',
          email: null,
          phone: null,
          active: true,
          primaryRole: null,
        ),
      );

      await useCase.execute(_intent, obs);

      expect(obs.breadcrumbs, contains(hasEvent('team.get.received')));
      expect(
        obs.breadcrumbs,
        contains(hasEventWithData('team.get.completed', {'roleCount': 0})),
      );
    });

    test('propagates Failure with errorCode breadcrumb', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'NOT_FOUND',
        message: 'no member',
        http: 404,
      );
      final useCaseFail = GetTeamMemberUseCase(team: _FailingTeam(error));

      final result = await useCaseFail.execute(_intent, obs);

      expect(result, isA<Failure<StandardResponse<TeamMemberDetailResponse>>>());
      expect(
        obs.breadcrumbs,
        contains(hasEventWithData('team.get.failed', {'errorCode': 'NOT_FOUND'})),
      );
    });
  });
}
