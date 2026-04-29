import 'package:test/test.dart';

import 'package:social_care_web/src/intents/list_patients_intent.dart';

void main() {
  group('ListPatientsIntent', () {
    test('constructs with all nullable fields defaulting to null', () {
      const intent = ListPatientsIntent();

      expect(intent.search, isNull);
      expect(intent.status, isNull);
      expect(intent.cursor, isNull);
      expect(intent.limit, isNull);
    });

    test('preserves explicit filters when provided', () {
      const intent = ListPatientsIntent(
        search: 'Silva',
        status: 'admitted',
        cursor: 'c-42',
        limit: 25,
      );

      expect(intent.search, equals('Silva'));
      expect(intent.status, equals('admitted'));
      expect(intent.cursor, equals('c-42'));
      expect(intent.limit, equals(25));
    });

    test('instances with equal fields are equal (Equatable)', () {
      const a = ListPatientsIntent(search: 'Ana', limit: 10);
      const b = ListPatientsIntent(search: 'Ana', limit: 10);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances differ when any field differs', () {
      const a = ListPatientsIntent(search: 'Ana', limit: 10);
      const b = ListPatientsIntent(search: 'Ana', limit: 20);

      expect(a, isNot(equals(b)));
    });

    group('parseFromQuery — factory', () {
      test('returns intent with all-null fields for empty query', () {
        final intent = ListPatientsIntent.parseFromQuery(const {});

        expect(intent, equals(const ListPatientsIntent()));
      });

      test('forwards search + status when provided', () {
        final intent = ListPatientsIntent.parseFromQuery(const {
          'search': 'Silva',
          'status': 'admitted',
        });

        expect(intent.search, equals('Silva'));
        expect(intent.status, equals('admitted'));
      });

      test('forwards cursor when provided', () {
        final intent = ListPatientsIntent.parseFromQuery(const {
          'cursor': 'c-99',
        });

        expect(intent.cursor, equals('c-99'));
      });

      test('parses limit as int when valid', () {
        final intent = ListPatientsIntent.parseFromQuery(const {'limit': '50'});

        expect(intent.limit, equals(50));
      });

      test('coerces empty/whitespace string filters to null', () {
        final intent = ListPatientsIntent.parseFromQuery(const {
          'search': '',
          'status': '  ',
        });

        expect(intent.search, isNull);
        expect(intent.status, isNull);
      });

      test('invalid limit (non-numeric) is coerced to null', () {
        final intent = ListPatientsIntent.parseFromQuery(const {
          'limit': 'not-a-number',
        });

        expect(intent.limit, isNull);
      });
    });
  });
}
