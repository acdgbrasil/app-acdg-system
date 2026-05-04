/// `acdg auth` — manage authentication. Parent command (C02).
///
/// Holds the four PKCE Loopback subcommands (login / status / logout /
/// refresh). The C01 stub became a full parent in C02 once the spike
/// landed and PKCE wiring became real.
library;

import 'package:args/command_runner.dart';

import 'auth_login_command.dart';
import 'auth_logout_command.dart';
import 'auth_refresh_command.dart';
import 'auth_status_command.dart';

/// Parent command for `acdg auth login|status|logout|refresh`.
final class AuthCommand extends Command<int> {
  AuthCommand({
    AuthLoginCommand? login,
    AuthStatusCommand? status,
    AuthLogoutCommand? logout,
    AuthRefreshCommand? refresh,
  }) {
    if (login != null) addSubcommand(login);
    if (status != null) addSubcommand(status);
    if (logout != null) addSubcommand(logout);
    if (refresh != null) addSubcommand(refresh);

    // The four-subcommand contract is required by the spike; without
    // wired collaborators, register schema-only placeholders so `--help`
    // still advertises them and `auth_command_test.dart` sees the names.
    if (subcommands.isEmpty) {
      addSubcommand(_PlaceholderCommand('login'));
      addSubcommand(_PlaceholderCommand('status'));
      addSubcommand(_PlaceholderCommand('logout'));
      addSubcommand(_PlaceholderCommand('refresh'));
    }
  }

  @override
  String get name => 'auth';

  @override
  String get description =>
      'Manage authentication (PKCE Loopback OIDC against Zitadel)';

  @override
  Future<int> run() async {
    printUsage();
    return 64; // EX_USAGE — `acdg auth` without a subcommand.
  }
}

/// Schema-only placeholder used when [AuthCommand] is constructed without
/// real collaborators (e.g. by `args` `--help` introspection in tests).
/// The real subcommands are injected by `cli_runner.dart` in production.
final class _PlaceholderCommand extends Command<int> {
  _PlaceholderCommand(this.name);

  @override
  final String name;

  @override
  String get description => 'auth $name';

  @override
  Future<int> run() async {
    printUsage();
    return 64;
  }
}
