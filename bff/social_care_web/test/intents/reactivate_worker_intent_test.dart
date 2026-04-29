import 'package:test/test.dart';

import 'package:social_care_web/src/intents/reactivate_worker_intent.dart';

/// Wave 0 RED contract for [ReactivateWorkerIntent] — A15 (path-only).
void main() {
  group('ReactivateWorkerIntent', () {
    test('constructs with the required memberId', () {
      const intent = ReactivateWorkerIntent(memberId: 'm-1');

      expect(intent.memberId, equals('m-1'));
    });

    test('Equatable by memberId', () {
      const a = ReactivateWorkerIntent(memberId: 'm-1');
      const b = ReactivateWorkerIntent(memberId: 'm-1');
      const c = ReactivateWorkerIntent(memberId: 'm-2');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });
}
