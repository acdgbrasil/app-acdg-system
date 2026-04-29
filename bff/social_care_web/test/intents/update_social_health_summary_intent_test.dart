import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/update_social_health_summary_intent.dart';
import 'package:social_care_web/src/intents/uuid_validation.dart';

import '../_test_uuids.dart';

/// Wave 0 RED contract for [UpdateSocialHealthSummaryIntent].
///
/// Canon: try/catch over `fromJson`; structural error message is
/// `'Invalid update-social-health-summary body: missing or malformed
/// required fields'`.

Map<String, dynamic> _validBody() => {
  'requiresConstantCare': true,
  'hasMobilityImpairment': false,
  'hasRelevantDrugTherapy': true,
  'functionalDependencies': <String>[],
};

void main() {
  group('UpdateSocialHealthSummaryIntent', () {
    test('constructs with patientId + request', () {
      const request = UpdateSocialHealthSummaryRequest(
        requiresConstantCare: true,
        hasMobilityImpairment: false,
        hasRelevantDrugTherapy: true,
      );

      const intent = UpdateSocialHealthSummaryIntent(
        patientId: kPatientUuid,
        request: request,
      );

      expect(intent.patientId, equals(kPatientUuid));
      expect(intent.request, equals(request));
    });

    test('instances with equal payload are equal (Equatable)', () {
      const request = UpdateSocialHealthSummaryRequest(
        requiresConstantCare: true,
        hasMobilityImpairment: false,
        hasRelevantDrugTherapy: true,
      );

      const a = UpdateSocialHealthSummaryIntent(
        patientId: kPatientUuid,
        request: request,
      );
      const b = UpdateSocialHealthSummaryIntent(
        patientId: kPatientUuid,
        request: request,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different patientId are not equal', () {
      const request = UpdateSocialHealthSummaryRequest(
        requiresConstantCare: true,
        hasMobilityImpairment: false,
        hasRelevantDrugTherapy: true,
      );

      const a = UpdateSocialHealthSummaryIntent(
        patientId: kPatientUuid,
        request: request,
      );
      const b = UpdateSocialHealthSummaryIntent(
        patientId: kPatientUuidAlt,
        request: request,
      );

      expect(a, isNot(equals(b)));
    });

    group('parseFromBody — Result<UpdateSocialHealthSummaryIntent>', () {
      test('returns Success when body is valid', () {
        final result = UpdateSocialHealthSummaryIntent.parseFromBody(
          kPatientUuid,
          _validBody(),
        );

        expect(result, isA<Success<UpdateSocialHealthSummaryIntent>>());
      });

      test('Success payload preserves patientId and request fields', () {
        final body = _validBody()
          ..['functionalDependencies'] = <String>['BATHING', 'EATING'];

        final result = UpdateSocialHealthSummaryIntent.parseFromBody(
          kPatientUuid,
          body,
        );

        switch (result) {
          case Success(:final value):
            expect(value.patientId, equals(kPatientUuid));
            expect(value.request.requiresConstantCare, isTrue);
            expect(
              value.request.functionalDependencies,
              equals(<String>['BATHING', 'EATING']),
            );
          case Failure():
            fail('Expected Success, got Failure');
        }
      });

      test('returns Failure when requiresConstantCare is missing', () {
        final body = _validBody()..remove('requiresConstantCare');

        final result = UpdateSocialHealthSummaryIntent.parseFromBody(
          kPatientUuid,
          body,
        );

        expect(result, isA<Failure<UpdateSocialHealthSummaryIntent>>());
      });

      test('returns Failure when body is empty', () {
        final result = UpdateSocialHealthSummaryIntent.parseFromBody(
          kPatientUuid,
          const {},
        );

        expect(result, isA<Failure<UpdateSocialHealthSummaryIntent>>());
      });

      test('Failure message is structural (no field values echoed)', () {
        final body = _validBody()
          ..['requiresConstantCare'] = 'NOT_A_BOOL_MARKER';
        body.remove('hasMobilityImpairment');

        final result = UpdateSocialHealthSummaryIntent.parseFromBody(
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
                'Invalid update-social-health-summary body: '
                'missing or malformed required fields',
              ),
            );
            expect(text, isNot(contains('NOT_A_BOOL_MARKER')));
            expect(text, isNot(contains('hasMobilityImpairment')));
        }
      });

      test(
        'returns Failure with UuidPathParamError when path id is not UUID v4',
        () {
          final result = UpdateSocialHealthSummaryIntent.parseFromBody(
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
