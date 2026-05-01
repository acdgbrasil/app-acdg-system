import 'package:core_contracts/core_contracts.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/reactivate_worker_intent.dart';
import 'package:social_care_web/src/intents/uuid_validation.dart';

import '../_test_uuids.dart';

/// Contract for [ReactivateWorkerIntent] post-A23 (Template A V2).
///
/// Path-only intent for `PUT /team/{memberId}/reactivate`. The route
/// param is validated as RFC 4122 v4 via the canonical
/// [validateUuidPathParam] helper. `parseFromPath` returns a [Result]
/// so the handler can short-circuit malformed path ids with a 400
/// `INVALID_REACTIVATE_WORKER_PARAMS` response. Failure mode is
/// exclusively [UuidPathParamError] (PII-safe).
void main() {
  group('ReactivateWorkerIntent', () {
    test('constructs directly with a pre-validated memberId', () {
      const intent = ReactivateWorkerIntent(memberId: kMemberUuid);

      expect(intent.memberId, equals(kMemberUuid));
    });

    test('Equatable by memberId', () {
      const a = ReactivateWorkerIntent(memberId: kMemberUuid);
      const b = ReactivateWorkerIntent(memberId: kMemberUuid);
      const c = ReactivateWorkerIntent(memberId: kMemberUuidAlt);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    group('parseFromPath — Result<ReactivateWorkerIntent>', () {
      test('returns Success with normalized id for valid UUID v4', () {
        final result = ReactivateWorkerIntent.parseFromPath(kMemberUuid);

        switch (result) {
          case Success(:final value):
            expect(value.memberId, equals(kMemberUuid));
          case Failure():
            fail('Expected Success for canonical UUID v4');
        }
      });

      test('normalizes uppercase input to lowercase', () {
        final result = ReactivateWorkerIntent.parseFromPath(
          kMemberUuid.toUpperCase(),
        );

        switch (result) {
          case Success(:final value):
            expect(value.memberId, equals(kMemberUuid));
          case Failure():
            fail('Expected Success — uppercase should be normalized');
        }
      });

      test('returns Failure with UuidPathParamError for non-UUID input', () {
        final result = ReactivateWorkerIntent.parseFromPath(kNonUuid);

        switch (result) {
          case Success():
            fail('Expected Failure for non-UUID');
          case Failure(:final error):
            expect(error, isA<UuidPathParamError>());
            expect(
              (error as UuidPathParamError).fieldName,
              equals('memberId'),
            );
            // PII safety — must not echo raw input.
            expect(error.toString(), isNot(contains(kNonUuid)));
        }
      });

      test('returns Failure for empty string', () {
        final result = ReactivateWorkerIntent.parseFromPath('');

        expect(result, isA<Failure<ReactivateWorkerIntent>>());
      });

      test('returns Failure for UUID v1 (rejects non-v4 versions)', () {
        final result = ReactivateWorkerIntent.parseFromPath(kUuidV1);

        expect(result, isA<Failure<ReactivateWorkerIntent>>());
      });
    });
  });
}
