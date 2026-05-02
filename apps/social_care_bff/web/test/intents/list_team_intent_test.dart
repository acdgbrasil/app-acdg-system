import 'package:core_contracts/core_contracts.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/list_team_intent.dart';

/// Wave 0 RED contract for [ListTeamIntent] — A15.
///
/// **First "query-tolerant" intent in the BFF Web canon**: zero filters
/// is valid; present filters are validated. Failure surfaces only when a
/// present filter is malformed or oversized. Variant of A14's query-only
/// canon (which requires at least one value).
void main() {
  group('ListTeamIntent', () {
    test('constructs with all-null filters by default', () {
      const intent = ListTeamIntent();

      expect(intent.role, isNull);
      expect(intent.active, isNull);
      expect(intent.search, isNull);
    });

    test('Equatable across all 3 fields', () {
      const a = ListTeamIntent(role: 'admin', active: true, search: 'maria');
      const b = ListTeamIntent(role: 'admin', active: true, search: 'maria');
      const c = ListTeamIntent(role: 'admin', active: false, search: 'maria');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    group('parseFromQuery', () {
      test('returns Success with all-null filters when query is empty', () {
        final result = ListTeamIntent.parseFromQuery({});

        switch (result) {
          case Success(:final value):
            expect(value.role, isNull);
            expect(value.active, isNull);
            expect(value.search, isNull);
          case Failure():
            fail('Expected Success on empty query');
        }
      });

      test('returns Success when only role is present', () {
        final result = ListTeamIntent.parseFromQuery({'role': 'admin'});

        switch (result) {
          case Success(:final value):
            expect(value.role, equals('admin'));
            expect(value.active, isNull);
            expect(value.search, isNull);
          case Failure():
            fail('Expected Success');
        }
      });

      test('parses active=true into bool true', () {
        final result = ListTeamIntent.parseFromQuery({'active': 'true'});

        switch (result) {
          case Success(:final value):
            expect(value.active, isTrue);
          case Failure():
            fail('Expected Success');
        }
      });

      test('parses active=false into bool false', () {
        final result = ListTeamIntent.parseFromQuery({'active': 'false'});

        switch (result) {
          case Success(:final value):
            expect(value.active, isFalse);
          case Failure():
            fail('Expected Success');
        }
      });

      test('returns Failure when active is not "true"/"false"', () {
        final result = ListTeamIntent.parseFromQuery({'active': 'abc'});

        expect(result, isA<Failure<ListTeamIntent>>());
      });

      test('returns Failure when active is "1" (strict bool parsing)', () {
        final result = ListTeamIntent.parseFromQuery({'active': '1'});

        expect(result, isA<Failure<ListTeamIntent>>());
      });

      test('treats empty active="" as absent (Success with null)', () {
        final result = ListTeamIntent.parseFromQuery({'active': ''});

        switch (result) {
          case Success(:final value):
            expect(value.active, isNull);
          case Failure():
            fail('Expected Success — empty string treated as absent');
        }
      });

      test('trims surrounding whitespace from role and search', () {
        final result = ListTeamIntent.parseFromQuery({
          'role': '  admin  ',
          'search': '  maria  ',
        });

        switch (result) {
          case Success(:final value):
            expect(value.role, equals('admin'));
            expect(value.search, equals('maria'));
          case Failure():
            fail('Expected Success');
        }
      });

      test('treats whitespace-only role as absent', () {
        final result = ListTeamIntent.parseFromQuery({'role': '   '});

        switch (result) {
          case Success(:final value):
            expect(value.role, isNull);
          case Failure():
            fail('Expected Success — whitespace treated as absent');
        }
      });

      test(
        'returns Failure when search exceeds the 100-char cap',
        () {
          final long = 'a' * 101;
          final result = ListTeamIntent.parseFromQuery({'search': long});

          expect(result, isA<Failure<ListTeamIntent>>());
        },
      );

      test(
        'returns Failure when role exceeds the 100-char cap',
        () {
          final long = 'a' * 101;
          final result = ListTeamIntent.parseFromQuery({'role': long});

          expect(result, isA<Failure<ListTeamIntent>>());
        },
      );

      test('Failure NEVER echoes raw role / search content', () {
        final result = ListTeamIntent.parseFromQuery({'active': 'maybe'});

        switch (result) {
          case Success():
            fail('Expected Failure');
          case Failure(:final error):
            expect(error.toString(), isNot(contains('maybe')));
        }
      });
    });
  });
}
