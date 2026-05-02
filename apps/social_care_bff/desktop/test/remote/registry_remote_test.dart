/// RED-phase tests for `RegistryRemote` (A16-v2).
///
/// `RegistryRemote implements RegistryContract`. Eleven methods.
///
/// ── Patients (4) ─────────────────────────────────────────────────────
///   * `fetchPatients({search, status, cursor, limit})`
///       → `GET /api/v1/patients` (returns `PaginatedList<PatientSummaryResponse>`)
///   * `registerPatient(req)`
///       → `POST /api/v1/patients` (returns `StandardIdResponse`)
///   * `fetchPatient(patientId)`
///       → `GET /api/v1/patients/{patientId}` (returns
///         `StandardResponse<PatientResponse>`)
///   * `fetchPatientByPersonId(personId)`
///       → `GET /api/v1/patients/by-person/{personId}` (returns
///         `StandardResponse<PatientResponse>`)
///
/// ── Family members (3) ───────────────────────────────────────────────
///   * `addFamilyMember(patientId, req, {cpf})`
///       → `POST /api/v1/patients/{patientId}/family-members` (void)
///   * `removeFamilyMember(patientId, memberId)`
///       → `DELETE /api/v1/patients/{patientId}/family-members/{memberId}` (void)
///   * `assignPrimaryCaregiver(patientId, req)`
///       → `PUT /api/v1/patients/{patientId}/primary-caregiver` (void)
///
/// ── Social identity (1) ──────────────────────────────────────────────
///   * `updateSocialIdentity(patientId, req)`
///       → `PUT /api/v1/patients/{patientId}/social-identity` (void)
///
/// ── Lifecycle (3) ────────────────────────────────────────────────────
///   * `dischargePatient(patientId, req)`   → POST `.../discharge`  (void)
///   * `readmitPatient(patientId, req)`     → POST `.../readmit`    (void)
///   * `admitPatient(patientId)`            → POST `.../admit`      (void)
///   * `withdrawPatient(patientId, req)`    → POST `.../withdraw`   (void)
///
/// Backend paths preserved from legacy `social_care_bff_remote.dart`
/// lines 113-378.
///
/// REGRA #2 note: the legacy `addFamilyMember` accepts an optional `cpf`
/// argument that is **never used** in the request — it's a leftover hook
/// for backend lookup that the new sub-contract still exposes. We test
/// that passing a `cpf` does NOT affect the path or body (preserving
/// backwards-compat). If the implementer wants to elevate `cpf` into a
/// query/header, they MUST also update RegistryContract — flagging here
/// rather than silently picking a behavior.
library;

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:social_care_desktop/src/remote/registry_remote.dart';
import 'package:test/test.dart';

import '../_test_uuids.dart';
import '_mock_dio.dart';

void main() {
  group('RegistryRemote', () {
    late MockDio dio;
    late RegistryRemote remote;

    setUp(() {
      dio = MockDio();
      remote = RegistryRemote(dio: dio);
    });

    test('implements RegistryContract', () {
      expect(remote, isA<RegistryContract>());
    });

    // ── fetchPatients ──────────────────────────────────────────────────
    group('fetchPatients', () {
      Map<String, dynamic> emptyPayload() => <String, dynamic>{
        'data': <Map<String, dynamic>>[],
        'meta': <String, dynamic>{
          'pageSize': 100,
          'totalCount': 0,
          'hasMore': false,
          'nextCursor': null,
        },
      };

      test('hits GET /api/v1/patients', () async {
        dio.nextStatusCode = 200;
        dio.nextResponseData = emptyPayload();

        await remote.fetchPatients();

        expect(dio.lastMethod, equals('GET'));
        expect(dio.lastPath, equals('/api/v1/patients'));
      });

      test('forwards search, status, cursor, limit as query params', () async {
        dio.nextStatusCode = 200;
        dio.nextResponseData = emptyPayload();

        await remote.fetchPatients(
          search: 'Maria',
          status: 'admitted',
          cursor: 'abc123',
          limit: 25,
        );

        expect(dio.lastQueryParameters?['search'], equals('Maria'));
        expect(dio.lastQueryParameters?['status'], equals('admitted'));
        expect(dio.lastQueryParameters?['cursor'], equals('abc123'));
        expect(dio.lastQueryParameters?['limit'], equals(25));
      });

      test('parses PaginatedList<PatientSummaryResponse> on 200', () async {
        dio.nextStatusCode = 200;
        dio.nextResponseData = <String, dynamic>{
          'data': <Map<String, dynamic>>[
            <String, dynamic>{
              'patientId': kPatientUuid,
              'personId': kPersonUuid,
              'firstName': 'Maria',
              'lastName': 'Silva',
              'fullName': 'Maria Silva',
              'memberCount': 3,
              'status': 'admitted',
            },
          ],
          'meta': <String, dynamic>{
            'pageSize': 100,
            'totalCount': 1,
            'hasMore': false,
            'nextCursor': null,
          },
        };

        final result = await remote.fetchPatients();

        switch (result) {
          case Success(:final value):
            expect(value.data, hasLength(1));
            expect(value.data.first.patientId, equals(kPatientUuid));
            expect(value.meta.totalCount, equals(1));
          case Failure():
            fail('Expected Success on 200 with valid body');
        }
      });

      test(
        'maps non-2xx with error body to Failure(BackendErrorResponse)',
        () async {
          dio.nextStatusCode = 500;
          dio.nextResponseData = kBackendErrorBody(
            code: 'PAT-500',
            message: 'database down',
            http: 500,
          );

          final result = await remote.fetchPatients();

          switch (result) {
            case Success():
              fail('Expected Failure on 500');
            case Failure(:final error):
              expect(error, isA<BackendErrorResponse>());
              expect(
                (error as BackendErrorResponse).error.code,
                equals('PAT-500'),
              );
          }
        },
      );

      test('returns Failure when Dio throws', () async {
        dio.nextThrow = Exception('connection timeout');

        final result = await remote.fetchPatients();

        expect(result, isA<Failure<PaginatedList<PatientSummaryResponse>>>());
      });

      // T1.2 regression: large lists (>50 items) take the Isolate.run
      // threshold path. Behavior contract MUST be identical to the
      // inline path — same data, same meta, same ordering.
      test(
        'parses large list (100 items) — exercises Isolate threshold path '
        '(T1.2 regression)',
        () async {
          // Build 100 distinct patient summaries with deterministic ids.
          final entries = List<Map<String, dynamic>>.generate(100, (i) {
            // Build valid UUID v4-shape strings derived from i so each
            // entry has a unique, parseable id. Format: a1b2c3d4-eXXX-...
            final hex = i.toRadixString(16).padLeft(4, '0');
            return <String, dynamic>{
              'patientId': 'a1b2c3d4-e5f6-4789-a012-345678$hex',
              'personId': 'b2c3d4e5-f6a7-4890-b123-456789ab${hex.substring(0, 4)}',
              'firstName': 'Patient$i',
              'lastName': 'Surname$i',
              'fullName': 'Patient$i Surname$i',
              'memberCount': i % 7,
              'status': i.isEven ? 'admitted' : 'discharged',
            };
          });
          dio.nextStatusCode = 200;
          dio.nextResponseData = <String, dynamic>{
            'data': entries,
            'meta': <String, dynamic>{
              'pageSize': 100,
              'totalCount': 100,
              'hasMore': false,
              'nextCursor': null,
            },
          };

          final result = await remote.fetchPatients(limit: 100);

          switch (result) {
            case Success(:final value):
              // Behavior preservation contract:
              // 1. Same number of entries
              expect(value.data, hasLength(100));
              // 2. Same ordering (ASC by index in source)
              expect(value.data.first.firstName, equals('Patient0'));
              expect(value.data.last.firstName, equals('Patient99'));
              // 3. Field round-trip is intact (no data loss across isolate boundary)
              expect(value.data[42].lastName, equals('Surname42'));
              expect(value.data[42].memberCount, equals(42 % 7));
              // 4. Meta unchanged
              expect(value.meta.totalCount, equals(100));
              expect(value.meta.pageSize, equals(100));
            case Failure():
              fail('Expected Success on 200 with 100-item body');
          }
        },
      );

      // T1.2 regression: small lists (≤50) stay on inline path.
      // Same behavior contract as the larger original "parses... on 200"
      // test, but with exactly the boundary count to lock the threshold
      // semantic.
      test(
        'parses 50 items (boundary) — stays on inline path '
        '(T1.2 regression)',
        () async {
          final entries = List<Map<String, dynamic>>.generate(50, (i) {
            final hex = i.toRadixString(16).padLeft(4, '0');
            return <String, dynamic>{
              'patientId': 'a1b2c3d4-e5f6-4789-a012-345678$hex',
              'personId': 'b2c3d4e5-f6a7-4890-b123-456789ab${hex.substring(0, 4)}',
              'firstName': 'P$i',
              'lastName': 'L$i',
              'fullName': 'P$i L$i',
              'memberCount': 0,
              'status': 'admitted',
            };
          });
          dio.nextStatusCode = 200;
          dio.nextResponseData = <String, dynamic>{
            'data': entries,
            'meta': <String, dynamic>{
              'pageSize': 50,
              'totalCount': 50,
              'hasMore': false,
              'nextCursor': null,
            },
          };

          final result = await remote.fetchPatients(limit: 50);

          switch (result) {
            case Success(:final value):
              expect(value.data, hasLength(50));
              expect(value.data.first.firstName, equals('P0'));
              expect(value.data.last.firstName, equals('P49'));
            case Failure():
              fail('Expected Success on 200 with 50-item body');
          }
        },
      );
    });

    // ── registerPatient ────────────────────────────────────────────────
    group('registerPatient', () {
      const request = RegisterPatientRequest(
        personId: kPersonUuid,
        prRelationshipId: kLookupItemUuid,
        initialDiagnoses: <DiagnosisDraftDto>[
          DiagnosisDraftDto(
            icdCode: 'Q90.0',
            date: '2026-04-01',
            description: 'Down syndrome',
          ),
        ],
      );

      test('hits POST /api/v1/patients with toJson body', () async {
        dio.nextStatusCode = 201;
        dio.nextResponseData = kIdResponseBody(kPatientUuid);

        await remote.registerPatient(request);

        expect(dio.lastMethod, equals('POST'));
        expect(dio.lastPath, equals('/api/v1/patients'));
        expect(dio.lastBody, equals(request.toJson()));
      });

      test('parses StandardIdResponse on 201', () async {
        dio.nextStatusCode = 201;
        dio.nextResponseData = kIdResponseBody(kPatientUuid);

        final result = await remote.registerPatient(request);

        switch (result) {
          case Success(:final value):
            expect(value.data.id, equals(kPatientUuid));
          case Failure():
            fail('Expected Success on 201');
        }
      });

      test(
        'maps non-2xx with error body to Failure(BackendErrorResponse)',
        () async {
          dio.nextStatusCode = 409;
          dio.nextResponseData = kBackendErrorBody(
            code: 'PAT-409',
            message: 'duplicate person',
            http: 409,
          );

          final result = await remote.registerPatient(request);

          switch (result) {
            case Success():
              fail('Expected Failure on 409');
            case Failure(:final error):
              expect(error, isA<BackendErrorResponse>());
              expect(
                (error as BackendErrorResponse).error.code,
                equals('PAT-409'),
              );
          }
        },
      );

      test('returns Failure when Dio throws', () async {
        dio.nextThrow = Exception('network down');

        final result = await remote.registerPatient(request);

        expect(result, isA<Failure<StandardIdResponse>>());
      });
    });

    // ── fetchPatient ───────────────────────────────────────────────────
    group('fetchPatient', () {
      test('hits GET /api/v1/patients/<id>', () async {
        dio.nextStatusCode = 200;
        dio.nextResponseData = <String, dynamic>{
          'data': <String, dynamic>{
            'patientId': kPatientUuid,
            'personId': kPersonUuid,
            'status': 'admitted',
            'version': 0,
          },
          'meta': <String, dynamic>{'timestamp': '2026-04-29T10:00:00.000Z'},
        };

        await remote.fetchPatient(kPatientUuid);

        expect(dio.lastMethod, equals('GET'));
        expect(dio.lastPath, equals('/api/v1/patients/$kPatientUuid'));
      });

      test('parses PatientResponse on 200', () async {
        dio.nextStatusCode = 200;
        dio.nextResponseData = <String, dynamic>{
          'data': <String, dynamic>{
            'patientId': kPatientUuid,
            'personId': kPersonUuid,
            'status': 'admitted',
            'version': 0,
          },
          'meta': <String, dynamic>{'timestamp': '2026-04-29T10:00:00.000Z'},
        };

        final result = await remote.fetchPatient(kPatientUuid);

        switch (result) {
          case Success(:final value):
            expect(value.data.patientId, equals(kPatientUuid));
            expect(value.data.personId, equals(kPersonUuid));
          case Failure():
            fail('Expected Success on 200');
        }
      });

      test(
        'maps 404 with error body to Failure(BackendErrorResponse)',
        () async {
          dio.nextStatusCode = 404;
          dio.nextResponseData = kBackendErrorBody(
            code: 'PAT-404',
            message: 'patient not found',
            http: 404,
          );

          final result = await remote.fetchPatient(kPatientUuid);

          switch (result) {
            case Success():
              fail('Expected Failure on 404');
            case Failure(:final error):
              expect(error, isA<BackendErrorResponse>());
              expect(
                (error as BackendErrorResponse).error.code,
                equals('PAT-404'),
              );
          }
        },
      );

      test('returns Failure when Dio throws', () async {
        dio.nextThrow = Exception('reset');

        final result = await remote.fetchPatient(kPatientUuid);

        expect(result, isA<Failure<StandardResponse<PatientResponse>>>());
      });
    });

    // ── fetchPatientByPersonId ─────────────────────────────────────────
    group('fetchPatientByPersonId', () {
      test('hits GET /api/v1/patients/by-person/<id>', () async {
        dio.nextStatusCode = 200;
        dio.nextResponseData = <String, dynamic>{
          'data': <String, dynamic>{
            'patientId': kPatientUuid,
            'personId': kPersonUuid,
            'status': 'admitted',
            'version': 0,
          },
          'meta': <String, dynamic>{'timestamp': '2026-04-29T10:00:00.000Z'},
        };

        await remote.fetchPatientByPersonId(kPersonUuid);

        expect(dio.lastMethod, equals('GET'));
        expect(dio.lastPath, equals('/api/v1/patients/by-person/$kPersonUuid'));
      });

      test('parses PatientResponse on 200', () async {
        dio.nextStatusCode = 200;
        dio.nextResponseData = <String, dynamic>{
          'data': <String, dynamic>{
            'patientId': kPatientUuid,
            'personId': kPersonUuid,
            'status': 'admitted',
            'version': 0,
          },
          'meta': <String, dynamic>{'timestamp': '2026-04-29T10:00:00.000Z'},
        };

        final result = await remote.fetchPatientByPersonId(kPersonUuid);

        switch (result) {
          case Success(:final value):
            expect(value.data.personId, equals(kPersonUuid));
          case Failure():
            fail('Expected Success on 200');
        }
      });

      test(
        'maps 404 with error body to Failure(BackendErrorResponse)',
        () async {
          dio.nextStatusCode = 404;
          dio.nextResponseData = kBackendErrorBody(
            code: 'PAT-404',
            message: 'no patient for person',
            http: 404,
          );

          final result = await remote.fetchPatientByPersonId(kPersonUuid);

          switch (result) {
            case Success():
              fail('Expected Failure on 404');
            case Failure(:final error):
              expect(error, isA<BackendErrorResponse>());
          }
        },
      );

      test('returns Failure when Dio throws', () async {
        dio.nextThrow = Exception('boom');

        final result = await remote.fetchPatientByPersonId(kPersonUuid);

        expect(result, isA<Failure<StandardResponse<PatientResponse>>>());
      });
    });

    // ── addFamilyMember ────────────────────────────────────────────────
    group('addFamilyMember', () {
      const request = AddFamilyMemberRequest(
        memberPersonId: kPersonUuidAlt,
        relationship: 'mother',
        isResiding: true,
        isCaregiver: true,
        hasDisability: false,
        birthDate: '1985-06-15',
        prRelationshipId: kLookupItemUuid,
      );

      test(
        'hits POST /api/v1/patients/<id>/family-members with body',
        () async {
          dio.nextStatusCode = 201;

          await remote.addFamilyMember(kPatientUuid, request);

          expect(dio.lastMethod, equals('POST'));
          expect(
            dio.lastPath,
            equals('/api/v1/patients/$kPatientUuid/family-members'),
          );
          expect(dio.lastBody, equals(request.toJson()));
        },
      );

      test('returns Success(null) on 201', () async {
        dio.nextStatusCode = 201;

        final result = await remote.addFamilyMember(kPatientUuid, request);

        expect(result, isA<Success<void>>());
      });

      test('also accepts 200 and 204 for replay/idempotency', () async {
        dio.nextStatusCode = 200;
        var result = await remote.addFamilyMember(kPatientUuid, request);
        expect(result, isA<Success<void>>());

        dio.nextStatusCode = 204;
        result = await remote.addFamilyMember(kPatientUuid, request);
        expect(result, isA<Success<void>>());
      });

      test('optional cpf does not change path or body', () async {
        // REGRA #2 note: see file-level docstring. cpf is preserved as a
        // legacy parameter that does not affect the wire shape.
        dio.nextStatusCode = 201;

        await remote.addFamilyMember(kPatientUuid, request, cpf: '12345678900');

        expect(
          dio.lastPath,
          equals('/api/v1/patients/$kPatientUuid/family-members'),
        );
        expect(dio.lastBody, equals(request.toJson()));
      });

      test(
        'maps non-2xx with error body to Failure(BackendErrorResponse)',
        () async {
          dio.nextStatusCode = 422;
          dio.nextResponseData = kBackendErrorBody(
            code: 'FAM-422',
            message: 'duplicate member',
            http: 422,
          );

          final result = await remote.addFamilyMember(kPatientUuid, request);

          switch (result) {
            case Success():
              fail('Expected Failure on 422');
            case Failure(:final error):
              expect(error, isA<BackendErrorResponse>());
              expect(
                (error as BackendErrorResponse).error.code,
                equals('FAM-422'),
              );
          }
        },
      );

      test('returns Failure when Dio throws', () async {
        dio.nextThrow = Exception('eof');

        final result = await remote.addFamilyMember(kPatientUuid, request);

        expect(result, isA<Failure<void>>());
      });
    });

    // ── removeFamilyMember ─────────────────────────────────────────────
    group('removeFamilyMember', () {
      test('hits DELETE /api/v1/patients/<pid>/family-members/<mid>', () async {
        dio.nextStatusCode = 204;

        await remote.removeFamilyMember(kPatientUuid, kFamilyMemberUuid);

        expect(dio.lastMethod, equals('DELETE'));
        expect(
          dio.lastPath,
          equals(
            '/api/v1/patients/$kPatientUuid/family-members/$kFamilyMemberUuid',
          ),
        );
      });

      test('returns Success(null) on 204', () async {
        dio.nextStatusCode = 204;

        final result = await remote.removeFamilyMember(
          kPatientUuid,
          kFamilyMemberUuid,
        );

        expect(result, isA<Success<void>>());
      });

      test(
        'maps 404 with error body to Failure(BackendErrorResponse)',
        () async {
          dio.nextStatusCode = 404;
          dio.nextResponseData = kBackendErrorBody(
            code: 'FAM-404',
            message: 'member not found',
            http: 404,
          );

          final result = await remote.removeFamilyMember(
            kPatientUuid,
            kFamilyMemberUuid,
          );

          switch (result) {
            case Success():
              fail('Expected Failure on 404');
            case Failure(:final error):
              expect(error, isA<BackendErrorResponse>());
              expect(
                (error as BackendErrorResponse).error.code,
                equals('FAM-404'),
              );
          }
        },
      );

      test('returns Failure when Dio throws', () async {
        dio.nextThrow = Exception('reset');

        final result = await remote.removeFamilyMember(
          kPatientUuid,
          kFamilyMemberUuid,
        );

        expect(result, isA<Failure<void>>());
      });
    });

    // ── assignPrimaryCaregiver ─────────────────────────────────────────
    group('assignPrimaryCaregiver', () {
      const request = AssignPrimaryCaregiverRequest(
        memberPersonId: kPersonUuidAlt,
      );

      test(
        'hits PUT /api/v1/patients/<id>/primary-caregiver with body',
        () async {
          dio.nextStatusCode = 204;

          await remote.assignPrimaryCaregiver(kPatientUuid, request);

          expect(dio.lastMethod, equals('PUT'));
          expect(
            dio.lastPath,
            equals('/api/v1/patients/$kPatientUuid/primary-caregiver'),
          );
          expect(dio.lastBody, equals(request.toJson()));
        },
      );

      test('returns Success(null) on 204', () async {
        dio.nextStatusCode = 204;

        final result = await remote.assignPrimaryCaregiver(
          kPatientUuid,
          request,
        );

        expect(result, isA<Success<void>>());
      });

      test(
        'maps non-2xx with error body to Failure(BackendErrorResponse)',
        () async {
          dio.nextStatusCode = 409;
          dio.nextResponseData = kBackendErrorBody(
            code: 'CAR-409',
            message: 'caregiver mismatch',
            http: 409,
          );

          final result = await remote.assignPrimaryCaregiver(
            kPatientUuid,
            request,
          );

          switch (result) {
            case Success():
              fail('Expected Failure on 409');
            case Failure(:final error):
              expect(error, isA<BackendErrorResponse>());
          }
        },
      );

      test('returns Failure when Dio throws', () async {
        dio.nextThrow = Exception('boom');

        final result = await remote.assignPrimaryCaregiver(
          kPatientUuid,
          request,
        );

        expect(result, isA<Failure<void>>());
      });
    });

    // ── updateSocialIdentity ───────────────────────────────────────────
    group('updateSocialIdentity', () {
      const request = UpdateSocialIdentityRequest(
        typeId: kLookupItemUuid,
        description: 'Self-declared',
      );

      test(
        'hits PUT /api/v1/patients/<id>/social-identity with body',
        () async {
          dio.nextStatusCode = 204;

          await remote.updateSocialIdentity(kPatientUuid, request);

          expect(dio.lastMethod, equals('PUT'));
          expect(
            dio.lastPath,
            equals('/api/v1/patients/$kPatientUuid/social-identity'),
          );
          expect(dio.lastBody, equals(request.toJson()));
        },
      );

      test('returns Success(null) on 204', () async {
        dio.nextStatusCode = 204;

        final result = await remote.updateSocialIdentity(kPatientUuid, request);

        expect(result, isA<Success<void>>());
      });

      test(
        'maps non-2xx with error body to Failure(BackendErrorResponse)',
        () async {
          dio.nextStatusCode = 400;
          dio.nextResponseData = kBackendErrorBody(
            code: 'SID-400',
            message: 'unknown typeId',
            http: 400,
          );

          final result = await remote.updateSocialIdentity(
            kPatientUuid,
            request,
          );

          switch (result) {
            case Success():
              fail('Expected Failure on 400');
            case Failure(:final error):
              expect(error, isA<BackendErrorResponse>());
          }
        },
      );

      test('returns Failure when Dio throws', () async {
        dio.nextThrow = Exception('eof');

        final result = await remote.updateSocialIdentity(kPatientUuid, request);

        expect(result, isA<Failure<void>>());
      });
    });

    // ── dischargePatient ───────────────────────────────────────────────
    group('dischargePatient', () {
      const request = DischargePatientRequest(
        reason: 'completed_program',
        notes: 'all goals met',
      );

      test('hits POST /api/v1/patients/<id>/discharge with body', () async {
        dio.nextStatusCode = 204;

        await remote.dischargePatient(kPatientUuid, request);

        expect(dio.lastMethod, equals('POST'));
        expect(
          dio.lastPath,
          equals('/api/v1/patients/$kPatientUuid/discharge'),
        );
        expect(dio.lastBody, equals(request.toJson()));
      });

      test('returns Success(null) on 204', () async {
        dio.nextStatusCode = 204;

        final result = await remote.dischargePatient(kPatientUuid, request);

        expect(result, isA<Success<void>>());
      });

      test(
        'maps non-2xx with error body to Failure(BackendErrorResponse)',
        () async {
          dio.nextStatusCode = 409;
          dio.nextResponseData = kBackendErrorBody(
            code: 'LIF-409',
            message: 'already discharged',
            http: 409,
          );

          final result = await remote.dischargePatient(kPatientUuid, request);

          switch (result) {
            case Success():
              fail('Expected Failure on 409');
            case Failure(:final error):
              expect(error, isA<BackendErrorResponse>());
          }
        },
      );

      test('returns Failure when Dio throws', () async {
        dio.nextThrow = Exception('boom');

        final result = await remote.dischargePatient(kPatientUuid, request);

        expect(result, isA<Failure<void>>());
      });
    });

    // ── readmitPatient ─────────────────────────────────────────────────
    group('readmitPatient', () {
      const request = ReadmitPatientRequest(notes: 're-engaged');

      test('hits POST /api/v1/patients/<id>/readmit with body', () async {
        dio.nextStatusCode = 204;

        await remote.readmitPatient(kPatientUuid, request);

        expect(dio.lastMethod, equals('POST'));
        expect(dio.lastPath, equals('/api/v1/patients/$kPatientUuid/readmit'));
        expect(dio.lastBody, equals(request.toJson()));
      });

      test('returns Success(null) on 204', () async {
        dio.nextStatusCode = 204;

        final result = await remote.readmitPatient(kPatientUuid, request);

        expect(result, isA<Success<void>>());
      });

      test(
        'maps non-2xx with error body to Failure(BackendErrorResponse)',
        () async {
          dio.nextStatusCode = 409;
          dio.nextResponseData = kBackendErrorBody(
            code: 'LIF-409',
            message: 'already admitted',
            http: 409,
          );

          final result = await remote.readmitPatient(kPatientUuid, request);

          switch (result) {
            case Success():
              fail('Expected Failure on 409');
            case Failure(:final error):
              expect(error, isA<BackendErrorResponse>());
          }
        },
      );

      test('returns Failure when Dio throws', () async {
        dio.nextThrow = Exception('reset');

        final result = await remote.readmitPatient(kPatientUuid, request);

        expect(result, isA<Failure<void>>());
      });
    });

    // ── admitPatient ───────────────────────────────────────────────────
    group('admitPatient', () {
      test('hits POST /api/v1/patients/<id>/admit with no body', () async {
        dio.nextStatusCode = 204;

        await remote.admitPatient(kPatientUuid);

        expect(dio.lastMethod, equals('POST'));
        expect(dio.lastPath, equals('/api/v1/patients/$kPatientUuid/admit'));
      });

      test('returns Success(null) on 204', () async {
        dio.nextStatusCode = 204;

        final result = await remote.admitPatient(kPatientUuid);

        expect(result, isA<Success<void>>());
      });

      test(
        'maps non-2xx with error body to Failure(BackendErrorResponse)',
        () async {
          dio.nextStatusCode = 404;
          dio.nextResponseData = kBackendErrorBody(
            code: 'LIF-404',
            message: 'not in waitlist',
            http: 404,
          );

          final result = await remote.admitPatient(kPatientUuid);

          switch (result) {
            case Success():
              fail('Expected Failure on 404');
            case Failure(:final error):
              expect(error, isA<BackendErrorResponse>());
          }
        },
      );

      test('returns Failure when Dio throws', () async {
        dio.nextThrow = Exception('eof');

        final result = await remote.admitPatient(kPatientUuid);

        expect(result, isA<Failure<void>>());
      });
    });

    // ── withdrawPatient ────────────────────────────────────────────────
    group('withdrawPatient', () {
      const request = WithdrawPatientRequest(
        reason: 'family_decision',
        notes: 'moved out of region',
      );

      test('hits POST /api/v1/patients/<id>/withdraw with body', () async {
        dio.nextStatusCode = 204;

        await remote.withdrawPatient(kPatientUuid, request);

        expect(dio.lastMethod, equals('POST'));
        expect(dio.lastPath, equals('/api/v1/patients/$kPatientUuid/withdraw'));
        expect(dio.lastBody, equals(request.toJson()));
      });

      test('returns Success(null) on 204', () async {
        dio.nextStatusCode = 204;

        final result = await remote.withdrawPatient(kPatientUuid, request);

        expect(result, isA<Success<void>>());
      });

      test(
        'maps non-2xx with error body to Failure(BackendErrorResponse)',
        () async {
          dio.nextStatusCode = 409;
          dio.nextResponseData = kBackendErrorBody(
            code: 'LIF-409',
            message: 'already withdrawn',
            http: 409,
          );

          final result = await remote.withdrawPatient(kPatientUuid, request);

          switch (result) {
            case Success():
              fail('Expected Failure on 409');
            case Failure(:final error):
              expect(error, isA<BackendErrorResponse>());
          }
        },
      );

      test('returns Failure when Dio throws', () async {
        dio.nextThrow = Exception('boom');

        final result = await remote.withdrawPatient(kPatientUuid, request);

        expect(result, isA<Failure<void>>());
      });
    });
  });
}
