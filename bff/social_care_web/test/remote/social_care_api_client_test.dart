import 'package:core_contracts/core_contracts.dart';
import 'package:dio/dio.dart';
import 'package:shared/shared.dart';
import 'package:social_care_web/src/handlers/handler_utils.dart';
import 'package:social_care_web/src/remote/social_care_api_client.dart';
import 'package:test/test.dart';

/// Fake Dio adapter that returns preconfigured responses.
class _FakeHttpAdapter implements HttpClientAdapter {
  Response<dynamic>? nextResponse;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final resp = nextResponse!;
    return ResponseBody.fromString(
      '',
      resp.statusCode ?? 200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Creates a Dio instance with a fake adapter that returns [response].
Dio _dioReturning(int statusCode, Map<String, dynamic> data) {
  final dio = Dio(BaseOptions(
    baseUrl: 'http://localhost',
    headers: {
      'Authorization': 'Bearer test',
      'X-Actor-Id': 'test-actor',
      'Content-Type': 'application/json',
    },
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      handler.resolve(Response(
        requestOptions: options,
        statusCode: statusCode,
        data: data,
      ));
    },
  ));

  return dio;
}

void main() {
  group('SocialCareApiClient — BackendError mapping', () {
    test(
      'maps 422 Unprocessable Entity to Failure(BackendError) with correct message',
      () async {
        final dio = _dioReturning(422, {
          'error': {
            'code': 'REGP-006',
            'message': 'Ao menos um diagnóstico deve ser informado',
          },
        });
        final client = SocialCareApiClient(
          baseUrl: 'http://localhost',
          actorId: 'test',
          accessToken: 'test',
          dio: dio,
        );

        final result = await client.fetchPatients();

        expect(result.isFailure, isTrue);
        final error = (result as Failure).error;
        expect(error, isA<BackendError>());

        final backendError = error as BackendError;
        expect(backendError.statusCode, equals(422));
        expect(
          backendError.message,
          contains('Ao menos um diagnóstico deve ser informado'),
        );
      },
    );

    test(
      'maps 500 Internal Server Error to Failure(BackendError)',
      () async {
        final dio = _dioReturning(500, {
          'message': 'Internal Server Error',
        });
        final client = SocialCareApiClient(
          baseUrl: 'http://localhost',
          actorId: 'test',
          accessToken: 'test',
          dio: dio,
        );

        final result = await client.fetchPatients();

        expect(result.isFailure, isTrue);
        final error = (result as Failure).error;
        expect(error, isA<BackendError>());
        expect((error as BackendError).statusCode, equals(500));
      },
    );

    test(
      'maps 400 Bad Request to Failure(BackendError) preserving status',
      () async {
        final dio = _dioReturning(400, {
          'error': {
            'code': 'PAT-001',
            'message': 'Invalid patient data',
          },
        });
        final client = SocialCareApiClient(
          baseUrl: 'http://localhost',
          actorId: 'test',
          accessToken: 'test',
          dio: dio,
        );

        final result = await client.fetchPatients();

        expect(result.isFailure, isTrue);
        final error = (result as Failure).error;
        expect(error, isA<BackendError>());

        final backendError = error as BackendError;
        expect(backendError.statusCode, equals(400));
        expect(backendError.message, contains('PAT-001'));
      },
    );

    test('backendError() extracts correct HTTP status from BackendError',
        () {
      final error = BackendError(statusCode: 422, message: 'Validation failed');
      final response = backendError(error);

      expect(response.statusCode, equals(422));
    });

    test('backendError() falls back to 502 for non-BackendError', () {
      final response = backendError('some random error');

      expect(response.statusCode, equals(502));
    });
  });
}
