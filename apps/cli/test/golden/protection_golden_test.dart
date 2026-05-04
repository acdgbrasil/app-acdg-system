/// W0 RED — golden tests for `acdg protection ...` (violation, referral,
/// placement-history).
library;

import 'package:test/test.dart';

import '_helpers/golden_compare.dart';
import '_helpers/golden_runner.dart';
import '_helpers/mock_bff_server.dart';

void main() {
  group('acdg protection violation', () {
    test('happy path — surfaces report id', () async {
      // Impl POSTs `/patients/<id>/violations` (no `/protection/` segment).
      // Source of truth: `protection_violation_command.dart:162`.
      final server = MockBffServer()
        ..register(
          method: 'POST',
          path: '/patients/*/violations',
          fixture: 'protection/violation_success.json',
        );

      final result = await runCliForGolden(const [
        'protection',
        'violation',
        '11111111-1111-4111-8111-111111111111',
        '--victim-id=22222222-2222-4222-8222-222222222222',
        '--violation-type=neglect',
        '--description-of-fact=Inadequate care',
        '--output=table',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'protection/violation_success.golden');
    });
  });

  group('acdg protection referral', () {
    test('happy path — surfaces referral id', () async {
      // Impl POSTs `/patients/<id>/referrals` (no `/protection/` segment).
      // Source of truth: `protection_referral_command.dart:136`.
      final server = MockBffServer()
        ..register(
          method: 'POST',
          path: '/patients/*/referrals',
          fixture: 'protection/referral_success.json',
        );

      final result = await runCliForGolden(const [
        'protection',
        'referral',
        '11111111-1111-4111-8111-111111111111',
        '--referred-person-id=22222222-2222-4222-8222-222222222222',
        '--destination-service=CRAS',
        '--reason=Family support',
        '--output=table',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'protection/referral_success.golden');
    });
  });
}
