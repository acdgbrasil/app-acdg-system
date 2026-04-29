import 'package:test/test.dart';

import 'package:social_care_web/src/intents/deactivate_role_intent.dart';

/// Wave 0 RED contract for [DeactivateRoleIntent] — A15 (path-only, 2 params).
void main() {
  group('DeactivateRoleIntent', () {
    test('constructs with required memberId and roleId', () {
      const intent = DeactivateRoleIntent(memberId: 'm-1', roleId: 'r-1');

      expect(intent.memberId, equals('m-1'));
      expect(intent.roleId, equals('r-1'));
    });

    test('Equatable across both fields', () {
      const a = DeactivateRoleIntent(memberId: 'm-1', roleId: 'r-1');
      const b = DeactivateRoleIntent(memberId: 'm-1', roleId: 'r-1');
      const c = DeactivateRoleIntent(memberId: 'm-1', roleId: 'r-2');
      const d = DeactivateRoleIntent(memberId: 'm-2', roleId: 'r-1');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a, isNot(equals(d)));
    });
  });
}
