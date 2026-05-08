import 'package:core_contracts/core_contracts.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/approve_lookup_request_intent.dart';
import 'package:social_care_web/src/intents/uuid_validation.dart';

import '../_test_uuids.dart';

/// A13 / A23 contract for [ApproveLookupRequestIntent] — Template A V2.
///
/// Canon: path-only intent with single UUID v4 [requestId].
/// `parseFromPath` chains via [Result.map] over `validateUuidPathParam`
/// — no manual cast on the sealed `Result<T>` (PATTERN_MATCHING_POLICY
/// §P5).
void main() {
  group('ApproveLookupRequestIntent', () {
    test('constructs with the required requestId', () {
      const intent = ApproveLookupRequestIntent(requestId: kLookupRequestUuid);

      expect(intent.requestId, equals(kLookupRequestUuid));
    });

    test('instances with equal requestId are equal (Equatable)', () {
      const a = ApproveLookupRequestIntent(requestId: kLookupRequestUuid);
      const b = ApproveLookupRequestIntent(requestId: kLookupRequestUuid);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different requestId are not equal', () {
      const a = ApproveLookupRequestIntent(requestId: kLookupRequestUuid);
      const b = ApproveLookupRequestIntent(requestId: kLookupItemUuid);

      expect(a, isNot(equals(b)));
    });

    group(
      'parseFromPath — Result<ApproveLookupRequestIntent> (Template A V2)',
      () {
        test(
          'returns Success carrying the validated requestId for valid UUID v4',
          () {
            final result = ApproveLookupRequestIntent.parseFromPath(
              kLookupRequestUuid,
            );

            // Cast in test is fail-fast (§P5 exception).
            final success = result as Success<ApproveLookupRequestIntent>;
            expect(success.value.requestId, equals(kLookupRequestUuid));
          },
        );

        test(
          'normalizes uppercase / whitespace to canonical lowercase form',
          () {
            final result = ApproveLookupRequestIntent.parseFromPath(
              ' ${kLookupRequestUuid.toUpperCase()} ',
            );

            final success = result as Success<ApproveLookupRequestIntent>;
            expect(success.value.requestId, equals(kLookupRequestUuid));
          },
        );

        test(
          'returns Failure with UuidPathParamError when input is not UUID v4',
          () {
            final result = ApproveLookupRequestIntent.parseFromPath(kNonUuid);

            switch (result) {
              case Success():
                fail('Expected Failure for non-UUID input');
              case Failure(:final error):
                expect(error, isA<UuidPathParamError>());
                expect(
                  error.toString(),
                  isNot(contains(kNonUuid)),
                  reason: 'PII safety: error must not echo raw input',
                );
            }
          },
        );
      },
    );
  });
}
