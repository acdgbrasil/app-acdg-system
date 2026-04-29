import 'package:test/test.dart';

import 'package:social_care_web/src/intents/reactivate_role_intent.dart';

/// Wave 0 RED contract for [ReactivateRoleIntent] — A15 (path-only, 2 params).
void main() {
  group('ReactivateRoleIntent', () {
    test('constructs with required memberId and roleId', () {
      const intent = ReactivateRoleIntent(memberId: 'm-1', roleId: 'r-1');

      expect(intent.memberId, equals('m-1'));
      expect(intent.roleId, equals('r-1'));
    });

    test('Equatable across both fields', () {
      const a = ReactivateRoleIntent(memberId: 'm-1', roleId: 'r-1');
      const b = ReactivateRoleIntent(memberId: 'm-1', roleId: 'r-1');
      const c = ReactivateRoleIntent(memberId: 'm-1', roleId: 'r-2');
      const d = ReactivateRoleIntent(memberId: 'm-2', roleId: 'r-1');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a, isNot(equals(d)));
    });
  });
}
