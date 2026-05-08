import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/auth/session_store.dart';
import 'package:social_care_web/src/intents/auth_callback_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/auth_callback_use_case.dart';

import 'test_observability.dart';

class _FailingAuthBff extends FakeAuthBff {
  _FailingAuthBff(this._error);

  final BackendError _error;

  @override
  Future<Result<StandardResponse<void>>> callback({
    required String code,
    required String state,
  }) async => Failure(_error);
}

void main() {
  group('AuthCallbackUseCase (Wave 0 — contract-based)', () {
    late FakeAuthBff fakeAuth;
    late SessionStore sessionStore;
    late ObservabilityContext obs;
    late AuthCallbackUseCase useCase;

    setUp(() {
      fakeAuth = FakeAuthBff();
      sessionStore = SessionStore(
        ttl: const Duration(hours: 1),
        clock: () => DateTime.utc(2026, 5, 4, 12, 0),
      );
      obs = ObservabilityContext.noop();
      useCase = AuthCallbackUseCase(auth: fakeAuth, sessionStore: sessionStore);
    });

    test('returns Success when AuthContract.callback succeeds', () async {
      final result = await useCase.execute(
        const AuthCallbackIntent(code: 'abc', state: 'xyz'),
        obs,
      );

      expect(result, isA<Success>());
    });

    test('emits auth.callback.received breadcrumb on dispatch', () async {
      await useCase.execute(
        const AuthCallbackIntent(code: 'abc', state: 'xyz'),
        obs,
      );

      expect(obs.breadcrumbs, contains(hasEvent('auth.callback.received')));
    });

    test('emits auth.callback.session_established on success', () async {
      await useCase.execute(
        const AuthCallbackIntent(code: 'abc', state: 'xyz'),
        obs,
      );

      expect(
        obs.breadcrumbs,
        contains(hasEvent('auth.callback.session_established')),
      );
    });

    test('breadcrumb never contains the raw OIDC code (PII masking)', () async {
      const rawCode = 'raw-oidc-code-secret-value';
      await useCase.execute(
        const AuthCallbackIntent(code: rawCode, state: 'xyz'),
        obs,
      );

      for (final record in obs.breadcrumbs) {
        final dumped = record.data.toString();
        expect(
          dumped,
          isNot(contains(rawCode)),
          reason: 'OIDC code must be masked (prefix-only) in observability',
        );
      }
    });

    test(
      'breadcrumb may carry masked code prefix (e.g. first 6 chars + ***)',
      () async {
        await useCase.execute(
          const AuthCallbackIntent(code: 'abcdef-secret', state: 'xyz'),
          obs,
        );

        final received = obs.breadcrumbs.firstWhere(
          (b) => b.event == 'auth.callback.received',
        );
        // Either "codePrefix" key exists with masked form OR code is absent.
        final codePrefix = received.data['codePrefix'];
        if (codePrefix != null) {
          expect(
            codePrefix,
            allOf(
              isA<String>(),
              predicate<String>((s) => s.endsWith('***'), 'ends with *** mask'),
            ),
          );
        }
      },
    );

    test('returns Failure when AuthContract.callback fails', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'OIDC_EXCHANGE_FAILED',
        message: 'Token exchange failed',
        http: 502,
      );
      final failing = _FailingAuthBff(error);
      final failingUseCase = AuthCallbackUseCase(
        auth: failing,
        sessionStore: sessionStore,
      );

      final result = await failingUseCase.execute(
        const AuthCallbackIntent(code: 'abc', state: 'xyz'),
        obs,
      );

      expect(result, isA<Failure>());
    });

    test('emits auth.callback.failed on backend failure', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'OIDC_EXCHANGE_FAILED',
        message: 'Token exchange failed',
        http: 502,
      );
      final failing = _FailingAuthBff(error);
      final failingUseCase = AuthCallbackUseCase(
        auth: failing,
        sessionStore: sessionStore,
      );

      await failingUseCase.execute(
        const AuthCallbackIntent(code: 'abc', state: 'xyz'),
        obs,
      );

      expect(obs.breadcrumbs, contains(hasEvent('auth.callback.failed')));
    });
  });
}
