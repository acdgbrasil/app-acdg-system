/// `acdg assessment` — update assessment forms. Stub for C01; real impl C05.
library;

import 'package:args/command_runner.dart';

import '_stub_command.dart';

/// Assessment verbs (housing, health, education, ...). Stubbed for C01.
final class AssessmentCommand extends Command<int> {
  AssessmentCommand({StringSink? stdout}) : _stdout = stdout;

  final StringSink? _stdout;

  @override
  String get name => 'assessment';

  @override
  String get description => 'Update assessment forms';

  @override
  Future<int> run() => writeStub(out: _stdout, pendingTicket: 'C05');
}
