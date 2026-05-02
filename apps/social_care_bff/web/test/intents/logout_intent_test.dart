import 'package:test/test.dart';

import 'package:social_care_web/src/intents/logout_intent.dart';

void main() {
  group('LogoutIntent', () {
    test('constructs with required sessionId', () {
      const intent = LogoutIntent(sessionId: 'session-abc');

      expect(intent.sessionId, equals('session-abc'));
    });

    test('instances with equal sessionId are equal (Equatable)', () {
      const a = LogoutIntent(sessionId: 'session-abc');
      const b = LogoutIntent(sessionId: 'session-abc');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different sessionId are not equal', () {
      const a = LogoutIntent(sessionId: 'session-abc');
      const b = LogoutIntent(sessionId: 'session-xyz');

      expect(a, isNot(equals(b)));
    });
  });
}
