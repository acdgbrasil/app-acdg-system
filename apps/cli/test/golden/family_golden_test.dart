/// W0 RED — golden tests for `acdg family ...` (4 verbs).
library;

import 'package:test/test.dart';

import '_helpers/golden_compare.dart';
import '_helpers/golden_runner.dart';
import '_helpers/mock_bff_server.dart';

void main() {
  group('acdg family add', () {
    test('happy path — POST /patients/<id>/family-members', () async {
      final server = MockBffServer()
        ..register(
          method: 'POST',
          path: '/patients/*/family-members',
          fixture: 'family/add_member_success.json',
        );

      // Impl uses POSITIONAL `<patient-id>` (NOT `--patient-id`).
      // Required flags per `family_add_command.dart`:
      //   --relationship, --birth-date, --pr-relationship-id.
      // (`--member-cpf`, `--full-name` are optional People-Context inputs.)
      final result = await runCliForGolden(const [
        'family',
        'add',
        '11111111-1111-4111-8111-111111111111',
        '--relationship=SON',
        '--birth-date=2010-08-20',
        '--pr-relationship-id=66666666-1111-4111-8111-111111111111',
        '--member-cpf=98765432100',
        '--full-name=Carlos Silva',
        '--output=table',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'family/add_success.golden');
    });
  });

  group('acdg family remove', () {
    test('happy path — DELETE void', () async {
      final server = MockBffServer()
        ..register(
          method: 'DELETE',
          path: '/patients/*/family-members/*',
          response: MockResponse.noContent(),
        );

      // Impl uses POSITIONAL `<patient-id>` (NOT `--patient-id`).
      // Source of truth: `family_remove_command.dart:43-58`.
      final result = await runCliForGolden(const [
        'family',
        'remove',
        '11111111-1111-4111-8111-111111111111',
        '--member-id=22222222-2222-4222-8222-222222222222',
        '--output=table',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'family/remove_success.golden');
    });
  });

  group('acdg family assign-caregiver', () {
    test('happy path — PUT /primary-caregiver', () async {
      final server = MockBffServer()
        ..register(
          method: 'PUT',
          path: '/patients/*/primary-caregiver',
          response: MockResponse.noContent(),
        );

      // Impl uses POSITIONAL `<patient-id>` (NOT `--patient-id`).
      // Source of truth: `family_assign_caregiver_command.dart:48-65`.
      final result = await runCliForGolden(const [
        'family',
        'assign-caregiver',
        '11111111-1111-4111-8111-111111111111',
        '--member-id=22222222-2222-4222-8222-222222222222',
        '--output=table',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'family/assign_caregiver_success.golden');
    });
  });

  group('acdg family update-identity', () {
    test('happy path — PUT /social-identity', () async {
      // Impl PUTs `/patients/<id>/social-identity` (NOT
      // `/family-members/<id>/social-identity`). Source of truth:
      // `family_update_identity_command.dart:80-83`. Flag set is
      // `--type-id` + optional `--description`; positional is the
      // patient id.
      final server = MockBffServer()
        ..register(
          method: 'PUT',
          path: '/patients/*/social-identity',
          response: MockResponse.noContent(),
        );

      final result = await runCliForGolden(const [
        'family',
        'update-identity',
        '11111111-1111-4111-8111-111111111111',
        '--type-id=77777777-1111-4111-8111-111111111111',
        '--output=table',
      ], mockAdapter: server.asAdapter());

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'family/update_identity_success.golden');
    });
  });
}
