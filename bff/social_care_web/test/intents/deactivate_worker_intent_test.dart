import 'package:test/test.dart';

import 'package:social_care_web/src/intents/deactivate_worker_intent.dart';

/// Wave 0 RED contract for [DeactivateWorkerIntent] — A15 (path-only).
void main() {
  group('DeactivateWorkerIntent', () {
    test('constructs with the required memberId', () {
      const intent = DeactivateWorkerIntent(memberId: 'm-1');

      expect(intent.memberId, equals('m-1'));
    });

    test('Equatable by memberId', () {
      const a = DeactivateWorkerIntent(memberId: 'm-1');
      const b = DeactivateWorkerIntent(memberId: 'm-1');
      const c = DeactivateWorkerIntent(memberId: 'm-2');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });
}
