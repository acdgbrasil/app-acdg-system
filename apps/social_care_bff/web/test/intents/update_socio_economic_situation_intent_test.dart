import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/update_socio_economic_situation_intent.dart';
import 'package:social_care_web/src/intents/uuid_validation.dart';

import '../_test_uuids.dart';

/// Wave 0 RED contract for [UpdateSocioEconomicSituationIntent].
///
/// Canon: try/catch over `fromJson`; structural error message is
/// `'Invalid update-socio-economic body: missing or malformed required
/// fields'`.

Map<String, dynamic> _validBody() => {
  'totalFamilyIncome': 1500.0,
  'incomePerCapita': 500.0,
  'receivesSocialBenefit': true,
  'mainSourceOfIncome': 'FORMAL_EMPLOYMENT',
  'hasUnemployed': false,
  'socialBenefits': <Map<String, dynamic>>[],
};

void main() {
  group('UpdateSocioEconomicSituationIntent', () {
    test('constructs with patientId + request', () {
      const request = UpdateSocioEconomicSituationRequest(
        totalFamilyIncome: 1500,
        incomePerCapita: 500,
        receivesSocialBenefit: true,
        mainSourceOfIncome: 'FORMAL_EMPLOYMENT',
        hasUnemployed: false,
      );

      const intent = UpdateSocioEconomicSituationIntent(
        patientId: kPatientUuid,
        request: request,
      );

      expect(intent.patientId, equals(kPatientUuid));
      expect(intent.request, equals(request));
    });

    test('instances with equal payload are equal (Equatable)', () {
      const request = UpdateSocioEconomicSituationRequest(
        totalFamilyIncome: 1500,
        incomePerCapita: 500,
        receivesSocialBenefit: true,
        mainSourceOfIncome: 'FORMAL_EMPLOYMENT',
        hasUnemployed: false,
      );

      const a = UpdateSocioEconomicSituationIntent(
        patientId: kPatientUuid,
        request: request,
      );
      const b = UpdateSocioEconomicSituationIntent(
        patientId: kPatientUuid,
        request: request,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different patientId are not equal', () {
      const request = UpdateSocioEconomicSituationRequest(
        totalFamilyIncome: 1500,
        incomePerCapita: 500,
        receivesSocialBenefit: true,
        mainSourceOfIncome: 'FORMAL_EMPLOYMENT',
        hasUnemployed: false,
      );

      const a = UpdateSocioEconomicSituationIntent(
        patientId: kPatientUuid,
        request: request,
      );
      const b = UpdateSocioEconomicSituationIntent(
        patientId: kPatientUuidAlt,
        request: request,
      );

      expect(a, isNot(equals(b)));
    });

    group('parseFromBody — Result<UpdateSocioEconomicSituationIntent>', () {
      test('returns Success when body is valid', () {
        final result = UpdateSocioEconomicSituationIntent.parseFromBody(
          kPatientUuid,
          _validBody(),
        );

        expect(result, isA<Success<UpdateSocioEconomicSituationIntent>>());
      });

      test('Success payload preserves patientId and request fields', () {
        final result = UpdateSocioEconomicSituationIntent.parseFromBody(
          kPatientUuid,
          _validBody(),
        );

        switch (result) {
          case Success(:final value):
            expect(value.patientId, equals(kPatientUuid));
            expect(value.request.totalFamilyIncome, equals(1500.0));
            expect(
              value.request.mainSourceOfIncome,
              equals('FORMAL_EMPLOYMENT'),
            );
          case Failure():
            fail('Expected Success, got Failure');
        }
      });

      test(
        'returns Failure when required field mainSourceOfIncome is missing',
        () {
          final body = _validBody()..remove('mainSourceOfIncome');

          final result = UpdateSocioEconomicSituationIntent.parseFromBody(
            kPatientUuid,
            body,
          );

          expect(result, isA<Failure<UpdateSocioEconomicSituationIntent>>());
        },
      );

      test('returns Failure when body is empty', () {
        final result = UpdateSocioEconomicSituationIntent.parseFromBody(
          kPatientUuid,
          const {},
        );

        expect(result, isA<Failure<UpdateSocioEconomicSituationIntent>>());
      });

      test('Failure message is structural (no field values echoed)', () {
        final body = _validBody()..['mainSourceOfIncome'] = 'SECRET_MARKER_ZZZ';
        body.remove('totalFamilyIncome');

        final result = UpdateSocioEconomicSituationIntent.parseFromBody(
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
                'Invalid update-socio-economic body: '
                'missing or malformed required fields',
              ),
            );
            expect(text, isNot(contains('SECRET_MARKER_ZZZ')));
            expect(text, isNot(contains('totalFamilyIncome')));
        }
      });

      test(
        'returns Failure with UuidPathParamError when path id is not UUID v4',
        () {
          final result = UpdateSocioEconomicSituationIntent.parseFromBody(
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
