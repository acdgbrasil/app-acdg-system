import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/create_lookup_item_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/create_lookup_item_use_case.dart';

import 'test_observability.dart';

/// Forces every call to [LookupContract.createLookupItem] to fail with the
/// configured [BackendError]. Used to validate the failure-path breadcrumb.
class _FailingLookup extends FakeLookupBff {
  _FailingLookup(this.error);
  final BackendError error;

  @override
  Future<Result<StandardIdResponse>> createLookupItem(
    String tableName,
    CreateLookupItemRequest request,
  ) async => Failure(error);
}

const _request = CreateLookupItemRequest(codigo: 'MAE', descricao: 'Mae');

const _intent = CreateLookupItemIntent(
  tableName: 'dominio_parentesco',
  request: _request,
);

void main() {
  group('CreateLookupItemUseCase', () {
    late FakeLookupBff fakeLookup;
    late ObservabilityContext obs;
    late CreateLookupItemUseCase useCase;

    setUp(() {
      fakeLookup = FakeLookupBff();
      obs = ObservabilityContext.noop();
      useCase = CreateLookupItemUseCase(lookup: fakeLookup);
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

    test('persists item on the fake store (side-effect)', () async {
      await useCase.execute(_intent, obs);

      expect(fakeLookup.store.tables['dominio_parentesco'], isNotNull);
      expect(fakeLookup.store.tables['dominio_parentesco'], hasLength(1));
    });

    test('emits lookup.item.create.received with tableName only', () async {
      await useCase.execute(_intent, obs);

      expect(
        obs.breadcrumbs,
        contains(
          hasEventWithData('lookup.item.create.received', {
            'tableName': 'dominio_parentesco',
          }),
        ),
      );
    });

    test('emits lookup.item.create.completed on success', () async {
      await useCase.execute(_intent, obs);

      expect(
        obs.breadcrumbs,
        contains(hasEvent('lookup.item.create.completed')),
      );
    });

    test('.completed breadcrumb carries itemId (non-PII UUID)', () async {
      final result = await useCase.execute(_intent, obs);

      final expectedId = switch (result) {
        Success(:final value) => value.data.id,
        Failure() => fail('Expected Success'),
      };

      final completed = obs.breadcrumbs.firstWhere(
        (b) => b.event == 'lookup.item.create.completed',
      );
      expect(completed.data['itemId'], equals(expectedId));
    });

    test('propagates Failure when lookup.createLookupItem fails', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'DUPLICATE_CODE',
        message: 'codigo already exists',
        http: 409,
      );
      final failing = _FailingLookup(error);
      final useCaseFail = CreateLookupItemUseCase(lookup: failing);

      final result = await useCaseFail.execute(_intent, obs);

      expect(result, isA<Failure<StandardIdResponse>>());
    });

    test(
      'emits lookup.item.create.failed with errorCode on backend failure',
      () async {
        const error = BackendError(
          id: 'err-1',
          code: 'DUPLICATE_CODE',
          message: 'codigo already exists',
          http: 409,
        );
        final failing = _FailingLookup(error);
        final useCaseFail = CreateLookupItemUseCase(lookup: failing);

        await useCaseFail.execute(_intent, obs);

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('lookup.item.create.failed', {
              'errorCode': 'DUPLICATE_CODE',
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
            isNot(contains('MAE')),
            reason: 'codigo must not surface in breadcrumb data',
          );
          expect(
            dumped,
            isNot(contains('Mae')),
            reason: 'descricao must not surface in breadcrumb data',
          );
        }
      },
    );
  });
}
