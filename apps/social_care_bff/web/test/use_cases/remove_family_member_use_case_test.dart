import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/remove_family_member_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/remove_family_member_use_case.dart';

import 'test_observability.dart';

/// Wave 0 RED for the new [RemoveFamilyMemberUseCase].
///
/// Canonical simple UseCase:
/// - `registry.family.remove.received` — `patientId` + `memberId`
/// - `registry.family.remove.completed` — on success
/// - `registry.family.remove.failed` — on error (carries `errorCode`)
class _FailingRegistry extends FakeRegistryBff {
  _FailingRegistry(this.error);
  final BackendError error;

  @override
  Future<Result<void>> removeFamilyMember(
    String patientId,
    String memberId,
  ) async => Failure(error);
}

const _intent = RemoveFamilyMemberIntent(
  patientId: 'pat-1',
  memberId: 'mem-42',
);

void main() {
  group('RemoveFamilyMemberUseCase', () {
    late FakeRegistryBff fakeRegistry;
    late ObservabilityContext obs;
    late RemoveFamilyMemberUseCase useCase;

    setUp(() {
      fakeRegistry = FakeRegistryBff();
      obs = ObservabilityContext.noop();
      useCase = RemoveFamilyMemberUseCase(registry: fakeRegistry);
    });

    test('returns Success when registry accepts the removal', () async {
      final result = await useCase.execute(_intent, obs);

      expect(result, isA<Success<StandardResponse<void>>>());
    });

    test(
      'emits registry.family.remove.received with patientId + memberId',
      () async {
        await useCase.execute(_intent, obs);

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('registry.family.remove.received', {
              'patientId': 'pat-1',
              'memberId': 'mem-42',
            }),
          ),
        );
      },
    );

    test('emits registry.family.remove.completed on success', () async {
      await useCase.execute(_intent, obs);

      expect(
        obs.breadcrumbs,
        contains(hasEvent('registry.family.remove.completed')),
      );
    });

    test('propagates Failure when registry.removeFamilyMember fails', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'MEMBER_NOT_FOUND',
        message: 'member does not belong to patient',
        http: 404,
      );
      final failing = _FailingRegistry(error);
      final useCaseFail = RemoveFamilyMemberUseCase(registry: failing);

      final result = await useCaseFail.execute(_intent, obs);

      expect(result, isA<Failure<StandardResponse<void>>>());
    });

    test(
      'emits registry.family.remove.failed with errorCode on backend failure',
      () async {
        const error = BackendError(
          id: 'err-1',
          code: 'MEMBER_NOT_FOUND',
          message: 'member does not belong to patient',
          http: 404,
        );
        final failing = _FailingRegistry(error);
        final useCaseFail = RemoveFamilyMemberUseCase(registry: failing);

        await useCaseFail.execute(_intent, obs);

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('registry.family.remove.failed', {
              'errorCode': 'MEMBER_NOT_FOUND',
            }),
          ),
        );
      },
    );

    test('breadcrumbs carry no PII payload', () async {
      await useCase.execute(_intent, obs);

      for (final record in obs.breadcrumbs) {
        final dumped = record.data.toString();
        // There's no CPF/fullName on this intent, but guard the canon.
        expect(dumped, isNot(contains('11144477735')));
      }
    });
  });
}
