/// W0 RED — `AuthCommand` parent contract under C02.
///
/// **Replaces the C01 stub contract.** C01 declared `AuthCommand` as a leaf
/// command that printed "Not implemented yet — pending C02". C02 makes it
/// a parent command holding 4 subcommands: `login`, `status`, `logout`,
/// `refresh` (spike §1 ticket §Comandos).
///
/// W1 must update `apps/cli/lib/src/commands/auth_command.dart` so that:
///
/// ```dart
/// class AuthCommand extends Command<int> {
///   AuthCommand({...injectable collaborators...}) {
///     addSubcommand(AuthLoginCommand(...));
///     addSubcommand(AuthStatusCommand(...));
///     addSubcommand(AuthLogoutCommand(...));
///     addSubcommand(AuthRefreshCommand(...));
///   }
///   @override String get name => 'auth';
///   @override String get description => '...non-empty...';
/// }
/// ```
///
/// Subcommand-level orchestration tests live in:
///   * `auth_login_command_test.dart`
///   * `auth_status_command_test.dart`
///   * `auth_logout_command_test.dart`
///   * `auth_refresh_command_test.dart`
library;

import 'package:args/command_runner.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/auth_command.dart';

void main() {
  group('AuthCommand parent (C02)', () {
    test('extends args.Command<int>', () {
      expect(AuthCommand(), isA<Command<int>>());
    });

    test('name is "auth"', () {
      expect(AuthCommand().name, equals('auth'));
    });

    test('description is non-empty', () {
      expect(AuthCommand().description, isNotEmpty);
    });

    test(
      'registers the 4 subcommands required by the spike: login/status/logout/refresh',
      () {
        final cmd = AuthCommand();
        final names = cmd.subcommands.keys.toSet();

        expect(names, contains('login'));
        expect(names, contains('status'));
        expect(names, contains('logout'));
        expect(names, contains('refresh'));
      },
    );
  });
}
