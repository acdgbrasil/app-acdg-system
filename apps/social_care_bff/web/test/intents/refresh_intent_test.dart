import 'package:test/test.dart';

import 'package:social_care_web/src/intents/refresh_intent.dart';

void main() {
  group('RefreshIntent', () {
    test('constructs with required sessionId', () {
      const intent = RefreshIntent(sessionId: 'session-abc');

      expect(intent.sessionId, equals('session-abc'));
    });

    test('instances with equal sessionId are equal (Equatable)', () {
      const a = RefreshIntent(sessionId: 'session-abc');
      const b = RefreshIntent(sessionId: 'session-abc');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different sessionId are not equal', () {
      const a = RefreshIntent(sessionId: 'session-abc');
      const b = RefreshIntent(sessionId: 'session-xyz');

      expect(a, isNot(equals(b)));
    });
  });
}
