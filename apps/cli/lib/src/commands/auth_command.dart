/// `acdg auth` — manage authentication. Stub for C01; real PKCE flow in C02.
library;

import 'package:args/command_runner.dart';

import '_stub_command.dart';

/// Authentication entry point — login, logout, status (C02).
final class AuthCommand extends Command<int> {
  AuthCommand({StringSink? stdout}) : _stdout = stdout;

  final StringSink? _stdout;

  @override
  String get name => 'auth';

  @override
  String get description => 'Manage authentication';

  @override
  Future<int> run() => writeStub(out: _stdout, pendingTicket: 'C02');
}
