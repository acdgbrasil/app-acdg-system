import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/update_health_status_intent.dart';
import 'package:social_care_web/src/intents/uuid_validation.dart';

import '../_test_uuids.dart';

/// Wave 0 RED contract for [UpdateHealthStatusIntent].
///
/// Canon: try/catch over `fromJson`; structural error message is
/// `'Invalid update-health-status body: missing or malformed required
/// fields'`.
///
/// PII invariant: [DeficiencyDraftDto.responsibleCaregiverName] is a
/// free-text caregiver name. The Failure error message MUST NEVER echo it,
/// even when the deficiency payload is malformed in another field.

Map<String, dynamic> _validBody() => {
  'foodInsecurity': false,
  'deficiencies': <Map<String, dynamic>>[],
  'gestatingMembers': <Map<String, dynamic>>[],
  'constantCareNeeds': <String>[],
};

void main() {
  group('UpdateHealthStatusIntent', () {
    test('constructs with patientId + request', () {
      const request = UpdateHealthStatusRequest(foodInsecurity: false);

      const intent = UpdateHealthStatusIntent(
        patientId: kPatientUuid,
        request: request,
      );

      expect(intent.patientId, equals(kPatientUuid));
      expect(intent.request, equals(request));
    });

    test('instances with equal payload are equal (Equatable)', () {
      const request = UpdateHealthStatusRequest(foodInsecurity: false);

      const a = UpdateHealthStatusIntent(patientId: kPatientUuid, request: request);
      const b = UpdateHealthStatusIntent(patientId: kPatientUuid, request: request);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different patientId are not equal', () {
      const request = UpdateHealthStatusRequest(foodInsecurity: false);

      const a = UpdateHealthStatusIntent(patientId: kPatientUuid, request: request);
      const b = UpdateHealthStatusIntent(patientId: kPatientUuidAlt, request: request);

      expect(a, isNot(equals(b)));
    });

    group('parseFromBody — Result<UpdateHealthStatusIntent>', () {
      test('returns Success when body is valid', () {
        final result = UpdateHealthStatusIntent.parseFromBody(
          kPatientUuid,
          _validBody(),
        );

        expect(result, isA<Success<UpdateHealthStatusIntent>>());
      });

      test(
        'Success payload preserves patientId and nested deficiency fields',
        () {
          final body = _validBody()
            ..['deficiencies'] = <Map<String, dynamic>>[
              {
                'memberId': 'm-1',
                'deficiencyTypeId': 'def-1',
                'needsConstantCare': true,
                'responsibleCaregiverName': 'Dona Maria da Silva',
              },
            ];

          final result = UpdateHealthStatusIntent.parseFromBody(kPatientUuid, body);

          switch (result) {
            case Success(:final value):
              expect(value.patientId, equals(kPatientUuid));
              expect(value.request.foodInsecurity, isFalse);
              expect(value.request.deficiencies, hasLength(1));
              expect(
                value.request.deficiencies.first.responsibleCaregiverName,
                equals('Dona Maria da Silva'),
              );
            case Failure():
              fail('Expected Success, got Failure');
          }
        },
      );

      test('returns Failure when foodInsecurity is missing', () {
        final body = _validBody()..remove('foodInsecurity');

        final result = UpdateHealthStatusIntent.parseFromBody(kPatientUuid, body);

        expect(result, isA<Failure<UpdateHealthStatusIntent>>());
      });

      test('returns Failure when body is empty', () {
        final result = UpdateHealthStatusIntent.parseFromBody(
          kPatientUuid,
          const {},
        );

        expect(result, isA<Failure<UpdateHealthStatusIntent>>());
      });

      test('Failure message is structural (no field values echoed)', () {
        final body = <String, dynamic>{
          'foodInsecurity': 'NOT_A_BOOL_MARKER',
          'deficiencies': <Map<String, dynamic>>[],
          'gestatingMembers': <Map<String, dynamic>>[],
          'constantCareNeeds': <String>[],
        };

        final result = UpdateHealthStatusIntent.parseFromBody(kPatientUuid, body);

        switch (result) {
          case Success():
            fail('Expected Failure');
          case Failure(:final error):
            final text = error.toString();
            expect(
              text,
              equals(
                'Invalid update-health-status body: '
                'missing or malformed required fields',
              ),
            );
            expect(text, isNot(contains('NOT_A_BOOL_MARKER')));
        }
      });

      test('Failure message does NOT echo responsibleCaregiverName (PII)', () {
        // Deficiency entry is structurally complete BUT a sibling required
        // field (foodInsecurity) is missing — parse should fail and the
        // error message must never include the caregiver name.
        final body = <String, dynamic>{
          'deficiencies': <Map<String, dynamic>>[
            {
              'memberId': 'm-1',
              'deficiencyTypeId': 'def-1',
              'needsConstantCare': true,
              'responsibleCaregiverName': 'Dona Maria da Silva',
            },
          ],
          'gestatingMembers': <Map<String, dynamic>>[],
          'constantCareNeeds': <String>[],
          // foodInsecurity missing to force a parse failure
        };

        final result = UpdateHealthStatusIntent.parseFromBody(kPatientUuid, body);

        switch (result) {
          case Success():
            fail('Expected Failure');
          case Failure(:final error):
            final text = error.toString();
            expect(
              text,
              isNot(contains('Dona Maria')),
              reason: 'Parse error must never echo caregiver given name',
            );
            expect(
              text,
              isNot(contains('da Silva')),
              reason: 'Parse error must never echo caregiver family name',
            );
        }
      });

      test(
        'returns Failure with UuidPathParamError when path id is not UUID v4',
        () {
          final result = UpdateHealthStatusIntent.parseFromBody(
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
