/// W0 RED — golden tests for `acdg patient ...` commands.
///
/// Drives the assembled CLI through `CliRunner.run([...])` (not the leaf
/// command directly). Wires a `MockBffServer` adapter so the BFF round-trip
/// is mocked, then golden-compares stdout/stderr.
///
/// W1 contract surfaced here:
///   1. `CliRunner` accepts named params `adapter` + `credentialStore`.
///   2. `--output={table|json|yaml|auto}` switches the formatter at the
///      runner level (today JsonFormatter is hardcoded inside every
///      `_buildXxxCommand`).
///   3. Auto mode in non-tty (test env) defaults to JSON — pipe-friendly.
///   4. Goldens are stored under `test/golden/<verb>/<scenario>.golden`.
///
/// Expected RED state at W0 close:
///   * `dart analyze` reports `Method not found: ... CliRunner(...)` (named
///     params not implemented yet).
///   * Once W1 lands the params, the goldens still fail because the empty
///     placeholder `.golden` files don't match the rendered output.
///   * W1 must run `UPDATE_GOLDENS=1 dart test ...` once and commit the
///     refreshed goldens.
library;

import 'package:test/test.dart';

import '_helpers/golden_compare.dart';
import '_helpers/golden_runner.dart';
import '_helpers/mock_bff_server.dart';

void main() {
  group('acdg patient list', () {
    test('happy path — 2 patients (table)', () async {
      final server = MockBffServer()
        ..register(
          method: 'GET',
          path: '/patients',
          fixture: 'patient/list_2_patients.json',
        );

      final result = await runCliForGolden(const [
        'patient',
        'list',
        '--output=table',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'patient/list_table.golden');
    });

    test('happy path — 2 patients (json)', () async {
      final server = MockBffServer()
        ..register(
          method: 'GET',
          path: '/patients',
          fixture: 'patient/list_2_patients.json',
        );

      final result = await runCliForGolden(const [
        'patient',
        'list',
        '--output=json',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'patient/list_json.golden');
    });

    test('happy path — 2 patients (yaml)', () async {
      final server = MockBffServer()
        ..register(
          method: 'GET',
          path: '/patients',
          fixture: 'patient/list_2_patients.json',
        );

      final result = await runCliForGolden(const [
        'patient',
        'list',
        '--output=yaml',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'patient/list_yaml.golden');
    });

    test('empty list (table) — renders sentinel', () async {
      final server = MockBffServer()
        ..register(
          method: 'GET',
          path: '/patients',
          fixture: 'patient/list_empty.json',
        );

      final result = await runCliForGolden(const [
        'patient',
        'list',
        '--output=table',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'patient/list_empty_table.golden');
    });

    test('with search/status query — query string forwarded', () async {
      final server = MockBffServer()
        ..register(
          method: 'GET',
          path: '/patients',
          fixture: 'patient/list_2_patients.json',
        );

      final result = await runCliForGolden(const [
        'patient',
        'list',
        '--search=maria',
        '--status=admitted',
        '--output=json',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      // Wire-level assertion alongside the golden compare: query was forwarded.
      final lastReq = server.recordedRequests.last;
      expect(lastReq.method, equals('GET'));
      expect(lastReq.path, equals('/patients'));
      expect(lastReq.query['search'], equals('maria'));
      expect(lastReq.query['status'], equals('admitted'));
    });
  });

  group('acdg patient get', () {
    test('full detail (table)', () async {
      final server = MockBffServer()
        ..register(
          method: 'GET',
          path: '/patients/*',
          fixture: 'patient/get_full_detail.json',
        );

      final result = await runCliForGolden(const [
        'patient',
        'get',
        '11111111-1111-4111-8111-111111111111',
        '--output=table',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'patient/get_table.golden');
    });

    test('full detail (json)', () async {
      final server = MockBffServer()
        ..register(
          method: 'GET',
          path: '/patients/*',
          fixture: 'patient/get_full_detail.json',
        );

      final result = await runCliForGolden(const [
        'patient',
        'get',
        '11111111-1111-4111-8111-111111111111',
        '--output=json',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'patient/get_json.golden');
    });
  });

  group('acdg patient audit', () {
    test('3 events (table)', () async {
      // Impl GETs `/patients/<id>/audit-trail` (hyphenated). Source of
      // truth: `patient_audit_command.dart:69`.
      final server = MockBffServer()
        ..register(
          method: 'GET',
          path: '/patients/*/audit-trail',
          fixture: 'patient/audit_3_events.json',
        );

      final result = await runCliForGolden(const [
        'patient',
        'audit',
        '11111111-1111-4111-8111-111111111111',
        '--output=table',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'patient/audit_table.golden');
    });
  });

  group('acdg patient register', () {
    test('success (table) — surfaces new id', () async {
      final server = MockBffServer()
        ..register(
          method: 'POST',
          path: '/patients',
          fixture: 'patient/register_success.json',
        );

      // Canonical PatientRegisterCommand flag-mode requires the 5
      // top-level fields: --person-id, --pr-relationship-id, --icd-code,
      // --diagnosis-date, --diagnosis-description. Source of truth:
      // `patient_register_command.dart:_buildBodyFromFlags`.
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

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'patient/register_success.golden');
    });
  });

  group('acdg patient lifecycle (admit/discharge/readmit/withdraw)', () {
    test('admit — 204 no content', () async {
      final server = MockBffServer()
        ..register(
          method: 'POST',
          path: '/patients/*/admit',
          response: MockResponse.noContent(),
        );

      // Impl REQUIRES `--reason` AND `--admitted-at` (source of truth:
      // `patient_admit_command.dart:50-71`).
      final result = await runCliForGolden(const [
        'patient',
        'admit',
        '11111111-1111-4111-8111-111111111111',
        '--reason=program-start',
        '--admitted-at=2026-04-30T10:00:00Z',
        '--output=table',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'patient/admit_success.golden');
    });

    test('discharge — 204 no content', () async {
      final server = MockBffServer()
        ..register(
          method: 'POST',
          path: '/patients/*/discharge',
          response: MockResponse.noContent(),
        );

      final result = await runCliForGolden(const [
        'patient',
        'discharge',
        '11111111-1111-4111-8111-111111111111',
        '--reason=program-end',
        '--output=table',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'patient/discharge_success.golden');
    });

    test('readmit — 204 no content', () async {
      final server = MockBffServer()
        ..register(
          method: 'POST',
          path: '/patients/*/readmit',
          response: MockResponse.noContent(),
        );

      final result = await runCliForGolden(const [
        'patient',
        'readmit',
        '11111111-1111-4111-8111-111111111111',
        '--output=table',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'patient/readmit_success.golden');
    });

    test('withdraw — 204 no content', () async {
      final server = MockBffServer()
        ..register(
          method: 'POST',
          path: '/patients/*/withdraw',
          response: MockResponse.noContent(),
        );

      final result = await runCliForGolden(const [
        'patient',
        'withdraw',
        '11111111-1111-4111-8111-111111111111',
        '--reason=user-request',
        '--output=table',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'patient/withdraw_success.golden');
    });
  });
}
