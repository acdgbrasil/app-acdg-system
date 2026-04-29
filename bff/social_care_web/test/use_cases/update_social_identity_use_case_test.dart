import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/update_social_identity_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/update_social_identity_use_case.dart';

import 'test_observability.dart';

/// Wave 0 RED for the new [UpdateSocialIdentityUseCase].
///
/// Canonical simple UseCase:
/// - `registry.social_identity.update.received` — `patientId`
/// - `registry.social_identity.update.completed` — on success
/// - `registry.social_identity.update.failed` — on error
class _FailingRegistry extends FakeRegistryBff {
  _FailingRegistry(this.error);
  final BackendError error;

  @override
  Future<Result<void>> updateSocialIdentity(
    String patientId,
    UpdateSocialIdentityRequest request,
  ) async => Failure(error);
}

const _intent = UpdateSocialIdentityIntent(
  patientId: 'pat-1',
  request: UpdateSocialIdentityRequest(
    typeId: 'type-lgbtqia',
    description: 'Self-identifies as non-binary',
  ),
);

void main() {
  group('UpdateSocialIdentityUseCase', () {
    late FakeRegistryBff fakeRegistry;
    late ObservabilityContext obs;
    late UpdateSocialIdentityUseCase useCase;

    setUp(() {
      fakeRegistry = FakeRegistryBff();
      obs = ObservabilityContext.noop();
      useCase = UpdateSocialIdentityUseCase(registry: fakeRegistry);
    });

    test('returns Success when registry accepts the update', () async {
      final result = await useCase.execute(_intent, obs);

      expect(result, isA<Success<StandardResponse<void>>>());
    });

    test(
      'emits registry.social_identity.update.received with patientId',
      () async {
        await useCase.execute(_intent, obs);

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('registry.social_identity.update.received', {
              'patientId': 'pat-1',
            }),
          ),
        );
      },
    );

    test(
      'emits registry.social_identity.update.completed on success',
      () async {
        await useCase.execute(_intent, obs);

        expect(
          obs.breadcrumbs,
          contains(hasEvent('registry.social_identity.update.completed')),
        );
      },
    );

    test(
      'propagates Failure when registry.updateSocialIdentity fails',
      () async {
        const error = BackendError(
          id: 'err-1',
          code: 'IDENTITY_TYPE_NOT_FOUND',
          message: 'typeId does not match any lookup',
          http: 404,
        );
        final failing = _FailingRegistry(error);
        final useCaseFail = UpdateSocialIdentityUseCase(registry: failing);

        final result = await useCaseFail.execute(_intent, obs);

        expect(result, isA<Failure<StandardResponse<void>>>());
      },
    );

    test(
      'emits registry.social_identity.update.failed with errorCode on failure',
      () async {
        const error = BackendError(
          id: 'err-1',
          code: 'IDENTITY_TYPE_NOT_FOUND',
          message: 'typeId does not match any lookup',
          http: 404,
        );
        final failing = _FailingRegistry(error);
        final useCaseFail = UpdateSocialIdentityUseCase(registry: failing);

        await useCaseFail.execute(_intent, obs);

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('registry.social_identity.update.failed', {
              'errorCode': 'IDENTITY_TYPE_NOT_FOUND',
            }),
          ),
        );
      },
    );

    test('breadcrumbs carry no PII payload', () async {
      await useCase.execute(_intent, obs);

      for (final record in obs.breadcrumbs) {
        final dumped = record.data.toString();
        // The intent carries no CPF/fullName, but description is free-form:
        // Wave 1 MUST NOT forward it into breadcrumb data.
        expect(dumped, isNot(contains('Self-identifies as non-binary')));
      }
    });
  });
}
