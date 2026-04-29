import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/list_team_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/list_team_use_case.dart';

import 'test_observability.dart';

class _FailingTeam extends FakeTeamBff {
  _FailingTeam(this.error);
  final BackendError error;

  @override
  Future<Result<StandardResponse<List<TeamMemberResponse>>>> listTeam({
    String? role,
    bool? active,
    String? search,
  }) async => Failure(error);
}

void main() {
  group('ListTeamUseCase', () {
    late FakeTeamBff fakeTeam;
    late ObservabilityContext obs;
    late ListTeamUseCase useCase;

    setUp(() {
      fakeTeam = FakeTeamBff();
      obs = ObservabilityContext.noop();
      useCase = ListTeamUseCase(team: fakeTeam);
    });

    test('returns Success with empty list when team is unseeded', () async {
      final result = await useCase.execute(const ListTeamIntent(), obs);

      switch (result) {
        case Success(:final value):
          expect(value.data, isEmpty);
        case Failure():
          fail('Expected Success');
      }
    });

    test('forwards filters to TeamContract.listTeam', () async {
      fakeTeam.store.register(
        const TeamMemberResponse(
          id: 'm-1',
          personId: 'p-1',
          fullName: 'Maria Silva',
          email: 'maria@example.com',
          phone: null,
          active: true,
          primaryRole: 'social_worker',
        ),
      );

      final result = await useCase.execute(
        const ListTeamIntent(
          role: 'social_worker',
          active: true,
          search: 'Maria',
        ),
        obs,
      );

      switch (result) {
        case Success(:final value):
          expect(value.data, hasLength(1));
          expect(value.data.first.fullName, equals('Maria Silva'));
        case Failure():
          fail('Expected Success');
      }
    });

    test(
      'emits team.list.received with hasRole / hasActive / hasSearch booleans',
      () async {
        await useCase.execute(
          const ListTeamIntent(role: 'admin', search: 'maria'),
          obs,
        );

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('team.list.received', {
              'hasRole': true,
              'hasActive': false,
              'hasSearch': true,
            }),
          ),
        );
      },
    );

    test('emits team.list.completed with count on success', () async {
      fakeTeam.store.register(
        const TeamMemberResponse(
          id: 'm-1',
          personId: 'p-1',
          fullName: 'A',
          email: null,
          phone: null,
          active: true,
          primaryRole: null,
        ),
      );

      await useCase.execute(const ListTeamIntent(), obs);

      expect(
        obs.breadcrumbs,
        contains(hasEventWithData('team.list.completed', {'count': 1})),
      );
    });

    test('breadcrumb data NEVER includes raw search / role values', () async {
      await useCase.execute(
        const ListTeamIntent(role: 'admin', search: 'maria'),
        obs,
      );

      for (final bc in obs.breadcrumbs) {
        for (final v in bc.data.values) {
          if (v is String) {
            expect(v, isNot(equals('maria')));
            expect(v, isNot(equals('admin')));
          }
        }
      }
    });

    test('propagates Failure when team.listTeam fails', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'TEAM_UNAVAILABLE',
        message: 'upstream down',
        http: 502,
      );
      final useCaseFail = ListTeamUseCase(team: _FailingTeam(error));

      final result = await useCaseFail.execute(const ListTeamIntent(), obs);

      expect(result, isA<Failure<StandardResponse<List<TeamMemberResponse>>>>());
    });

    test('emits team.list.failed with errorCode on backend failure', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'TEAM_UNAVAILABLE',
        message: 'upstream down',
        http: 502,
      );
      final useCaseFail = ListTeamUseCase(team: _FailingTeam(error));

      await useCaseFail.execute(const ListTeamIntent(), obs);

      expect(
        obs.breadcrumbs,
        contains(
          hasEventWithData('team.list.failed', {
            'errorCode': 'TEAM_UNAVAILABLE',
          }),
        ),
      );
    });
  });
}
