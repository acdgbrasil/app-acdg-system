import 'package:core_contracts/core_contracts.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/deactivate_role_intent.dart';
import 'package:social_care_web/src/intents/uuid_validation.dart';

import '../_test_uuids.dart';

/// Contract for [DeactivateRoleIntent] post-A23 (Template B V2 — 2 path UUIDs).
///
/// Path-only intent for `PUT /team/{memberId}/roles/{roleId}/deactivate`.
/// Both route params are validated as RFC 4122 v4 via the canonical
/// [validateUuidPathParam] helper, combined with `combineWith` so the
/// failure short-circuits left-to-right (memberId first). Failure mode
/// is exclusively [UuidPathParamError] (PII-safe).
void main() {
  group('DeactivateRoleIntent', () {
    test('constructs with required memberId and roleId', () {
      const intent = DeactivateRoleIntent(
        memberId: kMemberUuid,
        roleId: kRoleUuid,
      );

      expect(intent.memberId, equals(kMemberUuid));
      expect(intent.roleId, equals(kRoleUuid));
    });

    test('Equatable across both fields', () {
      const a = DeactivateRoleIntent(
        memberId: kMemberUuid,
        roleId: kRoleUuid,
      );
      const b = DeactivateRoleIntent(
        memberId: kMemberUuid,
        roleId: kRoleUuid,
      );
      const c = DeactivateRoleIntent(
        memberId: kMemberUuid,
        roleId: kRoleUuidAlt,
      );
      const d = DeactivateRoleIntent(
        memberId: kMemberUuidAlt,
        roleId: kRoleUuid,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
      expect(a, isNot(equals(d)));
    });

    group('parseFromParams — Result<DeactivateRoleIntent>', () {
      test('returns Success when both ids are valid UUID v4', () {
        final result = DeactivateRoleIntent.parseFromParams(
          rawMemberId: kMemberUuid,
          rawRoleId: kRoleUuid,
        );

        expect(result, isA<Success<DeactivateRoleIntent>>());
        switch (result) {
          case Success(:final value):
            expect(value.memberId, equals(kMemberUuid));
            expect(value.roleId, equals(kRoleUuid));
          case Failure():
            fail('Expected Success');
        }
      });

      test('normalizes uppercase ids to lowercase (canonical UUID form)', () {
        final result = DeactivateRoleIntent.parseFromParams(
          rawMemberId: kMemberUuid.toUpperCase(),
          rawRoleId: kRoleUuid.toUpperCase(),
        );

        switch (result) {
          case Success(:final value):
            expect(value.memberId, equals(kMemberUuid));
            expect(value.roleId, equals(kRoleUuid));
          case Failure():
            fail('Expected Success');
        }
      });

      test(
        'returns Failure with UuidPathParamError when memberId is empty',
        () {
          final result = DeactivateRoleIntent.parseFromParams(
            rawMemberId: '',
            rawRoleId: kRoleUuid,
          );

          expect(result, isA<Failure<DeactivateRoleIntent>>());
          switch (result) {
            case Success():
              fail('Expected Failure');
            case Failure(:final error):
              expect(error, isA<UuidPathParamError>());
              expect(error.toString(), contains('memberId'));
          }
        },
      );

      test('returns Failure with UuidPathParamError when roleId is empty', () {
        final result = DeactivateRoleIntent.parseFromParams(
          rawMemberId: kMemberUuid,
          rawRoleId: '',
        );

        expect(result, isA<Failure<DeactivateRoleIntent>>());
        switch (result) {
          case Success():
            fail('Expected Failure');
          case Failure(:final error):
            expect(error, isA<UuidPathParamError>());
            expect(error.toString(), contains('roleId'));
        }
      });

      test(
        'returns Failure when memberId is not UUID v4 (regardless of roleId)',
        () {
          // Bad memberId + bad roleId — left-to-right short-circuit means
          // memberId is reported first.
          final result = DeactivateRoleIntent.parseFromParams(
            rawMemberId: kNonUuid,
            rawRoleId: kNonUuid,
          );

          switch (result) {
            case Success():
              fail('Expected Failure');
            case Failure(:final error):
              expect(error, isA<UuidPathParamError>());
              expect(error.toString(), contains('memberId'));
              expect(
                error.toString(),
                isNot(contains(kNonUuid)),
                reason: 'PII safety — must not echo raw input',
              );
          }
        },
      );

      test(
        'returns Failure when roleId is not UUID v4 (memberId valid)',
        () {
          final result = DeactivateRoleIntent.parseFromParams(
            rawMemberId: kMemberUuid,
            rawRoleId: kNonUuid,
          );

          switch (result) {
            case Success():
              fail('Expected Failure');
            case Failure(:final error):
              expect(error, isA<UuidPathParamError>());
              expect(error.toString(), contains('roleId'));
              expect(
                error.toString(),
                isNot(contains(kNonUuid)),
                reason: 'PII safety — must not echo raw input',
              );
          }
        },
      );

      test('rejects v1 UUID in either slot (only v4 allowed)', () {
        final r1 = DeactivateRoleIntent.parseFromParams(
          rawMemberId: kUuidV1,
          rawRoleId: kRoleUuid,
        );
        final r2 = DeactivateRoleIntent.parseFromParams(
          rawMemberId: kMemberUuid,
          rawRoleId: kUuidV1,
        );

        expect(r1, isA<Failure<DeactivateRoleIntent>>());
        expect(r2, isA<Failure<DeactivateRoleIntent>>());
      });
    });
  });
}
