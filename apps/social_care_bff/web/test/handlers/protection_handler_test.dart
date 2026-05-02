import 'dart:convert';

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/handlers/protection_handler.dart';
import 'package:social_care_web/src/use_cases/create_referral_use_case.dart';
import 'package:social_care_web/src/use_cases/report_rights_violation_use_case.dart';
import 'package:social_care_web/src/use_cases/update_placement_history_use_case.dart';

import '../_test_uuids.dart';

/// A [ProtectionContract] variant that forces every mutation to fail with a
/// well-known [BackendError]. Used to validate failure-path status codes in
/// the handler (A12 canon — mirrors A11's [_FailingCare]).
class _FailingProtection extends FakeProtectionBff {
  _FailingProtection(this.error);
  final BackendError error;

  @override
  Future<Result<StandardIdResponse>> createReferral(
    String patientId,
    CreateReferralRequest request,
  ) async => Failure(error);

  @override
  Future<Result<StandardIdResponse>> reportViolation(
    String patientId,
    ReportRightsViolationRequest request,
  ) async => Failure(error);

  @override
  Future<Result<void>> updatePlacementHistory(
    String patientId,
    UpdatePlacementHistoryRequest request,
  ) async => Failure(error);
}

/// A [ProtectionContract] variant that explodes with a raw [Exception]
/// wrapped in [Failure]. Used to validate the 500 sanitization path.
class _ExplodingProtection extends FakeProtectionBff {
  @override
  Future<Result<StandardIdResponse>> createReferral(
    String patientId,
    CreateReferralRequest request,
  ) async => Failure(Exception('internal leak marker xyz'));

  @override
  Future<Result<StandardIdResponse>> reportViolation(
    String patientId,
    ReportRightsViolationRequest request,
  ) async => Failure(Exception('internal leak marker xyz'));

  @override
  Future<Result<void>> updatePlacementHistory(
    String patientId,
    UpdatePlacementHistoryRequest request,
  ) async => Failure(Exception('internal leak marker xyz'));
}

ProtectionHandler _buildHandler({ProtectionContract? protection}) {
  final p = protection ?? FakeProtectionBff();
  return ProtectionHandler(
    createReferral: CreateReferralUseCase(protection: p),
    reportViolation: ReportRightsViolationUseCase(protection: p),
    updatePlacementHistory: UpdatePlacementHistoryUseCase(protection: p),
  );
}

Map<String, dynamic> _validReferralBody() => {
  'referredPersonId': '660e8400-e29b-41d4-a716-446655440001',
  'destinationService': 'CRAS Vila Nova',
  'reason': 'Encaminhamento para acompanhamento psicossocial',
  'professionalId': 'prof-42',
  'date': '2026-04-17T10:00:00Z',
};

Map<String, dynamic> _validViolationBody() => {
  'victimId': '660e8400-e29b-41d4-a716-446655440001',
  'violationType': 'PHYSICAL',
  'descriptionOfFact': 'Paciente apresentou hematomas no bracos em 14/04/2026',
  'violationTypeId': 'viol-phys',
  'reportDate': '2026-04-17T10:00:00Z',
  'incidentDate': '2026-04-14T00:00:00Z',
  'actionsTaken': 'Acionado Conselho Tutelar 8º distrito',
};

Map<String, dynamic> _validPlacementBody() => {
  'registries': [
    {
      'memberId': '770e8400-e29b-41d4-a716-446655440002',
      'startDate': '2023-05-01',
      'endDate': '2024-01-10',
      'reason': 'Afastamento temporario',
    },
  ],
  'collectiveSituations': {
    'homeLossReport': 'Familia perdeu moradia em enchente',
    'thirdPartyGuardReport': 'Criancas sob guarda de avos maternos',
  },
  'separationChecklist': {
    'adultInPrison': false,
    'adolescentInInternment': false,
  },
};

void main() {
  group('ProtectionHandler (thin handler — UseCase orchestration)', () {
    // ── POST /patients/<id>/referrals ───────────────────────────────────────

    group('POST /patients/<id>/referrals', () {
      test('returns 200/201 with { id } on happy path', () async {
        final handler = _buildHandler();

        final request = Request(
          'POST',
          Uri.parse('http://localhost/patients/$kPatientUuid/referrals'),
          body: jsonEncode(_validReferralBody()),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, lessThan(300));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(body['data'], isA<Map<String, dynamic>>());
        expect((body['data'] as Map)['id'], isNotEmpty);
      });

      test('returns 400 (INVALID_JSON) when body is invalid JSON', () async {
        final handler = _buildHandler();

        final request = Request(
          'POST',
          Uri.parse('http://localhost/patients/$kPatientUuid/referrals'),
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
        'returns 400 (INVALID_REFERRAL_BODY) when referredPersonId is missing',
        () async {
          final handler = _buildHandler();

          final body = _validReferralBody()..remove('referredPersonId');
          final request = Request(
            'POST',
            Uri.parse('http://localhost/patients/$kPatientUuid/referrals'),
            body: jsonEncode(body),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(400));
          final decoded =
              jsonDecode(await response.readAsString()) as Map<String, dynamic>;
          expect(
            (decoded['error'] as Map)['code'],
            equals('INVALID_REFERRAL_BODY'),
          );
        },
      );

      test(
        'returns 400 (INVALID_REFERRAL_BODY) when destinationService is missing',
        () async {
          final handler = _buildHandler();

          final body = _validReferralBody()..remove('destinationService');
          final request = Request(
            'POST',
            Uri.parse('http://localhost/patients/$kPatientUuid/referrals'),
            body: jsonEncode(body),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(400));
          final decoded =
              jsonDecode(await response.readAsString()) as Map<String, dynamic>;
          expect(
            (decoded['error'] as Map)['code'],
            equals('INVALID_REFERRAL_BODY'),
          );
        },
      );

      test(
        'returns upstream status when createReferral fails with BackendError',
        () async {
          final failing = _FailingProtection(
            const BackendError(
              id: 'err-1',
              code: 'INVALID_DESTINATION',
              message: 'destination service not registered',
              http: 422,
            ),
          );
          final handler = _buildHandler(protection: failing);

          final request = Request(
            'POST',
            Uri.parse('http://localhost/patients/$kPatientUuid/referrals'),
            body: jsonEncode(_validReferralBody()),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(422));
        },
      );

      test('500 response body sanitizes raw Exception / stack trace', () async {
        final handler = _buildHandler(protection: _ExplodingProtection());

        final request = Request(
          'POST',
          Uri.parse('http://localhost/patients/$kPatientUuid/referrals'),
          body: jsonEncode(_validReferralBody()),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);
        final body = await response.readAsString();

        expect(response.statusCode, equals(500));
        expect(body, isNot(contains('leak marker')));
        expect(body, isNot(contains('Exception:')));
        expect(body, isNot(contains('#0')));
      });

      test('400 response does NOT echo raw reason (PII)', () async {
        final handler = _buildHandler();

        // missing referredPersonId → INVALID_REFERRAL_BODY
        final body = {
          'destinationService': 'CRAS',
          'reason': 'Mae relatou violencia fisica contra o filho de 8 anos',
        };
        final request = Request(
          'POST',
          Uri.parse('http://localhost/patients/$kPatientUuid/referrals'),
          body: jsonEncode(body),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);
        final dumped = await response.readAsString();

        expect(response.statusCode, equals(400));
        expect(dumped, isNot(contains('violencia fisica')));
        expect(dumped, isNot(contains('8 anos')));
        expect(dumped, isNot(contains('Mae')));
      });
    });

    // ── POST /patients/<id>/violations ──────────────────────────────────────

    group('POST /patients/<id>/violations', () {
      test('returns 200/201 with { id } on happy path', () async {
        final handler = _buildHandler();

        final request = Request(
          'POST',
          Uri.parse('http://localhost/patients/$kPatientUuid/violations'),
          body: jsonEncode(_validViolationBody()),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, lessThan(300));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(body['data'], isA<Map<String, dynamic>>());
        expect((body['data'] as Map)['id'], isNotEmpty);
      });

      test('returns 400 (INVALID_JSON) when body is invalid JSON', () async {
        final handler = _buildHandler();

        final request = Request(
          'POST',
          Uri.parse('http://localhost/patients/$kPatientUuid/violations'),
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
        'returns 400 (INVALID_VIOLATION_BODY) when victimId is missing',
        () async {
          final handler = _buildHandler();

          final body = _validViolationBody()..remove('victimId');
          final request = Request(
            'POST',
            Uri.parse('http://localhost/patients/$kPatientUuid/violations'),
            body: jsonEncode(body),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(400));
          final decoded =
              jsonDecode(await response.readAsString()) as Map<String, dynamic>;
          expect(
            (decoded['error'] as Map)['code'],
            equals('INVALID_VIOLATION_BODY'),
          );
        },
      );

      test(
        'returns 400 (INVALID_VIOLATION_BODY) when descriptionOfFact is missing',
        () async {
          final handler = _buildHandler();

          final body = _validViolationBody()..remove('descriptionOfFact');
          final request = Request(
            'POST',
            Uri.parse('http://localhost/patients/$kPatientUuid/violations'),
            body: jsonEncode(body),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(400));
          final decoded =
              jsonDecode(await response.readAsString()) as Map<String, dynamic>;
          expect(
            (decoded['error'] as Map)['code'],
            equals('INVALID_VIOLATION_BODY'),
          );
        },
      );

      test(
        'returns upstream status when reportViolation fails with BackendError',
        () async {
          final failing = _FailingProtection(
            const BackendError(
              id: 'err-1',
              code: 'INVALID_VIOLATION_TYPE',
              message: 'violation type not recognized',
              http: 422,
            ),
          );
          final handler = _buildHandler(protection: failing);

          final request = Request(
            'POST',
            Uri.parse('http://localhost/patients/$kPatientUuid/violations'),
            body: jsonEncode(_validViolationBody()),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(422));
        },
      );

      test('500 response body sanitizes raw Exception / stack trace', () async {
        final handler = _buildHandler(protection: _ExplodingProtection());

        final request = Request(
          'POST',
          Uri.parse('http://localhost/patients/$kPatientUuid/violations'),
          body: jsonEncode(_validViolationBody()),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);
        final body = await response.readAsString();

        expect(response.statusCode, equals(500));
        expect(body, isNot(contains('leak marker')));
        expect(body, isNot(contains('Exception:')));
        expect(body, isNot(contains('#0')));
      });

      test(
        '400 response does NOT echo raw descriptionOfFact / actionsTaken (PII — CRITICAL)',
        () async {
          final handler = _buildHandler();

          // missing victimId → INVALID_VIOLATION_BODY
          final body = {
            'violationType': 'PHYSICAL',
            'descriptionOfFact':
                'Paciente relatou agressao fisica pela mae em 14/04/2026',
            'actionsTaken': 'Comunicado Conselho Tutelar distrital',
          };
          final request = Request(
            'POST',
            Uri.parse('http://localhost/patients/$kPatientUuid/violations'),
            body: jsonEncode(body),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);
          final dumped = await response.readAsString();

          expect(response.statusCode, equals(400));
          expect(dumped, isNot(contains('agressao fisica')));
          expect(dumped, isNot(contains('14/04/2026')));
          expect(dumped, isNot(contains('mae')));
          expect(dumped, isNot(contains('Conselho Tutelar')));
        },
      );
    });

    // ── PUT /patients/<id>/placement-history ────────────────────────────────

    group('PUT /patients/<id>/placement-history', () {
      test('returns 200 with null data on happy path', () async {
        final handler = _buildHandler();

        final request = Request(
          'PUT',
          Uri.parse('http://localhost/patients/$kPatientUuid/placement-history'),
          body: jsonEncode(_validPlacementBody()),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, lessThan(300));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(body.containsKey('data'), isTrue);
        expect(body['data'], isNull);
        expect(body['meta'], isA<Map<String, dynamic>>());
      });

      test('returns 200 when body is empty (all top-level optional)', () async {
        final handler = _buildHandler();

        final request = Request(
          'PUT',
          Uri.parse('http://localhost/patients/$kPatientUuid/placement-history'),
          body: jsonEncode(const <String, dynamic>{}),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, lessThan(300));
      });

      test('returns 400 (INVALID_JSON) when body is invalid JSON', () async {
        final handler = _buildHandler();

        final request = Request(
          'PUT',
          Uri.parse('http://localhost/patients/$kPatientUuid/placement-history'),
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
        'returns 400 (INVALID_PLACEMENT_HISTORY_BODY) when sub-DTO is malformed',
        () async {
          final handler = _buildHandler();

          // RegistryDraftDto requires memberId + startDate + reason. Omit
          // memberId → recursive fromJson throws → handler maps to 400.
          final body = {
            'registries': [
              {'startDate': '2023-05-01', 'reason': 'x'},
            ],
          };
          final request = Request(
            'PUT',
            Uri.parse('http://localhost/patients/$kPatientUuid/placement-history'),
            body: jsonEncode(body),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(400));
          final decoded =
              jsonDecode(await response.readAsString()) as Map<String, dynamic>;
          expect(
            (decoded['error'] as Map)['code'],
            equals('INVALID_PLACEMENT_HISTORY_BODY'),
          );
        },
      );

      test('returns upstream status when updatePlacementHistory fails with '
          'BackendError', () async {
        final failing = _FailingProtection(
          const BackendError(
            id: 'err-1',
            code: 'INVALID_PLACEMENT',
            message: 'placement history invalid',
            http: 409,
          ),
        );
        final handler = _buildHandler(protection: failing);

        final request = Request(
          'PUT',
          Uri.parse('http://localhost/patients/$kPatientUuid/placement-history'),
          body: jsonEncode(_validPlacementBody()),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(409));
      });

      test('500 response body sanitizes raw Exception / stack trace', () async {
        final handler = _buildHandler(protection: _ExplodingProtection());

        final request = Request(
          'PUT',
          Uri.parse('http://localhost/patients/$kPatientUuid/placement-history'),
          body: jsonEncode(_validPlacementBody()),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);
        final body = await response.readAsString();

        expect(response.statusCode, equals(500));
        expect(body, isNot(contains('leak marker')));
        expect(body, isNot(contains('Exception:')));
        expect(body, isNot(contains('#0')));
      });

      test(
        '400 response is EXACTLY the fixed structural literal — does NOT '
        'echo homeLossReport / thirdPartyGuardReport / registries[].reason',
        () async {
          final handler = _buildHandler();

          // Malformed sub-DTO (memberId missing) + PII markers sprinkled
          // across collectiveSituations and the bad registry reason.
          final body = {
            'registries': [
              {
                // memberId missing
                'startDate': '2023-05-01',
                'reason':
                    'Afastamento por violencia domestica — encaminhado CREAS',
              },
            ],
            'collectiveSituations': {
              'homeLossReport': 'Familia perdeu moradia em enchente de 2023',
              'thirdPartyGuardReport':
                  'Criancas ficaram com vizinha pois mae esta presa',
            },
          };
          final request = Request(
            'PUT',
            Uri.parse('http://localhost/patients/$kPatientUuid/placement-history'),
            body: jsonEncode(body),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);
          final dumped = await response.readAsString();

          expect(response.statusCode, equals(400));
          expect(dumped, isNot(contains('Familia perdeu moradia')));
          expect(dumped, isNot(contains('enchente')));
          expect(dumped, isNot(contains('vizinha')));
          expect(dumped, isNot(contains('presa')));
          expect(dumped, isNot(contains('violencia domestica')));
          expect(dumped, isNot(contains('CREAS')));
          expect(dumped, isNot(contains('Afastamento')));
        },
      );
    });

    // ── State matrix (P1) — sanitized error body ────────────────────────────

    group('State matrix (P1) — sanitized error body', () {
      test(
        'BackendError.message surfaces but Dart stack traces do not',
        () async {
          final failing = _FailingProtection(
            const BackendError(
              id: 'err-1',
              code: 'INVALID_DESTINATION',
              message: 'curated upstream message',
              http: 422,
            ),
          );
          final handler = _buildHandler(protection: failing);

          final request = Request(
            'POST',
            Uri.parse('http://localhost/patients/$kPatientUuid/referrals'),
            body: jsonEncode(_validReferralBody()),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);
          final body = await response.readAsString();

          expect(body, isNot(contains('#0')), reason: 'stack traces leak');
          expect(body, isNot(contains('Exception:')));
        },
      );
    });
  });
}
