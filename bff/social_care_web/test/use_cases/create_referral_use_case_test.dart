import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/create_referral_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/create_referral_use_case.dart';

import 'test_observability.dart';

/// Forces every call to [ProtectionContract.createReferral] to fail with
/// the configured [BackendError]. Used to validate the failure-path breadcrumb.
class _FailingProtection extends FakeProtectionBff {
  _FailingProtection(this.error);
  final BackendError error;

  @override
  Future<Result<StandardIdResponse>> createReferral(
    String patientId,
    CreateReferralRequest request,
  ) async => Failure(error);
}

const _request = CreateReferralRequest(
  referredPersonId: '660e8400-e29b-41d4-a716-446655440001',
  destinationService: 'CRAS Vila Nova',
  reason: 'Encaminhamento para acompanhamento psicossocial',
  professionalId: 'prof-42',
  date: '2026-04-17T10:00:00Z',
);

const _intent = CreateReferralIntent(patientId: 'pat-1', request: _request);

void main() {
  group('CreateReferralUseCase', () {
    late FakeProtectionBff fakeProtection;
    late ObservabilityContext obs;
    late CreateReferralUseCase useCase;

    setUp(() {
      fakeProtection = FakeProtectionBff();
      obs = ObservabilityContext.noop();
      useCase = CreateReferralUseCase(protection: fakeProtection);
    });

    test('returns Success with StandardIdResponse on happy path', () async {
      final result = await useCase.execute(_intent, obs);

      expect(result, isA<Success<StandardIdResponse>>());
      switch (result) {
        case Success(:final value):
          expect(value.data.id, isNotEmpty);
        case Failure():
          fail('Expected Success');
      }
    });

    test('persists referral on the fake store (side-effect)', () async {
      await useCase.execute(_intent, obs);

      expect(fakeProtection.store.referrals, hasLength(1));
      expect(
        fakeProtection.store.referrals.first.referredPersonId,
        equals('660e8400-e29b-41d4-a716-446655440001'),
      );
    });

    test(
      'emits protection.referral.create.received with patientId only',
      () async {
        await useCase.execute(_intent, obs);

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('protection.referral.create.received', {
              'patientId': 'pat-1',
            }),
          ),
        );
      },
    );

    test('emits protection.referral.create.completed on success', () async {
      await useCase.execute(_intent, obs);

      expect(
        obs.breadcrumbs,
        contains(hasEvent('protection.referral.create.completed')),
      );
    });

    test('.completed breadcrumb carries referralId (non-PII UUID)', () async {
      final result = await useCase.execute(_intent, obs);

      final expectedId = switch (result) {
        Success(:final value) => value.data.id,
        Failure() => fail('Expected Success'),
      };

      final completed = obs.breadcrumbs.firstWhere(
        (b) => b.event == 'protection.referral.create.completed',
      );
      expect(completed.data['referralId'], equals(expectedId));
    });

    test('propagates Failure when protection.createReferral fails', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'INVALID_DESTINATION',
        message: 'destination service not registered',
        http: 422,
      );
      final failing = _FailingProtection(error);
      final useCaseFail = CreateReferralUseCase(protection: failing);

      final result = await useCaseFail.execute(_intent, obs);

      expect(result, isA<Failure<StandardIdResponse>>());
    });

    test(
      'emits protection.referral.create.failed on backend failure with errorCode',
      () async {
        const error = BackendError(
          id: 'err-1',
          code: 'INVALID_DESTINATION',
          message: 'destination service not registered',
          http: 422,
        );
        final failing = _FailingProtection(error);
        final useCaseFail = CreateReferralUseCase(protection: failing);

        await useCaseFail.execute(_intent, obs);

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('protection.referral.create.failed', {
              'errorCode': 'INVALID_DESTINATION',
            }),
          ),
        );
      },
    );

    test(
      'breadcrumbs NEVER echo raw reason (PII — case history canon)',
      () async {
        await useCase.execute(_intent, obs);

        for (final record in obs.breadcrumbs) {
          final dumped = record.data.toString();
          expect(
            dumped,
            isNot(contains('acompanhamento psicossocial')),
            reason: 'reason must not surface in breadcrumb data',
          );
          expect(
            dumped,
            isNot(contains('Encaminhamento para')),
            reason: 'reason must not surface in breadcrumb data',
          );
        }
      },
    );

    test(
      'breadcrumbs NEVER echo destinationService (PII-adjacent — facility)',
      () async {
        await useCase.execute(_intent, obs);

        for (final record in obs.breadcrumbs) {
          final dumped = record.data.toString();
          expect(dumped, isNot(contains('CRAS Vila Nova')));
        }
      },
    );
  });
}
