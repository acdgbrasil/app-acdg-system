import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/toggle_lookup_item_intent.dart';
import 'package:social_care_web/src/intents/uuid_validation.dart';

import '../_test_uuids.dart';

/// Wave 0 RED contract for [ToggleLookupItemIntent] — A13.
///
/// Canon (P2 if-case, 1 required — mirrors [RegisterAppointmentIntent] shape
/// but with a bool-only required field):
/// - `active` is REQUIRED and MUST be a `bool`.
/// - Missing or non-bool values produce a [Failure] with the const message:
///   `"Invalid toggle-lookup-item body: missing or invalid [active]"`.
/// - Because the message is fixed (single field), `_ToggleLookupItemParseError`
///   IS `const`.
void main() {
  group('ToggleLookupItemIntent', () {
    test('constructs with tableName + itemId + ToggleLookupItemRequest', () {
      const request = ToggleLookupItemRequest(active: true);

      const intent = ToggleLookupItemIntent(
        tableName: 'dominio_parentesco',
        itemId: kLookupItemUuid,
        request: request,
      );

      expect(intent.tableName, equals('dominio_parentesco'));
      expect(intent.itemId, equals(kLookupItemUuid));
      expect(intent.request, equals(request));
    });

    test('instances with equal payload are equal (Equatable)', () {
      const request = ToggleLookupItemRequest(active: true);

      const a = ToggleLookupItemIntent(
        tableName: 'dominio_parentesco',
        itemId: kLookupItemUuid,
        request: request,
      );
      const b = ToggleLookupItemIntent(
        tableName: 'dominio_parentesco',
        itemId: kLookupItemUuid,
        request: request,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different active flag are not equal', () {
      const a = ToggleLookupItemIntent(
        tableName: 'dominio_parentesco',
        itemId: kLookupItemUuid,
        request: ToggleLookupItemRequest(active: true),
      );
      const b = ToggleLookupItemIntent(
        tableName: 'dominio_parentesco',
        itemId: kLookupItemUuid,
        request: ToggleLookupItemRequest(active: false),
      );

      expect(a, isNot(equals(b)));
    });

    group('parseFromBody — Result<ToggleLookupItemIntent> (P2 if-case)', () {
      test('returns Success when active is true', () {
        final result = ToggleLookupItemIntent.parseFromBody(
          'dominio_parentesco',
          kLookupItemUuid,
          const {'active': true},
        );

        expect(result, isA<Success<ToggleLookupItemIntent>>());
        switch (result) {
          case Success(:final value):
            expect(value.tableName, equals('dominio_parentesco'));
            expect(value.itemId, equals(kLookupItemUuid));
            expect(value.request.active, isTrue);
          case Failure():
            fail('Expected Success, got Failure');
        }
      });

      test('returns Success when active is false', () {
        final result = ToggleLookupItemIntent.parseFromBody(
          'dominio_parentesco',
          kLookupItemUuid,
          const {'active': false},
        );

        expect(result, isA<Success<ToggleLookupItemIntent>>());
        switch (result) {
          case Success(:final value):
            expect(value.request.active, isFalse);
          case Failure():
            fail('Expected Success, got Failure');
        }
      });

      test('returns Failure when active is missing', () {
        final result = ToggleLookupItemIntent.parseFromBody(
          'dominio_parentesco',
          kLookupItemUuid,
          const {},
        );

        expect(result, isA<Failure<ToggleLookupItemIntent>>());
      });

      test('returns Failure when active is not a bool (string)', () {
        final result = ToggleLookupItemIntent.parseFromBody(
          'dominio_parentesco',
          kLookupItemUuid,
          const {'active': 'true'},
        );

        expect(result, isA<Failure<ToggleLookupItemIntent>>());
      });

      test('returns Failure when active is not a bool (int)', () {
        final result = ToggleLookupItemIntent.parseFromBody(
          'dominio_parentesco',
          kLookupItemUuid,
          const {'active': 1},
        );

        expect(result, isA<Failure<ToggleLookupItemIntent>>());
      });

      test('returns Failure when active is null', () {
        final result = ToggleLookupItemIntent.parseFromBody(
          'dominio_parentesco',
          kLookupItemUuid,
          const <String, dynamic>{'active': null},
        );

        expect(result, isA<Failure<ToggleLookupItemIntent>>());
      });

      test('Failure message is the fixed const literal naming [active]', () {
        final result = ToggleLookupItemIntent.parseFromBody(
          'dominio_parentesco',
          kLookupItemUuid,
          const {},
        );

        switch (result) {
          case Success():
            fail('Expected Failure');
          case Failure(:final error):
            expect(
              error.toString(),
              equals(
                'Invalid toggle-lookup-item body: missing or invalid '
                '[active]',
              ),
            );
        }
      });
    });
  });
}
