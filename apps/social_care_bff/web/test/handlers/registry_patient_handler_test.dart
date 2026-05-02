import 'dart:convert';

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/handlers/registry_patient_handler.dart';
import 'package:social_care_web/src/use_cases/admit_patient_use_case.dart';
import 'package:social_care_web/src/use_cases/discharge_patient_use_case.dart';
import 'package:social_care_web/src/use_cases/get_patient_use_case.dart';
import 'package:social_care_web/src/use_cases/list_patients_use_case.dart';
import 'package:social_care_web/src/use_cases/readmit_patient_use_case.dart';
import 'package:social_care_web/src/use_cases/register_patient_use_case.dart';
import 'package:social_care_web/src/use_cases/withdraw_patient_use_case.dart';

import '../_test_uuids.dart';

/// A [RegistryContract] variant that forces every mutation to fail with a
/// well-known BackendError. Used to validate failure-path status codes in the
/// handler.
class _FailingRegistry extends FakeRegistryBff {
  _FailingRegistry(this.error);
  final BackendError error;

  @override
  Future<Result<StandardIdResponse>> registerPatient(
    RegisterPatientRequest request,
  ) async => Failure(error);

  @override
  Future<Result<void>> admitPatient(String patientId) async => Failure(error);

  @override
  Future<Result<void>> dischargePatient(
    String patientId,
    DischargePatientRequest request,
  ) async => Failure(error);

  @override
  Future<Result<void>> readmitPatient(
    String patientId,
    ReadmitPatientRequest request,
  ) async => Failure(error);

  @override
  Future<Result<void>> withdrawPatient(
    String patientId,
    WithdrawPatientRequest request,
  ) async => Failure(error);
}

/// Seeds a patient so `GET /patients/<id>` has a value to return.
void _seedPatient(FakeRegistryBff fake, {String id = kPatientUuid}) {
  fake.store.save(
    PatientResponse(patientId: id, personId: 'per-$id'),
    PatientSummaryResponse(
      patientId: id,
      personId: 'per-$id',
      fullName: 'Patient $id',
    ),
  );
}

RegistryPatientHandler _buildHandler({
  RegistryContract? registry,
  PeopleContract? people,
}) {
  final r = registry ?? FakeRegistryBff();
  final p = people ?? FakePeopleBff();
  return RegistryPatientHandler(
    register: RegisterPatientUseCase(registry: r, people: p),
    list: ListPatientsUseCase(registry: r, people: p),
    get: GetPatientUseCase(registry: r, people: p),
    admit: AdmitPatientUseCase(registry: r),
    discharge: DischargePatientUseCase(registry: r),
    readmit: ReadmitPatientUseCase(registry: r),
    withdraw: WithdrawPatientUseCase(registry: r),
  );
}

Map<String, dynamic> _validRegisterBody() => {
  'personId': '',
  'prRelationshipId': 'rel-self',
  'initialDiagnoses': <Map<String, dynamic>>[],
  'personalData': {
    'firstName': 'Ana',
    'lastName': 'Silva',
    'motherName': 'Marta Silva',
    'nationality': 'BRA',
    'sex': 'F',
    'birthDate': '2018-05-10',
  },
};

void main() {
  group('RegistryPatientHandler (thin handler — UseCase orchestration)', () {
    group('POST /patients', () {
      test('returns 200/201 with { id } on happy path', () async {
        final handler = _buildHandler();

        final request = Request(
          'POST',
          Uri.parse('http://localhost/patients'),
          body: jsonEncode(_validRegisterBody()),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, lessThan(300));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(body['data'], isA<Map<String, dynamic>>());
        expect((body['data'] as Map)['id'], isNotEmpty);
      });

      test('returns 400 when body is invalid JSON', () async {
        final handler = _buildHandler();

        final request = Request(
          'POST',
          Uri.parse('http://localhost/patients'),
          body: 'not json',
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
      });

      test('returns 400 when prRelationshipId is missing', () async {
        final handler = _buildHandler();

        final body = _validRegisterBody()..remove('prRelationshipId');
        final request = Request(
          'POST',
          Uri.parse('http://localhost/patients'),
          body: jsonEncode(body),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
      });

      test(
        'returns upstream status code when registry.registerPatient fails',
        () async {
          final failing = _FailingRegistry(
            const BackendError(
              id: 'err-1',
              code: 'PATIENT_DUPLICATE',
              message: 'patient already exists',
              http: 409,
            ),
          );
          final handler = _buildHandler(registry: failing);

          final request = Request(
            'POST',
            Uri.parse('http://localhost/patients'),
            body: jsonEncode(_validRegisterBody()),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(409));
        },
      );
    });

    group('GET /patients', () {
      test('returns 200 with an empty list when nothing is stored', () async {
        final handler = _buildHandler();

        final request = Request('GET', Uri.parse('http://localhost/patients'));
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(200));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(body['data'], isA<List<dynamic>>());
        expect(body['data'] as List, isEmpty);
      });

      test('returns 200 with seeded patients', () async {
        final fakeRegistry = FakeRegistryBff();
        _seedPatient(fakeRegistry, id: 'p-1');
        _seedPatient(fakeRegistry, id: 'p-2');

        final handler = _buildHandler(registry: fakeRegistry);

        final request = Request('GET', Uri.parse('http://localhost/patients'));
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(200));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(body['data'] as List, hasLength(2));
      });

      test('forwards search + limit query params', () async {
        final fakeRegistry = FakeRegistryBff();
        _seedPatient(fakeRegistry, id: 'p-1');

        final handler = _buildHandler(registry: fakeRegistry);

        final request = Request(
          'GET',
          Uri.parse('http://localhost/patients?search=Patient&limit=10'),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(200));
      });
    });

    group('GET /patients/<id>', () {
      test('returns 200 with the patient when found', () async {
        final fakeRegistry = FakeRegistryBff();
        _seedPatient(fakeRegistry, id: kPatientUuid);

        final handler = _buildHandler(registry: fakeRegistry);

        final request = Request(
          'GET',
          Uri.parse('http://localhost/patients/$kPatientUuid'),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(200));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect((body['data'] as Map)['patientId'], equals(kPatientUuid));
      });

      test(
        'returns 400 INVALID_GET_PATIENT_PARAMS when id is not a UUID v4',
        () async {
          final handler = _buildHandler();

          final request = Request(
            'GET',
            Uri.parse('http://localhost/patients/$kNonUuid'),
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(400));
          final body =
              jsonDecode(await response.readAsString()) as Map<String, dynamic>;
          final error = body['error'] as Map<String, dynamic>;
          expect(error['code'], equals('INVALID_GET_PATIENT_PARAMS'));
          // PII safety: error message must not echo the raw input.
          expect(error['message'], isNot(contains(kNonUuid)));
        },
      );

      test('returns 404 when patient does not exist', () async {
        // Use a valid v4 UUID that is NOT seeded — must pass UUID
        // validation but trigger the upstream "not found" path.
        final handler = _buildHandler();

        final request = Request(
          'GET',
          Uri.parse('http://localhost/patients/$kPatientUuidAlt'),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(404));
      });
    });

    group('POST /patients/<id>/admit', () {
      test('returns 200 on successful admission', () async {
        final handler = _buildHandler();

        final request = Request(
          'POST',
          Uri.parse('http://localhost/patients/$kPatientUuid/admit'),
          body: jsonEncode(const {
            'reason': 'Triage approved',
            'admittedAt': '2026-04-17T10:00:00Z',
          }),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, lessThan(300));
      });

      test('returns 400 when reason is missing', () async {
        final handler = _buildHandler();

        final request = Request(
          'POST',
          Uri.parse('http://localhost/patients/$kPatientUuid/admit'),
          body: jsonEncode(const {'admittedAt': '2026-04-17T10:00:00Z'}),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
      });

      test(
        'returns 400 INVALID_ADMIT_BODY when path id is not a UUID v4',
        () async {
          final handler = _buildHandler();

          final request = Request(
            'POST',
            Uri.parse('http://localhost/patients/$kNonUuid/admit'),
            body: jsonEncode(const {
              'reason': 'Triage approved',
              'admittedAt': '2026-04-17T10:00:00Z',
            }),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(400));
          final body =
              jsonDecode(await response.readAsString())
                  as Map<String, dynamic>;
          final error = body['error'] as Map<String, dynamic>;
          expect(error['code'], equals('INVALID_ADMIT_BODY'));
          // PII safety: error message must not echo the raw path input.
          expect(error['message'], isNot(contains(kNonUuid)));
        },
      );

      test('returns upstream status when admitPatient fails', () async {
        final failing = _FailingRegistry(
          const BackendError(
            id: 'err-1',
            code: 'INVALID_STATE',
            message: 'cannot admit',
            http: 409,
          ),
        );
        final handler = _buildHandler(registry: failing);

        final request = Request(
          'POST',
          Uri.parse('http://localhost/patients/$kPatientUuid/admit'),
          body: jsonEncode(const {
            'reason': 'Triage approved',
            'admittedAt': '2026-04-17T10:00:00Z',
          }),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(409));
      });
    });

    group('POST /patients/<id>/discharge', () {
      test('returns 200 on successful discharge', () async {
        final handler = _buildHandler();

        final request = Request(
          'POST',
          Uri.parse('http://localhost/patients/$kPatientUuid/discharge'),
          body: jsonEncode(const {'reason': 'Treatment completed'}),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, lessThan(300));
      });

      test('returns 400 when reason is missing', () async {
        final handler = _buildHandler();

        final request = Request(
          'POST',
          Uri.parse('http://localhost/patients/$kPatientUuid/discharge'),
          body: jsonEncode(const {}),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
      });

      test(
        'returns 400 INVALID_DISCHARGE_BODY when path id is not a UUID v4',
        () async {
          final handler = _buildHandler();

          final request = Request(
            'POST',
            Uri.parse('http://localhost/patients/$kNonUuid/discharge'),
            body: jsonEncode(const {'reason': 'Treatment completed'}),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(400));
          final body =
              jsonDecode(await response.readAsString())
                  as Map<String, dynamic>;
          final error = body['error'] as Map<String, dynamic>;
          expect(error['code'], equals('INVALID_DISCHARGE_BODY'));
          expect(error['message'], isNot(contains(kNonUuid)));
        },
      );

      test('returns upstream status when dischargePatient fails', () async {
        final failing = _FailingRegistry(
          const BackendError(
            id: 'err-1',
            code: 'INVALID_STATE',
            message: 'cannot discharge',
            http: 409,
          ),
        );
        final handler = _buildHandler(registry: failing);

        final request = Request(
          'POST',
          Uri.parse('http://localhost/patients/$kPatientUuid/discharge'),
          body: jsonEncode(const {'reason': 'x'}),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(409));
      });
    });

    group('POST /patients/<id>/readmit', () {
      test('returns 200 with empty body (notes is optional)', () async {
        final handler = _buildHandler();

        final request = Request(
          'POST',
          Uri.parse('http://localhost/patients/$kPatientUuid/readmit'),
          body: jsonEncode(const {}),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, lessThan(300));
      });

      test(
        'returns 400 INVALID_READMIT_BODY when path id is not a UUID v4',
        () async {
          final handler = _buildHandler();

          final request = Request(
            'POST',
            Uri.parse('http://localhost/patients/$kNonUuid/readmit'),
            body: jsonEncode(const {}),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(400));
          final body =
              jsonDecode(await response.readAsString())
                  as Map<String, dynamic>;
          final error = body['error'] as Map<String, dynamic>;
          expect(error['code'], equals('INVALID_READMIT_BODY'));
          expect(error['message'], isNot(contains(kNonUuid)));
        },
      );

      test('returns upstream status when readmitPatient fails', () async {
        final failing = _FailingRegistry(
          const BackendError(
            id: 'err-1',
            code: 'INVALID_STATE',
            message: 'cannot readmit',
            http: 409,
          ),
        );
        final handler = _buildHandler(registry: failing);

        final request = Request(
          'POST',
          Uri.parse('http://localhost/patients/$kPatientUuid/readmit'),
          body: jsonEncode(const {}),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(409));
      });
    });

    group('POST /patients/<id>/withdraw', () {
      test('returns 200 on successful withdrawal', () async {
        final handler = _buildHandler();

        final request = Request(
          'POST',
          Uri.parse('http://localhost/patients/$kPatientUuid/withdraw'),
          body: jsonEncode(const {'reason': 'Family relocated'}),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, lessThan(300));
      });

      test('returns 400 when reason is missing', () async {
        final handler = _buildHandler();

        final request = Request(
          'POST',
          Uri.parse('http://localhost/patients/$kPatientUuid/withdraw'),
          body: jsonEncode(const {}),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
      });

      test(
        'returns 400 INVALID_WITHDRAW_BODY when path id is not a UUID v4',
        () async {
          final handler = _buildHandler();

          final request = Request(
            'POST',
            Uri.parse('http://localhost/patients/$kNonUuid/withdraw'),
            body: jsonEncode(const {'reason': 'Family relocated'}),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(400));
          final body =
              jsonDecode(await response.readAsString())
                  as Map<String, dynamic>;
          final error = body['error'] as Map<String, dynamic>;
          expect(error['code'], equals('INVALID_WITHDRAW_BODY'));
          expect(error['message'], isNot(contains(kNonUuid)));
        },
      );

      test('returns upstream status when withdrawPatient fails', () async {
        final failing = _FailingRegistry(
          const BackendError(
            id: 'err-1',
            code: 'INVALID_STATE',
            message: 'cannot withdraw',
            http: 409,
          ),
        );
        final handler = _buildHandler(registry: failing);

        final request = Request(
          'POST',
          Uri.parse('http://localhost/patients/$kPatientUuid/withdraw'),
          body: jsonEncode(const {'reason': 'x'}),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(409));
      });
    });

    group('State matrix (P1) — sanitized error body', () {
      test(
        'error response body does NOT leak stack traces or raw exception messages',
        () async {
          final failing = _FailingRegistry(
            const BackendError(
              id: 'err-1',
              code: 'INVALID_STATE',
              message: 'internal leak marker xyz',
              http: 409,
            ),
          );
          final handler = _buildHandler(registry: failing);

          final request = Request(
            'POST',
            Uri.parse('http://localhost/patients/$kPatientUuid/admit'),
            body: jsonEncode(const {
              'reason': 'Triage',
              'admittedAt': '2026-04-17T10:00:00Z',
            }),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);
          final body = await response.readAsString();

          // BackendError messages CAN surface (they are curated by the
          // upstream service); but the handler must never attach a Dart
          // stack trace or nested exception prose.
          expect(body, isNot(contains('#0')), reason: 'stack traces leak');
          expect(body, isNot(contains('Exception:')));
        },
      );
    });
  });
}
