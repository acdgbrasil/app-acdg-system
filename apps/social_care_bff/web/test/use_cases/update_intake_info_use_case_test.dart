import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/update_intake_info_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/update_intake_info_use_case.dart';

import 'test_observability.dart';

/// Forces every call to [CareContract.updateIntakeInfo] to fail with the
/// configured [BackendError]. Used to validate the failure-path breadcrumb.
class _FailingCare extends FakeCareBff {
  _FailingCare(this.error);
  final BackendError error;

  @override
  Future<Result<void>> updateIntakeInfo(
    String patientId,
    RegisterIntakeInfoRequest request,
  ) async => Failure(error);
}

const _request = RegisterIntakeInfoRequest(
  ingressTypeId: 'ing-spontaneous',
  serviceReason: 'Procura por apoio psicossocial',
  originName: 'Hospital Regional Santa Casa',
  originContact: '(11) 98765-4321',
);

const _intent = UpdateIntakeInfoIntent(patientId: 'pat-1', request: _request);

void main() {
  group('UpdateIntakeInfoUseCase', () {
    late FakeCareBff fakeCare;
    late ObservabilityContext obs;
    late UpdateIntakeInfoUseCase useCase;

    setUp(() {
      fakeCare = FakeCareBff();
      obs = ObservabilityContext.noop();
      useCase = UpdateIntakeInfoUseCase(care: fakeCare);
    });

    test('returns Success when care.updateIntakeInfo accepts', () async {
      final result = await useCase.execute(_intent, obs);

      expect(result, isA<Success<StandardResponse<void>>>());
    });

    test('persists intake on the fake store (side-effect)', () async {
      await useCase.execute(_intent, obs);

      expect(fakeCare.store.intakes['pat-1'], isNotNull);
    });

    test('emits care.intake.update.received with patientId only', () async {
      await useCase.execute(_intent, obs);

      expect(
        obs.breadcrumbs,
        contains(
          hasEventWithData('care.intake.update.received', {
            'patientId': 'pat-1',
          }),
        ),
      );
    });

    test('emits care.intake.update.completed on success', () async {
      await useCase.execute(_intent, obs);

      expect(
        obs.breadcrumbs,
        contains(hasEvent('care.intake.update.completed')),
      );
    });

    test('propagates Failure when care.updateIntakeInfo fails', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'INVALID_INGRESS_TYPE',
        message: 'ingress type not found',
        http: 422,
      );
      final failing = _FailingCare(error);
      final useCaseFail = UpdateIntakeInfoUseCase(care: failing);

      final result = await useCaseFail.execute(_intent, obs);

      expect(result, isA<Failure<StandardResponse<void>>>());
    });

    test(
      'emits care.intake.update.failed with errorCode on backend failure',
      () async {
        const error = BackendError(
          id: 'err-1',
          code: 'INVALID_INGRESS_TYPE',
          message: 'ingress type not found',
          http: 422,
        );
        final failing = _FailingCare(error);
        final useCaseFail = UpdateIntakeInfoUseCase(care: failing);

        await useCaseFail.execute(_intent, obs);

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('care.intake.update.failed', {
              'errorCode': 'INVALID_INGRESS_TYPE',
            }),
          ),
        );
      },
    );

    test(
      'breadcrumbs NEVER echo originName / originContact / serviceReason (PII canon)',
      () async {
        await useCase.execute(_intent, obs);

        for (final record in obs.breadcrumbs) {
          final dumped = record.data.toString();
          expect(
            dumped,
            isNot(contains('Santa Casa')),
            reason: 'originName must not surface in breadcrumb data',
          );
          expect(
            dumped,
            isNot(contains('98765-4321')),
            reason: 'originContact must not surface in breadcrumb data',
          );
          expect(
            dumped,
            isNot(contains('apoio psicossocial')),
            reason: 'serviceReason must not surface in breadcrumb data',
          );
        }
      },
    );

    test('failure breadcrumbs also never echo PII fields', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'INVALID_INGRESS_TYPE',
        message: 'ingress type not found',
        http: 422,
      );
      final failing = _FailingCare(error);
      final useCaseFail = UpdateIntakeInfoUseCase(care: failing);

      await useCaseFail.execute(_intent, obs);

      for (final record in obs.breadcrumbs) {
        final dumped = record.data.toString();
        expect(dumped, isNot(contains('Santa Casa')));
        expect(dumped, isNot(contains('98765-4321')));
        expect(dumped, isNot(contains('apoio psicossocial')));
      }
    });
  });
}
