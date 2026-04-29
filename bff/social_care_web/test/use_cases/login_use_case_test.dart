import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/login_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/login_use_case.dart';

import 'test_observability.dart';

/// A [FakeAuthBff] variant that forces `login()` to return a [Failure].
///
/// Placed in the test file (private) to keep behavior close to each spec —
/// per feedback_mapper_per_request (each endpoint gets its own shape).
class _FailingAuthBff extends FakeAuthBff {
  _FailingAuthBff(this._error);

  final BackendError _error;

  @override
  Future<Result<String>> login() async => Failure(_error);
}

void main() {
  group('LoginUseCase', () {
    late FakeAuthBff fakeAuth;
    late ObservabilityContext obs;
    late LoginUseCase useCase;

    setUp(() {
      fakeAuth = FakeAuthBff();
      obs = ObservabilityContext.noop();
      useCase = LoginUseCase(auth: fakeAuth);
    });

    test('returns Success with redirect URL from the AuthContract', () async {
      final result = await useCase.execute(const LoginIntent(), obs);

      expect(result, isA<Success<String>>());
      switch (result) {
        case Success(:final value):
          expect(value, equals('https://fake-idp.local/authorize?state=fake'));
        case Failure():
          fail('Expected Success');
      }
    });

    test('emits auth.login.received breadcrumb on dispatch', () async {
      await useCase.execute(const LoginIntent(), obs);

      expect(obs.breadcrumbs, contains(hasEvent('auth.login.received')));
    });

    test('emits auth.login.redirect_issued breadcrumb on success', () async {
      await useCase.execute(const LoginIntent(), obs);

      expect(obs.breadcrumbs, contains(hasEvent('auth.login.redirect_issued')));
    });

    test('forwards returnTo into breadcrumb data when present', () async {
      await useCase.execute(const LoginIntent(returnTo: '/dashboard'), obs);

      expect(
        obs.breadcrumbs,
        contains(
          hasEventWithData('auth.login.received', {'returnTo': '/dashboard'}),
        ),
      );
    });

    test(
      'redirect URL breadcrumb does NOT leak client_secret or full query string',
      () async {
        await useCase.execute(const LoginIntent(), obs);

        for (final record in obs.breadcrumbs) {
          final dumped = record.data.toString();
          expect(
            dumped.toLowerCase(),
            isNot(contains('client_secret')),
            reason: 'client_secret is forbidden in observability payloads',
          );
        }
      },
    );

    test('returns Failure when AuthContract.login fails', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'OIDC_UNAVAILABLE',
        message: 'Zitadel unreachable',
      );
      final failing = _FailingAuthBff(error);
      final failingUseCase = LoginUseCase(auth: failing);

      final result = await failingUseCase.execute(const LoginIntent(), obs);

      expect(result, isA<Failure<String>>());
    });

    test('emits auth.login.failed breadcrumb on backend failure', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'OIDC_UNAVAILABLE',
        message: 'Zitadel unreachable',
      );
      final failing = _FailingAuthBff(error);
      final failingUseCase = LoginUseCase(auth: failing);

      await failingUseCase.execute(const LoginIntent(), obs);

      expect(obs.breadcrumbs, contains(hasEvent('auth.login.failed')));
    });
  });
}
