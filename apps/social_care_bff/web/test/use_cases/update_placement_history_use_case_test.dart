import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/update_placement_history_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/update_placement_history_use_case.dart';

import 'test_observability.dart';

/// Forces every call to [ProtectionContract.updatePlacementHistory] to fail
/// with the configured [BackendError]. Used to validate the failure-path
/// breadcrumb.
class _FailingProtection extends FakeProtectionBff {
  _FailingProtection(this.error);
  final BackendError error;

  @override
  Future<Result<void>> updatePlacementHistory(
    String patientId,
    UpdatePlacementHistoryRequest request,
  ) async => Failure(error);
}

const _request = UpdatePlacementHistoryRequest(
  registries: [
    RegistryDraftDto(
      memberId: '770e8400-e29b-41d4-a716-446655440002',
      startDate: '2023-05-01',
      reason: 'Afastamento por violencia domestica',
    ),
  ],
  collectiveSituations: CollectiveDraftDto(
    homeLossReport: 'Familia perdeu moradia em enchente de 2023',
    thirdPartyGuardReport: 'Criancas sob guarda de vizinhos — mae presa',
  ),
  separationChecklist: SeparationDraftDto(
    adultInPrison: true,
    adolescentInInternment: false,
  ),
);

const _intent = UpdatePlacementHistoryIntent(
  patientId: 'pat-1',
  request: _request,
);

void main() {
  group('UpdatePlacementHistoryUseCase', () {
    late FakeProtectionBff fakeProtection;
    late ObservabilityContext obs;
    late UpdatePlacementHistoryUseCase useCase;

    setUp(() {
      fakeProtection = FakeProtectionBff();
      obs = ObservabilityContext.noop();
      useCase = UpdatePlacementHistoryUseCase(protection: fakeProtection);
    });

    test(
      'returns Success with StandardResponse<void> when protection accepts update',
      () async {
        final result = await useCase.execute(_intent, obs);

        expect(result, isA<Success<StandardResponse<void>>>());
      },
    );

    test('persists placement on the fake store (side-effect)', () async {
      await useCase.execute(_intent, obs);

      final stored = fakeProtection.store.getPlacement('pat-1');
      expect(stored, isNotNull);
      expect(stored!.individualPlacements, hasLength(1));
    });

    test(
      'emits protection.placement_history.update.received with patientId',
      () async {
        await useCase.execute(_intent, obs);

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('protection.placement_history.update.received', {
              'patientId': 'pat-1',
            }),
          ),
        );
      },
    );

    test(
      'emits protection.placement_history.update.completed on success',
      () async {
        await useCase.execute(_intent, obs);

        expect(
          obs.breadcrumbs,
          contains(hasEvent('protection.placement_history.update.completed')),
        );
      },
    );

    test(
      'propagates Failure when protection.updatePlacementHistory fails',
      () async {
        const error = BackendError(
          id: 'err-1',
          code: 'INVALID_PLACEMENT',
          message: 'placement history invalid',
          http: 409,
        );
        final failing = _FailingProtection(error);
        final useCaseFail = UpdatePlacementHistoryUseCase(protection: failing);

        final result = await useCaseFail.execute(_intent, obs);

        expect(result, isA<Failure<StandardResponse<void>>>());
      },
    );

    test(
      'emits protection.placement_history.update.failed on backend failure',
      () async {
        const error = BackendError(
          id: 'err-1',
          code: 'INVALID_PLACEMENT',
          message: 'placement history invalid',
          http: 409,
        );
        final failing = _FailingProtection(error);
        final useCaseFail = UpdatePlacementHistoryUseCase(protection: failing);

        await useCaseFail.execute(_intent, obs);

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('protection.placement_history.update.failed', {
              'errorCode': 'INVALID_PLACEMENT',
            }),
          ),
        );
      },
    );

    test(
      'received breadcrumb carries ONLY patientId (no registries dump)',
      () async {
        await useCase.execute(_intent, obs);

        final received = obs.breadcrumbs.firstWhere(
          (b) => b.event == 'protection.placement_history.update.received',
        );
        expect(received.data.keys.toSet(), equals({'patientId'}));
      },
    );

    test(
      'breadcrumbs NEVER echo homeLossReport (PII — family narrative)',
      () async {
        await useCase.execute(_intent, obs);

        for (final record in obs.breadcrumbs) {
          final dumped = record.data.toString();
          expect(dumped, isNot(contains('Familia perdeu moradia')));
          expect(dumped, isNot(contains('enchente')));
          expect(dumped, isNot(contains('2023')));
        }
      },
    );

    test(
      'breadcrumbs NEVER echo thirdPartyGuardReport (PII — family narrative)',
      () async {
        await useCase.execute(_intent, obs);

        for (final record in obs.breadcrumbs) {
          final dumped = record.data.toString();
          expect(dumped, isNot(contains('vizinhos')));
          expect(dumped, isNot(contains('mae presa')));
          expect(dumped, isNot(contains('Criancas sob guarda')));
        }
      },
    );

    test(
      'breadcrumbs NEVER echo registries[].reason / memberId (PII)',
      () async {
        await useCase.execute(_intent, obs);

        for (final record in obs.breadcrumbs) {
          final dumped = record.data.toString();
          expect(dumped, isNot(contains('violencia domestica')));
          expect(dumped, isNot(contains('Afastamento')));
          expect(
            dumped,
            isNot(contains('770e8400-e29b-41d4-a716-446655440002')),
            reason: 'memberId UUID must not leak through breadcrumbs',
          );
        }
      },
    );

    test('breadcrumbs NEVER echo separationChecklist boolean flags', () async {
      await useCase.execute(_intent, obs);

      // Not PII per se, but the canonical breadcrumb set is
      // {patientId} / {} / {errorCode}. Checklist values don't belong.
      for (final record in obs.breadcrumbs) {
        expect(record.data.containsKey('adultInPrison'), isFalse);
        expect(record.data.containsKey('adolescentInInternment'), isFalse);
      }
    });
  });
}
