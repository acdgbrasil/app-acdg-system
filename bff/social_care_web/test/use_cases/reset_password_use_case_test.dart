import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/reset_password_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/reset_password_use_case.dart';

import 'test_observability.dart';

class _FailingTeam extends FakeTeamBff {
  _FailingTeam(this.error);
  final BackendError error;

  @override
  Future<Result<StandardResponse<void>>> resetPassword(
    String memberId,
  ) async => Failure(error);
}

const _intent = ResetPasswordIntent(memberId: 'm-1');

void main() {
  group('ResetPasswordUseCase', () {
    late FakeTeamBff fakeTeam;
    late ObservabilityContext obs;
    late ResetPasswordUseCase useCase;

    setUp(() {
      fakeTeam = FakeTeamBff();
      obs = ObservabilityContext.noop();
      useCase = ResetPasswordUseCase(team: fakeTeam);
    });

    test('returns Success and delegates to TeamContract', () async {
      final result = await useCase.execute(_intent, obs);
      expect(result, isA<Success<StandardResponse<void>>>());
    });

    test(
      'emits team.reset_password.received and completed on success',
      () async {
        await useCase.execute(_intent, obs);

        expect(
          obs.breadcrumbs,
          contains(hasEvent('team.reset_password.received')),
        );
        expect(
          obs.breadcrumbs,
          contains(hasEvent('team.reset_password.completed')),
        );
      },
    );

    test(
      'emits team.reset_password.failed with errorCode on backend failure',
      () async {
        const error = BackendError(
          id: 'err-1',
          code: 'IDP_DOWN',
          message: 'zitadel unavailable',
          http: 503,
        );
        final useCaseFail = ResetPasswordUseCase(team: _FailingTeam(error));

        await useCaseFail.execute(_intent, obs);

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('team.reset_password.failed', {
              'errorCode': 'IDP_DOWN',
            }),
          ),
        );
      },
    );
  });
}
