import 'dart:convert';

import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/handlers/assessment_handler.dart';

import 'test_helpers.dart';

void main() {
  group('AssessmentHandler', () {
    late FakeSocialCareBff fakeBff;
    late AssessmentHandler handler;

    setUp(() {
      fakeBff = FakeSocialCareBff(delay: Duration.zero);
      handler = AssessmentHandler(contractFactory: (_) => fakeBff);
    });

    group('PUT /patients/<id>/assessment/housing', () {
      test('returns 400 for invalid patient ID', () async {
        final request = testRequest(
          'PUT',
          '/patients/bad-uuid/assessment/housing',
          body: jsonEncode({'type': 'OWNED'}),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));

        final body = jsonDecode(await response.readAsString());
        expect(body['error'], contains('Invalid patient ID'));
      });

      test('returns 400 for invalid body', () async {
        final request = testRequest(
          'PUT',
          '/patients/$testPatientId/assessment/housing',
          body: 'not json',
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
      });
    });

    group('PUT /patients/<id>/assessment/socioeconomic', () {
      test('returns 400 for invalid patient ID', () async {
        final request = testRequest(
          'PUT',
          '/patients/bad-uuid/assessment/socioeconomic',
          body: jsonEncode({}),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
      });
    });

    group('PUT /patients/<id>/assessment/work-income', () {
      test('returns 400 for invalid patient ID', () async {
        final request = testRequest(
          'PUT',
          '/patients/bad-uuid/assessment/work-income',
          body: jsonEncode({}),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
      });
    });

    group('PUT /patients/<id>/assessment/education', () {
      test('returns 400 for invalid patient ID', () async {
        final request = testRequest(
          'PUT',
          '/patients/bad-uuid/assessment/education',
          body: jsonEncode({}),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
      });
    });

    group('PUT /patients/<id>/assessment/health', () {
      test('returns 400 for invalid patient ID', () async {
        final request = testRequest(
          'PUT',
          '/patients/bad-uuid/assessment/health',
          body: jsonEncode({}),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
      });
    });

    group('PUT /patients/<id>/assessment/community-support', () {
      test('returns 400 for invalid patient ID', () async {
        final request = testRequest(
          'PUT',
          '/patients/bad-uuid/assessment/community-support',
          body: jsonEncode({}),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
      });
    });

    group('PUT /patients/<id>/assessment/social-health-summary', () {
      test('returns 400 for invalid patient ID', () async {
        final request = testRequest(
          'PUT',
          '/patients/bad-uuid/assessment/social-health-summary',
          body: jsonEncode({}),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
      });
    });
  });
}
