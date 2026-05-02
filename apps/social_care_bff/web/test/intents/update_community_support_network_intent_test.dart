import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/update_community_support_network_intent.dart';
import 'package:social_care_web/src/intents/uuid_validation.dart';

import '../_test_uuids.dart';

/// Wave 0 RED contract for [UpdateCommunitySupportNetworkIntent].
///
/// Canon: try/catch over `fromJson`; structural error message is
/// `'Invalid update-community-support body: missing or malformed required
/// fields'`.
///
/// Note: the Community Support DTO carries only booleans + a categorical
/// enum (`familyConflicts`) — no free-text PII — so no `responsibleCaregiver`
/// test is required here.

Map<String, dynamic> _validBody() => {
  'hasRelativeSupport': true,
  'hasNeighborSupport': false,
  'familyConflicts': 'NONE',
  'patientParticipatesInGroups': true,
  'familyParticipatesInGroups': false,
  'patientHasAccessToLeisure': true,
  'facesDiscrimination': false,
};

void main() {
  group('UpdateCommunitySupportNetworkIntent', () {
    test('constructs with patientId + request', () {
      const request = UpdateCommunitySupportNetworkRequest(
        hasRelativeSupport: true,
        hasNeighborSupport: false,
        familyConflicts: 'NONE',
        patientParticipatesInGroups: true,
        familyParticipatesInGroups: false,
        patientHasAccessToLeisure: true,
        facesDiscrimination: false,
      );

      const intent = UpdateCommunitySupportNetworkIntent(
        patientId: kPatientUuid,
        request: request,
      );

      expect(intent.patientId, equals(kPatientUuid));
      expect(intent.request, equals(request));
    });

    test('instances with equal payload are equal (Equatable)', () {
      const request = UpdateCommunitySupportNetworkRequest(
        hasRelativeSupport: true,
        hasNeighborSupport: false,
        familyConflicts: 'NONE',
        patientParticipatesInGroups: true,
        familyParticipatesInGroups: false,
        patientHasAccessToLeisure: true,
        facesDiscrimination: false,
      );

      const a = UpdateCommunitySupportNetworkIntent(
        patientId: kPatientUuid,
        request: request,
      );
      const b = UpdateCommunitySupportNetworkIntent(
        patientId: kPatientUuid,
        request: request,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different patientId are not equal', () {
      const request = UpdateCommunitySupportNetworkRequest(
        hasRelativeSupport: true,
        hasNeighborSupport: false,
        familyConflicts: 'NONE',
        patientParticipatesInGroups: true,
        familyParticipatesInGroups: false,
        patientHasAccessToLeisure: true,
        facesDiscrimination: false,
      );

      const a = UpdateCommunitySupportNetworkIntent(
        patientId: kPatientUuid,
        request: request,
      );
      const b = UpdateCommunitySupportNetworkIntent(
        patientId: kPatientUuidAlt,
        request: request,
      );

      expect(a, isNot(equals(b)));
    });

    group('parseFromBody — Result<UpdateCommunitySupportNetworkIntent>', () {
      test('returns Success when body is valid', () {
        final result = UpdateCommunitySupportNetworkIntent.parseFromBody(
          kPatientUuid,
          _validBody(),
        );

        expect(result, isA<Success<UpdateCommunitySupportNetworkIntent>>());
      });

      test('Success payload preserves patientId and request fields', () {
        final result = UpdateCommunitySupportNetworkIntent.parseFromBody(
          kPatientUuid,
          _validBody(),
        );

        switch (result) {
          case Success(:final value):
            expect(value.patientId, equals(kPatientUuid));
            expect(value.request.hasRelativeSupport, isTrue);
            expect(value.request.familyConflicts, equals('NONE'));
          case Failure():
            fail('Expected Success, got Failure');
        }
      });

      test('returns Failure when familyConflicts is missing', () {
        final body = _validBody()..remove('familyConflicts');

        final result = UpdateCommunitySupportNetworkIntent.parseFromBody(
          kPatientUuid,
          body,
        );

        expect(result, isA<Failure<UpdateCommunitySupportNetworkIntent>>());
      });

      test('returns Failure when body is empty', () {
        final result = UpdateCommunitySupportNetworkIntent.parseFromBody(
          kPatientUuid,
          const {},
        );

        expect(result, isA<Failure<UpdateCommunitySupportNetworkIntent>>());
      });

      test('Failure message is structural (no field values echoed)', () {
        final body = _validBody()..['familyConflicts'] = 'SECRET_MARKER_ZZZ';
        body.remove('hasRelativeSupport');

        final result = UpdateCommunitySupportNetworkIntent.parseFromBody(
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
                'Invalid update-community-support body: '
                'missing or malformed required fields',
              ),
            );
            expect(text, isNot(contains('SECRET_MARKER_ZZZ')));
            expect(text, isNot(contains('hasRelativeSupport')));
        }
      });

      test(
        'returns Failure with UuidPathParamError when path id is not UUID v4',
        () {
          final result = UpdateCommunitySupportNetworkIntent.parseFromBody(
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
