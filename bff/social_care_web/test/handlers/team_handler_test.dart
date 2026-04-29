import 'dart:convert';

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/handlers/team_handler.dart';
import 'package:social_care_web/src/use_cases/assign_role_use_case.dart';
import 'package:social_care_web/src/use_cases/deactivate_role_use_case.dart';
import 'package:social_care_web/src/use_cases/deactivate_worker_use_case.dart';
import 'package:social_care_web/src/use_cases/get_team_member_use_case.dart';
import 'package:social_care_web/src/use_cases/list_team_use_case.dart';
import 'package:social_care_web/src/use_cases/reactivate_role_use_case.dart';
import 'package:social_care_web/src/use_cases/reactivate_worker_use_case.dart';
import 'package:social_care_web/src/use_cases/register_worker_use_case.dart';
import 'package:social_care_web/src/use_cases/reset_password_use_case.dart';

/// A [TeamContract] variant that forces every operation to fail with a
/// configured [BackendError]. Used to validate failure-path status codes.
class _FailingTeam extends FakeTeamBff {
  _FailingTeam(this.error);
  final BackendError error;

  @override
  Future<Result<StandardResponse<List<TeamMemberResponse>>>> listTeam({
    String? role,
    bool? active,
    String? search,
  }) async => Failure(error);

  @override
  Future<Result<StandardIdResponse>> registerWorker(
    RegisterPersonWithLoginRequest request,
  ) async => Failure(error);

  @override
  Future<Result<StandardResponse<TeamMemberDetailResponse>>> getTeamMember(
    String memberId,
  ) async => Failure(error);

  @override
  Future<Result<StandardResponse<void>>> deactivateWorker(
    String memberId,
  ) async => Failure(error);

  @override
  Future<Result<StandardResponse<void>>> reactivateWorker(
    String memberId,
  ) async => Failure(error);

  @override
  Future<Result<StandardResponse<void>>> resetPassword(
    String memberId,
  ) async => Failure(error);

  @override
  Future<Result<StandardIdResponse>> assignRole(
    String memberId,
    AssignRoleRequest request,
  ) async => Failure(error);

  @override
  Future<Result<StandardResponse<void>>> deactivateRole(
    String memberId,
    String roleId,
  ) async => Failure(error);

  @override
  Future<Result<StandardResponse<void>>> reactivateRole(
    String memberId,
    String roleId,
  ) async => Failure(error);
}

/// A [TeamContract] variant that explodes with a raw [Exception] wrapped
/// in [Failure]. Used to validate the 500 sanitization path.
class _ExplodingTeam extends FakeTeamBff {
  @override
  Future<Result<StandardIdResponse>> registerWorker(
    RegisterPersonWithLoginRequest request,
  ) async => Failure(Exception('internal leak marker xyz'));
}

TeamHandler _buildHandler({TeamContract? team}) {
  final t = team ?? FakeTeamBff();
  return TeamHandler(
    listTeam: ListTeamUseCase(team: t),
    registerWorker: RegisterWorkerUseCase(team: t),
    getTeamMember: GetTeamMemberUseCase(team: t),
    deactivateWorker: DeactivateWorkerUseCase(team: t),
    reactivateWorker: ReactivateWorkerUseCase(team: t),
    resetPassword: ResetPasswordUseCase(team: t),
    assignRole: AssignRoleUseCase(team: t),
    deactivateRole: DeactivateRoleUseCase(team: t),
    reactivateRole: ReactivateRoleUseCase(team: t),
  );
}

void _seedMember(
  FakeTeamBff fake, {
  required String id,
  String fullName = 'Maria Silva',
  bool active = true,
}) {
  fake.store.register(
    TeamMemberResponse(
      id: id,
      personId: 'p-$id',
      fullName: fullName,
      email: 'maria@example.com',
      phone: null,
      active: active,
      primaryRole: null,
    ),
  );
}

Map<String, dynamic> _validRegisterBody() => {
  'fullName': 'Maria Silva',
  'birthDate': '1990-05-12',
  'email': 'maria.silva@acdgbrasil.com.br',
};

Map<String, dynamic> _validAssignRoleBody() => {
  'system': 'social-care',
  'role': 'social_worker',
};

Map<String, dynamic> _decode(String body) =>
    jsonDecode(body) as Map<String, dynamic>;

void main() {
  group('TeamHandler (thin handler — UseCase orchestration)', () {
    // ── GET /team (query-tolerant) ────────────────────────────────────────

    group('GET /team (query-tolerant list)', () {
      test('returns 200 with empty list when team is unseeded', () async {
        final handler = _buildHandler();
        final response = await handler.router.call(
          Request('GET', Uri.parse('http://localhost/team')),
        );

        expect(response.statusCode, equals(200));
        final body = _decode(await response.readAsString());
        expect(body['data'], isA<List<dynamic>>());
        expect(body['data'] as List, isEmpty);
      });

      test('returns 200 with seeded members', () async {
        final fake = FakeTeamBff();
        _seedMember(fake, id: 'm-1');
        final handler = _buildHandler(team: fake);

        final response = await handler.router.call(
          Request('GET', Uri.parse('http://localhost/team')),
        );

        expect(response.statusCode, equals(200));
        final body = _decode(await response.readAsString());
        expect(body['data'] as List, hasLength(1));
      });

      test(
        'returns 400 INVALID_LIST_TEAM_QUERY when active is malformed',
        () async {
          final handler = _buildHandler();
          final response = await handler.router.call(
            Request('GET', Uri.parse('http://localhost/team?active=abc')),
          );

          expect(response.statusCode, equals(400));
          final body = _decode(await response.readAsString());
          expect(
            (body['error'] as Map<String, dynamic>)['code'],
            equals('INVALID_LIST_TEAM_QUERY'),
          );
        },
      );

      test('returns upstream status when listTeam fails', () async {
        final failing = _FailingTeam(
          const BackendError(
            id: 'err-1',
            code: 'TEAM_UNAVAILABLE',
            message: 'upstream down',
            http: 502,
          ),
        );
        final handler = _buildHandler(team: failing);
        final response = await handler.router.call(
          Request('GET', Uri.parse('http://localhost/team')),
        );

        expect(response.statusCode, equals(502));
      });
    });

    // ── POST /team ────────────────────────────────────────────────────────

    group('POST /team (register worker — P2 if-case 3 required)', () {
      test('returns 200 with generated id on happy path', () async {
        final handler = _buildHandler();
        final response = await handler.router.call(
          Request(
            'POST',
            Uri.parse('http://localhost/team'),
            body: jsonEncode(_validRegisterBody()),
            headers: {'content-type': 'application/json'},
          ),
        );

        expect(response.statusCode, equals(200));
        final body = _decode(await response.readAsString());
        expect((body['data'] as Map<String, dynamic>)['id'], isNotEmpty);
      });

      test(
        'returns 400 INVALID_REGISTER_WORKER_BODY when required fields missing',
        () async {
          final handler = _buildHandler();
          final response = await handler.router.call(
            Request(
              'POST',
              Uri.parse('http://localhost/team'),
              body: jsonEncode(<String, dynamic>{'fullName': 'M'}),
              headers: {'content-type': 'application/json'},
            ),
          );

          expect(response.statusCode, equals(400));
          final body = _decode(await response.readAsString());
          expect(
            (body['error'] as Map<String, dynamic>)['code'],
            equals('INVALID_REGISTER_WORKER_BODY'),
          );
        },
      );

      test('returns 400 INVALID_JSON when body is malformed', () async {
        final handler = _buildHandler();
        final response = await handler.router.call(
          Request(
            'POST',
            Uri.parse('http://localhost/team'),
            body: '{not-json',
            headers: {'content-type': 'application/json'},
          ),
        );

        expect(response.statusCode, equals(400));
        final body = _decode(await response.readAsString());
        expect(
          (body['error'] as Map<String, dynamic>)['code'],
          equals('INVALID_JSON'),
        );
      });

      test('returns upstream status when registerWorker fails', () async {
        final failing = _FailingTeam(
          const BackendError(
            id: 'err-1',
            code: 'EMAIL_TAKEN',
            message: 'curated upstream message',
            http: 409,
          ),
        );
        final handler = _buildHandler(team: failing);
        final response = await handler.router.call(
          Request(
            'POST',
            Uri.parse('http://localhost/team'),
            body: jsonEncode(_validRegisterBody()),
            headers: {'content-type': 'application/json'},
          ),
        );

        expect(response.statusCode, equals(409));
      });

      test('500 response sanitizes raw Exception / stack trace', () async {
        final handler = _buildHandler(team: _ExplodingTeam());
        final response = await handler.router.call(
          Request(
            'POST',
            Uri.parse('http://localhost/team'),
            body: jsonEncode(_validRegisterBody()),
            headers: {'content-type': 'application/json'},
          ),
        );

        expect(response.statusCode, equals(500));
        final body = await response.readAsString();
        expect(body, isNot(contains('internal leak marker xyz')));
        expect(body, isNot(contains('Exception:')));
      });
    });

    // ── GET /team/<id> ────────────────────────────────────────────────────

    group('GET /team/<id> (get member — path-only)', () {
      test('returns 200 with the member detail', () async {
        final fake = FakeTeamBff();
        _seedMember(fake, id: 'm-1');
        final handler = _buildHandler(team: fake);

        final response = await handler.router.call(
          Request('GET', Uri.parse('http://localhost/team/m-1')),
        );

        expect(response.statusCode, equals(200));
        final body = _decode(await response.readAsString());
        final data = body['data'] as Map<String, dynamic>;
        expect(data['id'], equals('m-1'));
      });

      test('returns upstream 404 when member is missing', () async {
        final failing = _FailingTeam(
          const BackendError(
            id: 'err-1',
            code: 'NOT_FOUND',
            message: 'unknown',
            http: 404,
          ),
        );
        final handler = _buildHandler(team: failing);
        final response = await handler.router.call(
          Request('GET', Uri.parse('http://localhost/team/missing')),
        );

        expect(response.statusCode, equals(404));
      });
    });

    // ── PUT /team/<id>/deactivate ─────────────────────────────────────────

    group('PUT /team/<id>/deactivate (path-only void)', () {
      test('returns 200 with null data on happy path', () async {
        final handler = _buildHandler();
        final response = await handler.router.call(
          Request(
            'PUT',
            Uri.parse('http://localhost/team/m-1/deactivate'),
          ),
        );

        expect(response.statusCode, equals(200));
        final body = _decode(await response.readAsString());
        expect(body['data'], isNull);
      });

      test('returns upstream status when deactivateWorker fails', () async {
        final failing = _FailingTeam(
          const BackendError(
            id: 'err-1',
            code: 'WORKER_LOCKED',
            message: 'cannot deactivate',
            http: 409,
          ),
        );
        final handler = _buildHandler(team: failing);
        final response = await handler.router.call(
          Request(
            'PUT',
            Uri.parse('http://localhost/team/m-1/deactivate'),
          ),
        );

        expect(response.statusCode, equals(409));
      });
    });

    // ── PUT /team/<id>/reactivate ─────────────────────────────────────────

    group('PUT /team/<id>/reactivate (path-only void)', () {
      test('returns 200 with null data on happy path', () async {
        final handler = _buildHandler();
        final response = await handler.router.call(
          Request(
            'PUT',
            Uri.parse('http://localhost/team/m-1/reactivate'),
          ),
        );

        expect(response.statusCode, equals(200));
      });
    });

    // ── POST /team/<id>/reset-password ────────────────────────────────────

    group('POST /team/<id>/reset-password (path-only void)', () {
      test('returns 200 with null data on happy path', () async {
        final handler = _buildHandler();
        final response = await handler.router.call(
          Request(
            'POST',
            Uri.parse('http://localhost/team/m-1/reset-password'),
          ),
        );

        expect(response.statusCode, equals(200));
      });

      test('returns upstream status when resetPassword fails', () async {
        final failing = _FailingTeam(
          const BackendError(
            id: 'err-1',
            code: 'IDP_DOWN',
            message: 'zitadel unavailable',
            http: 503,
          ),
        );
        final handler = _buildHandler(team: failing);
        final response = await handler.router.call(
          Request(
            'POST',
            Uri.parse('http://localhost/team/m-1/reset-password'),
          ),
        );

        expect(response.statusCode, equals(503));
      });
    });

    // ── POST /team/<id>/roles ─────────────────────────────────────────────

    group('POST /team/<id>/roles (assign role — P2 if-case 2 required)', () {
      test('returns 200 with generated roleId on happy path', () async {
        final handler = _buildHandler();
        final response = await handler.router.call(
          Request(
            'POST',
            Uri.parse('http://localhost/team/m-1/roles'),
            body: jsonEncode(_validAssignRoleBody()),
            headers: {'content-type': 'application/json'},
          ),
        );

        expect(response.statusCode, equals(200));
        final body = _decode(await response.readAsString());
        expect((body['data'] as Map<String, dynamic>)['id'], isNotEmpty);
      });

      test(
        'returns 400 INVALID_ASSIGN_ROLE_BODY when system is missing',
        () async {
          final handler = _buildHandler();
          final response = await handler.router.call(
            Request(
              'POST',
              Uri.parse('http://localhost/team/m-1/roles'),
              body: jsonEncode(<String, dynamic>{'role': 'social_worker'}),
              headers: {'content-type': 'application/json'},
            ),
          );

          expect(response.statusCode, equals(400));
          final body = _decode(await response.readAsString());
          expect(
            (body['error'] as Map<String, dynamic>)['code'],
            equals('INVALID_ASSIGN_ROLE_BODY'),
          );
        },
      );

      test('returns 400 INVALID_JSON when body is malformed', () async {
        final handler = _buildHandler();
        final response = await handler.router.call(
          Request(
            'POST',
            Uri.parse('http://localhost/team/m-1/roles'),
            body: '{broken',
            headers: {'content-type': 'application/json'},
          ),
        );

        expect(response.statusCode, equals(400));
        final body = _decode(await response.readAsString());
        expect(
          (body['error'] as Map<String, dynamic>)['code'],
          equals('INVALID_JSON'),
        );
      });

      test('returns upstream status when assignRole fails', () async {
        final failing = _FailingTeam(
          const BackendError(
            id: 'err-1',
            code: 'ROLE_CONFLICT',
            message: 'already assigned',
            http: 409,
          ),
        );
        final handler = _buildHandler(team: failing);
        final response = await handler.router.call(
          Request(
            'POST',
            Uri.parse('http://localhost/team/m-1/roles'),
            body: jsonEncode(_validAssignRoleBody()),
            headers: {'content-type': 'application/json'},
          ),
        );

        expect(response.statusCode, equals(409));
      });
    });

    // ── PUT /team/<id>/roles/<roleId>/deactivate ──────────────────────────

    group('PUT /team/<id>/roles/<roleId>/deactivate (path-only void)', () {
      test('returns 200 with null data on happy path', () async {
        final handler = _buildHandler();
        final response = await handler.router.call(
          Request(
            'PUT',
            Uri.parse('http://localhost/team/m-1/roles/r-1/deactivate'),
          ),
        );

        expect(response.statusCode, equals(200));
      });
    });

    // ── PUT /team/<id>/roles/<roleId>/reactivate ──────────────────────────

    group('PUT /team/<id>/roles/<roleId>/reactivate (path-only void)', () {
      test('returns 200 with null data on happy path', () async {
        final handler = _buildHandler();
        final response = await handler.router.call(
          Request(
            'PUT',
            Uri.parse('http://localhost/team/m-1/roles/r-1/reactivate'),
          ),
        );

        expect(response.statusCode, equals(200));
      });
    });

    // ── Topology hiding (legacy /team/people/* surfaces) ──────────────────

    group('topology hiding — legacy /team/people/* routes are gone', () {
      test('GET /team/people/by-cpf/<cpf> is no longer routed', () async {
        final handler = _buildHandler();
        final response = await handler.router.call(
          Request(
            'GET',
            Uri.parse('http://localhost/team/people/by-cpf/12345678901'),
          ),
        );

        // The route was deleted in A15 — shelf_router returns 404 when no
        // handler matches.
        expect(response.statusCode, equals(404));
      });

      test('GET /team/people/<id>/roles is no longer routed', () async {
        final handler = _buildHandler();
        final response = await handler.router.call(
          Request(
            'GET',
            Uri.parse('http://localhost/team/people/p-1/roles'),
          ),
        );

        expect(response.statusCode, equals(404));
      });

      test('POST /team/people/<id>/roles is no longer routed', () async {
        final handler = _buildHandler();
        final response = await handler.router.call(
          Request(
            'POST',
            Uri.parse('http://localhost/team/people/p-1/roles'),
            body: jsonEncode(<String, dynamic>{'system': 's', 'role': 'r'}),
            headers: {'content-type': 'application/json'},
          ),
        );

        expect(response.statusCode, equals(404));
      });
    });
  });
}
