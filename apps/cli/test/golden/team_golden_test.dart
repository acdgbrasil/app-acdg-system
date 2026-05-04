/// W0 RED — golden tests for `acdg team ...` (9 endpoints incl. nested
/// `team role {assign|deactivate|reactivate}`).
library;

import 'package:test/test.dart';

import '_helpers/golden_compare.dart';
import '_helpers/golden_runner.dart';
import '_helpers/mock_bff_server.dart';

void main() {
  group('acdg team list', () {
    test('3 members (table)', () async {
      final server = MockBffServer()
        ..register(
          method: 'GET',
          path: '/team',
          fixture: 'team/list_3_members.json',
        );

      final result = await runCliForGolden(const [
        'team',
        'list',
        '--output=table',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'team/list_table.golden');
    });

    test('3 members (json)', () async {
      final server = MockBffServer()
        ..register(
          method: 'GET',
          path: '/team',
          fixture: 'team/list_3_members.json',
        );

      final result = await runCliForGolden(const [
        'team',
        'list',
        '--output=json',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'team/list_json.golden');
    });
  });

  group('acdg team get', () {
    test('member detail (table)', () async {
      final server = MockBffServer()
        ..register(
          method: 'GET',
          path: '/team/*',
          fixture: 'team/get_member.json',
        );

      final result = await runCliForGolden(const [
        'team',
        'get',
        '88888888-1111-4111-8111-111111111111',
        '--output=table',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'team/get_table.golden');
    });
  });

  group('acdg team register', () {
    test('happy path — surfaces new id', () async {
      final server = MockBffServer()
        ..register(
          method: 'POST',
          path: '/team',
          fixture: 'team/register_success.json',
        );

      final result = await runCliForGolden(const [
        'team',
        'register',
        '--full-name=Ana Pereira',
        '--birth-date=1985-04-12',
        '--email=ana@acdgbrasil.com.br',
        '--output=table',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'team/register_success.golden');
    });
  });

  group('acdg team lifecycle (deactivate/reactivate/reset-password)', () {
    test('deactivate — 204', () async {
      final server = MockBffServer()
        ..register(
          method: 'PUT',
          path: '/team/*/deactivate',
          response: MockResponse.noContent(),
        );

      final result = await runCliForGolden(const [
        'team',
        'deactivate',
        '88888888-1111-4111-8111-111111111111',
        '--output=table',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'team/deactivate_success.golden');
    });

    test('reactivate — 204', () async {
      final server = MockBffServer()
        ..register(
          method: 'PUT',
          path: '/team/*/reactivate',
          response: MockResponse.noContent(),
        );

      final result = await runCliForGolden(const [
        'team',
        'reactivate',
        '88888888-1111-4111-8111-111111111111',
        '--output=table',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'team/reactivate_success.golden');
    });

    test('reset-password — 204', () async {
      final server = MockBffServer()
        ..register(
          method: 'POST',
          path: '/team/*/reset-password',
          response: MockResponse.noContent(),
        );

      final result = await runCliForGolden(const [
        'team',
        'reset-password',
        '88888888-1111-4111-8111-111111111111',
        '--output=table',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'team/reset_password_success.golden');
    });
  });

  group('acdg team role', () {
    test('assign — 204', () async {
      // Impl requires BOTH `--system` AND `--role-id`. The mock route is a
      // 200 with the standard `{data:{id:...},meta:{...}}` envelope so the
      // command surfaces the assignment id; a 204 was the W0 guess but
      // `team_role_assign_command.dart:87-91` decodes
      // `decodeStandardIdResponse` and emits "Assigned role <id>".
      final server = MockBffServer()
        ..register(
          method: 'POST',
          path: '/team/*/roles',
          fixture: 'team/register_success.json',
        );

      final result = await runCliForGolden(const [
        'team',
        'role',
        'assign',
        '88888888-1111-4111-8111-111111111111',
        '--system=social_care',
        '--role-id=social_worker',
        '--output=table',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'team/role_assign_success.golden');
    });
  });
}
