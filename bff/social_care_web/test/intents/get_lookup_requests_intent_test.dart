import 'package:test/test.dart';

import 'package:social_care_web/src/intents/get_lookup_requests_intent.dart';

/// Wave 0 RED contract for [GetLookupRequestsIntent] — A13 (no body, no
/// params).
///
/// Canon (intent-vazio):
/// - Empty value object with no fields and no parser.
/// - All instances compare equal — Equatable.props is `const []`.
void main() {
  group('GetLookupRequestsIntent', () {
    test('constructs without arguments', () {
      const intent = GetLookupRequestsIntent();

      expect(intent, isA<GetLookupRequestsIntent>());
    });

    test('all instances are equal (empty props)', () {
      const a = GetLookupRequestsIntent();
      const b = GetLookupRequestsIntent();

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('props is empty', () {
      const intent = GetLookupRequestsIntent();

      expect(intent.props, isEmpty);
    });
  });
}
