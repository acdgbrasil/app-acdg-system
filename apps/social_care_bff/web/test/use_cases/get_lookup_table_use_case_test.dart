import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/get_lookup_table_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/get_lookup_table_use_case.dart';

import 'test_observability.dart';

/// Forces every call to [LookupContract.getLookupTable] to fail with the
/// configured [BackendError]. Used to validate the failure-path breadcrumb.
class _FailingLookup extends FakeLookupBff {
  _FailingLookup(this.error);
  final BackendError error;

  @override
  Future<Result<StandardResponse<List<LookupItemResponse>>>> getLookupTable(
    String tableName,
  ) async => Failure(error);
}

const _intent = GetLookupTableIntent(tableName: 'dominio_parentesco');

void main() {
  group('GetLookupTableUseCase', () {
    late FakeLookupBff fakeLookup;
    late ObservabilityContext obs;
    late GetLookupTableUseCase useCase;

    setUp(() {
      fakeLookup = FakeLookupBff();
      obs = ObservabilityContext.noop();
      useCase = GetLookupTableUseCase(lookup: fakeLookup);
    });

    test('returns Success with empty list when table is unseeded', () async {
      final result = await useCase.execute(_intent, obs);

      expect(
        result,
        isA<Success<StandardResponse<List<LookupItemResponse>>>>(),
      );
      switch (result) {
        case Success(:final value):
          expect(value.data, isEmpty);
        case Failure():
          fail('Expected Success');
      }
    });

    test('returns Success with seeded items', () async {
      fakeLookup.store.addItem(
        'dominio_parentesco',
        const LookupItemResponse(id: '1', codigo: 'MAE', descricao: 'Mae'),
      );
      fakeLookup.store.addItem(
        'dominio_parentesco',
        const LookupItemResponse(id: '2', codigo: 'PAI', descricao: 'Pai'),
      );

      final result = await useCase.execute(_intent, obs);

      switch (result) {
        case Success(:final value):
          expect(value.data, hasLength(2));
        case Failure():
          fail('Expected Success');
      }
    });

    test('emits lookup.table.get.received with tableName', () async {
      await useCase.execute(_intent, obs);

      expect(
        obs.breadcrumbs,
        contains(
          hasEventWithData('lookup.table.get.received', {
            'tableName': 'dominio_parentesco',
          }),
        ),
      );
    });

    test('emits lookup.table.get.completed with count on success', () async {
      fakeLookup.store.addItem(
        'dominio_parentesco',
        const LookupItemResponse(id: '1', codigo: 'MAE', descricao: 'Mae'),
      );
      fakeLookup.store.addItem(
        'dominio_parentesco',
        const LookupItemResponse(id: '2', codigo: 'PAI', descricao: 'Pai'),
      );

      await useCase.execute(_intent, obs);

      expect(
        obs.breadcrumbs,
        contains(hasEventWithData('lookup.table.get.completed', {'count': 2})),
      );
    });

    test('propagates Failure when lookup.getLookupTable fails', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'LOOKUP_UNAVAILABLE',
        message: 'upstream down',
        http: 502,
      );
      final failing = _FailingLookup(error);
      final useCaseFail = GetLookupTableUseCase(lookup: failing);

      final result = await useCaseFail.execute(_intent, obs);

      expect(
        result,
        isA<Failure<StandardResponse<List<LookupItemResponse>>>>(),
      );
    });

    test(
      'emits lookup.table.get.failed with errorCode on backend failure',
      () async {
        const error = BackendError(
          id: 'err-1',
          code: 'LOOKUP_UNAVAILABLE',
          message: 'upstream down',
          http: 502,
        );
        final failing = _FailingLookup(error);
        final useCaseFail = GetLookupTableUseCase(lookup: failing);

        await useCaseFail.execute(_intent, obs);

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('lookup.table.get.failed', {
              'errorCode': 'LOOKUP_UNAVAILABLE',
            }),
          ),
        );
      },
    );
  });
}
