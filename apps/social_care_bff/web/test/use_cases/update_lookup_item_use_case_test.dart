import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/update_lookup_item_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/update_lookup_item_use_case.dart';

import 'test_observability.dart';

/// Forces every call to [LookupContract.updateLookupItem] to fail with the
/// configured [BackendError]. Used to validate the failure-path breadcrumb.
class _FailingLookup extends FakeLookupBff {
  _FailingLookup(this.error);
  final BackendError error;

  @override
  Future<Result<StandardResponse<void>>> updateLookupItem(
    String tableName,
    String itemId,
    UpdateLookupItemRequest request,
  ) async => Failure(error);
}

const _request = UpdateLookupItemRequest(
  codigo: 'NEW_CODE',
  descricao: 'New description',
);

const _intent = UpdateLookupItemIntent(
  tableName: 'dominio_parentesco',
  itemId: 'item-1',
  request: _request,
);

void main() {
  group('UpdateLookupItemUseCase', () {
    late FakeLookupBff fakeLookup;
    late ObservabilityContext obs;
    late UpdateLookupItemUseCase useCase;

    setUp(() {
      fakeLookup = FakeLookupBff();
      obs = ObservabilityContext.noop();
      useCase = UpdateLookupItemUseCase(lookup: fakeLookup);
    });

    test('returns Success with StandardResponse<void> on happy path', () async {
      final result = await useCase.execute(_intent, obs);

      expect(result, isA<Success<StandardResponse<void>>>());
    });

    test('emits lookup.item.update.received with tableName + itemId', () async {
      await useCase.execute(_intent, obs);

      expect(
        obs.breadcrumbs,
        contains(
          hasEventWithData('lookup.item.update.received', {
            'tableName': 'dominio_parentesco',
            'itemId': 'item-1',
          }),
        ),
      );
    });

    test('emits lookup.item.update.completed on success', () async {
      await useCase.execute(_intent, obs);

      expect(
        obs.breadcrumbs,
        contains(hasEvent('lookup.item.update.completed')),
      );
    });

    test('propagates Failure when lookup.updateLookupItem fails', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'ITEM_NOT_FOUND',
        message: 'item does not exist',
        http: 404,
      );
      final failing = _FailingLookup(error);
      final useCaseFail = UpdateLookupItemUseCase(lookup: failing);

      final result = await useCaseFail.execute(_intent, obs);

      expect(result, isA<Failure<StandardResponse<void>>>());
    });

    test(
      'emits lookup.item.update.failed with errorCode on backend failure',
      () async {
        const error = BackendError(
          id: 'err-1',
          code: 'ITEM_NOT_FOUND',
          message: 'item does not exist',
          http: 404,
        );
        final failing = _FailingLookup(error);
        final useCaseFail = UpdateLookupItemUseCase(lookup: failing);

        await useCaseFail.execute(_intent, obs);

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('lookup.item.update.failed', {
              'errorCode': 'ITEM_NOT_FOUND',
            }),
          ),
        );
      },
    );

    test(
      'breadcrumbs NEVER echo raw codigo / descricao (domain content)',
      () async {
        await useCase.execute(_intent, obs);

        for (final record in obs.breadcrumbs) {
          final dumped = record.data.toString();
          expect(
            dumped,
            isNot(contains('NEW_CODE')),
            reason: 'codigo must not surface in breadcrumb data',
          );
          expect(
            dumped,
            isNot(contains('New description')),
            reason: 'descricao must not surface in breadcrumb data',
          );
        }
      },
    );
  });
}
