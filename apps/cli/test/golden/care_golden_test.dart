/// W0 RED — golden tests for `acdg care ...` (appointment, intake).
library;

import 'package:test/test.dart';

import '_helpers/golden_compare.dart';
import '_helpers/golden_runner.dart';
import '_helpers/mock_bff_server.dart';

void main() {
  group('acdg care appointment', () {
    test('happy path — surfaces appointment id', () async {
      final server = MockBffServer()
        ..register(
          method: 'POST',
          path: '/patients/*/appointments',
          fixture: 'care/appointment_success.json',
        );

      final result = await runCliForGolden(const [
        'care',
        'appointment',
        '11111111-1111-4111-8111-111111111111',
        '--professional-id=99999999-1111-4111-8111-111111111111',
        '--date=2026-05-04T14:00:00Z',
        '--output=table',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'care/appointment_success.golden');
    });
  });

  group('acdg care intake', () {
    test('happy path — 204 void', () async {
      final server = MockBffServer()
        ..register(
          method: 'PUT',
          path: '/patients/*/intake',
          response: MockResponse.noContent(),
        );

      final result = await runCliForGolden(const [
        'care',
        'intake',
        '11111111-1111-4111-8111-111111111111',
        '--ingress-type-id=99999999-2222-4222-8222-222222222222',
        '--service-reason=Routine intake',
        '--output=table',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'care/intake_success.golden');
    });
  });
}
