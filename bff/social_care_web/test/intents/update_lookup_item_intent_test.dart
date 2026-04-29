import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/update_lookup_item_intent.dart';
import 'package:social_care_web/src/intents/uuid_validation.dart';

import '../_test_uuids.dart';

/// Wave 0 RED contract for [UpdateLookupItemIntent] — A13.
///
/// Canon (P2-tolerant — first use of this variant in the monorepo):
/// - Both DTO fields (`codigo`, `descricao`) are OPTIONAL (0 required).
/// - Parse is a **total function** — it NEVER returns [Failure]. Missing or
///   non-string values silently collapse to `null` via the `_asString`
///   helper; an empty `{}` body yields a Success with both fields null.
/// - Because parse never fails, there is NO `_UpdateLookupItemParseError`
///   class; the handler routes JSON-level malformed input through the
///   `INVALID_JSON` code from `_readJsonBody` before this parser runs.
///
/// Tests deliberately omit a `returns Failure` case — by design, the intent
/// has no failure path for a decoded `Map<String, dynamic>` body.
void main() {
  group('UpdateLookupItemIntent', () {
    test('constructs with tableName + itemId + UpdateLookupItemRequest', () {
      const request = UpdateLookupItemRequest(codigo: 'MAE', descricao: 'Mae');

      const intent = UpdateLookupItemIntent(
        tableName: 'dominio_parentesco',
        itemId: kLookupItemUuid,
        request: request,
      );

      expect(intent.tableName, equals('dominio_parentesco'));
      expect(intent.itemId, equals(kLookupItemUuid));
      expect(intent.request, equals(request));
    });

    test('instances with equal payload are equal (Equatable)', () {
      const request = UpdateLookupItemRequest(codigo: 'MAE', descricao: 'Mae');

      const a = UpdateLookupItemIntent(
        tableName: 'dominio_parentesco',
        itemId: kLookupItemUuid,
        request: request,
      );
      const b = UpdateLookupItemIntent(
        tableName: 'dominio_parentesco',
        itemId: kLookupItemUuid,
        request: request,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different itemId are not equal', () {
      const request = UpdateLookupItemRequest(codigo: 'MAE', descricao: 'Mae');

      const a = UpdateLookupItemIntent(
        tableName: 'dominio_parentesco',
        itemId: kLookupItemUuid,
        request: request,
      );
      const b = UpdateLookupItemIntent(
        tableName: 'dominio_parentesco',
        itemId: kLookupRequestUuid, // distinct UUID for inequality assertion
        request: request,
      );

      expect(a, isNot(equals(b)));
    });

    group(
      'parseFromBody — Result<UpdateLookupItemIntent> (P2-tolerant, total)',
      () {
        test('returns Success when both fields are provided', () {
          final result = UpdateLookupItemIntent.parseFromBody(
            'dominio_parentesco',
            kLookupItemUuid,
            const {'codigo': 'NEW_CODE', 'descricao': 'New description'},
          );

          expect(result, isA<Success<UpdateLookupItemIntent>>());
          switch (result) {
            case Success(:final value):
              expect(value.tableName, equals('dominio_parentesco'));
              expect(value.itemId, equals(kLookupItemUuid));
              expect(value.request.codigo, equals('NEW_CODE'));
              expect(value.request.descricao, equals('New description'));
            case Failure():
              fail('P2-tolerant parse must never fail');
          }
        });

        test(
          'returns Success with only codigo — descricao collapses to null',
          () {
            final result = UpdateLookupItemIntent.parseFromBody(
              'dominio_parentesco',
              kLookupItemUuid,
              const {'codigo': 'NEW_CODE'},
            );

            switch (result) {
              case Success(:final value):
                expect(value.request.codigo, equals('NEW_CODE'));
                expect(value.request.descricao, isNull);
              case Failure():
                fail('P2-tolerant parse must never fail');
            }
          },
        );

        test(
          'returns Success with only descricao — codigo collapses to null',
          () {
            final result = UpdateLookupItemIntent.parseFromBody(
              'dominio_parentesco',
              kLookupItemUuid,
              const {'descricao': 'New description'},
            );

            switch (result) {
              case Success(:final value):
                expect(value.request.codigo, isNull);
                expect(value.request.descricao, equals('New description'));
              case Failure():
                fail('P2-tolerant parse must never fail');
            }
          },
        );

        test('returns Success with both fields null when body is empty {}', () {
          final result = UpdateLookupItemIntent.parseFromBody(
            'dominio_parentesco',
            kLookupItemUuid,
            const {},
          );

          switch (result) {
            case Success(:final value):
              expect(value.tableName, equals('dominio_parentesco'));
              expect(value.itemId, equals(kLookupItemUuid));
              expect(value.request.codigo, isNull);
              expect(value.request.descricao, isNull);
            case Failure():
              fail('P2-tolerant parse must never fail on empty body');
          }
        });

        test(
          'non-string values silently collapse to null (tolerance canon)',
          () {
            final result = UpdateLookupItemIntent.parseFromBody(
              'dominio_parentesco',
              kLookupItemUuid,
              const <String, dynamic>{'codigo': 42, 'descricao': true},
            );

            switch (result) {
              case Success(:final value):
                expect(value.request.codigo, isNull);
                expect(value.request.descricao, isNull);
              case Failure():
                fail('P2-tolerant parse must never fail on type mismatch');
            }
          },
        );

        test(
          'empty string for codigo is preserved as empty string (not null)',
          () {
            // The P2-tolerant canon treats any `String` as-is — only
            // type-mismatch collapses to null. Empty-string vs null
            // semantics are the UseCase's concern, not the Intent parser's.
            final result = UpdateLookupItemIntent.parseFromBody(
              'dominio_parentesco',
              kLookupItemUuid,
              const {'codigo': '', 'descricao': ''},
            );

            switch (result) {
              case Success(:final value):
                expect(value.request.codigo, equals(''));
                expect(value.request.descricao, equals(''));
              case Failure():
                fail('P2-tolerant parse must never fail');
            }
          },
        );
      },
    );
  });
}
