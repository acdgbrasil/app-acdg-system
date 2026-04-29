import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/toggle_lookup_item_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/toggle_lookup_item_use_case.dart';

import 'test_observability.dart';

/// Forces every call to [LookupContract.toggleLookupItem] to fail with the
/// configured [BackendError]. Used to validate the failure-path breadcrumb.
class _FailingLookup extends FakeLookupBff {
  _FailingLookup(this.error);
  final BackendError error;

  @override
  Future<Result<StandardResponse<void>>> toggleLookupItem(
    String tableName,
    String itemId,
    ToggleLookupItemRequest request,
  ) async => Failure(error);
}

const _request = ToggleLookupItemRequest(active: false);

const _intent = ToggleLookupItemIntent(
  tableName: 'dominio_parentesco',
  itemId: 'item-1',
  request: _request,
);

void main() {
  group('ToggleLookupItemUseCase', () {
    late FakeLookupBff fakeLookup;
    late ObservabilityContext obs;
    late ToggleLookupItemUseCase useCase;

    setUp(() {
      fakeLookup = FakeLookupBff();
      obs = ObservabilityContext.noop();
      useCase = ToggleLookupItemUseCase(lookup: fakeLookup);
    });

    test('returns Success with StandardResponse<void> on happy path', () async {
      final result = await useCase.execute(_intent, obs);

      expect(result, isA<Success<StandardResponse<void>>>());
    });

    test(
      'emits lookup.item.toggle.received with tableName + itemId + active',
      () async {
        await useCase.execute(_intent, obs);

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('lookup.item.toggle.received', {
              'tableName': 'dominio_parentesco',
              'itemId': 'item-1',
              'active': false,
            }),
          ),
        );
      },
    );

    test('.received breadcrumb carries active flag (non-PII bool)', () async {
      const intentOn = ToggleLookupItemIntent(
        tableName: 'dominio_parentesco',
        itemId: 'item-1',
        request: ToggleLookupItemRequest(active: true),
      );

      await useCase.execute(intentOn, obs);

      final received = obs.breadcrumbs.firstWhere(
        (b) => b.event == 'lookup.item.toggle.received',
      );
      expect(received.data['active'], isTrue);
    });

    test('emits lookup.item.toggle.completed on success', () async {
      await useCase.execute(_intent, obs);

      expect(
        obs.breadcrumbs,
        contains(hasEvent('lookup.item.toggle.completed')),
      );
    });

    test('propagates Failure when lookup.toggleLookupItem fails', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'ITEM_NOT_FOUND',
        message: 'item does not exist',
        http: 404,
      );
      final failing = _FailingLookup(error);
      final useCaseFail = ToggleLookupItemUseCase(lookup: failing);

      final result = await useCaseFail.execute(_intent, obs);

      expect(result, isA<Failure<StandardResponse<void>>>());
    });

    test(
      'emits lookup.item.toggle.failed with errorCode on backend failure',
      () async {
        const error = BackendError(
          id: 'err-1',
          code: 'ITEM_NOT_FOUND',
          message: 'item does not exist',
          http: 404,
        );
        final failing = _FailingLookup(error);
        final useCaseFail = ToggleLookupItemUseCase(lookup: failing);

        await useCaseFail.execute(_intent, obs);

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('lookup.item.toggle.failed', {
              'errorCode': 'ITEM_NOT_FOUND',
            }),
          ),
        );
      },
    );
  });
}
