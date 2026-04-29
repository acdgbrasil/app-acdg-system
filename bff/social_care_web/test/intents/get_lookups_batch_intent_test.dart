import 'package:core_contracts/core_contracts.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/get_lookups_batch_intent.dart';

/// Wave 0 RED contract for [GetLookupsBatchIntent] — A14.
///
/// Canon (intent-from-query — *first* of its kind in the BFF Web canon):
/// - `tables` is parsed from the request's query string, NOT from a JSON
///   body. The factory mirrors the shape of [parseFromBody] used by P2
///   intents but consumes `Map<String, String>` (shelf's
///   `request.url.queryParameters`).
/// - The parser is **tolerant** to whitespace and empty tokens between
///   commas (`tables=a,,b` → `[a, b]`), matching the project-wide CSV
///   convention established in `people-context/src/config/env.ts:31-34`
///   (split → trim → filter).
/// - Hard cap of **20** distinct tables (sized to ~54% headroom over the
///   13 entries currently in `AllowedLookupTables.swift`).
/// - Equality/hashCode are backed by [Equatable.props].
void main() {
  group('GetLookupsBatchIntent', () {
    test('constructs with the required tables list', () {
      const intent = GetLookupsBatchIntent(
        tables: ['dominio_parentesco', 'dominio_tipo_identidade'],
      );

      expect(
        intent.tables,
        equals(['dominio_parentesco', 'dominio_tipo_identidade']),
      );
    });

    test('instances with equal tables are equal (Equatable)', () {
      const a = GetLookupsBatchIntent(tables: ['a', 'b']);
      const b = GetLookupsBatchIntent(tables: ['a', 'b']);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different tables are not equal', () {
      const a = GetLookupsBatchIntent(tables: ['a', 'b']);
      const b = GetLookupsBatchIntent(tables: ['a', 'c']);

      expect(a, isNot(equals(b)));
    });

    group('parseFromQuery', () {
      test('returns Success for a single-table CSV', () {
        final result = GetLookupsBatchIntent.parseFromQuery({
          'tables': 'dominio_parentesco',
        });

        expect(result, isA<Success<GetLookupsBatchIntent>>());
        switch (result) {
          case Success(:final value):
            expect(value.tables, equals(['dominio_parentesco']));
          case Failure():
            fail('Expected Success');
        }
      });

      test('returns Success for a multi-table CSV', () {
        final result = GetLookupsBatchIntent.parseFromQuery({
          'tables': 'dominio_parentesco,dominio_tipo_identidade,dominio_tipo_ingresso',
        });

        switch (result) {
          case Success(:final value):
            expect(
              value.tables,
              equals([
                'dominio_parentesco',
                'dominio_tipo_identidade',
                'dominio_tipo_ingresso',
              ]),
            );
          case Failure():
            fail('Expected Success');
        }
      });

      test('trims surrounding whitespace from each token', () {
        final result = GetLookupsBatchIntent.parseFromQuery({
          'tables': ' a , b ,c',
        });

        switch (result) {
          case Success(:final value):
            expect(value.tables, equals(['a', 'b', 'c']));
          case Failure():
            fail('Expected Success');
        }
      });

      test('filters out empty tokens between commas (tolerant)', () {
        final result = GetLookupsBatchIntent.parseFromQuery({
          'tables': 'a,,b,',
        });

        switch (result) {
          case Success(:final value):
            expect(value.tables, equals(['a', 'b']));
          case Failure():
            fail('Expected Success');
        }
      });

      test('returns Failure when tables param is absent', () {
        final result = GetLookupsBatchIntent.parseFromQuery({});

        expect(result, isA<Failure<GetLookupsBatchIntent>>());
      });

      test('returns Failure when tables param is empty string', () {
        final result = GetLookupsBatchIntent.parseFromQuery({'tables': ''});

        expect(result, isA<Failure<GetLookupsBatchIntent>>());
      });

      test('returns Failure when tables param is only whitespace', () {
        final result = GetLookupsBatchIntent.parseFromQuery({'tables': '   '});

        expect(result, isA<Failure<GetLookupsBatchIntent>>());
      });

      test('returns Failure when tables param is only commas', () {
        final result = GetLookupsBatchIntent.parseFromQuery({'tables': ',,,'});

        expect(result, isA<Failure<GetLookupsBatchIntent>>());
      });

      test(
        'returns Success when count is exactly at the 20-table cap',
        () {
          final tables = List.generate(20, (i) => 't$i');
          final result = GetLookupsBatchIntent.parseFromQuery({
            'tables': tables.join(','),
          });

          switch (result) {
            case Success(:final value):
              expect(value.tables, hasLength(20));
            case Failure():
              fail('Expected Success at boundary (20 tables)');
          }
        },
      );

      test('returns Failure when count exceeds the 20-table cap', () {
        final tables = List.generate(21, (i) => 't$i');
        final result = GetLookupsBatchIntent.parseFromQuery({
          'tables': tables.join(','),
        });

        expect(result, isA<Failure<GetLookupsBatchIntent>>());
      });
    });
  });
}
