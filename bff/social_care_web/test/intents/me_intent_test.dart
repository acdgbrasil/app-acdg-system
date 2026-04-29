import 'package:test/test.dart';

import 'package:social_care_web/src/intents/me_intent.dart';

void main() {
  group('MeIntent', () {
    test('constructs with required sessionId', () {
      const intent = MeIntent(sessionId: 'session-abc');

      expect(intent.sessionId, equals('session-abc'));
    });

    test('instances with equal sessionId are equal (Equatable)', () {
      const a = MeIntent(sessionId: 'session-abc');
      const b = MeIntent(sessionId: 'session-abc');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different sessionId are not equal', () {
      const a = MeIntent(sessionId: 'session-abc');
      const b = MeIntent(sessionId: 'session-xyz');

      expect(a, isNot(equals(b)));
    });
  });
}
