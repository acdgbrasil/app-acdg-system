/// `acdg care` — care appointments and intake. Stub for C01; real impl C06.
library;

import 'package:args/command_runner.dart';

import '_stub_command.dart';

/// Care verbs (appointment register, intake info). Stubbed for C01.
final class CareCommand extends Command<int> {
  CareCommand({StringSink? stdout}) : _stdout = stdout;

  final StringSink? _stdout;

  @override
  String get name => 'care';

  @override
  String get description => 'Care appointments and intake';

  @override
  Future<int> run() => writeStub(out: _stdout, pendingTicket: 'C06');
}
