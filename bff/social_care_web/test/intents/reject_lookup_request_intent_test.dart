import 'package:test/test.dart';

import 'package:social_care_web/src/intents/reject_lookup_request_intent.dart';

/// Wave 0 RED contract for [RejectLookupRequestIntent] — A13 (path-only).
///
/// Canon (intent-sem-body — mirrors [GetPatientIntent] from A08):
/// - `requestId` is injected straight from the shelf route parameter; the
///   intent is a pure value object with NO `parseFromBody`.
void main() {
  group('RejectLookupRequestIntent', () {
    test('constructs with the required requestId', () {
      const intent = RejectLookupRequestIntent(
        requestId: '660e8400-e29b-41d4-a716-446655440001',
      );

      expect(intent.requestId, equals('660e8400-e29b-41d4-a716-446655440001'));
    });

    test('instances with equal requestId are equal (Equatable)', () {
      const a = RejectLookupRequestIntent(
        requestId: '660e8400-e29b-41d4-a716-446655440001',
      );
      const b = RejectLookupRequestIntent(
        requestId: '660e8400-e29b-41d4-a716-446655440001',
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different requestId are not equal', () {
      const a = RejectLookupRequestIntent(
        requestId: '660e8400-e29b-41d4-a716-446655440001',
      );
      const b = RejectLookupRequestIntent(
        requestId: '770e8400-e29b-41d4-a716-446655440002',
      );

      expect(a, isNot(equals(b)));
    });
  });
}
