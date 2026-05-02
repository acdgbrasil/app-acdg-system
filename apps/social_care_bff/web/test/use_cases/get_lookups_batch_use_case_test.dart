import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/get_lookups_batch_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/get_lookups_batch_use_case.dart';

import 'test_observability.dart';

/// Forces every call to [LookupContract.getLookupsBatch] to fail with the
/// configured [BackendError]. Used to validate the failure-path breadcrumb.
class _FailingLookup extends FakeLookupBff {
  _FailingLookup(this.error);
  final BackendError error;

  @override
  Future<Result<StandardResponse<LookupsBatchResponse>>> getLookupsBatch(
    List<String> tables,
  ) async => Failure(error);
}

const _intent = GetLookupsBatchIntent(
  tables: ['dominio_parentesco', 'dominio_tipo_identidade'],
);

void main() {
  group('GetLookupsBatchUseCase', () {
    late FakeLookupBff fakeLookup;
    late ObservabilityContext obs;
    late GetLookupsBatchUseCase useCase;

    setUp(() {
      fakeLookup = FakeLookupBff();
      obs = ObservabilityContext.noop();
      useCase = GetLookupsBatchUseCase(lookup: fakeLookup);
    });

    test('returns Success with empty lists when tables are unseeded', () async {
      final result = await useCase.execute(_intent, obs);

      expect(result, isA<Success<StandardResponse<LookupsBatchResponse>>>());
      switch (result) {
        case Success(:final value):
          expect(value.data.tables, hasLength(2));
          expect(value.data.tables['dominio_parentesco'], isEmpty);
          expect(value.data.tables['dominio_tipo_identidade'], isEmpty);
        case Failure():
          fail('Expected Success');
      }
    });

    test('returns Success with seeded items keyed by table name', () async {
      fakeLookup.store.addItem(
        'dominio_parentesco',
        const LookupItemResponse(id: '1', codigo: 'MAE', descricao: 'Mae'),
      );
      fakeLookup.store.addItem(
        'dominio_parentesco',
        const LookupItemResponse(id: '2', codigo: 'PAI', descricao: 'Pai'),
      );
      fakeLookup.store.addItem(
        'dominio_tipo_identidade',
        const LookupItemResponse(id: '10', codigo: 'RG', descricao: 'RG'),
      );

      final result = await useCase.execute(_intent, obs);

      switch (result) {
        case Success(:final value):
          expect(value.data.tables['dominio_parentesco'], hasLength(2));
          expect(value.data.tables['dominio_tipo_identidade'], hasLength(1));
        case Failure():
          fail('Expected Success');
      }
    });

    test('emits lookup.batch.get.received with tableCount', () async {
      await useCase.execute(_intent, obs);

      expect(
        obs.breadcrumbs,
        contains(
          hasEventWithData('lookup.batch.get.received', {'tableCount': 2}),
        ),
      );
    });

    test(
      'emits lookup.batch.get.completed with totalItems on success',
      () async {
        fakeLookup.store.addItem(
          'dominio_parentesco',
          const LookupItemResponse(id: '1', codigo: 'MAE', descricao: 'Mae'),
        );
        fakeLookup.store.addItem(
          'dominio_parentesco',
          const LookupItemResponse(id: '2', codigo: 'PAI', descricao: 'Pai'),
        );
        fakeLookup.store.addItem(
          'dominio_tipo_identidade',
          const LookupItemResponse(id: '10', codigo: 'RG', descricao: 'RG'),
        );

        await useCase.execute(_intent, obs);

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('lookup.batch.get.completed', {'totalItems': 3}),
          ),
        );
      },
    );

    test('propagates Failure when lookup.getLookupsBatch fails', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'LOOKUP_UNAVAILABLE',
        message: 'upstream down',
        http: 502,
      );
      final failing = _FailingLookup(error);
      final useCaseFail = GetLookupsBatchUseCase(lookup: failing);

      final result = await useCaseFail.execute(_intent, obs);

      expect(result, isA<Failure<StandardResponse<LookupsBatchResponse>>>());
    });

    test(
      'emits lookup.batch.get.failed with errorCode on backend failure',
      () async {
        const error = BackendError(
          id: 'err-1',
          code: 'LOOKUP_UNAVAILABLE',
          message: 'upstream down',
          http: 502,
        );
        final failing = _FailingLookup(error);
        final useCaseFail = GetLookupsBatchUseCase(lookup: failing);

        await useCaseFail.execute(_intent, obs);

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('lookup.batch.get.failed', {
              'errorCode': 'LOOKUP_UNAVAILABLE',
            }),
          ),
        );
      },
    );
  });
}
