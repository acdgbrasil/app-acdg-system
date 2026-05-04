/// W0 RED — golden tests for `acdg lookup ...` (9 endpoints incl. nested
/// `lookup request {list|create|approve|reject}`).
library;

import 'package:test/test.dart';

import '_helpers/golden_compare.dart';
import '_helpers/golden_runner.dart';
import '_helpers/mock_bff_server.dart';

void main() {
  group('acdg lookup get', () {
    test('single table (table fmt)', () async {
      final server = MockBffServer()
        ..register(
          method: 'GET',
          path: '/lookups/dominio_genero',
          fixture: 'lookup/single_table.json',
        );

      final result = await runCliForGolden(const [
        'lookup',
        'get',
        'dominio_genero',
        '--output=table',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'lookup/get_table.golden');
    });

    test('single table (json)', () async {
      final server = MockBffServer()
        ..register(
          method: 'GET',
          path: '/lookups/dominio_genero',
          fixture: 'lookup/single_table.json',
        );

      final result = await runCliForGolden(const [
        'lookup',
        'get',
        'dominio_genero',
        '--output=json',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'lookup/get_json.golden');
    });

    test('single table (yaml)', () async {
      final server = MockBffServer()
        ..register(
          method: 'GET',
          path: '/lookups/dominio_genero',
          fixture: 'lookup/single_table.json',
        );

      final result = await runCliForGolden(const [
        'lookup',
        'get',
        'dominio_genero',
        '--output=yaml',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'lookup/get_yaml.golden');
    });
  });

  group('acdg lookup batch', () {
    test('3 tables (json)', () async {
      final server = MockBffServer()
        ..register(
          method: 'GET',
          path: '/lookups',
          fixture: 'lookup/batch_3_tables.json',
        );

      // Impl takes the CSV as a POSITIONAL argument — there is NO
      // `--tables=` flag. Source of truth:
      // `lookup_batch_command.dart:57-68`.
      final result = await runCliForGolden(const [
        'lookup',
        'batch',
        'dominio_genero,dominio_parentesco,dominio_escolaridade',
        '--output=json',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'lookup/batch_json.golden');
    });
  });

  group('acdg lookup create', () {
    test('happy path — POST /lookups/<table>', () async {
      final server = MockBffServer()
        ..register(
          method: 'POST',
          path: '/lookups/dominio_genero',
          fixture: 'patient/register_success.json',
        );

      final result = await runCliForGolden(const [
        'lookup',
        'create',
        'dominio_genero',
        '--code=NB',
        '--label=Não Binário',
        '--output=table',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'lookup/create_success.golden');
    });
  });

  group('acdg lookup toggle (PATCH)', () {
    test('toggle active flag', () async {
      // Impl PATCHes `/lookups/<table>/<id>/toggle` (extra `/toggle`
      // segment). Source of truth: `lookup_toggle_command.dart:86`.
      final server = MockBffServer()
        ..register(
          method: 'PATCH',
          path: '/lookups/dominio_genero/*/toggle',
          response: MockResponse.noContent(),
        );

      final result = await runCliForGolden(const [
        'lookup',
        'toggle',
        'dominio_genero',
        '55555555-1111-4111-8111-111111111111',
        '--active=true',
        '--output=table',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'lookup/toggle_success.golden');
    });
  });

  group('acdg lookup request', () {
    test('list — empty', () async {
      // Impl GETs `/lookup-requests` (hyphenated, top-level). Source of
      // truth: `lookup_request_list_command.dart:41`.
      final server = MockBffServer()
        ..register(
          method: 'GET',
          path: '/lookup-requests',
          fixture: 'lookup/request_list_empty.json',
        );

      final result = await runCliForGolden(const [
        'lookup',
        'request',
        'list',
        '--output=table',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'lookup/request_list_empty.golden');
    });
  });
}
