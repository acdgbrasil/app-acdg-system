/// `acdg family` — family member operations. Stub for C01; real impl C04.
library;

import 'package:args/command_runner.dart';

import '_stub_command.dart';

/// Family composition verbs (add, remove, list). Stubbed for C01.
final class FamilyCommand extends Command<int> {
  FamilyCommand({StringSink? stdout}) : _stdout = stdout;

  final StringSink? _stdout;

  @override
  String get name => 'family';

  @override
  String get description => 'Family member operations';

  @override
  Future<int> run() => writeStub(out: _stdout, pendingTicket: 'C04');
}
