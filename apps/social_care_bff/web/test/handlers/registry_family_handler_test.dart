import 'dart:convert';

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/handlers/registry_family_handler.dart';
import 'package:social_care_web/src/use_cases/add_family_member_use_case.dart';
import 'package:social_care_web/src/use_cases/assign_primary_caregiver_use_case.dart';
import 'package:social_care_web/src/use_cases/get_audit_trail_use_case.dart';
import 'package:social_care_web/src/use_cases/remove_family_member_use_case.dart';
import 'package:social_care_web/src/use_cases/update_social_identity_use_case.dart';

import '../_test_uuids.dart';

/// Wave 0 RED for the new unified [RegistryFamilyHandler].
///
/// Routes (mounted on the shared `/` namespace; real server prefixes `/api`):
/// - `POST   /patients/<id>/family-members`
/// - `DELETE /patients/<id>/family-members/<memberId>`
/// - `PUT    /patients/<id>/primary-caregiver`
/// - `PUT    /patients/<id>/social-identity`
/// - `GET    /patients/<id>/audit-trail`
///
/// Canon: same helpers as [RegistryPatientHandler] — `_readJsonBody`,
/// `_extractError`, `_wrapVoidResult`, `_badRequest`, `_jsonHeaders`.
/// BackendError.http → HTTP status passthrough; non-BackendError →
/// 500 `INTERNAL` without leaking inner message.

/// Forces every registry mutation relevant to this handler to fail with
/// [error]. Used for upstream-status passthrough tests.
class _FailingRegistry extends FakeRegistryBff {
  _FailingRegistry(this.error);
  final BackendError error;

  @override
  Future<Result<void>> addFamilyMember(
    String patientId,
    AddFamilyMemberRequest request, {
    String? cpf,
  }) async => Failure(error);

  @override
  Future<Result<void>> removeFamilyMember(
    String patientId,
    String memberId,
  ) async => Failure(error);

  @override
  Future<Result<void>> assignPrimaryCaregiver(
    String patientId,
    AssignPrimaryCaregiverRequest request,
  ) async => Failure(error);

  @override
  Future<Result<void>> updateSocialIdentity(
    String patientId,
    UpdateSocialIdentityRequest request,
  ) async => Failure(error);
}

/// Forces the audit contract to fail.
class _FailingAudit extends FakeAuditBff {
  _FailingAudit(this.error);
  final BackendError error;

  @override
  Future<Result<StandardResponse<List<AuditTrailEntryResponse>>>> getAuditTrail(
    String patientId, {
    String? eventType,
    int? limit,
    int? offset,
  }) async => Failure(error);
}

/// Registry that returns a non-[BackendError] failure (a raw `Exception`).
/// Used to pin the 500 `INTERNAL` path — handler MUST NOT echo the inner
/// message (which could carry a stack trace or secret).
class _ExplodingRegistry extends FakeRegistryBff {
  @override
  Future<Result<void>> addFamilyMember(
    String patientId,
    AddFamilyMemberRequest request, {
    String? cpf,
  }) async => Failure(Exception('leak marker xyz'));
}

/// Capturing audit fake — asserts query params pass through to the contract.
class _CapturingAudit extends FakeAuditBff {
  String? capturedEventType;
  int? capturedLimit;
  int? capturedOffset;

  @override
  Future<Result<StandardResponse<List<AuditTrailEntryResponse>>>> getAuditTrail(
    String patientId, {
    String? eventType,
    int? limit,
    int? offset,
  }) async {
    capturedEventType = eventType;
    capturedLimit = limit;
    capturedOffset = offset;
    return super.getAuditTrail(
      patientId,
      eventType: eventType,
      limit: limit,
      offset: offset,
    );
  }
}

AuditTrailEntryResponse _entry(
  String id, {
  String aggregateId = kPatientUuid,
}) => AuditTrailEntryResponse(
  id: id,
  aggregateId: aggregateId,
  eventType: 'PATIENT_REGISTERED',
  occurredAt: '2026-04-17T10:00:00Z',
  recordedAt: '2026-04-17T10:00:01Z',
);

RegistryFamilyHandler _buildHandler({
  RegistryContract? registry,
  PeopleContract? people,
  AuditContract? audit,
}) {
  final r = registry ?? FakeRegistryBff();
  final p = people ?? FakePeopleBff();
  final a = audit ?? FakeAuditBff();
  return RegistryFamilyHandler(
    add: AddFamilyMemberUseCase(registry: r, people: p),
    remove: RemoveFamilyMemberUseCase(registry: r),
    assignCaregiver: AssignPrimaryCaregiverUseCase(registry: r),
    updateIdentity: UpdateSocialIdentityUseCase(registry: r),
    getAudit: GetAuditTrailUseCase(audit: a),
  );
}

Map<String, dynamic> _validAddFamilyMemberBody() => {
  'cpf': '11144477735',
  'fullName': 'Ana Silva',
  'birthDate': '2018-05-10',
  'relationship': 'CHILD',
  'isResiding': true,
  'isCaregiver': false,
  'hasDisability': false,
  'prRelationshipId': 'rel-child',
  'requiredDocuments': <String>[],
};

void main() {
  group('RegistryFamilyHandler — 5-endpoint canonical handler', () {
    // ── POST /patients/<id>/family-members ────────────────────────────────
    group('POST /patients/<id>/family-members', () {
      test('returns 2xx on happy path', () async {
        final handler = _buildHandler();

        final request = Request(
          'POST',
          Uri.parse('http://localhost/patients/$kPatientUuid/family-members'),
          body: jsonEncode(_validAddFamilyMemberBody()),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, lessThan(300));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(body['data'], isNull);
      });

      test('returns 400 INVALID_JSON when body is malformed', () async {
        final handler = _buildHandler();

        final request = Request(
          'POST',
          Uri.parse('http://localhost/patients/$kPatientUuid/family-members'),
          body: 'not json',
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect((body['error'] as Map)['code'], equals('INVALID_JSON'));
      });

      test(
        'returns 400 INVALID_ADD_FAMILY_MEMBER_BODY when required fields missing',
        () async {
          final handler = _buildHandler();

          final body = _validAddFamilyMemberBody()..remove('relationship');
          final request = Request(
            'POST',
            Uri.parse('http://localhost/patients/$kPatientUuid/family-members'),
            body: jsonEncode(body),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(400));
          final decoded =
              jsonDecode(await response.readAsString()) as Map<String, dynamic>;
          expect(
            (decoded['error'] as Map)['code'],
            equals('INVALID_ADD_FAMILY_MEMBER_BODY'),
          );
        },
      );

      test('400 body does NOT echo raw CPF from request (PII)', () async {
        final handler = _buildHandler();

        final body = _validAddFamilyMemberBody()..remove('relationship');
        final request = Request(
          'POST',
          Uri.parse('http://localhost/patients/$kPatientUuid/family-members'),
          body: jsonEncode(body),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);
        final text = await response.readAsString();

        expect(text, isNot(contains('11144477735')));
        expect(text, isNot(contains('Ana Silva')));
      });

      test('propagates BackendError http status (e.g. 409 conflict)', () async {
        final failing = _FailingRegistry(
          const BackendError(
            id: 'err-1',
            code: 'RELATIONSHIP_INVALID',
            message: 'relationship incompatible with existing family',
            http: 409,
          ),
        );
        final handler = _buildHandler(registry: failing);

        final body = _validAddFamilyMemberBody()
          ..remove('cpf') // avoid People detour; go straight to Registry
          ..remove('fullName')
          ..['memberPersonId'] = 'per-42';
        final request = Request(
          'POST',
          Uri.parse('http://localhost/patients/$kPatientUuid/family-members'),
          body: jsonEncode(body),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(409));
      });

      test(
        'returns 500 INTERNAL without leaking inner message on non-BackendError',
        () async {
          final handler = _buildHandler(registry: _ExplodingRegistry());

          final body = _validAddFamilyMemberBody()
            ..remove('cpf')
            ..remove('fullName')
            ..['memberPersonId'] = 'per-42';
          final request = Request(
            'POST',
            Uri.parse('http://localhost/patients/$kPatientUuid/family-members'),
            body: jsonEncode(body),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);
          final text = await response.readAsString();

          expect(response.statusCode, equals(500));
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          expect((decoded['error'] as Map)['code'], equals('INTERNAL'));
          expect(text, isNot(contains('leak marker xyz')));
        },
      );

      test(
        'returns 400 INVALID_ADD_FAMILY_MEMBER_BODY when path id is not UUID v4',
        () async {
          final handler = _buildHandler();

          final request = Request(
            'POST',
            Uri.parse('http://localhost/patients/$kNonUuid/family-members'),
            body: jsonEncode(_validAddFamilyMemberBody()),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);
          final text = await response.readAsString();

          expect(response.statusCode, equals(400));
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          expect(
            (decoded['error'] as Map)['code'],
            equals('INVALID_ADD_FAMILY_MEMBER_BODY'),
          );
          expect(
            text,
            isNot(contains(kNonUuid)),
            reason: 'PII safety — must not echo raw path input',
          );
        },
      );
    });

    // ── DELETE /patients/<id>/family-members/<memberId> ───────────────────
    group('DELETE /patients/<id>/family-members/<memberId>', () {
      test('returns 2xx on happy path (void success)', () async {
        final handler = _buildHandler();

        final request = Request(
          'DELETE',
          Uri.parse(
            'http://localhost/patients/$kPatientUuid/family-members/$kFamilyMemberUuid',
          ),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, lessThan(300));
      });

      test('propagates 404 when Registry says memberId unknown', () async {
        final failing = _FailingRegistry(
          const BackendError(
            id: 'err-1',
            code: 'MEMBER_NOT_FOUND',
            message: 'member does not belong to patient',
            http: 404,
          ),
        );
        final handler = _buildHandler(registry: failing);

        final request = Request(
          'DELETE',
          Uri.parse(
            'http://localhost/patients/$kPatientUuid/family-members/$kFamilyMemberUuidAlt',
          ),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(404));
      });

      test(
        'returns 400 INVALID_REMOVE_FAMILY_MEMBER_PARAMS when patientId is not UUID v4',
        () async {
          final handler = _buildHandler();

          final request = Request(
            'DELETE',
            Uri.parse(
              'http://localhost/patients/$kNonUuid/family-members/$kFamilyMemberUuid',
            ),
          );
          final response = await handler.router.call(request);
          final text = await response.readAsString();

          expect(response.statusCode, equals(400));
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          expect(
            (decoded['error'] as Map)['code'],
            equals('INVALID_REMOVE_FAMILY_MEMBER_PARAMS'),
          );
          expect((decoded['error'] as Map)['message'], contains('patientId'));
          expect(text, isNot(contains(kNonUuid)));
        },
      );

      test(
        'returns 400 INVALID_REMOVE_FAMILY_MEMBER_PARAMS when memberId is not UUID v4',
        () async {
          final handler = _buildHandler();

          final request = Request(
            'DELETE',
            Uri.parse(
              'http://localhost/patients/$kPatientUuid/family-members/$kNonUuid',
            ),
          );
          final response = await handler.router.call(request);
          final text = await response.readAsString();

          expect(response.statusCode, equals(400));
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          expect(
            (decoded['error'] as Map)['code'],
            equals('INVALID_REMOVE_FAMILY_MEMBER_PARAMS'),
          );
          expect((decoded['error'] as Map)['message'], contains('memberId'));
          expect(text, isNot(contains(kNonUuid)));
        },
      );
    });

    // ── PUT /patients/<id>/primary-caregiver ──────────────────────────────
    group('PUT /patients/<id>/primary-caregiver', () {
      test('returns 2xx on happy path', () async {
        final handler = _buildHandler();

        final request = Request(
          'PUT',
          Uri.parse(
            'http://localhost/patients/$kPatientUuid/primary-caregiver',
          ),
          body: jsonEncode(const {'memberPersonId': 'per-42'}),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, lessThan(300));
      });

      test('returns 400 when memberPersonId is missing', () async {
        final handler = _buildHandler();

        final request = Request(
          'PUT',
          Uri.parse(
            'http://localhost/patients/$kPatientUuid/primary-caregiver',
          ),
          body: jsonEncode(const {}),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
      });

      test(
        'returns upstream status when assignPrimaryCaregiver fails',
        () async {
          final failing = _FailingRegistry(
            const BackendError(
              id: 'err-1',
              code: 'MEMBER_NOT_FOUND',
              message: 'not a member',
              http: 404,
            ),
          );
          final handler = _buildHandler(registry: failing);

          final request = Request(
            'PUT',
            Uri.parse(
              'http://localhost/patients/$kPatientUuid/primary-caregiver',
            ),
            body: jsonEncode(const {'memberPersonId': 'per-42'}),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(404));
        },
      );

      test(
        'returns 400 INVALID_PRIMARY_CAREGIVER_BODY when path id is not UUID v4',
        () async {
          final handler = _buildHandler();

          final request = Request(
            'PUT',
            Uri.parse('http://localhost/patients/$kNonUuid/primary-caregiver'),
            body: jsonEncode(const {'memberPersonId': 'per-42'}),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);
          final text = await response.readAsString();

          expect(response.statusCode, equals(400));
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          expect(
            (decoded['error'] as Map)['code'],
            equals('INVALID_PRIMARY_CAREGIVER_BODY'),
          );
          expect(text, isNot(contains(kNonUuid)));
        },
      );
    });

    // ── PUT /patients/<id>/social-identity ────────────────────────────────
    group('PUT /patients/<id>/social-identity', () {
      test('returns 2xx on happy path', () async {
        final handler = _buildHandler();

        final request = Request(
          'PUT',
          Uri.parse('http://localhost/patients/$kPatientUuid/social-identity'),
          body: jsonEncode(const {'typeId': 'type-1', 'description': 'desc'}),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, lessThan(300));
      });

      test('returns 400 when typeId is missing', () async {
        final handler = _buildHandler();

        final request = Request(
          'PUT',
          Uri.parse('http://localhost/patients/$kPatientUuid/social-identity'),
          body: jsonEncode(const {}),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
      });

      test('returns upstream status when updateSocialIdentity fails', () async {
        final failing = _FailingRegistry(
          const BackendError(
            id: 'err-1',
            code: 'IDENTITY_TYPE_NOT_FOUND',
            message: 'typeId unknown',
            http: 404,
          ),
        );
        final handler = _buildHandler(registry: failing);

        final request = Request(
          'PUT',
          Uri.parse('http://localhost/patients/$kPatientUuid/social-identity'),
          body: jsonEncode(const {'typeId': 'type-1'}),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(404));
      });

      test(
        'returns 400 INVALID_SOCIAL_IDENTITY_BODY when path id is not UUID v4',
        () async {
          final handler = _buildHandler();

          final request = Request(
            'PUT',
            Uri.parse('http://localhost/patients/$kNonUuid/social-identity'),
            body: jsonEncode(const {'typeId': 'type-1'}),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);
          final text = await response.readAsString();

          expect(response.statusCode, equals(400));
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          expect(
            (decoded['error'] as Map)['code'],
            equals('INVALID_SOCIAL_IDENTITY_BODY'),
          );
          expect(text, isNot(contains(kNonUuid)));
        },
      );
    });

    // ── GET /patients/<id>/audit-trail ────────────────────────────────────
    group('GET /patients/<id>/audit-trail', () {
      test('returns 200 with empty list when no entries', () async {
        final handler = _buildHandler();

        final request = Request(
          'GET',
          Uri.parse('http://localhost/patients/$kPatientUuid/audit-trail'),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(200));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(body['data'], isA<List<dynamic>>());
        expect(body['data'] as List, isEmpty);
      });

      test('returns 200 with seeded entries', () async {
        final fake = FakeAuditBff();
        fake.seed(kPatientUuid, [_entry('ev-1'), _entry('ev-2')]);

        final handler = _buildHandler(audit: fake);

        final request = Request(
          'GET',
          Uri.parse('http://localhost/patients/$kPatientUuid/audit-trail'),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(200));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(body['data'] as List, hasLength(2));
      });

      test('forwards eventType + limit + offset to the contract', () async {
        final capturing = _CapturingAudit();
        final handler = _buildHandler(audit: capturing);

        final request = Request(
          'GET',
          Uri.parse(
            'http://localhost/patients/$kPatientUuid/audit-trail'
            '?eventType=PATIENT_REGISTERED&limit=25&offset=10',
          ),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(200));
        expect(capturing.capturedEventType, equals('PATIENT_REGISTERED'));
        expect(capturing.capturedLimit, equals(25));
        expect(capturing.capturedOffset, equals(10));
      });

      test('returns upstream status when audit contract fails', () async {
        final failing = _FailingAudit(
          const BackendError(
            id: 'err-1',
            code: 'AUDIT_UNAVAILABLE',
            message: 'audit down',
            http: 502,
          ),
        );
        final handler = _buildHandler(audit: failing);

        final request = Request(
          'GET',
          Uri.parse('http://localhost/patients/$kPatientUuid/audit-trail'),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(502));
      });

      test(
        'returns 400 INVALID_GET_AUDIT_TRAIL_PARAMS when path id is not UUID v4',
        () async {
          final handler = _buildHandler();

          final request = Request(
            'GET',
            Uri.parse('http://localhost/patients/$kNonUuid/audit-trail'),
          );
          final response = await handler.router.call(request);
          final text = await response.readAsString();

          expect(response.statusCode, equals(400));
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          expect(
            (decoded['error'] as Map)['code'],
            equals('INVALID_GET_AUDIT_TRAIL_PARAMS'),
          );
          expect((decoded['error'] as Map)['message'], contains('patientId'));
          expect(text, isNot(contains(kNonUuid)));
        },
      );
    });

    // ── Cross-cutting PII / state matrix ─────────────────────────────────
    group('State matrix (P1) — sanitized error body', () {
      test('error response body does NOT contain Dart stack traces or inner '
          'Exception prose', () async {
        final handler = _buildHandler(registry: _ExplodingRegistry());

        final body = _validAddFamilyMemberBody()
          ..remove('cpf')
          ..remove('fullName')
          ..['memberPersonId'] = 'per-42';
        final request = Request(
          'POST',
          Uri.parse('http://localhost/patients/$kPatientUuid/family-members'),
          body: jsonEncode(body),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);
        final text = await response.readAsString();

        expect(text, isNot(contains('#0')), reason: 'stack trace leak');
        expect(text, isNot(contains('Exception:')));
      });
    });
  });
}
