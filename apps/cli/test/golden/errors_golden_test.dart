/// W0 RED — golden tests for error paths.
///
/// Pins the exit-code matrix established in C03 and the stderr-message
/// shapes in `_command_helpers.dart::stderrMessageFor`:
///   * 401 / no session       → exit 2  + "Authentication required"
///   * 422 validation failure → exit 1  + "Server error (422): ..."
///   * 500 server error       → exit 1  + "Server error (500): ..."
///   * 503 / network          → exit 1  + "Server error (503): ..."
///   * Unknown command        → exit 64 + Usage error on stderr.
library;

import 'package:test/test.dart';

import '_helpers/golden_compare.dart';
import '_helpers/golden_runner.dart';
import '_helpers/mock_bff_server.dart';

void main() {
  group('error paths', () {
    test('401 with no token client wired → exit 2 + auth message', () async {
      final server = MockBffServer()
        ..register(
          method: 'GET',
          path: '/patients',
          fixture: 'errors/auth_expired.json',
          statusCode: 401,
        );

      final result = await runCliForGolden(
        const ['patient', 'list', '--output=table'],
        mockAdapter: server.asAdapter(),
        credentialStore: FakeCredentialStore.signedIn(),
      );

      expect(result.exitCode, equals(2));
      expectGolden(result.stderr, 'errors/auth_expired_table.golden');
    });

    test('signed-out (401 from BFF) → exit 2 + auth message', () async {
      // The CLI does NOT short-circuit on a missing local session — it
      // dispatches the request anyway (no Bearer header) and lets the BFF
      // 401 it. We register a 401 fixture so the test exercises the
      // `AuthRequiredError → exit 2` mapping rather than the unmatched-
      // route 404 fallback.
      final server = MockBffServer()
        ..register(
          method: 'GET',
          path: '/patients',
          fixture: 'errors/auth_expired.json',
          statusCode: 401,
        );

      final result = await runCliForGolden(
        const ['patient', 'list', '--output=table'],
        mockAdapter: server.asAdapter(),
        credentialStore: FakeCredentialStore.signedOut(),
      );

      expect(result.exitCode, equals(2));
      expectGolden(result.stderr, 'errors/no_session_table.golden');
    });

    test('422 validation failure → exit 1 + server message', () async {
      final server = MockBffServer()
        ..register(
          method: 'POST',
          path: '/patients',
          fixture: 'errors/validation.json',
          statusCode: 422,
        );

      // Use the canonical PatientRegisterCommand flag set:
      //   --person-id, --pr-relationship-id, --icd-code,
      //   --diagnosis-date, --diagnosis-description (all REQUIRED in
      //   flag-mode per `patient_register_command.dart::_buildBodyFromFlags`).
      // The wire body is well-formed; the mock returns 422 to exercise the
      // server-error-on-success-shape path.
      final result = await runCliForGolden(const [
        'patient',
        'register',
        '--person-id=11111111-1111-4111-8111-111111111111',
        '--pr-relationship-id=22222222-2222-4222-8222-222222222222',
        '--icd-code=Q90.0',
        '--diagnosis-date=2026-04-01',
        '--diagnosis-description=Down syndrome — initial diagnosis',
        '--output=table',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(1));
      expectGolden(result.stderr, 'errors/validation_table.golden');
    });

    test('500 → exit 1 + status surfaced on stderr', () async {
      final server = MockBffServer()
        ..register(
          method: 'GET',
          path: '/patients',
          fixture: 'errors/server_error.json',
          statusCode: 500,
        );

      final result = await runCliForGolden(const [
        'patient',
        'list',
        '--output=table',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(1));
      expectGolden(result.stderr, 'errors/server_500_table.golden');
    });

    test('unknown command → exit 64 + usage on stderr', () async {
      final server = MockBffServer();

      final result = await runCliForGolden(const [
        'definitely-not-a-real-command',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(64));
      expect(
        result.stderr,
        isNotEmpty,
        reason: 'unknown command should produce usage stderr',
      );
    });
  });
}
