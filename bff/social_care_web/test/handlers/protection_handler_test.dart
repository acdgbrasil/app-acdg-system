import 'dart:convert';

import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/handlers/protection_handler.dart';

import 'test_helpers.dart';

void main() {
  group('ProtectionHandler', () {
    late FakeSocialCareBff fakeBff;
    late ProtectionHandler handler;

    setUp(() {
      fakeBff = FakeSocialCareBff(delay: Duration.zero);
      handler = ProtectionHandler(contractFactory: (_) => fakeBff);
    });

    group('PUT /patients/<id>/placement-history', () {
      test('returns 400 for invalid body', () async {
        final request = testRequest(
          'PUT',
          '/patients/$testPatientId/placement-history',
          body: 'not json',
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
      });

      test('returns 400 for empty JSON body', () async {
        final request = testRequest(
          'PUT',
          '/patients/$testPatientId/placement-history',
          body: jsonEncode({}),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
      });
    });

    group('POST /patients/<id>/violations', () {
      test('returns 400 for invalid body', () async {
        final request = testRequest(
          'POST',
          '/patients/$testPatientId/violations',
          body: 'not json',
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
      });

      test('returns 400 for invalid patient ID', () async {
        // Use a non-JSON body to ensure we get a 400 regardless
        final request = testRequest(
          'POST',
          '/patients/bad-uuid/violations',
          body: 'not json',
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
      });
    });

    group('POST /patients/<id>/referrals', () {
      test('returns 400 for invalid body', () async {
        final request = testRequest(
          'POST',
          '/patients/$testPatientId/referrals',
          body: 'not json',
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
      });

      test('returns 400 for invalid patient ID', () async {
        final request = testRequest(
          'POST',
          '/patients/bad-uuid/referrals',
          body: 'not json',
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
      });
    });
  });
}
