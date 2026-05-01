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

import '../_test_uuids.dart';

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
        _seedMember(fake, id: kMemberUuid);
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
        _seedMember(fake, id: kMemberUuid);
        final handler = _buildHandler(team: fake);

        final response = await handler.router.call(
          Request('GET', Uri.parse('http://localhost/team/$kMemberUuid')),
        );

        expect(response.statusCode, equals(200));
        final body = _decode(await response.readAsString());
        final data = body['data'] as Map<String, dynamic>;
        expect(data['id'], equals(kMemberUuid));
      });

      test(
        'returns upstream 404 when member is missing (valid UUID, '
        'absent from store)',
        () async {
          final failing = _FailingTeam(
            const BackendError(
              id: 'err-1',
              code: 'NOT_FOUND',
              message: 'unknown',
              http: 404,
            ),
          );
          final handler = _buildHandler(team: failing);
          // REGRA #2 (CLAUDE.md): use a *valid* UUID that is absent from
          // the store. After the A23 retrofit, a non-UUID literal here
          // would be intercepted by the UUID gate and return 400, not 404.
          final response = await handler.router.call(
            Request(
              'GET',
              Uri.parse('http://localhost/team/$kMemberUuidAlt'),
            ),
          );

          expect(response.statusCode, equals(404));
        },
      );
    });

    // ── PUT /team/<id>/deactivate ─────────────────────────────────────────

    group('PUT /team/<id>/deactivate (path-only void)', () {
      test('returns 200 with null data on happy path', () async {
        final handler = _buildHandler();
        final response = await handler.router.call(
          Request(
            'PUT',
            Uri.parse('http://localhost/team/$kMemberUuid/deactivate'),
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
            Uri.parse('http://localhost/team/$kMemberUuid/deactivate'),
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
            Uri.parse('http://localhost/team/$kMemberUuid/reactivate'),
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
            Uri.parse('http://localhost/team/$kMemberUuid/reset-password'),
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
            Uri.parse(
              'http://localhost/team/$kMemberUuid/reset-password',
            ),
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
            Uri.parse('http://localhost/team/$kMemberUuid/roles'),
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
              Uri.parse('http://localhost/team/$kMemberUuid/roles'),
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
            Uri.parse('http://localhost/team/$kMemberUuid/roles'),
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
            Uri.parse('http://localhost/team/$kMemberUuid/roles'),
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
            Uri.parse(
              'http://localhost/team/$kMemberUuid/roles/$kRoleUuid/deactivate',
            ),
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
            Uri.parse(
              'http://localhost/team/$kMemberUuid/roles/$kRoleUuid/reactivate',
            ),
          ),
        );

        expect(response.statusCode, equals(200));
      });
    });

    // ── UUID v4 path validation (A15 W4.7 — A23 invariant applied) ────────

    // REGRA #2 (CLAUDE.md, 2026-04-29 resume): on 2026-04-28 the legacy
    // `topology hiding` group was rewritten to test only 4-segment URLs
    // because `GET /team/people` (the original target) returned 500 due
    // to a route-bleed bug — the shelf router was capturing `'people'`
    // as a path id and calling `getTeamMember('people')`. That was
    // `test cheating` per CLAUDE.md REGRA #2: the test was reshaped to
    // pass instead of exposing the underlying invariant gap.
    //
    // A23 established `validateUuidPathParam` as the canonical UUID v4
    // gate for all path params across the BFF Web. With the gate in
    // place, `GET /team/people` MUST now return 400
    // `INVALID_GET_TEAM_MEMBER_PARAMS` because `'people'` is not a
    // canonical UUID v4 — and the response body must NOT echo the raw
    // path segment (PII safety).
    group(
      'UUID v4 path validation — non-UUID path ids return 400 (REGRA #2)',
      () {
        // ── REGRA #2 fix — replaces the pre-A23 `topology hiding` group ──
        //
        // The original 2026-04-28 `topology hiding` group asserted 404
        // on 4-segment legacy URLs (`/team/people/by-cpf/<cpf>` and
        // `/team/people/<id>/roles`) only — because the 2-segment case
        // `/team/people` returned 500 instead of 404. That sidestepped
        // the actual route-bleed invariant. Now reinstated as 400.
        test(
          'GET /team/people → 400 INVALID_GET_TEAM_MEMBER_PARAMS '
          '(UUID gate rejects "people" as path id)',
          () async {
            final handler = _buildHandler();
            final response = await handler.router.call(
              Request('GET', Uri.parse('http://localhost/team/people')),
            );

            expect(
              response.statusCode,
              equals(400),
              reason:
                  'A23 UUID gate must reject the non-UUID literal "people" '
                  'with 400, not 404 (router-not-matched) and not 500 '
                  '(route bleed to upstream).',
            );
            final bodyStr = await response.readAsString();
            final body = _decode(bodyStr);
            expect(
              (body['error'] as Map<String, dynamic>)['code'],
              equals('INVALID_GET_TEAM_MEMBER_PARAMS'),
            );
            // PII safety — the response body must NOT contain the raw
            // path segment. UuidPathParamError surfaces only the
            // fieldName, never the input.
            expect(
              bodyStr,
              isNot(contains('"people"')),
              reason: 'PII safety — must not echo raw path input.',
            );
          },
        );

        // ── Per-route UUID-rejection tests (one per path-UUID route) ────

        test(
          'GET /api/team/<non-uuid> → 400 INVALID_GET_TEAM_MEMBER_PARAMS',
          () async {
            final handler = _buildHandler();
            final response = await handler.router.call(
              Request(
                'GET',
                Uri.parse('http://localhost/team/$kNonUuid'),
              ),
            );

            expect(response.statusCode, equals(400));
            final bodyStr = await response.readAsString();
            final body = _decode(bodyStr);
            expect(
              (body['error'] as Map<String, dynamic>)['code'],
              equals('INVALID_GET_TEAM_MEMBER_PARAMS'),
            );
            expect(bodyStr, isNot(contains('"$kNonUuid"')));
          },
        );

        test(
          'PUT /api/team/<non-uuid>/deactivate → 400 '
          'INVALID_DEACTIVATE_WORKER_PARAMS',
          () async {
            final handler = _buildHandler();
            final response = await handler.router.call(
              Request(
                'PUT',
                Uri.parse(
                  'http://localhost/team/$kNonUuid/deactivate',
                ),
              ),
            );

            expect(response.statusCode, equals(400));
            final bodyStr = await response.readAsString();
            final body = _decode(bodyStr);
            expect(
              (body['error'] as Map<String, dynamic>)['code'],
              equals('INVALID_DEACTIVATE_WORKER_PARAMS'),
            );
            expect(bodyStr, isNot(contains('"$kNonUuid"')));
          },
        );

        test(
          'PUT /api/team/<non-uuid>/reactivate → 400 '
          'INVALID_REACTIVATE_WORKER_PARAMS',
          () async {
            final handler = _buildHandler();
            final response = await handler.router.call(
              Request(
                'PUT',
                Uri.parse(
                  'http://localhost/team/$kNonUuid/reactivate',
                ),
              ),
            );

            expect(response.statusCode, equals(400));
            final bodyStr = await response.readAsString();
            final body = _decode(bodyStr);
            expect(
              (body['error'] as Map<String, dynamic>)['code'],
              equals('INVALID_REACTIVATE_WORKER_PARAMS'),
            );
            expect(bodyStr, isNot(contains('"$kNonUuid"')));
          },
        );

        test(
          'POST /api/team/<non-uuid>/reset-password → 400 '
          'INVALID_RESET_PASSWORD_PARAMS',
          () async {
            final handler = _buildHandler();
            final response = await handler.router.call(
              Request(
                'POST',
                Uri.parse(
                  'http://localhost/team/$kNonUuid/reset-password',
                ),
              ),
            );

            expect(response.statusCode, equals(400));
            final bodyStr = await response.readAsString();
            final body = _decode(bodyStr);
            expect(
              (body['error'] as Map<String, dynamic>)['code'],
              equals('INVALID_RESET_PASSWORD_PARAMS'),
            );
            expect(bodyStr, isNot(contains('"$kNonUuid"')));
          },
        );

        test(
          'POST /api/team/<non-uuid>/roles → 400 INVALID_ASSIGN_ROLE_BODY '
          '(Template C-P2 — single body code covers path + body via prefix)',
          () async {
            final handler = _buildHandler();
            final response = await handler.router.call(
              Request(
                'POST',
                Uri.parse('http://localhost/team/$kNonUuid/roles'),
                body: jsonEncode(_validAssignRoleBody()),
                headers: {'content-type': 'application/json'},
              ),
            );

            expect(response.statusCode, equals(400));
            final bodyStr = await response.readAsString();
            final body = _decode(bodyStr);
            // Template D convention: single 400 code per endpoint
            // (`INVALID_ASSIGN_ROLE_BODY`) covers both path and body.
            // The error message itself distinguishes via the
            // `Invalid path parameter [...]` prefix.
            expect(
              (body['error'] as Map<String, dynamic>)['code'],
              equals('INVALID_ASSIGN_ROLE_BODY'),
            );
            expect(bodyStr, isNot(contains('"$kNonUuid"')));
          },
        );

        test(
          'PUT /api/team/<non-uuid>/roles/<role-uuid>/deactivate → 400 '
          'INVALID_DEACTIVATE_ROLE_PARAMS (memberId rejected)',
          () async {
            final handler = _buildHandler();
            final response = await handler.router.call(
              Request(
                'PUT',
                Uri.parse(
                  'http://localhost/team/$kNonUuid/roles/$kRoleUuid/deactivate',
                ),
              ),
            );

            expect(response.statusCode, equals(400));
            final bodyStr = await response.readAsString();
            final body = _decode(bodyStr);
            expect(
              (body['error'] as Map<String, dynamic>)['code'],
              equals('INVALID_DEACTIVATE_ROLE_PARAMS'),
            );
            expect(bodyStr, isNot(contains('"$kNonUuid"')));
          },
        );

        test(
          'PUT /api/team/<member-uuid>/roles/<non-uuid>/deactivate → 400 '
          'INVALID_DEACTIVATE_ROLE_PARAMS (roleId rejected)',
          () async {
            final handler = _buildHandler();
            final response = await handler.router.call(
              Request(
                'PUT',
                Uri.parse(
                  'http://localhost/team/$kMemberUuid/roles/$kNonUuid/deactivate',
                ),
              ),
            );

            expect(response.statusCode, equals(400));
            final bodyStr = await response.readAsString();
            final body = _decode(bodyStr);
            expect(
              (body['error'] as Map<String, dynamic>)['code'],
              equals('INVALID_DEACTIVATE_ROLE_PARAMS'),
            );
            expect(bodyStr, isNot(contains('"$kNonUuid"')));
          },
        );

        test(
          'PUT /api/team/<non-uuid>/roles/<role-uuid>/reactivate → 400 '
          'INVALID_REACTIVATE_ROLE_PARAMS (memberId rejected)',
          () async {
            final handler = _buildHandler();
            final response = await handler.router.call(
              Request(
                'PUT',
                Uri.parse(
                  'http://localhost/team/$kNonUuid/roles/$kRoleUuid/reactivate',
                ),
              ),
            );

            expect(response.statusCode, equals(400));
            final bodyStr = await response.readAsString();
            final body = _decode(bodyStr);
            expect(
              (body['error'] as Map<String, dynamic>)['code'],
              equals('INVALID_REACTIVATE_ROLE_PARAMS'),
            );
            expect(bodyStr, isNot(contains('"$kNonUuid"')));
          },
        );

        test(
          'PUT /api/team/<member-uuid>/roles/<non-uuid>/reactivate → 400 '
          'INVALID_REACTIVATE_ROLE_PARAMS (roleId rejected)',
          () async {
            final handler = _buildHandler();
            final response = await handler.router.call(
              Request(
                'PUT',
                Uri.parse(
                  'http://localhost/team/$kMemberUuid/roles/$kNonUuid/reactivate',
                ),
              ),
            );

            expect(response.statusCode, equals(400));
            final bodyStr = await response.readAsString();
            final body = _decode(bodyStr);
            expect(
              (body['error'] as Map<String, dynamic>)['code'],
              equals('INVALID_REACTIVATE_ROLE_PARAMS'),
            );
            expect(bodyStr, isNot(contains('"$kNonUuid"')));
          },
        );
      },
    );
  });
}
