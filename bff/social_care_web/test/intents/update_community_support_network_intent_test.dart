import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/update_community_support_network_intent.dart';

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
        patientId: 'pat-1',
        request: request,
      );

      expect(intent.patientId, equals('pat-1'));
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
        patientId: 'pat-1',
        request: request,
      );
      const b = UpdateCommunitySupportNetworkIntent(
        patientId: 'pat-1',
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
        patientId: 'pat-1',
        request: request,
      );
      const b = UpdateCommunitySupportNetworkIntent(
        patientId: 'pat-2',
        request: request,
      );

      expect(a, isNot(equals(b)));
    });

    group('parseFromBody — Result<UpdateCommunitySupportNetworkIntent>', () {
      test('returns Success when body is valid', () {
        final result = UpdateCommunitySupportNetworkIntent.parseFromBody(
          'pat-1',
          _validBody(),
        );

        expect(result, isA<Success<UpdateCommunitySupportNetworkIntent>>());
      });

      test('Success payload preserves patientId and request fields', () {
        final result = UpdateCommunitySupportNetworkIntent.parseFromBody(
          'pat-1',
          _validBody(),
        );

        switch (result) {
          case Success(:final value):
            expect(value.patientId, equals('pat-1'));
            expect(value.request.hasRelativeSupport, isTrue);
            expect(value.request.familyConflicts, equals('NONE'));
          case Failure():
            fail('Expected Success, got Failure');
        }
      });

      test('returns Failure when familyConflicts is missing', () {
        final body = _validBody()..remove('familyConflicts');

        final result = UpdateCommunitySupportNetworkIntent.parseFromBody(
          'pat-1',
          body,
        );

        expect(result, isA<Failure<UpdateCommunitySupportNetworkIntent>>());
      });

      test('returns Failure when body is empty', () {
        final result = UpdateCommunitySupportNetworkIntent.parseFromBody(
          'pat-1',
          const {},
        );

        expect(result, isA<Failure<UpdateCommunitySupportNetworkIntent>>());
      });

      test('Failure message is structural (no field values echoed)', () {
        final body = _validBody()..['familyConflicts'] = 'SECRET_MARKER_ZZZ';
        body.remove('hasRelativeSupport');

        final result = UpdateCommunitySupportNetworkIntent.parseFromBody(
          'pat-1',
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
    });
  });
}
