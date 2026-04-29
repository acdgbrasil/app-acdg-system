import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/register_patient_intent.dart';

/// A representative happy-path body the APP sends to `POST /api/patients`.
///
/// Wave 1 MUST keep [RegisterPatientIntent.parseFromBody] aligned with this
/// shape; adding new keys is fine, renaming them requires rewriting these
/// tests.
Map<String, dynamic> _validBody() => {
  'personId': '',
  'prRelationshipId': 'rel-patient-self',
  'initialDiagnoses': <Map<String, dynamic>>[
    {
      'icdCode': 'Q87.1',
      'date': '2026-01-10',
      'description': 'Noonan syndrome',
    },
  ],
  'personalData': {
    'firstName': 'Ana',
    'lastName': 'Silva',
    'motherName': 'Marta Silva',
    'nationality': 'BRA',
    'sex': 'F',
    'birthDate': '2018-05-10',
  },
  'civilDocuments': {'cpf': '11144477735'},
};

void main() {
  group('RegisterPatientIntent', () {
    test('constructs with a RegisterPatientRequest payload', () {
      const request = RegisterPatientRequest(
        personId: '',
        initialDiagnoses: <DiagnosisDraftDto>[],
        prRelationshipId: 'rel-self',
      );

      const intent = RegisterPatientIntent(request: request);

      expect(intent.request, equals(request));
    });

    test('instances with equal payload are equal (Equatable)', () {
      const request = RegisterPatientRequest(
        personId: '',
        initialDiagnoses: <DiagnosisDraftDto>[],
        prRelationshipId: 'rel-self',
      );

      const a = RegisterPatientIntent(request: request);
      const b = RegisterPatientIntent(request: request);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different payloads are not equal', () {
      const a = RegisterPatientIntent(
        request: RegisterPatientRequest(
          personId: '',
          initialDiagnoses: <DiagnosisDraftDto>[],
          prRelationshipId: 'rel-self',
        ),
      );
      const b = RegisterPatientIntent(
        request: RegisterPatientRequest(
          personId: '',
          initialDiagnoses: <DiagnosisDraftDto>[],
          prRelationshipId: 'rel-mother',
        ),
      );

      expect(a, isNot(equals(b)));
    });

    group('parseFromBody — Result<RegisterPatientIntent> (P2 if-case)', () {
      test('returns Success when required fields are present', () {
        final result = RegisterPatientIntent.parseFromBody(_validBody());

        expect(result, isA<Success<RegisterPatientIntent>>());
      });

      test(
        'Success payload preserves prRelationshipId and first diagnosis',
        () {
          final result = RegisterPatientIntent.parseFromBody(_validBody());

          switch (result) {
            case Success(:final value):
              expect(
                value.request.prRelationshipId,
                equals('rel-patient-self'),
              );
              expect(value.request.initialDiagnoses, isNotEmpty);
              expect(
                value.request.initialDiagnoses.first.icdCode,
                equals('Q87.1'),
              );
            case Failure():
              fail('Expected Success, got Failure');
          }
        },
      );

      test('returns Failure when prRelationshipId is missing', () {
        final body = _validBody()..remove('prRelationshipId');

        final result = RegisterPatientIntent.parseFromBody(body);

        expect(result, isA<Failure<RegisterPatientIntent>>());
      });

      test('returns Failure when body is empty', () {
        final result = RegisterPatientIntent.parseFromBody(const {});

        expect(result, isA<Failure<RegisterPatientIntent>>());
      });

      test(
        'Failure message does NOT echo raw CPF from civilDocuments (PII)',
        () {
          final body = {
            // missing prRelationshipId — forces failure
            'civilDocuments': {'cpf': '11144477735'},
          };

          final result = RegisterPatientIntent.parseFromBody(body);

          switch (result) {
            case Success():
              fail('Expected Failure');
            case Failure(:final error):
              expect(
                error.toString(),
                isNot(contains('11144477735')),
                reason: 'Parse error must never echo raw CPF',
              );
          }
        },
      );

      test(
        'Failure message does NOT echo raw full name from personalData (PII)',
        () {
          final body = {
            // missing prRelationshipId — forces failure
            'personalData': {'firstName': 'Ana', 'lastName': 'Silva Santos'},
          };

          final result = RegisterPatientIntent.parseFromBody(body);

          switch (result) {
            case Success():
              fail('Expected Failure');
            case Failure(:final error):
              final dumped = error.toString();
              expect(dumped, isNot(contains('Silva Santos')));
              expect(dumped, isNot(contains('Ana Silva')));
          }
        },
      );
    });
  });
}
