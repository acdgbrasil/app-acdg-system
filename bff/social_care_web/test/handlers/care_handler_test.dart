import 'dart:convert';

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/handlers/care_handler.dart';
import 'package:social_care_web/src/use_cases/register_appointment_use_case.dart';
import 'package:social_care_web/src/use_cases/update_intake_info_use_case.dart';

/// A [CareContract] variant that forces every mutation to fail with a
/// well-known [BackendError]. Used to validate failure-path status codes
/// in the handler.
class _FailingCare extends FakeCareBff {
  _FailingCare(this.error);
  final BackendError error;

  @override
  Future<Result<StandardIdResponse>> registerAppointment(
    String patientId,
    RegisterAppointmentRequest request,
  ) async => Failure(error);

  @override
  Future<Result<void>> updateIntakeInfo(
    String patientId,
    RegisterIntakeInfoRequest request,
  ) async => Failure(error);
}

/// A [CareContract] variant that explodes with a raw [Exception] wrapped in
/// [Failure]. Used to validate the 500 sanitization path.
class _ExplodingCare extends FakeCareBff {
  @override
  Future<Result<StandardIdResponse>> registerAppointment(
    String patientId,
    RegisterAppointmentRequest request,
  ) async => Failure(Exception('internal leak marker xyz'));

  @override
  Future<Result<void>> updateIntakeInfo(
    String patientId,
    RegisterIntakeInfoRequest request,
  ) async => Failure(Exception('internal leak marker xyz'));
}

CareHandler _buildHandler({CareContract? care}) {
  final c = care ?? FakeCareBff();
  return CareHandler(
    registerAppointment: RegisterAppointmentUseCase(care: c),
    updateIntakeInfo: UpdateIntakeInfoUseCase(care: c),
  );
}

Map<String, dynamic> _validAppointmentBody() => {
  'professionalId': 'prof-42',
  'summary': 'Primeira consulta',
  'actionPlan': 'Encaminhar',
  'date': '2026-04-17T10:00:00Z',
  'type': 'intake',
};

Map<String, dynamic> _validIntakeBody() => {
  'ingressTypeId': 'ing-spontaneous',
  'serviceReason': 'Procura por apoio psicossocial',
  'originName': 'Unidade Basica Vila Nova',
  'originContact': '(11) 4002-8922',
};

void main() {
  group('CareHandler (thin handler — UseCase orchestration)', () {
    group('POST /patients/<id>/appointments', () {
      test('returns 200/201 with { id } on happy path', () async {
        final handler = _buildHandler();

        final request = Request(
          'POST',
          Uri.parse('http://localhost/patients/pat-1/appointments'),
          body: jsonEncode(_validAppointmentBody()),
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
          Uri.parse('http://localhost/patients/pat-1/appointments'),
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
        'returns 400 (INVALID_APPOINTMENT_BODY) when professionalId is missing',
        () async {
          final handler = _buildHandler();

          final body = _validAppointmentBody()..remove('professionalId');
          final request = Request(
            'POST',
            Uri.parse('http://localhost/patients/pat-1/appointments'),
            body: jsonEncode(body),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(400));
          final decoded =
              jsonDecode(await response.readAsString()) as Map<String, dynamic>;
          expect(
            (decoded['error'] as Map)['code'],
            equals('INVALID_APPOINTMENT_BODY'),
          );
        },
      );

      test(
        'returns upstream status when registerAppointment fails with BackendError',
        () async {
          final failing = _FailingCare(
            const BackendError(
              id: 'err-1',
              code: 'INVALID_PROFESSIONAL',
              message: 'professional not found',
              http: 422,
            ),
          );
          final handler = _buildHandler(care: failing);

          final request = Request(
            'POST',
            Uri.parse('http://localhost/patients/pat-1/appointments'),
            body: jsonEncode(_validAppointmentBody()),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(422));
        },
      );

      test('500 response body sanitizes raw Exception / stack trace', () async {
        final handler = _buildHandler(care: _ExplodingCare());

        final request = Request(
          'POST',
          Uri.parse('http://localhost/patients/pat-1/appointments'),
          body: jsonEncode(_validAppointmentBody()),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);
        final body = await response.readAsString();

        expect(response.statusCode, equals(500));
        expect(
          body,
          isNot(contains('leak marker')),
          reason: 'inner exception message must not leak',
        );
        expect(
          body,
          isNot(contains('Exception:')),
          reason: 'Dart exception prose must not leak',
        );
        expect(
          body,
          isNot(contains('#0')),
          reason: 'stack trace must not leak',
        );
      });

      test(
        '400 response does NOT echo raw summary / actionPlan (PII)',
        () async {
          final handler = _buildHandler();

          // missing professionalId → INVALID_APPOINTMENT_BODY
          final body = {
            'summary': 'Paciente relata abuso familiar',
            'actionPlan': 'Acionar conselho tutelar',
          };
          final request = Request(
            'POST',
            Uri.parse('http://localhost/patients/pat-1/appointments'),
            body: jsonEncode(body),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);
          final dumped = await response.readAsString();

          expect(response.statusCode, equals(400));
          expect(dumped, isNot(contains('abuso familiar')));
          expect(dumped, isNot(contains('conselho tutelar')));
        },
      );
    });

    group('PUT /patients/<id>/intake', () {
      test('returns 200 with null data on happy path', () async {
        final handler = _buildHandler();

        final request = Request(
          'PUT',
          Uri.parse('http://localhost/patients/pat-1/intake'),
          body: jsonEncode(_validIntakeBody()),
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

      test('returns 400 (INVALID_JSON) when body is invalid JSON', () async {
        final handler = _buildHandler();

        final request = Request(
          'PUT',
          Uri.parse('http://localhost/patients/pat-1/intake'),
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
        'returns 400 (INVALID_INTAKE_BODY) when ingressTypeId is missing',
        () async {
          final handler = _buildHandler();

          final body = _validIntakeBody()..remove('ingressTypeId');
          final request = Request(
            'PUT',
            Uri.parse('http://localhost/patients/pat-1/intake'),
            body: jsonEncode(body),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(400));
          final decoded =
              jsonDecode(await response.readAsString()) as Map<String, dynamic>;
          expect(
            (decoded['error'] as Map)['code'],
            equals('INVALID_INTAKE_BODY'),
          );
        },
      );

      test(
        'returns 400 (INVALID_INTAKE_BODY) when serviceReason is missing',
        () async {
          final handler = _buildHandler();

          final body = _validIntakeBody()..remove('serviceReason');
          final request = Request(
            'PUT',
            Uri.parse('http://localhost/patients/pat-1/intake'),
            body: jsonEncode(body),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(400));
          final decoded =
              jsonDecode(await response.readAsString()) as Map<String, dynamic>;
          expect(
            (decoded['error'] as Map)['code'],
            equals('INVALID_INTAKE_BODY'),
          );
        },
      );

      test(
        'returns upstream status when updateIntakeInfo fails with BackendError',
        () async {
          final failing = _FailingCare(
            const BackendError(
              id: 'err-1',
              code: 'INVALID_INGRESS_TYPE',
              message: 'ingress type not found',
              http: 422,
            ),
          );
          final handler = _buildHandler(care: failing);

          final request = Request(
            'PUT',
            Uri.parse('http://localhost/patients/pat-1/intake'),
            body: jsonEncode(_validIntakeBody()),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(422));
        },
      );

      test('500 response body sanitizes raw Exception / stack trace', () async {
        final handler = _buildHandler(care: _ExplodingCare());

        final request = Request(
          'PUT',
          Uri.parse('http://localhost/patients/pat-1/intake'),
          body: jsonEncode(_validIntakeBody()),
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
        '400 response does NOT echo raw originName / originContact / serviceReason (PII)',
        () async {
          final handler = _buildHandler();

          // missing ingressTypeId + serviceReason → INVALID_INTAKE_BODY
          final body = {
            'originName': 'Hospital Regional Santa Casa',
            'originContact': '(11) 98765-4321',
            'serviceReason': '', // empty forces failure but carries no value
          };
          final request = Request(
            'PUT',
            Uri.parse('http://localhost/patients/pat-1/intake'),
            body: jsonEncode(body),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);
          final dumped = await response.readAsString();

          expect(response.statusCode, equals(400));
          expect(dumped, isNot(contains('Santa Casa')));
          expect(dumped, isNot(contains('98765-4321')));
        },
      );
    });

    group('State matrix (P1) — sanitized error body', () {
      test(
        'BackendError.message surfaces but Dart stack traces do not',
        () async {
          final failing = _FailingCare(
            const BackendError(
              id: 'err-1',
              code: 'INVALID_PROFESSIONAL',
              message: 'curated upstream message',
              http: 422,
            ),
          );
          final handler = _buildHandler(care: failing);

          final request = Request(
            'POST',
            Uri.parse('http://localhost/patients/pat-1/appointments'),
            body: jsonEncode(_validAppointmentBody()),
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
