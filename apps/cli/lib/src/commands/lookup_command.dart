/// `acdg lookup` — lookup tables and approval requests. Stub for C01; real impl C08.
library;

import 'package:args/command_runner.dart';

import '_stub_command.dart';

/// Lookup verbs (browse tables, request additions). Stubbed for C01.
final class LookupCommand extends Command<int> {
  LookupCommand({StringSink? stdout}) : _stdout = stdout;

  final StringSink? _stdout;

  @override
  String get name => 'lookup';

  @override
  String get description => 'Lookup tables and approval requests';

  @override
  Future<int> run() => writeStub(out: _stdout, pendingTicket: 'C08');
}
