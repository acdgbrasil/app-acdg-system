import 'package:test/test.dart';

import 'package:social_care_web/src/intents/get_lookup_table_intent.dart';

/// Wave 0 RED contract for [GetLookupTableIntent] — A13 (path-only).
///
/// Canon (intent-sem-body — mirrors [GetPatientIntent] from A08):
/// - `tableName` is injected straight from the shelf route parameter; the
///   intent is a pure value object with NO `parseFromBody`.
/// - Equality/hashCode are backed by [Equatable.props].
void main() {
  group('GetLookupTableIntent', () {
    test('constructs with the required tableName', () {
      const intent = GetLookupTableIntent(tableName: 'dominio_parentesco');

      expect(intent.tableName, equals('dominio_parentesco'));
    });

    test('instances with equal tableName are equal (Equatable)', () {
      const a = GetLookupTableIntent(tableName: 'dominio_parentesco');
      const b = GetLookupTableIntent(tableName: 'dominio_parentesco');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different tableName are not equal', () {
      const a = GetLookupTableIntent(tableName: 'dominio_parentesco');
      const b = GetLookupTableIntent(tableName: 'dominio_grau_dependencia');

      expect(a, isNot(equals(b)));
    });
  });
}
