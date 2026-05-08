import 'package:core_contracts/core_contracts.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/remove_family_member_intent.dart';
import 'package:social_care_web/src/intents/uuid_validation.dart';

import '../_test_uuids.dart';

/// Contract for [RemoveFamilyMemberIntent] post-A23.
///
/// No request body — only two route params: `patientId` + `memberId`.
/// Both are validated as UUID v4 via the canonical [validateUuidPathParam]
/// helper. The parser still returns a [Result] for symmetry with the other
/// A09 intents so the handler can short-circuit via the same P1 switch.
/// Failure modes are exclusively [UuidPathParamError] (PII-safe — only
/// the fieldName surfaces, never the raw input).
void main() {
  group('RemoveFamilyMemberIntent', () {
    test('constructs with patientId + memberId', () {
      const intent = RemoveFamilyMemberIntent(
        patientId: kPatientUuid,
        memberId: kFamilyMemberUuid,
      );

      expect(intent.patientId, equals(kPatientUuid));
      expect(intent.memberId, equals(kFamilyMemberUuid));
    });

    test('instances with equal payload are equal (Equatable)', () {
      const a = RemoveFamilyMemberIntent(
        patientId: kPatientUuid,
        memberId: kFamilyMemberUuid,
      );
      const b = RemoveFamilyMemberIntent(
        patientId: kPatientUuid,
        memberId: kFamilyMemberUuid,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different payloads are not equal', () {
      const a = RemoveFamilyMemberIntent(
        patientId: kPatientUuid,
        memberId: kFamilyMemberUuid,
      );
      const b = RemoveFamilyMemberIntent(
        patientId: kPatientUuid,
        memberId: kFamilyMemberUuidAlt,
      );

      expect(a, isNot(equals(b)));
    });

    group('parseFromParams — Result<RemoveFamilyMemberIntent>', () {
      test('returns Success when both ids are valid UUID v4', () {
        final result = RemoveFamilyMemberIntent.parseFromParams(
          rawPatientId: kPatientUuid,
          rawMemberId: kFamilyMemberUuid,
        );

        expect(result, isA<Success<RemoveFamilyMemberIntent>>());
        switch (result) {
          case Success(:final value):
            expect(value.patientId, equals(kPatientUuid));
            expect(value.memberId, equals(kFamilyMemberUuid));
          case Failure():
            fail('Expected Success');
        }
      });

      test('normalizes uppercase ids to lowercase (canonical UUID form)', () {
        final result = RemoveFamilyMemberIntent.parseFromParams(
          rawPatientId: kPatientUuid.toUpperCase(),
          rawMemberId: kFamilyMemberUuid.toUpperCase(),
        );

        switch (result) {
          case Success(:final value):
            expect(value.patientId, equals(kPatientUuid));
            expect(value.memberId, equals(kFamilyMemberUuid));
          case Failure():
            fail('Expected Success');
        }
      });

      test(
        'returns Failure with UuidPathParamError when patientId is empty',
        () {
          final result = RemoveFamilyMemberIntent.parseFromParams(
            rawPatientId: '',
            rawMemberId: kFamilyMemberUuid,
          );

          expect(result, isA<Failure<RemoveFamilyMemberIntent>>());
          switch (result) {
            case Success():
              fail('Expected Failure');
            case Failure(:final error):
              expect(error, isA<UuidPathParamError>());
              expect(error.toString(), contains('patientId'));
          }
        },
      );

      test(
        'returns Failure with UuidPathParamError when memberId is empty',
        () {
          final result = RemoveFamilyMemberIntent.parseFromParams(
            rawPatientId: kPatientUuid,
            rawMemberId: '',
          );

          expect(result, isA<Failure<RemoveFamilyMemberIntent>>());
          switch (result) {
            case Success():
              fail('Expected Failure');
            case Failure(:final error):
              expect(error, isA<UuidPathParamError>());
              expect(error.toString(), contains('memberId'));
          }
        },
      );

      test('returns Failure when patientId is not UUID v4', () {
        final result = RemoveFamilyMemberIntent.parseFromParams(
          rawPatientId: kNonUuid,
          rawMemberId: kFamilyMemberUuid,
        );

        switch (result) {
          case Success():
            fail('Expected Failure');
          case Failure(:final error):
            expect(error, isA<UuidPathParamError>());
            expect(error.toString(), contains('patientId'));
            expect(
              error.toString(),
              isNot(contains(kNonUuid)),
              reason: 'PII safety — must not echo raw input',
            );
        }
      });

      test(
        'returns Failure when memberId is not UUID v4 (patientId valid)',
        () {
          final result = RemoveFamilyMemberIntent.parseFromParams(
            rawPatientId: kPatientUuid,
            rawMemberId: kNonUuid,
          );

          switch (result) {
            case Success():
              fail('Expected Failure');
            case Failure(:final error):
              expect(error, isA<UuidPathParamError>());
              expect(error.toString(), contains('memberId'));
              expect(error.toString(), isNot(contains(kNonUuid)));
          }
        },
      );

      test('rejects v1 UUID (only v4 allowed)', () {
        final result = RemoveFamilyMemberIntent.parseFromParams(
          rawPatientId: kUuidV1,
          rawMemberId: kFamilyMemberUuid,
        );

        expect(result, isA<Failure<RemoveFamilyMemberIntent>>());
      });
    });
  });
}
