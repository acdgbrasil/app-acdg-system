/// `acdg team` — team management. Stub for C01; real impl C09.
library;

import 'package:args/command_runner.dart';

import '_stub_command.dart';

/// Team verbs (list, invite, role-change). Stubbed for C01.
final class TeamCommand extends Command<int> {
  TeamCommand({StringSink? stdout}) : _stdout = stdout;

  final StringSink? _stdout;

  @override
  String get name => 'team';

  @override
  String get description => 'Team management';

  @override
  Future<int> run() => writeStub(out: _stdout, pendingTicket: 'C09');
}
