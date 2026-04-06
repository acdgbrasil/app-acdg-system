import 'dart:convert';

import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/handlers/care_handler.dart';

import 'test_helpers.dart';

void main() {
  group('CareHandler', () {
    late FakeSocialCareBff fakeBff;
    late CareHandler handler;

    setUp(() {
      fakeBff = FakeSocialCareBff(delay: Duration.zero);
      handler = CareHandler(contractFactory: (_) => fakeBff);
    });

    group('POST /patients/<id>/appointments', () {
      test('returns 400 for invalid body', () async {
        final request = testRequest(
          'POST',
          '/patients/$testPatientId/appointments',
          body: 'not json',
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
      });

      test('returns 400 for empty JSON body', () async {
        final request = testRequest(
          'POST',
          '/patients/$testPatientId/appointments',
          body: jsonEncode({}),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
      });
    });

    group('PUT /patients/<id>/intake', () {
      test('returns 400 for invalid body', () async {
        final request = testRequest(
          'PUT',
          '/patients/$testPatientId/intake',
          body: 'not json',
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
      });

      test('returns 400 for empty JSON body', () async {
        final request = testRequest(
          'PUT',
          '/patients/$testPatientId/intake',
          body: jsonEncode({}),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
      });
    });
  });
}
