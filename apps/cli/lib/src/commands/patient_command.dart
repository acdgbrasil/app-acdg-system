/// `acdg patient` — patient registry operations. Stub for C01; real impl C03.
library;

import 'package:args/command_runner.dart';

import '_stub_command.dart';

/// Patient registry verbs (list, get, register, update). Stubbed for C01.
final class PatientCommand extends Command<int> {
  PatientCommand({StringSink? stdout}) : _stdout = stdout;

  final StringSink? _stdout;

  @override
  String get name => 'patient';

  @override
  String get description => 'Patient registry operations';

  @override
  Future<int> run() => writeStub(out: _stdout, pendingTicket: 'C03');
}
