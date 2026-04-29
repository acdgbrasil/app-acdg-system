import 'package:test/test.dart';

import 'package:social_care_web/src/intents/reset_password_intent.dart';

/// Wave 0 RED contract for [ResetPasswordIntent] — A15 (path-only).
void main() {
  group('ResetPasswordIntent', () {
    test('constructs with the required memberId', () {
      const intent = ResetPasswordIntent(memberId: 'm-1');

      expect(intent.memberId, equals('m-1'));
    });

    test('Equatable by memberId', () {
      const a = ResetPasswordIntent(memberId: 'm-1');
      const b = ResetPasswordIntent(memberId: 'm-1');
      const c = ResetPasswordIntent(memberId: 'm-2');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });
}
