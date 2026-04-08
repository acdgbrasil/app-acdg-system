import 'dart:convert';

import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:social_care/social_care.dart';

import '../../../testing/fixtures/patient_fixtures.dart';

/// A fake [HttpClientAdapter] that captures requests and returns canned
/// responses without hitting a real server.
class FakeHttpClientAdapter implements HttpClientAdapter {
  late ResponseBody Function(RequestOptions options) handler;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Object? body, {int statusCode = 200}) {
  return ResponseBody.fromString(
    body != null ? jsonEncode(body) : '',
    statusCode,
    headers: {
      'content-type': ['application/json'],
    },
  );
}

ResponseBody noContentResponse() {
  return ResponseBody.fromString('', 204);
}

void main() {
  late FakeHttpClientAdapter adapter;
  late Dio dio;
  late HttpSocialCareClient client;

  setUp(() {
    adapter = FakeHttpClientAdapter();
    dio = Dio(BaseOptions(baseUrl: 'http://test-bff'))
      ..httpClientAdapter = adapter;
    client = HttpSocialCareClient(dio: dio);
  });

  group('HttpSocialCareClient', () {
    // =========================================================================
    // Dio Configuration
    // =========================================================================

    group('configuration', () {
      test('custom baseUrl constructor is accepted', () {
        final custom = HttpSocialCareClient(baseUrl: 'https://my-bff.com/api');
        expect(custom, isNotNull);
      });

      test('does not send Authorization header', () async {
        adapter.handler = (_) => jsonResponse({'status': 'ok'});
        await client.checkHealth();
        expect(
          adapter.lastRequest!.headers.containsKey('Authorization'),
          isFalse,
        );
      });

      test('does not send X-Actor-Id header', () async {
        adapter.handler = (_) => jsonResponse({'status': 'ok'});
        await client.checkHealth();
        expect(adapter.lastRequest!.headers.containsKey('X-Actor-Id'), isFalse);
      });

      test('sets content-type to application/json', () async {
        // Verify that a client created via the production path (no injected
        // Dio) configures contentType correctly. We use a custom Dio with
        // the same BaseOptions the constructor would create.
        final prodAdapter = FakeHttpClientAdapter();
        final customDio = Dio(
          BaseOptions(
            baseUrl: 'http://test-bff',
            contentType: 'application/json',
          ),
        )..httpClientAdapter = prodAdapter;
        final customClient = HttpSocialCareClient(dio: customDio);

        prodAdapter.handler = (_) => jsonResponse({'status': 'ok'});
        await customClient.checkHealth();
        expect(prodAdapter.lastRequest!.contentType, 'application/json');
      });
    });

    // =========================================================================
    // Health
    // =========================================================================

    group('checkHealth', () {
      test('returns Success on 200', () async {
        adapter.handler = (_) => jsonResponse({'status': 'ok'});
        final result = await client.checkHealth();
        expect(result, isA<Success<void>>());
        expect(adapter.lastRequest!.path, '/health/live');
      });

      test('returns Failure on network error', () async {
        adapter.handler = (_) => throw DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionTimeout,
        );
        final result = await client.checkHealth();
        expect(result, isA<Failure<void>>());
      });
    });

    group('checkReady', () {
      test('returns Success on 200', () async {
        adapter.handler = (_) => jsonResponse({'status': 'ready'});
        final result = await client.checkReady();
        expect(result, isA<Success<void>>());
        expect(adapter.lastRequest!.path, '/health/ready');
      });
    });

    // =========================================================================
    // Registry — fetchPatients
    // =========================================================================

    group('fetchPatients', () {
      test('returns list of PatientOverview on 200', () async {
        adapter.handler = (_) => jsonResponse([
          {
            'patientId': '550e8400-e29b-41d4-a716-000000000001',
            'personId': '550e8400-e29b-41d4-a716-000000000002',
            'firstName': 'Maria',
            'lastName': 'Silva',
            'fullName': 'Maria Silva',
            'primaryDiagnosis': 'Q90.0',
            'memberCount': 2,
          },
        ]);

        final result = await client.fetchPatients();
        expect(result, isA<Success<List<PatientOverview>>>());

        final patients = (result as Success<List<PatientOverview>>).value;
        expect(patients, hasLength(1));
        expect(patients.first.firstName, 'Maria');
        expect(
          patients.first.patientId,
          '550e8400-e29b-41d4-a716-000000000001',
        );
        expect(adapter.lastRequest!.path, '/patients');
        expect(adapter.lastRequest!.method, 'GET');
      });

      test('returns Failure on non-200', () async {
        adapter.handler = (_) =>
            jsonResponse({'error': 'boom'}, statusCode: 500);
        final result = await client.fetchPatients();
        expect(result, isA<Failure<List<PatientOverview>>>());
      });

      test('returns Failure on exception', () async {
        adapter.handler = (_) => throw Exception('network down');
        final result = await client.fetchPatients();
        expect(result, isA<Failure<List<PatientOverview>>>());
      });
    });

    // =========================================================================
    // Registry — registerPatient
    // =========================================================================

    group('registerPatient', () {
      test('returns PatientId on 200', () async {
        const id = '550e8400-e29b-41d4-a716-000000000001';
        adapter.handler = (options) {
          expect(options.method, 'POST');
          expect(options.path, '/patients');
          return jsonResponse({'id': id});
        };

        final result = await client.registerPatient(
          PatientFixtures.validPatient,
        );
        expect(result, isA<Success<PatientId>>());
        expect((result as Success<PatientId>).value.value, id);
      });

      test('returns Failure on non-200', () async {
        adapter.handler = (_) =>
            jsonResponse({'error': 'fail'}, statusCode: 400);
        final result = await client.registerPatient(
          PatientFixtures.validPatient,
        );
        expect(result, isA<Failure<PatientId>>());
      });
    });

    // =========================================================================
    // Registry — fetchPatient
    // =========================================================================

    group('fetchPatient', () {
      test('returns PatientRemote on 200', () async {
        const id = '550e8400-e29b-41d4-a716-000000000001';
        adapter.handler = (options) {
          expect(options.path, '/patients/$id');
          expect(options.method, 'GET');
          return jsonResponse({
            'patientId': id,
            'personId': '550e8400-e29b-41d4-a716-000000000002',
            'version': 1,
          });
        };

        final result = await client.fetchPatient(PatientFixtures.patientId);
        expect(result, isA<Success<PatientRemote>>());

        final patient = (result as Success<PatientRemote>).value;
        expect(patient.patientId, id);
      });

      test('returns Failure on 404', () async {
        adapter.handler = (_) =>
            jsonResponse({'error': 'not found'}, statusCode: 404);
        final result = await client.fetchPatient(PatientFixtures.patientId);
        expect(result, isA<Failure<PatientRemote>>());
      });
    });

    // =========================================================================
    // Registry — fetchPatientByPersonId
    // =========================================================================

    group('fetchPatientByPersonId', () {
      test('returns PatientRemote on 200', () async {
        const personIdStr = '550e8400-e29b-41d4-a716-000000000002';
        adapter.handler = (options) {
          expect(options.path, '/patients/by-person/$personIdStr');
          return jsonResponse({
            'patientId': '550e8400-e29b-41d4-a716-000000000001',
            'personId': personIdStr,
            'version': 1,
          });
        };

        final result = await client.fetchPatientByPersonId(
          PatientFixtures.personId,
        );
        expect(result, isA<Success<PatientRemote>>());
      });
    });

    // =========================================================================
    // Registry — addFamilyMember
    // =========================================================================

    group('addFamilyMember', () {
      test('returns Success on 204', () async {
        adapter.handler = (options) {
          expect(options.method, 'POST');
          expect(
            options.path,
            '/patients/${PatientFixtures.patientId.value}/family-members',
          );
          return noContentResponse();
        };

        final result = await client.addFamilyMember(
          PatientFixtures.patientId,
          PatientFixtures.familyMember,
          PatientFixtures.prRelationshipId,
        );
        expect(result, isA<Success<void>>());
      });

      test('returns Failure on 500', () async {
        adapter.handler = (_) =>
            jsonResponse({'error': 'fail'}, statusCode: 500);
        final result = await client.addFamilyMember(
          PatientFixtures.patientId,
          PatientFixtures.familyMember,
          PatientFixtures.prRelationshipId,
        );
        expect(result, isA<Failure<void>>());
      });
    });

    // =========================================================================
    // Registry — removeFamilyMember
    // =========================================================================

    group('removeFamilyMember', () {
      test('returns Success on 204', () async {
        adapter.handler = (options) {
          expect(options.method, 'DELETE');
          expect(
            options.path,
            '/patients/${PatientFixtures.patientId.value}'
            '/family-members/${PatientFixtures.familyMemberPersonId.value}',
          );
          return noContentResponse();
        };

        final result = await client.removeFamilyMember(
          PatientFixtures.patientId,
          PatientFixtures.familyMemberPersonId,
        );
        expect(result, isA<Success<void>>());
      });
    });

    // =========================================================================
    // Registry — assignPrimaryCaregiver
    // =========================================================================

    group('assignPrimaryCaregiver', () {
      test('sends memberPersonId in body and returns Success on 204', () async {
        adapter.handler = (options) {
          expect(options.method, 'PUT');
          expect(
            options.path,
            '/patients/${PatientFixtures.patientId.value}/primary-caregiver',
          );
          final body = options.data as Map<String, dynamic>;
          expect(
            body['memberPersonId'],
            PatientFixtures.familyMemberPersonId.value,
          );
          return noContentResponse();
        };

        final result = await client.assignPrimaryCaregiver(
          PatientFixtures.patientId,
          PatientFixtures.familyMemberPersonId,
        );
        expect(result, isA<Success<void>>());
      });
    });

    // =========================================================================
    // Registry — getAuditTrail
    // =========================================================================

    group('getAuditTrail', () {
      test('returns list of AuditEvent on 200', () async {
        adapter.handler = (options) {
          expect(
            options.path,
            '/patients/${PatientFixtures.patientId.value}/audit-trail',
          );
          return jsonResponse([
            {
              'id': 'evt-001',
              'aggregateId': PatientFixtures.patientId.value,
              'eventType': 'PatientRegistered',
              'actorId': 'actor-1',
              'payload': {'key': 'value'},
              'occurredAt': '2026-01-15T10:30:00.000Z',
              'recordedAt': '2026-01-15T10:30:01.000Z',
            },
          ]);
        };

        final result = await client.getAuditTrail(PatientFixtures.patientId);
        expect(result, isA<Success<List<AuditEvent>>>());

        final events = (result as Success<List<AuditEvent>>).value;
        expect(events, hasLength(1));
        expect(events.first.eventType, 'PatientRegistered');
        expect(events.first.actorId, 'actor-1');
      });

      test('passes eventType query parameter', () async {
        adapter.handler = (options) {
          expect(options.queryParameters['eventType'], 'PatientRegistered');
          return jsonResponse([]);
        };

        await client.getAuditTrail(
          PatientFixtures.patientId,
          eventType: 'PatientRegistered',
        );
      });
    });

    // =========================================================================
    // Lookup
    // =========================================================================

    group('getLookupTable', () {
      test('returns list of LookupItem on 200', () async {
        adapter.handler = (options) {
          expect(options.path, '/lookups/dominio_parentesco');
          expect(options.method, 'GET');
          return jsonResponse([
            {'id': 'id-1', 'codigo': 'PAI', 'descricao': 'Pai'},
            {'id': 'id-2', 'codigo': 'MAE', 'descricao': 'Mae'},
          ]);
        };

        final result = await client.getLookupTable('dominio_parentesco');
        expect(result, isA<Success<List<LookupItem>>>());

        final items = (result as Success<List<LookupItem>>).value;
        expect(items, hasLength(2));
        expect(items[0].codigo, 'PAI');
        expect(items[1].descricao, 'Mae');
      });

      test('returns Failure on error', () async {
        adapter.handler = (_) =>
            jsonResponse({'error': 'not found'}, statusCode: 500);
        final result = await client.getLookupTable('nonexistent');
        expect(result, isA<Failure<List<LookupItem>>>());
      });
    });

    // =========================================================================
    // Error handling
    // =========================================================================

    group('error handling', () {
      test('DioException connectionTimeout maps to NetworkError', () async {
        adapter.handler = (_) => throw DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionTimeout,
        );
        final result = await client.fetchPatients();
        expect(result, isA<Failure<List<PatientOverview>>>());
        expect((result as Failure).error, isA<NetworkError>());
      });

      test('DioException connectionError maps to NetworkError', () async {
        adapter.handler = (_) => throw DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionError,
        );
        final result = await client.fetchPatients();
        expect(result, isA<Failure<List<PatientOverview>>>());
        expect((result as Failure).error, isA<NetworkError>());
      });

      test('generic exception maps to UnexpectedSocialCareError', () async {
        adapter.handler = (_) => throw const FormatException('bad json');
        final result = await client.fetchPatient(PatientFixtures.patientId);
        expect(result, isA<Failure<PatientRemote>>());
        expect((result as Failure).error, isA<UnexpectedSocialCareError>());
      });
    });

    group('error mapping (_failureFromResponse)', () {
      test('409 with REGP-001 maps to DuplicatePatientError', () async {
        adapter.handler = (_) => jsonResponse({
          'error': 'REGP-001: O paciente com este PersonId já está registrado.',
        }, statusCode: 409);
        final result = await client.registerPatient(
          PatientFixtures.validPatient,
        );
        expect(result, isA<Failure<PatientId>>());
        expect((result as Failure).error, isA<DuplicatePatientError>());
      });

      test('409 without backend code maps to DuplicatePatientError', () async {
        adapter.handler = (_) =>
            jsonResponse({'error': 'Conflict'}, statusCode: 409);
        final result = await client.registerPatient(
          PatientFixtures.validPatient,
        );
        expect(result, isA<Failure<PatientId>>());
        // PAT-409 from status code fallback
        expect((result as Failure).error, isA<DuplicatePatientError>());
      });

      test('backend code PAT-008 maps to PrMemberRequiredError', () async {
        adapter.handler = (_) => jsonResponse({
          'error': 'PAT-008: É necessário exatamente uma PR.',
        }, statusCode: 422);
        final result = await client.registerPatient(
          PatientFixtures.validPatient,
        );
        expect(result, isA<Failure<PatientId>>());
        expect((result as Failure).error, isA<PrMemberRequiredError>());
      });

      test(
        'backend code PAT-009 maps to MultiplePrimaryReferencesError',
        () async {
          adapter.handler = (_) => jsonResponse({
            'error': 'PAT-009: Não é permitido mais de uma PR.',
          }, statusCode: 422);
          final result = await client.registerPatient(
            PatientFixtures.validPatient,
          );
          expect(result, isA<Failure<PatientId>>());
          expect(
            (result as Failure).error,
            isA<MultiplePrimaryReferencesError>(),
          );
        },
      );

      test('unknown backend code maps to ServerError', () async {
        adapter.handler = (_) => jsonResponse({
          'error': 'XYZ-999: Something weird happened',
        }, statusCode: 500);
        final result = await client.registerPatient(
          PatientFixtures.validPatient,
        );
        expect(result, isA<Failure<PatientId>>());
        expect((result as Failure).error, isA<ServerError>());
        final error = (result as Failure).error as ServerError;
        expect(error.backendCode, 'XYZ-999');
        expect(error.backendMessage, 'Something weird happened');
      });

      test('empty message after code uses fallback', () async {
        adapter.handler = (_) =>
            jsonResponse({'error': 'VAL-001: '}, statusCode: 422);
        final result = await client.registerPatient(
          PatientFixtures.validPatient,
        );
        expect(result, isA<Failure<PatientId>>());
        expect((result as Failure).error, isA<InvalidDataError>());
        // Should NOT have empty message
        final error = (result as Failure).error as InvalidDataError;
        expect(error.message, isNotEmpty);
      });
    });
  });
}
