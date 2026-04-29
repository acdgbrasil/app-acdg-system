import 'package:test/test.dart';

import 'package:social_care_web/src/intents/get_team_member_intent.dart';

/// Wave 0 RED contract for [GetTeamMemberIntent] — A15 (path-only).
void main() {
  group('GetTeamMemberIntent', () {
    test('constructs with the required memberId', () {
      const intent = GetTeamMemberIntent(memberId: 'm-1');

      expect(intent.memberId, equals('m-1'));
    });

    test('instances with equal memberId are equal (Equatable)', () {
      const a = GetTeamMemberIntent(memberId: 'm-1');
      const b = GetTeamMemberIntent(memberId: 'm-1');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different memberId are not equal', () {
      const a = GetTeamMemberIntent(memberId: 'm-1');
      const b = GetTeamMemberIntent(memberId: 'm-2');

      expect(a, isNot(equals(b)));
    });
  });
}
