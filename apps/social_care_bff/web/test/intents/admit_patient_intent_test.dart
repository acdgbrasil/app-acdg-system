import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/admit_patient_intent.dart';
import 'package:social_care_web/src/intents/uuid_validation.dart';

import '../_test_uuids.dart';

void main() {
  group('AdmitPatientIntent', () {
    test('constructs with required patientId + request', () {
      const request = AdmitPatientRequest(
        reason: 'Triage approved',
        admittedAt: '2026-04-17T10:00:00Z',
      );

      const intent = AdmitPatientIntent(
        patientId: kPatientUuid,
        request: request,
      );

      expect(intent.patientId, equals(kPatientUuid));
      expect(intent.request, equals(request));
    });

    test('instances with equal fields are equal (Equatable)', () {
      const request = AdmitPatientRequest(
        reason: 'Triage approved',
        admittedAt: '2026-04-17T10:00:00Z',
      );

      const a = AdmitPatientIntent(patientId: kPatientUuid, request: request);
      const b = AdmitPatientIntent(patientId: kPatientUuid, request: request);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances differ when patientId differs', () {
      const request = AdmitPatientRequest(
        reason: 'Triage approved',
        admittedAt: '2026-04-17T10:00:00Z',
      );

      const a = AdmitPatientIntent(patientId: kPatientUuid, request: request);
      const b = AdmitPatientIntent(
        patientId: kPatientUuidAlt,
        request: request,
      );

      expect(a, isNot(equals(b)));
    });

    group('parseFromBody — Result<AdmitPatientIntent> (P2 if-case)', () {
      test('returns Success when reason + admittedAt are present', () {
        final result = AdmitPatientIntent.parseFromBody(kPatientUuid, const {
          'reason': 'Triage approved',
          'admittedAt': '2026-04-17T10:00:00Z',
          'notes': 'Patient ready for care',
        });

        expect(result, isA<Success<AdmitPatientIntent>>());
        switch (result) {
          case Success(:final value):
            expect(value.patientId, equals(kPatientUuid));
            expect(value.request.reason, equals('Triage approved'));
            expect(value.request.admittedAt, equals('2026-04-17T10:00:00Z'));
            expect(value.request.notes, equals('Patient ready for care'));
          case Failure():
            fail('Expected Success');
        }
      });

      test('returns Failure when reason is missing', () {
        final result = AdmitPatientIntent.parseFromBody(kPatientUuid, const {
          'admittedAt': '2026-04-17T10:00:00Z',
        });

        expect(result, isA<Failure<AdmitPatientIntent>>());
      });

      test('returns Failure when admittedAt is missing', () {
        final result = AdmitPatientIntent.parseFromBody(kPatientUuid, const {
          'reason': 'Triage approved',
        });

        expect(result, isA<Failure<AdmitPatientIntent>>());
      });

      test('returns Failure when reason is empty', () {
        final result = AdmitPatientIntent.parseFromBody(kPatientUuid, const {
          'reason': '',
          'admittedAt': '2026-04-17T10:00:00Z',
        });

        expect(result, isA<Failure<AdmitPatientIntent>>());
      });

      test(
        'returns Failure with UuidPathParamError when path id is not UUID v4',
        () {
          final result = AdmitPatientIntent.parseFromBody(kNonUuid, const {
            'reason': 'Triage approved',
            'admittedAt': '2026-04-17T10:00:00Z',
          });

          switch (result) {
            case Success():
              fail('Expected Failure for non-UUID path id');
            case Failure(:final error):
              expect(error, isA<UuidPathParamError>());
              expect(
                (error as UuidPathParamError).fieldName,
                equals('patientId'),
              );
              // PII safety: error must not echo the raw path input.
              expect(error.toString(), isNot(contains(kNonUuid)));
          }
        },
      );

      test('returns Failure for empty patientId (UUID gate rejects it)', () {
        final result = AdmitPatientIntent.parseFromBody('', const {
          'reason': 'Triage approved',
          'admittedAt': '2026-04-17T10:00:00Z',
        });

        switch (result) {
          case Success():
            fail('Expected Failure for empty path id');
          case Failure(:final error):
            expect(error, isA<UuidPathParamError>());
        }
      });
    });
  });
}
