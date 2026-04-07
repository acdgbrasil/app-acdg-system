import 'dart:convert';

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/handlers/registry_handler.dart';

import 'test_helpers.dart';

/// Creates a minimal valid Patient domain object for testing via reconstitute
/// (skips creation invariants like requiring a PR family member).
Patient _testPatient() {
  final patientId =
      (PatientId.create(testPatientId) as Success<PatientId>).value;
  final personId = (PersonId.create(testPersonId) as Success<PersonId>).value;
  final lookupId = (LookupId.create(testLookupId) as Success<LookupId>).value;
  final icdCode = (IcdCode.create('E70.0') as Success<IcdCode>).value;
  final birthDate =
      (TimeStamp.fromIso('2000-01-15T00:00:00Z') as Success<TimeStamp>).value;
  final diagDate =
      (TimeStamp.fromIso('2025-01-01T00:00:00Z') as Success<TimeStamp>).value;

  final personalData =
      (PersonalData.create(
                firstName: 'Maria',
                lastName: 'Silva',
                motherName: 'Ana Silva',
                nationality: 'Brasileira',
                birthDate: birthDate,
                sex: Sex.feminino,
              )
              as Success<PersonalData>)
          .value;

  final diagnosis =
      (Diagnosis.create(id: icdCode, date: diagDate, description: 'PKU')
              as Success<Diagnosis>)
          .value;

  return Patient.reconstitute(
    id: patientId,
    version: 1,
    personId: personId,
    prRelationshipId: lookupId,
    personalData: personalData,
    diagnoses: [diagnosis],
  );
}

void main() {
  group('RegistryHandler', () {
    late FakeSocialCareBff fakeBff;
    late RegistryHandler handler;

    setUp(() {
      fakeBff = FakeSocialCareBff(delay: Duration.zero);
      handler = RegistryHandler(
        contractFactory: (_) => fakeBff,
        peopleContextFactory: (_) => FakePeopleContextClient(),
      );
    });

    group('GET /patients', () {
      test('returns empty list when no patients registered', () async {
        final request = testRequest('GET', '/patients');
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(200));

        final body = jsonDecode(await response.readAsString()) as List;
        expect(body, isEmpty);
      });

      test('returns list of patients after registration (enriched via people-context)', () async {
        // Pre-populate fake with a patient domain object
        final patient = _testPatient();
        await fakeBff.registerPatient(patient);

        final request = testRequest('GET', '/patients');
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(200));

        final body = jsonDecode(await response.readAsString()) as List;
        expect(body, hasLength(1));
        expect(body[0]['patientId'], equals(testPatientId));
        // The BFF should have called people-context and injected fullName and birthDate/age
        expect(body[0]['fullName'], isNotEmpty);
      });
    });

    group('POST /patients', () {
      test('returns 400 for invalid JSON body', () async {
        final request = testRequest('POST', '/patients', body: 'not json');
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
      });

      test('returns 400 for missing required fields', () async {
        final request = testRequest(
          'POST',
          '/patients',
          body: jsonEncode({'patientId': 'bad'}),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
      });
    });

    group('GET /patients/<id>', () {
      test('returns patient detail', () async {
        final patient = _testPatient();
        await fakeBff.registerPatient(patient);

        final request = testRequest('GET', '/patients/$testPatientId');
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(200));

        final body = jsonDecode(await response.readAsString());
        expect(body['patientId'], equals(testPatientId));
      });

      test('returns 400 for invalid patient ID format', () async {
        final request = testRequest('GET', '/patients/not-a-uuid');
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
      });

      test('returns 502 when patient not found (backend error)', () async {
        final request = testRequest('GET', '/patients/$testPatientId');
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(502));
      });
    });

    group('DELETE /patients/<id>/family-members/<memberId>', () {
      test('returns 204 on success', () async {
        final request = testRequest(
          'DELETE',
          '/patients/$testPatientId/family-members/$testMemberId',
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(204));
      });

      test('returns 400 for invalid patient ID', () async {
        final request = testRequest(
          'DELETE',
          '/patients/bad-id/family-members/$testMemberId',
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
      });

      test('returns 400 for invalid member ID', () async {
        final request = testRequest(
          'DELETE',
          '/patients/$testPatientId/family-members/bad-id',
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
      });
    });

    group('PUT /patients/<id>/primary-caregiver', () {
      test('returns 204 on success', () async {
        final request = testRequest(
          'PUT',
          '/patients/$testPatientId/primary-caregiver',
          body: jsonEncode({'memberPersonId': testMemberId}),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(204));
      });

      test('returns 400 when memberPersonId is missing', () async {
        final request = testRequest(
          'PUT',
          '/patients/$testPatientId/primary-caregiver',
          body: jsonEncode({}),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
      });
    });

    group('GET /patients/<id>/audit-trail', () {
      test('returns empty list', () async {
        final request = testRequest(
          'GET',
          '/patients/$testPatientId/audit-trail',
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(200));

        final body = jsonDecode(await response.readAsString()) as List;
        expect(body, isEmpty);
      });

      test('returns 400 for invalid patient ID', () async {
        final request = testRequest('GET', '/patients/bad-uuid/audit-trail');
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
      });
    });
  });
}
