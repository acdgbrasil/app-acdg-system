import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/update_work_and_income_intent.dart';
import 'package:social_care_web/src/intents/uuid_validation.dart';

import '../_test_uuids.dart';

/// Wave 0 RED contract for [UpdateWorkAndIncomeIntent].
///
/// Canon: try/catch over `fromJson`; structural error message is
/// `'Invalid update-work-and-income body: missing or malformed required
/// fields'`. The only required primitive is `hasRetiredMembers`;
/// `individualIncomes` and `socialBenefits` default to empty lists.

Map<String, dynamic> _validBody() => {
  'hasRetiredMembers': false,
  'individualIncomes': <Map<String, dynamic>>[],
  'socialBenefits': <Map<String, dynamic>>[],
};

void main() {
  group('UpdateWorkAndIncomeIntent', () {
    test('constructs with patientId + request', () {
      const request = UpdateWorkAndIncomeRequest(hasRetiredMembers: false);

      const intent = UpdateWorkAndIncomeIntent(
        patientId: kPatientUuid,
        request: request,
      );

      expect(intent.patientId, equals(kPatientUuid));
      expect(intent.request, equals(request));
    });

    test('instances with equal payload are equal (Equatable)', () {
      const request = UpdateWorkAndIncomeRequest(hasRetiredMembers: false);

      const a = UpdateWorkAndIncomeIntent(
        patientId: kPatientUuid,
        request: request,
      );
      const b = UpdateWorkAndIncomeIntent(
        patientId: kPatientUuid,
        request: request,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different patientId are not equal', () {
      const request = UpdateWorkAndIncomeRequest(hasRetiredMembers: false);

      const a = UpdateWorkAndIncomeIntent(
        patientId: kPatientUuid,
        request: request,
      );
      const b = UpdateWorkAndIncomeIntent(
        patientId: kPatientUuidAlt,
        request: request,
      );

      expect(a, isNot(equals(b)));
    });

    group('parseFromBody — Result<UpdateWorkAndIncomeIntent>', () {
      test('returns Success when body is valid', () {
        final result = UpdateWorkAndIncomeIntent.parseFromBody(
          kPatientUuid,
          _validBody(),
        );

        expect(result, isA<Success<UpdateWorkAndIncomeIntent>>());
      });

      test('Success payload preserves patientId and request fields', () {
        final body = _validBody()
          ..['individualIncomes'] = <Map<String, dynamic>>[
            {
              'memberId': 'm-1',
              'occupationId': 'occ-1',
              'hasWorkCard': true,
              'monthlyAmount': 1500.0,
            },
          ];

        final result = UpdateWorkAndIncomeIntent.parseFromBody(
          kPatientUuid,
          body,
        );

        switch (result) {
          case Success(:final value):
            expect(value.patientId, equals(kPatientUuid));
            expect(value.request.hasRetiredMembers, isFalse);
            expect(value.request.individualIncomes, hasLength(1));
            expect(
              value.request.individualIncomes.first.occupationId,
              equals('occ-1'),
            );
          case Failure():
            fail('Expected Success, got Failure');
        }
      });

      test('returns Failure when hasRetiredMembers is missing', () {
        final body = _validBody()..remove('hasRetiredMembers');

        final result = UpdateWorkAndIncomeIntent.parseFromBody(
          kPatientUuid,
          body,
        );

        expect(result, isA<Failure<UpdateWorkAndIncomeIntent>>());
      });

      test('returns Failure when body is empty', () {
        final result = UpdateWorkAndIncomeIntent.parseFromBody(
          kPatientUuid,
          const {},
        );

        expect(result, isA<Failure<UpdateWorkAndIncomeIntent>>());
      });

      test('Failure message is structural (no field values echoed)', () {
        // memberId is PII-ish (arbitrary identifier from caller): ensure that
        // malformed nested payload values never surface in the error string.
        final body = <String, dynamic>{
          'hasRetiredMembers': 'NOT_A_BOOL_MARKER',
        };

        final result = UpdateWorkAndIncomeIntent.parseFromBody(
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
                'Invalid update-work-and-income body: '
                'missing or malformed required fields',
              ),
            );
            expect(text, isNot(contains('NOT_A_BOOL_MARKER')));
        }
      });

      test(
        'returns Failure with UuidPathParamError when path id is not UUID v4',
        () {
          final result = UpdateWorkAndIncomeIntent.parseFromBody(
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
