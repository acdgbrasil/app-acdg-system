import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:social_care_web/src/handlers/handler_utils.dart';
import 'package:social_care_web/src/middleware/session_middleware.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  group('getSession', () {
    test('extracts session from request context', () {
      final request = Request(
        'GET',
        Uri.parse('http://localhost/test'),
        context: {sessionContextKey: testSession},
      );

      final session = getSession(request);

      expect(session.id, equals('test-session-id'));
      expect(session.accessToken, equals('test-access-token'));
      expect(session.userId, equals('test-user-id'));
    });
  });

  group('readJsonBody', () {
    test('parses valid JSON body', () async {
      final request = Request(
        'POST',
        Uri.parse('http://localhost/test'),
        body: '{"name": "John", "age": 30}',
      );

      final body = await readJsonBody(request);

      expect(body['name'], equals('John'));
      expect(body['age'], equals(30));
    });

    test('throws on invalid JSON', () async {
      final request = Request(
        'POST',
        Uri.parse('http://localhost/test'),
        body: 'not json',
      );

      expect(() => readJsonBody(request), throwsA(isA<FormatException>()));
    });
  });

  group('jsonOk', () {
    test('returns 200 with JSON body', () async {
      final response = jsonOk({'key': 'value'});

      expect(response.statusCode, equals(200));
      expect(response.headers['content-type'], equals('application/json'));

      final body = jsonDecode(await response.readAsString());
      expect(body['key'], equals('value'));
    });

    test('handles list data', () async {
      final response = jsonOk([1, 2, 3]);

      expect(response.statusCode, equals(200));

      final body = jsonDecode(await response.readAsString());
      expect(body, equals([1, 2, 3]));
    });
  });

  group('jsonNoContent', () {
    test('returns 204 with no body', () {
      final response = jsonNoContent();

      expect(response.statusCode, equals(204));
    });
  });

  group('jsonError', () {
    test('returns error with correct status and message', () async {
      final response = jsonError(400, 'Bad request');

      expect(response.statusCode, equals(400));
      expect(response.headers['content-type'], equals('application/json'));

      final body = jsonDecode(await response.readAsString());
      expect(body['error'], equals('Bad request'));
    });

    test('returns 500 error', () async {
      final response = jsonError(500, 'Internal error');

      expect(response.statusCode, equals(500));

      final body = jsonDecode(await response.readAsString());
      expect(body['error'], equals('Internal error'));
    });
  });
}
