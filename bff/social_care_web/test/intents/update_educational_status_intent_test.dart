import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/update_educational_status_intent.dart';
import 'package:social_care_web/src/intents/uuid_validation.dart';

import '../_test_uuids.dart';

/// Wave 0 RED contract for [UpdateEducationalStatusIntent].
///
/// Canon: try/catch over `fromJson`; structural error message is
/// `'Invalid update-educational-status body: missing or malformed required
/// fields'`.
/// All top-level collections default to empty; failure is exercised by
/// sending malformed nested entries or an overtly wrong-typed top-level
/// value.

Map<String, dynamic> _validBody() => {
  'memberProfiles': <Map<String, dynamic>>[],
  'programOccurrences': <Map<String, dynamic>>[],
};

void main() {
  group('UpdateEducationalStatusIntent', () {
    test('constructs with patientId + request', () {
      const request = UpdateEducationalStatusRequest();

      const intent = UpdateEducationalStatusIntent(
        patientId: kPatientUuid,
        request: request,
      );

      expect(intent.patientId, equals(kPatientUuid));
      expect(intent.request, equals(request));
    });

    test('instances with equal payload are equal (Equatable)', () {
      const request = UpdateEducationalStatusRequest();

      const a = UpdateEducationalStatusIntent(
        patientId: kPatientUuid,
        request: request,
      );
      const b = UpdateEducationalStatusIntent(
        patientId: kPatientUuid,
        request: request,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different patientId are not equal', () {
      const request = UpdateEducationalStatusRequest();

      const a = UpdateEducationalStatusIntent(
        patientId: kPatientUuid,
        request: request,
      );
      const b = UpdateEducationalStatusIntent(
        patientId: kPatientUuidAlt,
        request: request,
      );

      expect(a, isNot(equals(b)));
    });

    group('parseFromBody — Result<UpdateEducationalStatusIntent>', () {
      test('returns Success when body is valid', () {
        final result = UpdateEducationalStatusIntent.parseFromBody(
          kPatientUuid,
          _validBody(),
        );

        expect(result, isA<Success<UpdateEducationalStatusIntent>>());
      });

      test('Success payload preserves patientId and nested profiles', () {
        final body = _validBody()
          ..['memberProfiles'] = <Map<String, dynamic>>[
            {
              'memberId': 'm-1',
              'canReadWrite': true,
              'attendsSchool': false,
              'educationLevelId': 'lvl-1',
            },
          ];

        final result = UpdateEducationalStatusIntent.parseFromBody(
          kPatientUuid,
          body,
        );

        switch (result) {
          case Success(:final value):
            expect(value.patientId, equals(kPatientUuid));
            expect(value.request.memberProfiles, hasLength(1));
            expect(
              value.request.memberProfiles.first.educationLevelId,
              equals('lvl-1'),
            );
          case Failure():
            fail('Expected Success, got Failure');
        }
      });

      test('returns Failure when nested profile required field is missing', () {
        final body = _validBody()
          ..['memberProfiles'] = <Map<String, dynamic>>[
            {
              'memberId': 'm-1',
              'canReadWrite': true,
              'attendsSchool': false,
              // educationLevelId missing
            },
          ];

        final result = UpdateEducationalStatusIntent.parseFromBody(
          kPatientUuid,
          body,
        );

        expect(result, isA<Failure<UpdateEducationalStatusIntent>>());
      });

      test('returns Failure when memberProfiles is not a list', () {
        final body = <String, dynamic>{
          'memberProfiles': 'NOT_A_LIST_MARKER',
          'programOccurrences': <Map<String, dynamic>>[],
        };

        final result = UpdateEducationalStatusIntent.parseFromBody(
          kPatientUuid,
          body,
        );

        expect(result, isA<Failure<UpdateEducationalStatusIntent>>());
      });

      test('Failure message is structural (no field values echoed)', () {
        final body = <String, dynamic>{
          'memberProfiles': 'NOT_A_LIST_MARKER',
          'programOccurrences': <Map<String, dynamic>>[],
        };

        final result = UpdateEducationalStatusIntent.parseFromBody(
          kPatientUuid,
          body,
        );

        switch (result) {
          case Success():
            fail('Expected Failure');
          case Failure(:final error):
            final text = error.toString();
            expect(
              text,
              equals(
                'Invalid update-educational-status body: '
                'missing or malformed required fields',
              ),
            );
            expect(text, isNot(contains('NOT_A_LIST_MARKER')));
        }
      });

      test(
        'returns Failure with UuidPathParamError when path id is not UUID v4',
        () {
          final result = UpdateEducationalStatusIntent.parseFromBody(
            kNonUuid,
            _validBody(),
          );

          switch (result) {
            case Success():
              fail('Expected Failure for non-UUID path id');
            case Failure(:final error):
              expect(error, isA<UuidPathParamError>());
              expect(
                (error as UuidPathParamError).fieldName,
                equals('patientId'),
              );
              expect(error.toString(), isNot(contains(kNonUuid)));
          }
        },
      );
    });
  });
}
