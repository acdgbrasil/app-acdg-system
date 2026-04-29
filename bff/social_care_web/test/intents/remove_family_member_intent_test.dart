import 'package:core_contracts/core_contracts.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/remove_family_member_intent.dart';

/// Wave 0 RED contract for the new [RemoveFamilyMemberIntent].
///
/// No request body — only two route params: `patientId` + `memberId`.
/// The parser still returns a [Result] for symmetry with the other A09
/// intents, so the handler can short-circuit via the same P1 switch.
/// Both IDs are required and non-empty; otherwise the parser returns a
/// [Failure] carrying a [_RemoveFamilyMemberParseError].
void main() {
  group('RemoveFamilyMemberIntent', () {
    test('constructs with patientId + memberId', () {
      const intent = RemoveFamilyMemberIntent(
        patientId: 'pat-1',
        memberId: 'mem-42',
      );

      expect(intent.patientId, equals('pat-1'));
      expect(intent.memberId, equals('mem-42'));
    });

    test('instances with equal payload are equal (Equatable)', () {
      const a = RemoveFamilyMemberIntent(
        patientId: 'pat-1',
        memberId: 'mem-42',
      );
      const b = RemoveFamilyMemberIntent(
        patientId: 'pat-1',
        memberId: 'mem-42',
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different payloads are not equal', () {
      const a = RemoveFamilyMemberIntent(
        patientId: 'pat-1',
        memberId: 'mem-42',
      );
      const b = RemoveFamilyMemberIntent(
        patientId: 'pat-1',
        memberId: 'mem-43',
      );

      expect(a, isNot(equals(b)));
    });

    group('parseFromParams — Result<RemoveFamilyMemberIntent>', () {
      test('returns Success when both ids are present', () {
        final result = RemoveFamilyMemberIntent.parseFromParams(
          patientId: 'pat-1',
          memberId: 'mem-42',
        );

        expect(result, isA<Success<RemoveFamilyMemberIntent>>());
        switch (result) {
          case Success(:final value):
            expect(value.patientId, equals('pat-1'));
            expect(value.memberId, equals('mem-42'));
          case Failure():
            fail('Expected Success');
        }
      });

      test('returns Failure when patientId is empty', () {
        final result = RemoveFamilyMemberIntent.parseFromParams(
          patientId: '',
          memberId: 'mem-42',
        );

        expect(result, isA<Failure<RemoveFamilyMemberIntent>>());
      });

      test('returns Failure when memberId is empty', () {
        final result = RemoveFamilyMemberIntent.parseFromParams(
          patientId: 'pat-1',
          memberId: '',
        );

        expect(result, isA<Failure<RemoveFamilyMemberIntent>>());
      });

      test('Failure message references structural field names only', () {
        final result = RemoveFamilyMemberIntent.parseFromParams(
          patientId: 'pat-1',
          memberId: '',
        );

        switch (result) {
          case Success():
            fail('Expected Failure');
          case Failure(:final error):
            expect(error.toString(), contains('memberId'));
        }
      });
    });
  });
}
