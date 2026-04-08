import 'package:core_contracts/core_contracts.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:shared/shared.dart';

/// Fake Dio adapter that returns pre-configured responses.
class _FakeDioAdapter implements HttpClientAdapter {
  ResponseBody? nextResponse;
  int nextStatusCode = 200;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return nextResponse ??
        ResponseBody.fromString(
          '{"data": {"id": "canonical-123"}}',
          nextStatusCode,
          headers: {
            'content-type': ['application/json'],
          },
        );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('PeopleContextClient', () {
    late Dio dio;
    late _FakeDioAdapter adapter;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
      adapter = _FakeDioAdapter();
      dio.httpClientAdapter = adapter;
    });

    group('registerPerson', () {
      test('returns canonical personId on 201', () async {
        adapter.nextStatusCode = 201;
        adapter.nextResponse = ResponseBody.fromString(
          '{"data": {"id": "canonical-abc"}}',
          201,
          headers: {
            'content-type': ['application/json'],
          },
        );

        final client = PeopleContextClient(
          baseUrl: 'http://localhost',
          accessToken: 'token',
          actorId: 'actor',
          dio: dio,
        );

        final result = await client.registerPerson(
          fullName: 'Maria Silva',
          birthDate: '2000-01-15',
          cpf: '00906366356',
        );

        expect(result, isA<Success<String>>());
        expect((result as Success).value, equals('canonical-abc'));
      });

      test('returns Failure when response body is null', () async {
        adapter.nextResponse = ResponseBody.fromString(
          '',
          200,
          headers: {
            'content-type': ['application/json'],
          },
        );

        final client = PeopleContextClient(
          baseUrl: 'http://localhost',
          accessToken: 'token',
          actorId: 'actor',
          dio: dio,
        );

        final result = await client.registerPerson(
          fullName: 'Maria Silva',
          birthDate: '2000-01-15',
        );

        expect(result, isA<Failure<String>>());
      });

      test('returns Failure on non-success status code', () async {
        adapter.nextResponse = ResponseBody.fromString(
          '{"error": "not found"}',
          404,
          headers: {
            'content-type': ['application/json'],
          },
        );

        final client = PeopleContextClient(
          baseUrl: 'http://localhost',
          accessToken: 'token',
          actorId: 'actor',
          dio: dio,
        );

        final result = await client.registerPerson(
          fullName: 'Maria Silva',
          birthDate: '2000-01-15',
        );

        expect(result, isA<Failure<String>>());
      });
    });

    group('getPerson', () {
      test('returns person data on 200', () async {
        adapter.nextResponse = ResponseBody.fromString(
          '{"data": {"id": "p-123", "fullName": "Maria", "birthDate": "2000-01-15"}}',
          200,
          headers: {
            'content-type': ['application/json'],
          },
        );

        final client = PeopleContextClient(
          baseUrl: 'http://localhost',
          accessToken: 'token',
          actorId: 'actor',
          dio: dio,
        );

        final result = await client.getPerson('p-123');

        expect(result, isA<Success<Map<String, dynamic>>>());
        final data = (result as Success).value as Map<String, dynamic>;
        expect(data['fullName'], equals('Maria'));
      });

      test('returns Failure with status code on error', () async {
        adapter.nextResponse = ResponseBody.fromString(
          '{"error": "unauthorized"}',
          401,
          headers: {
            'content-type': ['application/json'],
          },
        );

        final client = PeopleContextClient(
          baseUrl: 'http://localhost',
          accessToken: 'token',
          actorId: 'actor',
          dio: dio,
        );

        final result = await client.getPerson('p-123');

        expect(result, isA<Failure<Map<String, dynamic>>>());
        final error = (result as Failure).error as String;
        expect(error, contains('401'));
      });
    });
  });
}
