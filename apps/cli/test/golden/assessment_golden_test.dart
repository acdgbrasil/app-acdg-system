/// W0 RED — golden tests for `acdg assessment ...` (7 fichas, all PUT void).
///
/// One representative ficha per ID-only path verb. The full 7×3-format matrix
/// is overkill for goldens — unit tests in `test/commands/assessment_*` already
/// pin the wire shape. Goldens here only assert the success-line stdout.
library;

import 'package:test/test.dart';

import '_helpers/golden_compare.dart';
import '_helpers/golden_runner.dart';
import '_helpers/mock_bff_server.dart';

void main() {
  group('acdg assessment housing', () {
    test('happy path — 204 void', () async {
      final server = MockBffServer()
        ..register(
          method: 'PUT',
          path: '/patients/*/assessment/housing',
          response: MockResponse.noContent(),
        );

      // Impl requires the full 15-field set (6 strings + 3 ints + 5 bools
      // + accessibilityLevel). Source of truth:
      // `assessment_housing_command.dart::_buildBodyFromFlags`.
      final result = await runCliForGolden(const [
        'assessment',
        'housing',
        '11111111-1111-4111-8111-111111111111',
        '--type=alvenaria',
        '--wall-material=concrete',
        '--number-of-rooms=4',
        '--number-of-bedrooms=2',
        '--number-of-bathrooms=1',
        '--water-supply=public_network',
        '--has-piped-water=true',
        '--electricity-access=public_network',
        '--sewage-disposal=public_network',
        '--waste-collection=public_collection',
        '--accessibility-level=full',
        '--is-in-geographic-risk-area=false',
        '--has-difficult-access=false',
        '--is-in-social-conflict-area=false',
        '--has-diagnostic-observations=false',
        '--output=table',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'assessment/housing_success.golden');
    });
  });

  group('acdg assessment health', () {
    test('happy path — 204 void', () async {
      final server = MockBffServer()
        ..register(
          method: 'PUT',
          path: '/patients/*/assessment/health',
          response: MockResponse.noContent(),
        );

      // Impl requires `--food-insecurity=true|false` (no
      // `--has-medical-followup`). Source of truth:
      // `assessment_health_command.dart:_buildBodyFromFlags`.
      final result = await runCliForGolden(const [
        'assessment',
        'health',
        '11111111-1111-4111-8111-111111111111',
        '--food-insecurity=false',
        '--output=table',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'assessment/health_success.golden');
    });
  });
}
